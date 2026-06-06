{ config, pkgs, noctalia-pkg, ... }:

{
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

    input = {
      keyboard.numlock = true;

      touchpad = {
        tap = true;
        natural-scroll = true;
      };

      mouse = {
        accel-profile = "flat";
        accel-speed = 1.0;
      };

      focus-follows-mouse.enable = true;
      workspace-auto-back-and-forth = true;
    };

    layout = {
      gaps = 4;
      center-focused-column = "never";
      background-color = "transparent";
      preset-column-widths = [
        { proportion = 1.0 / 3.0; }
        { proportion = 1.0 / 2.0; }
        { proportion = 2.0 / 3.0; }
      ];
      focus-ring.width = 2;
    };

    binds = {
      "Mod+Return".action.spawn = [ "kitty" ];
      "Mod+Shift+E".action.quit = { };
    };
  };
}
