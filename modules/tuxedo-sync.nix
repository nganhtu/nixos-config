{ pkgs, ... }:

let
  gistId = "4418ae6298da240da039d04b0ddc2222";
  ghUser = "nganhtu";

  # gist là secret (URL-readable không cần auth) → chỉ push mới cần token.
  # askpass in ra token của nganhtu, không đụng active account (đang ashytuna).
  askpass = pkgs.writeShellScript "tuxedo-sync-askpass" ''
    exec ${pkgs.gh}/bin/gh auth token --user ${ghUser}
  '';

  sync = pkgs.writeShellApplication {
    name = "tuxedo-sync";
    runtimeInputs = with pkgs; [ git coreutils diffutils util-linux ];
    text = ''
      GIST_ID="${gistId}"
      GHUSER="${ghUser}"
      REPO="$HOME/.local/share/tuxedo-sync"
      FILES=(todo.txt done.txt)
      HOST="$(uname -n)"

      # chống 2 lần chạy chồng
      exec 9>"$HOME/.local/share/tuxedo-sync.lock"
      flock -n 9 || exit 0

      # bootstrap clone lần đầu
      if [ ! -d "$REPO/.git" ]; then
        mkdir -p "$(dirname "$REPO")"
        git clone --quiet "https://gist.github.com/$GIST_ID.git" "$REPO"
        printf 'todo.txt merge=union\ndone.txt merge=union\n' > "$REPO/.git/info/attributes"
        git -C "$REPO" config user.name "tuxedo-sync"
        git -C "$REPO" config user.email "tuxedo-sync@$HOST"
      fi
      cd "$REPO"

      # đưa file local vào cây làm việc của repo, nhớ hash để chống race
      declare -A pre
      for f in "''${FILES[@]}"; do
        lp="$HOME/$f"
        if [ -f "$lp" ]; then
          pre["$f"]="$(sha1sum < "$lp")"
          cp -f "$lp" "$f"
        fi
      done

      # commit trạng thái local nếu có thay đổi
      git add -A
      if ! git diff --quiet --cached; then
        git commit --quiet -m "sync $HOST $(date -Is)"
      fi

      # pull + merge (union). fetch không cần auth; offline thì bỏ qua êm.
      if git fetch --quiet origin main 2>/dev/null; then
        if ! git merge --quiet --no-edit origin/main 2>/dev/null; then
          git merge --abort 2>/dev/null || true
        fi
        # push (cần token nganhtu qua askpass; helper rỗng để bỏ qua global helper)
        GIT_ASKPASS="${askpass}" GIT_TERMINAL_PROMPT=0 \
          git -c credential.helper= \
          push --quiet "https://$GHUSER@gist.github.com/$GIST_ID.git" HEAD:main \
          2>/dev/null || true
      fi

      # ghi kết quả merge về $HOME, trừ khi user vừa sửa file giữa chừng
      for f in "''${FILES[@]}"; do
        lp="$HOME/$f"
        [ -f "$f" ] || continue
        if [ -f "$lp" ]; then
          cmp -s "$f" "$lp" && continue
          now="$(sha1sum < "$lp")"
          [ "''${pre[$f]:-}" = "$now" ] || continue
        fi
        cp -f "$f" "$lp.tuxedo-sync.tmp"
        mv -f "$lp.tuxedo-sync.tmp" "$lp"
      done
    '';
  };
in
{
  systemd.user.services.tuxedo-sync = {
    Unit.Description = "Sync tuxedo todo.txt/done.txt qua gist";
    Service = {
      Type = "oneshot";
      ExecStart = "${sync}/bin/tuxedo-sync";
    };
  };

  systemd.user.timers.tuxedo-sync = {
    Unit.Description = "Chạy tuxedo-sync mỗi phút";
    Timer = {
      OnActiveSec = "1min";
      OnUnitActiveSec = "1min";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
