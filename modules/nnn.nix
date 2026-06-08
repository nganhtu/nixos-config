{ config, pkgs, ... }:

{
  home.packages = [
    (pkgs.nnn.override { withNerdIcons = true; })
  ];

  xdg.configFile = {
    "nnn/plugins/.nnn-plugin-helper".source = ../nnn/plugins/.nnn-plugin-helper;
    "nnn/plugins/opener" = {
      source = ../nnn/plugins/opener;
      executable = true;
    };
    "nnn/plugins/fzopen" = {
      source = ../nnn/plugins/fzopen;
      executable = true;
    };
    "nnn/plugins/preview-tui" = {
      source = ../nnn/plugins/preview-tui;
      executable = true;
    };
  };

  home.sessionVariables = {
    NNN_PLUG = "p:preview-tui;f:fzopen";
    NNN_FCOLORS = "c1e2272e006033f7c6d6abc4";
    NNN_FIFO = "/tmp/nnn.fifo";
    NNN_OPENER = "${config.xdg.configHome}/nnn/plugins/opener";
    VISUAL = "hx";
    EDITOR = "hx";
  };

  programs.zsh.shellAliases = {
    nnn = "nnn -H -P p";
  };
}
