{ config, pkgs, noctalia-pkg, ... }:

{
  home.username = "nat";
  home.homeDirectory = "/home/nat";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  home.packages = [ noctalia-pkg ];

  programs.niri.settings = {
    prefer-no-csd = true;
    hotkey-overlay.skip-at-startup = true;

    environment = {
      QS_CONFIG_PATH = "${noctalia-pkg}/share/noctalia-shell";
    };

    spawn-at-startup = [
      { command = [ "noctalia-shell" ]; }
      { command = [ "fcitx5" "-d" ]; }
      { command = [ "wl-paste" "--watch" "cliphist" "store" ]; }
    ];

    layout.background-color = "transparent";

    binds = {
      "Mod+Return".action.spawn = [ "kitty" ];
      "Mod+Shift+E".action.quit = {};
    };
  };

  programs.noctalia-shell.enable = true;
}
