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
      # Helix 25.07 mặc định python dùng ty/ruff, không có pyright → wire lại.
      language-server.pyright = {
        command = "pyright-langserver";
        args = [ "--stdio" ];
      };

      language = [
        {
          name = "python";
          language-servers = [ "pyright" "ruff" ];
        }
        {
          # nil tự được nhận làm LSP; Helix không có formatter nix mặc định.
          name = "nix";
          formatter.command = "nixfmt";
        }
      ];
    };
  };
}
