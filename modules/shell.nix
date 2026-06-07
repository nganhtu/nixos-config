{ ... }:

{
  programs.zsh = {
    enable = true;

    oh-my-zsh = {
      enable = true;
      theme = "natys";
      custom = "${../shell}";
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

      ssh = "kitten ssh";
      cat = "bat";

      vi = "nvim";
      suvi = "sudo -E nvim";
      suhx = "sudo -E hx";

      doco = "docker compose";
      docodul = "docker compose down && docker compose up -d && docker compose logs -f";
      docobuild = "COMPOSE_BAKE=true docker compose build";

      gitcfnganhtu = ''git config user.name "nganhtu" && git config user.email "ng.anh.tu.1123@gmail.com"'';
      gitcfashytuna = ''git config user.name "ashytuna" && git config user.email "ashytuna@gmail.com"'';
      gitcftuna = ''git config user.name "tuna" && git config user.email "tuna@onschool.edu.vn"'';

      cdc = "cd ~/src/Onschool/SLC";

      nrs = "sudo nixos-rebuild switch --flake ~/nixos-config#Niquesse";

      upsync = "update_and_merge_sync";
    };

    initContent = ''
      export PATH="$HOME/.local/bin:$PATH"

      setopt appendhistory

      fastfetch -l NixOS -s title:separator:kernel:uptime:packages:shell:wm:terminal:localip:locale:break:theme:icons:cursor:font:terminalfont:break:colors

      if command -v fzf >/dev/null 2>&1; then
        source <(fzf --zsh)
      fi

      alias watch_cpu="watch -n 1 \"grep '^[c]pu MHz' /proc/cpuinfo\""

      check_hmwon() {
        for hwmon in /sys/class/hwmon/hwmon*/name; do
          echo "$hwmon: $(cat $hwmon)"
        done
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

      update() {
        echo -e "\n[+] Requesting sudo access..."
        sudo pwd

        echo -e "\n[+] Pruning Docker system..."
        docker system prune -f || true
        docker network create srm 2>/dev/null || true
        docker network create slc 2>/dev/null || true

        echo -e "\n[+] Updating tldr pages..."
        tldr --update || true

        echo -e "\n[+] Cleaning systemd journal (keeping last 1 week)..."
        sudo journalctl --vacuum-time=1w

        echo -e "\n[+] Updating flake inputs..."
        (cd ~/nixos-config && nix flake update)

        echo -e "\n[+] Rebuilding NixOS..."
        sudo nixos-rebuild switch --flake ~/nixos-config#Niquesse

        echo -e "\n[+] Cleaning old generations (giữ 10 bản gần nhất)..."
        sudo nix-env --delete-generations '+10' --profile /nix/var/nix/profiles/system
        nix-env --delete-generations '+10' --profile "$HOME/.local/state/nix/profiles/home-manager" 2>/dev/null || true

        echo -e "\n[+] Collecting nix garbage (store paths không tham chiếu)..."
        nix-collect-garbage
        sudo nix-collect-garbage

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
