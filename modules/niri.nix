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

    animations = {
      workspace-switch.kind.spring = {
        damping-ratio = 1.0;
        stiffness = 1000;
        epsilon = 0.0001;
      };
      window-open.kind.easing = {
        duration-ms = 200;
        curve = "ease-out-quad";
      };
      window-close.kind.easing = {
        duration-ms = 200;
        curve = "ease-out-cubic";
      };
      horizontal-view-movement.kind.spring = {
        damping-ratio = 1.0;
        stiffness = 900;
        epsilon = 0.0001;
      };
      window-movement.kind.spring = {
        damping-ratio = 1.0;
        stiffness = 800;
        epsilon = 0.0001;
      };
      window-resize.kind.spring = {
        damping-ratio = 1.0;
        stiffness = 1000;
        epsilon = 0.0001;
      };
      config-notification-open-close.kind.spring = {
        damping-ratio = 0.6;
        stiffness = 1200;
        epsilon = 0.001;
      };
      screenshot-ui-open.kind.easing = {
        duration-ms = 300;
        curve = "ease-out-quad";
      };
      overview-open-close.kind.spring = {
        damping-ratio = 1.0;
        stiffness = 900;
        epsilon = 0.0001;
      };
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
