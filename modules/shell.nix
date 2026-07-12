{ ... }:

{
  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
  };

  programs.zoxide.enable = true;

  programs.lazygit = {
    enable = true;
    settings.git.pagers = [
      {
        colorArg = "always";
        pager = "delta --paging=never";
      }
    ];
  };

  programs.zsh = {
    enable = true;

    oh-my-zsh = {
      enable = true;
      theme = "natys";
      custom = "${../assets/shell}";
      plugins = [ "git" ];
    };

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 10000;
      save = 10000;
    };

    shellAliases = {
      ls = "lsd";
      l = "ls -l";
      la = "ls -a";
      lla = "ls -la";
      lt = "ls --tree";
      sulla = "sudo lsd -la";
      sult = "sudo lsd --tree";

      cat = "bat";

      vi = "nvim";
      suvi = "sudo -E nvim";
      suhx = "sudo -E hx";

      doco = "docker compose";
      docodul = "docker compose down && docker compose up -d && docker compose logs -f";
      docobuild = "COMPOSE_BAKE=true docker compose build";

      dv = "devenv";
      dvu = "devenv up";
      dvpr = "devenv processes";

      gitcfnganhtu = ''git config user.name "nganhtu" && git config user.email "ng.anh.tu.1123@gmail.com"'';
      gitcfashytuna = ''git config user.name "ashytuna" && git config user.email "ashytuna@gmail.com"'';
      gitcftuna = ''git config user.name "tuna" && git config user.email "tuna@onschool.edu.vn"'';

      cdc = "cd ~/src/Onschool/SLC";


      upsync = "update_and_merge_sync";
    };

    initContent = ''
      export PATH="$HOME/.local/bin:$PATH"

      setopt appendhistory

      # ── herdr: hiện lệnh đang chạy dở lên sidebar (phần AGENTS) ──
      # Shell trần KHÔNG phải "agent" nên custom_status của nó không render;
      # report-agent "phong" pane thành agent tạm → lúc đó mới hiện. LABEL cố
      # định = glyph terminal (nf U+F120) để phân biệt với AI agent thật (claude,
      # …); custom_status = dòng lệnh. Đang chạy = chấm working cạnh space + 1
      # entry ở AGENTS; xong thì release (tắt). Lệnh LỖI nháy blocked 3s rồi tắt.
      # preexec set SAU ~1s để lệnh chớp nhoáng không kịp hiện. Chỉ trong herdr.
      if [[ -n $HERDR_PANE_ID ]]; then
        autoload -Uz add-zsh-hook
        # LABEL = "$" (d\u00f2ng l\u1ec7nh shell), ph\u00e2n bi\u1ec7t v\u1edbi AI agent th\u1eadt (claude\u2026).
        # KH\u00d4NG d\u00f9ng glyph Nerd Font (vd U+F120 ">_"): n\u00f3 n\u1eb1m trong Private Use
        # Area, font sans m\u1eb7c \u0111\u1ecbnh (Segoe UI Variable \u2014 noctalia l\u1ea5y qua fc-match
        # cho notification) KH\u00d4NG c\u00f3 n\u00f3 \u2192 ph\u1ea3i fallback, ra sai advance width
        # (sidebar tr\u00f4ng d\u00ednh v\u00e0o "\u00b7") v\u00e0 nu\u1ed1t lu\u00f4n d\u1ea5u c\u00e1ch quanh label
        # (notification th\u00e0nh ">_needs attention"). "$" c\u00f3 trong c\u1ea3 Monaspace l\u1eabn
        # Segoe UI Variable n\u00ean kh\u00f4ng c\u1ea7n ch\u00e8n g\u00ec th\u00eam. K\u00fd t\u1ef1 kh\u00e1c c\u0169ng an to\u00e0n: \u00bb.
        _herdr_glyph='$'
        # `herdr integration` \u2014 herdr t\u1ef1 nh\u1eadn di\u1ec7n c\u00e1c agent n\u00e0y v\u00e0 t\u1ef1 qu\u1ea3n
        # label + state c\u1ee7a ch\u00fang. 1 pane ch\u1ec9 gi\u1eef 1 agent record, n\u00ean v\u1edbi ch\u00fang
        # shell ch\u1ec9 \u0111\u01b0\u1ee3c g\u00f3p custom_status (report-metadata), TUY\u1ec6T \u0110\u1ed0I kh\u00f4ng
        # report-agent \u2014 s\u1ebd \u0111\u00e8 m\u1ea5t label, state th\u1eadt l\u1eabn notification.
        _herdr_agents=(claude codex copilot cursor devin droid hermes kilo kimi
                       mastracode omp opencode pi qodercli)

        _herdr_report()  { herdr pane report-agent "$HERDR_PANE_ID" --source shell --agent "$_herdr_glyph" --state "$1" --custom-status "$2" &>/dev/null; }
        _herdr_release() { herdr pane release-agent "$HERDR_PANE_ID" --source shell --agent "$_herdr_glyph" &>/dev/null; }
        _herdr_meta()    { herdr pane report-metadata "$HERDR_PANE_ID" --source shell "$@" &>/dev/null; }
        _herdr_focused() { [[ "$(herdr pane get "$HERDR_PANE_ID" 2>/dev/null | jq -r '.result.pane.focused')" == true ]]; }

        # Cắt cho vừa sidebar (mặc định 26 cột; trừ chấm + label + " · " + lề).
        # herdr KHÔNG tự thêm "…", nó cắt cụt → phải tự cắt ngắn hơn bề rộng.
        _herdr_max=16
        _herdr_fit() {
          REPLY=$1
          (( ''${#REPLY} > _herdr_max )) && REPLY="''${REPLY[1,_herdr_max-1]}…"
        }

        # Trạng thái của lệnh foreground, đọc từ termios + wchan:
        #   idle    = tty ở chế độ raw → một TUI (helix, tuxedo, btop) đã chiếm
        #             terminal và đang sẵn sàng nhận phím. KHÔNG chặn ta.
        #   blocked = canonical VÀ (tắt echo | fg kẹt read tty) → đang chờ ta gõ.
        #             -echo là prompt mật khẩu; sudo setuid root nên /proc/<pid>/wchan
        #             bị che (=0) → termios là tín hiệu DUY NHẤT bắt được nó.
        #             wait_woken = kẹt trong read() trên tty (prompt y/N). Hiếm gặp
        #             ngoài ca này: zle/TUI/poll đều ra poll_schedule_timeout.
        #   working = còn lại: lệnh batch đang chạy. nom (nrs) giữ tty canonical
        #             suốt lúc vẽ tiến độ nên KHÔNG bị nhận nhầm thành idle.
        _herdr_state() {
          local flags=(''${(f)"$(stty -F $TTY -a 2>/dev/null | tr ' ;' '\n\n')"})
          if (( ''${#flags} == 0 )); then
            REPLY=working
          elif (( ! $flags[(Ie)icanon] )); then
            REPLY=idle
          elif (( $flags[(Ie)-echo] )); then
            REPLY=blocked
          elif ps -t ''${TTY#/dev/} -o stat=,wchan:20= 2>/dev/null | grep -q '+.*wait_woken'; then
            REPLY=blocked
          else
            REPLY=working
          fi
        }

        _herdr_watch() {
          local state=
          sleep 1
          while :; do
            _herdr_state
            if [[ $REPLY != $state ]]; then
              state=$REPLY
              _herdr_report $state "$1"
              # --sound none: herdr đã tự phát tiếng khi agent đổi state ở space
              # nền ([ui.sound]); toast này chỉ để đọc lệnh nào đang chờ.
              if [[ $state == blocked ]] && ! _herdr_focused; then
                herdr notification show "$1" --body "đang chờ nhập · ''${PWD:t}" --sound none &>/dev/null
              fi
            fi
            sleep 2
          done
        }

        _herdr_preexec() {
          # lệnh mới → dẹp nháy-lỗi còn treo của lệnh trước (kẻo timer của nó
          # release nhầm, hoặc kẹt blocked nếu lệnh này chớp nhoáng < 1s).
          if [[ -n $_herdr_blocked_timer ]]; then
            kill $_herdr_blocked_timer 2>/dev/null
            _herdr_blocked_timer=
            _herdr_release
          fi
          _herdr_fit "$1"
          local cmd=$REPLY
          if (( $_herdr_agents[(Ie)''${''${1%% *}:t}] )); then
            _herdr_agent_cmd=$cmd
            _herdr_meta --custom-status "$cmd"
            return
          fi
          _herdr_cmd=$cmd
          _herdr_start=$SECONDS
          _herdr_watch "$cmd" &!
          _herdr_watcher=$!
        }

        _herdr_precmd() {
          local ret=$?
          if [[ -n $_herdr_agent_cmd ]]; then
            _herdr_meta --clear-custom-status
            _herdr_agent_cmd=
            return $ret
          fi
          [[ -n $_herdr_cmd ]] || return $ret
          [[ -n $_herdr_watcher ]] && kill $_herdr_watcher 2>/dev/null
          local elapsed=$(( SECONDS - _herdr_start ))
          if (( elapsed >= 1 )); then
            if (( ret != 0 )); then
              _herdr_fit "✗ $_herdr_cmd"   # tiền tố ✗ có thể đẩy quá bề rộng → cắt lại
              _herdr_report blocked "$REPLY"
              ( sleep 3 && _herdr_release ) &!
              _herdr_blocked_timer=$!
            else
              _herdr_release
            fi
            if (( elapsed >= 20 )) && ! _herdr_focused; then
              herdr notification show "$_herdr_cmd" --body "xong sau ''${elapsed}s · ''${PWD:t}" --sound done &>/dev/null
            fi
          fi
          _herdr_cmd= _herdr_watcher=
          return $ret
        }

        add-zsh-hook preexec _herdr_preexec
        # precmd chạy TRƯỚC các precmd khác để $? còn nguyên exit status của lệnh;
        # hàm trả lại $ret nên precmd sau (theme...) vẫn thấy đúng exit status.
        precmd_functions=(_herdr_precmd ''${precmd_functions:#_herdr_precmd})
      fi

      # fastfetch với ảnh vuông ngẫu nhiên. Config của ta ở ff.jsonc/ssh.jsonc
      # (modules/fastfetch.nix) — cố ý KHÔNG dùng config.jsonc để `fastfetch`
      # trần giữ nguyên bản gốc. Qua ssh dùng ssh.jsonc (module GUI chết qua
      # ssh → thay block phần cứng, logo kitty-icat để kitten tự stream ảnh).
      # Terminal không có kitty graphics (herdr không passthrough, cũng không
      # trả lời query pixel — đã probe bằng `kitten icat --detect-support`
      # trong pane) → vẽ ảnh bằng chafa symbols (chỉ cần cell, không cần
      # pixel) bơm qua --logo-type data-raw; đường cùng mới về NixOS ascii.
      ff() {
        local dir=~/Pictures/square
        local cache=~/.cache/fastfetch-thumbs
        local cfg=~/.config/fastfetch/ff.jsonc
        local chafacfg=~/.config/fastfetch/chafa.jsonc
        if [[ -n $SSH_CONNECTION ]]; then
          cfg=~/.config/fastfetch/ssh.jsonc
          chafacfg=$cfg
        fi
        # Quét đệ quy mọi thư mục con; cache giữ nguyên cấu trúc con để tên
        # file trùng nhau giữa các folder không đè thumbnail của nhau.
        local pics=("$dir"/**/*.(jpg|jpeg|png|webp)(N))
        if (( ''${#pics} > 0 )); then
          local pic=''${pics[RANDOM % ''${#pics} + 1]}
          local thumb="$cache/''${''${pic#$dir/}:r}.png"
          if [[ ! -f $thumb ]]; then
            mkdir -p "''${thumb:h}"
            magick "$pic" -resize 512x512 "$thumb" 2>/dev/null || thumb=$pic
          fi
          # --logo-recache: né bug fastfetch (≤2.65.1, master chưa sửa) — đường
          # cache ảnh tính logoHeight thừa 1 (thiếu -1 so với đường render mới)
          # → ảnh nào trúng cache là cả block chữ nhảy lên đè dòng lệnh.
          if [[ $TERM == xterm-kitty* ]]; then
            fastfetch --config "$cfg" --logo-recache --logo "$thumb"
            return
          fi
          # 33x15 --stretch: 15 dòng art + 1 padding = 16 dòng chữ (chafa.jsonc
          # thêm mem bù chỗ tfnt mất trong herdr); 33 cột vì cell font hiện tại
          # hẹp hơn tỉ lệ 1:2 chafa giả định — ép khung cho ảnh vuông ra vuông.
          # tty (TERM=linux): font kernel chỉ có 8 glyph khối CP437 (▀▄▌▐█░▒▓)
          # — ép chafa đúng bộ đó kẻo ra rừng #; cell 8x16 chuẩn 1:2 nên 30x15
          # vuông thật không cần --stretch; module GUI chết trong tty nên mượn
          # luôn ssh.jsonc (toàn module phần cứng). Override qua CLI: padding
          # của ssh.jsonc (top/left=0, chỉnh cho kitty-icat) làm ảnh sát mép,
          # còn width=32 kế thừa từ logo gốc > art 30 làm hở thêm 2 cột gap.
          if (( ''${+commands[chafa]} )); then
            local cargs=(--symbols block --stretch -s 33x15)
            local fargs=()
            if [[ $TERM == linux ]]; then
              chafacfg=~/.config/fastfetch/ssh.jsonc
              cargs=(--symbols vhalf+hhalf+solid+stipple -c 16 -s 30x15)
              fargs=(--logo-width 30 --logo-padding-top 1 --logo-padding-left 2 --logo-padding-right 3)
            elif [[ -n $SSH_CONNECTION ]]; then
              # ssh.jsonc để padding top/left=0, right=5 riêng cho path kitty-icat
              # thật (icat tự định vị lại con trỏ nên bù trừ khác); nhánh
              # data-raw/chafa này không qua icat nên không dính quirk đó — cần
              # padding thường như local.
              fargs=(--logo-padding-top 1 --logo-padding-left 2 --logo-padding-right 3)
            fi
            # --polite on: bỏ cặp ESC[?25l/h (giấu/hiện con trỏ) — fastfetch
            # không parse được escape dạng ?25l nên đếm nhầm bề rộng art +3 cột.
            fastfetch --config "$chafacfg" --logo-type data-raw "''${fargs[@]}" \
              --logo "$(chafa -f symbols --polite on "''${cargs[@]}" "$thumb")"
            return
          fi
        fi
        fastfetch --config "$cfg" --logo-type builtin --logo NixOS
      }

      # Resize sẵn toàn bộ ảnh về thumbnail 512px cho ff (chạy trong update).
      ffcache() {
        local dir=~/Pictures/square
        local cache=~/.cache/fastfetch-thumbs
        [[ -d $dir ]] || return 0
        local pics=("$dir"/**/*.(jpg|jpeg|png|webp)(N))
        local total=''${#pics}
        (( total == 0 )) && { echo "ffcache: không có ảnh trong $dir"; return 0; }
        local pic thumb
        local n=0 i=0
        local width=30                                # bề rộng thanh tiến trình
        typeset -A valid                              # tập đường thumb hợp lệ
        for pic in "''${pics[@]}"; do
          (( i += 1 ))
          thumb="$cache/''${''${pic#$dir/}:r}.png"
          valid[$thumb]=1
          if [[ ! -f $thumb || $pic -nt $thumb ]]; then
            mkdir -p "''${thumb:h}"
            magick "$pic" -resize 512x512 "$thumb" && (( n += 1 ))
          fi
          # Thanh tiến trình cập nhật tại chỗ, chỉ vẽ khi stdout là terminal.
          if [[ -t 1 ]]; then
            local filled=$(( i * width / total ))
            printf '\r\e[Kffcache [%s%s] %3d%% (%d/%d)' \
              "''${(l:filled::#:)}" "''${(l:width-filled:)}" $(( i * 100 / total )) $i $total
          fi
        done
        [[ -t 1 ]] && printf '\r\e[K'                 # xóa dòng progress trước khi in kết quả
        # Prune: xóa thumb mồ côi (nguồn đã biến mất) + dọn thư mục con rỗng.
        local p=0
        if [[ -d $cache ]]; then
          for thumb in "$cache"/**/*.png(N); do
            [[ -z ''${valid[$thumb]} ]] && rm -f "$thumb" && (( p += 1 ))
          done
          find "$cache" -mindepth 1 -type d -empty -delete 2>/dev/null
        fi
        echo "ffcache: thêm $n, xóa $p thumbnail mồ côi ($cache)"
      }

      ff

      if command -v fzf >/dev/null 2>&1; then
        source <(fzf --zsh)
      fi

      alias watch_cpu="watch -n 1 \"grep '^[c]pu MHz' /proc/cpuinfo\""

      # gdu interactive — mặc định duyệt cả cây / (gồm /home, /nix); truyền path để soi riêng, vd: diskusage ~
      diskusage() {
        sudo gdu "''${1:-/}"
      }

      check_hmwon() {
        for hwmon in /sys/class/hwmon/hwmon*/name; do
          echo "$hwmon: $(cat $hwmon)"
        done
      }

      # screenrec — quay màn hình chất lượng cao (VAAPI hardware encode trên Intel iGPU, 60fps).
      # Mặc định KHÔNG thu âm. Audio:
      #   -a  thu tiếng máy/app (monitor của sink đang phát, sạch không qua mic)
      #   -m  thu mic (default source)
      # (-a và -m loại trừ nhau; thu cả hai cùng lúc cần virtual combined source.)
      #   screenrec          → toàn màn hình, không tiếng
      #   screenrec -r       → chọn vùng bằng slurp
      #   screenrec -a       → kèm tiếng app
      #   screenrec -m       → kèm mic
      #   (kết hợp được, vd: screenrec -r -a)
      #   Ctrl+C để dừng. File lưu ở ~/Videos/rec-<ngày-giờ>.mp4
      screenrec() {
        local out="$HOME/Videos/rec-$(date +%Y%m%d-%H%M%S).mp4"
        mkdir -p "$HOME/Videos"
        local args=(-c h264_vaapi -d /dev/dri/renderD128 -p qp=18 -r 60)
        local audio=""
        while [[ $# -gt 0 ]]; do
          case "$1" in
            -r) local area; area=$(slurp) || return 1; args+=(-g "$area") ;;
            -a) audio="-a$(pactl get-default-sink).monitor" ;;
            -m) audio="-a" ;;
            *)  echo "screenrec: tùy chọn lạ '$1' (chỉ nhận -r, -a, -m)"; return 1 ;;
          esac
          shift
        done
        [[ -n "$audio" ]] && args+=("$audio")
        echo "Recording → $out   (Ctrl+C để dừng)"
        wf-recorder "''${args[@]}" -f "$out"
      }

      docobash() {
        local container="$1"
        shift
        docker compose exec -it --user 1000 "$container" bash "$@"
      }

      docosh() {
        local container="$1"
        shift
        docker compose exec -it --user 1000 "$container" sh "$@"
      }

      # `devenv processes logs` không có -f; theo dõi realtime bằng tail -F file log
      # (.devenv/run = symlink ổn định tới runtime dir). Không tên → mọi process.
      dvlog() {
        setopt local_options null_glob
        local files=(.devenv/run/processes/logs/''${1:-*}.*.log)
        if (( ''${#files} == 0 )); then
          echo "Không thấy log — devenv đang chạy chưa? (cần .devenv/run/processes/logs)"
          return 1
        fi
        tail -F "''${files[@]}"
      }

      nrs() {
        nh os switch
      }

      update() {
        echo -e "\n[+] Requesting sudo access..."
        sudo pwd

        echo -e "\n[+] Updating flake inputs..."
        (cd ~/nixos-config && nix flake update)

        echo -e "\n[+] Rebuilding NixOS..."
        nh os switch

        echo -e "\n[+] Pruning Docker system..."
        docker system prune -f --volumes || true
        docker network create srm 2>/dev/null || true
        docker network create slc 2>/dev/null || true

        echo -e "\n[+] Updating tldr pages..."
        tldr --update || true

        echo -e "\n[+] Caching fastfetch thumbnails..."
        ffcache || true

        echo -e "\n[+] Cleaning systemd journal (keeping last 1 week)..."
        sudo journalctl --vacuum-time=1w

        echo -e "\n[+] Dọn generation cũ + GC (nh clean, giữ 10 bản)..."
        nh clean all --keep 25

        echo -e "\n[✔] All tasks completed successfully."
      }

      update_and_merge_sync() {
        local current_branch=$(git branch --show-current)
        local remote=$(git config --get branch.$current_branch.remote || echo "origin")

        if [[ -z "$current_branch" ]]; then
          echo "❌ Lỗi: Bạn không ở trong một Git repository."
          return 1
        fi

        local stashed=0
        if ! git diff-index --quiet HEAD --; then
          echo "📦 Phát hiện code chưa commit. Đang tự động cất tạm (stash) để bảo vệ dữ liệu..."
          git stash push -m "Auto-stash before upsync"
          stashed=1
        fi

        echo "🚀 Đang fetch dữ liệu mới nhất từ remote '$remote'..."
        git fetch $remote
        git fetch $remote master:master release:release staging:staging 2>/dev/null || true

        local merge_order=("master" "release" "staging")
        local merge_failed=0

        for br in "''${merge_order[@]}"; do
          echo "\n=> Đang tiến hành merge '$remote/$br' vào '$current_branch'..."
          if git merge "$remote/$br"; then
            echo "✅ Merge '$br' thành công!"
          else
            echo "❌ LỖI: Xảy ra Conflict khi merge '$br'!"
            merge_failed=1
            break
          fi
        done

        if [[ $stashed -eq 1 ]]; then
          if [[ $merge_failed -eq 1 ]]; then
            echo "\n🛑 Quá trình merge đã dừng lại do conflict."
            echo "💡 LƯU Ý: Code đang viết dở của bạn vẫn an toàn trong stash."
            echo "Hãy giải quyết conflict của việc merge trước, commit lại, sau đó gõ lệnh 'git stash pop' để lấy lại code cũ của bạn."
            return 1
          else
            echo "\n♻️ Đang khôi phục lại code chưa commit của bạn..."
            if git stash pop; then
              echo "✅ Đã khôi phục code dở dang thành công!"
            else
              echo "⚠️ CẢNH BÁO: Có conflict giữa code dở dang của bạn và code mới tải về!"
              echo "Đừng lo, code không bị mất. Hãy mở editor lên và resolve conflict cho phần code bạn đang viết nhé."
            fi
          fi
        fi

        if [[ $merge_failed -eq 0 ]]; then
          echo "\n🎉 HOÀN TẤT: Nhánh '$current_branch' đã được update an toàn!"
        fi
      }
    '';
  };
}
