{ config, pkgs, noctalia-pkg, ... }:

{
  home.packages = [ pkgs.apple-cursor ];

  programs.niri.settings = {
    prefer-no-csd = true;
    screenshot-path = null;
    hotkey-overlay.skip-at-startup = true;

    cursor = {
      theme = "macOS";
      size = 24;
    };

    debug.honor-xdg-activation-with-invalid-serial = { };

    environment = {
      QS_CONFIG_PATH = "${noctalia-pkg}/share/noctalia-shell";

      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      QT_QPA_PLATFORM = "wayland";
      QT_QPA_PLATFORMTHEME = "gtk3";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      XDG_CURRENT_DESKTOP = "niri";
      XDG_SESSION_TYPE = "wayland";

      QT_IM_MODULE = "fcitx5";
      XMODIFIERS = "@im=fcitx5";
      INPUT_METHOD = "fcitx5";
      SDL_IM_MODULE = "fcitx5";

      _JAVA_AWT_WM_NONREPARENTING = "1";
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

    outputs."eDP-1" = {
      enable = true;
      mode = {
        width = 1920;
        height = 1080;
        refresh = 144.001;
      };
      scale = 1.0;
    };

    window-rules = [
      {
        geometry-corner-radius = {
          top-left = 8.0;
          top-right = 8.0;
          bottom-left = 8.0;
          bottom-right = 8.0;
        };
        clip-to-geometry = true;
        default-column-width.proportion = 1.0;
      }
      {
        matches = [ { app-id = "kitty"; } ];
        default-column-width.proportion = 0.5;
      }
      {
        matches = [ { app-id = "steam"; } ];
        excludes = [ { title = "^[Ss]team$"; } ];
        open-floating = true;
      }
      {
        matches = [ { app-id = "steam"; title = "^notificationtoasts_\\d+_desktop$"; } ];
        default-floating-position = {
          x = 10;
          y = 10;
          relative-to = "bottom-right";
        };
        open-focused = false;
      }
    ];

    layer-rules = [
      {
        matches = [ { namespace = "^noctalia-wallpaper*"; } ];
        place-within-backdrop = true;
      }
    ];

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
