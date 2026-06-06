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
  };
}
