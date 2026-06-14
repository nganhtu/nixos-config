{ config, pkgs, ... }:

{
  programs.helix = {
    enable = true;

    settings = {
      theme = "transparent_focus_nova";

      editor = {
        insert-final-newline = true;
        soft-wrap.enable = true;
        trim-final-newlines = true;

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        indent-guides = {
          render = true;
          character = "│";
        };

        inline-diagnostics = {
          cursor-line = "error";
          other-lines = "warning";
          max-diagnostics = 50;
        };

        statusline = {
          left = [ "mode" "spinner" "file-name" "file-modification-indicator" ];
          center = [ "version-control" "diagnostics" ];
          right = [ "selections" "position" "file-type" "file-line-ending" ];
        };
      };
    };

    themes.transparent_focus_nova = {
      inherits = "focus_nova";
      "ui.background" = { };
    };

    languages = {
      language-server = {
        # Helix 25.07 mặc định python dùng ty/ruff, không có pyright → wire lại.
        pyright = {
          command = "pyright-langserver";
          args = [ "--stdio" ];
        };
        nixd.command = "nixd";
        phpactor = {
          command = "phpactor";
          args = [ "language-server" ];
        };
        tailwindcss = {
          command = "tailwindcss-language-server";
          args = [ "--stdio" ];
        };
        vuels = {
          command = "vue-language-server";
          args = [ "--stdio" ];
          config.typescript.tsdk = "${pkgs.typescript}/lib/node_modules/typescript/lib";
          config.vue.hybridMode = false;
        };
      };

      language = [
        {
          name = "python";
          language-servers = [ "pyright" "ruff" ];
        }
        {
          # nixd thay nil (hiểu được option NixOS/flake); nixfmt làm formatter.
          name = "nix";
          language-servers = [ "nixd" ];
          formatter.command = "nixfmt";
        }
        {
          # intelephense (free) thiếu rename → ghép phpactor lo riêng rename-symbol.
          name = "php";
          language-servers = [
            "intelephense"
            {
              name = "phpactor";
              only-features = [ "rename-symbol" ];
            }
          ];
        }
        {
          name = "html";
          language-servers = [ "vscode-html-language-server" "tailwindcss" ];
        }
        {
          name = "css";
          language-servers = [ "vscode-css-language-server" "tailwindcss" ];
        }
        {
          name = "jsx";
          language-servers = [ "typescript-language-server" "tailwindcss" ];
        }
        {
          name = "tsx";
          language-servers = [ "typescript-language-server" "tailwindcss" ];
        }
        {
          name = "svelte";
          language-servers = [ "svelteserver" "tailwindcss" ];
        }
        {
          name = "vue";
          language-servers = [ "vuels" "tailwindcss" ];
        }
      ];
    };
  };

  # Override Helix.desktop của nixpkgs (Exec=hx, Terminal=true) → mở trong kitty.
  # Bỏ ConsoleOnly để file manager "Open With" liệt kê được.
  xdg.desktopEntries.Helix = {
    name = "Helix";
    genericName = "Text Editor";
    comment = "Edit text files";
    exec = "kitty hx %F";
    terminal = false;
    type = "Application";
    icon = "helix";
    categories = [ "Utility" "TextEditor" ];
    startupNotify = false;
    mimeType = [ "text/plain" "text/x-makefile" "application/x-shellscript" ];
    settings.Keywords = "Text;editor;";
  };
}
