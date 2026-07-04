{ config, pkgs, options, ... }:

{
  home.packages = [ pkgs.apple-cursor ];

  # open-maximized-to-edges chưa có trong schema niri-flake (PR #1382 chưa merge)
  # → nối node KDL thô vào config render từ settings. Ristretto xin maximize lúc
  # mở; niri unstable map maximize sang "maximized-to-edges" (sát mép, không
  # gaps/bo góc) và chỉ rule này chặn được — open-maximized giờ chỉ là full-width.
  programs.niri.config = options.programs.niri.config.default ++ [
    {
      name = "window-rule";
      arguments = [ ];
      properties = { };
      children = [
        {
          name = "match";
          arguments = [ ];
          properties.app-id = "^org\\.xfce\\.ristretto$";
          children = [ ];
        }
        {
          name = "open-maximized-to-edges";
          arguments = [ false ];
          properties = { };
          children = [ ];
        }
      ];
    }
  ];

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
      NIXOS_OZONE_WL = "1";
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

    xwayland-satellite.path = "${pkgs.xwayland-satellite}/bin/xwayland-satellite";

    spawn-at-startup = [
      { command = [ "noctalia" ]; }
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
      {
        matches = [ { app-id = "swappy"; } ];
        open-floating = true;
      }
      {
        matches = [ { app-id = "^xdg-desktop-portal-gtk$"; } ];
        open-floating = true;
      }
      {
        matches = [ { app-id = "thunar"; title = "^Rename "; } ];
        open-floating = true;
      }
      {
        matches = [ { app-id = "^org\\.gnome\\.FileRoller$"; } ];
        open-floating = true;
      }
      {
        # Ristretto tự xin fullscreen/maximize lúc mở; open-maximized-to-edges
        # (phần chặn maximize) nằm ở block programs.niri.config phía trên.
        matches = [ { app-id = "^org\\.xfce\\.ristretto$"; } ];
        open-fullscreen = false;
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
      focus-ring = {
        width = 2;
        active.color = "#CCCCFF";
      };
    };

    binds = {
      # ─── Hotkey overlay ───
      "Mod+Shift+Escape".action.show-hotkey-overlay = { };

      # ─── Apps ───
      "Mod+Return" = {
        hotkey-overlay.title = "Open Terminal: kitty";
        action.spawn = [ "kitty" ];
      };
      "Mod+D" = {
        hotkey-overlay.title = "Open App Launcher: noctalia launcher";
        action.spawn = [ "noctalia" "msg" "panel-toggle" "launcher" ];
      };
      "Mod+B" = {
        hotkey-overlay.title = "Open Browser: Google Chrome";
        action.spawn = [ "google-chrome-stable" ];
      };
      "Mod+Alt+L" = {
        hotkey-overlay.title = "Lock Screen: noctalia lock";
        action.spawn = [ "noctalia" "msg" "session" "lock" ];
      };
      "Mod+Shift+Q" = {
        hotkey-overlay.title = "Session Menu: noctalia sessionMenu";
        action.spawn = [ "noctalia" "msg" "panel-toggle" "session" ];
      };
      "Mod+E" = {
        hotkey-overlay.title = "File Manager: Thunar";
        action.spawn = [ "thunar" ];
      };

      # ─── Media controls ───
      "XF86AudioRaiseVolume" = {
        allow-when-locked = true;
        action.spawn = [ "noctalia" "msg" "volume-up" ];
      };
      "XF86AudioLowerVolume" = {
        allow-when-locked = true;
        action.spawn = [ "noctalia" "msg" "volume-down" ];
      };
      "XF86AudioMute" = {
        allow-when-locked = true;
        action.spawn = [ "noctalia" "msg" "volume-mute" ];
      };
      "XF86AudioMicMute" = {
        allow-when-locked = true;
        action.spawn = [ "noctalia" "msg" "mic-mute" ];
      };
      "XF86AudioNext" = {
        allow-when-locked = true;
        action.spawn = [ "noctalia" "msg" "media" "next" ];
      };
      "XF86AudioPrev" = {
        allow-when-locked = true;
        action.spawn = [ "noctalia" "msg" "media" "previous" ];
      };
      "XF86AudioPlay" = {
        allow-when-locked = true;
        action.spawn = [ "noctalia" "msg" "media" "toggle" ];
      };
      "XF86AudioPause" = {
        allow-when-locked = true;
        action.spawn = [ "noctalia" "msg" "media" "toggle" ];
      };

      # ─── Brightness ───
      "XF86MonBrightnessUp" = {
        allow-when-locked = true;
        action.spawn = [ "noctalia" "msg" "brightness-up" ];
      };
      "XF86MonBrightnessDown" = {
        allow-when-locked = true;
        action.spawn = [ "noctalia" "msg" "brightness-down" ];
      };

      # ─── Window/focus ───
      "Mod+Q".action.close-window = { };

      "Mod+Left".action.focus-column-left = { };
      "Mod+H".action.focus-column-left = { };
      "Mod+Right".action.focus-column-right = { };
      "Mod+L".action.focus-column-right = { };
      "Mod+Up".action.focus-window-up = { };
      "Mod+K".action.focus-window-up = { };
      "Mod+Down".action.focus-window-down = { };
      "Mod+J".action.focus-window-down = { };

      "Mod+WheelScrollRight".action.focus-column-right = { };
      "Mod+WheelScrollLeft".action.focus-column-left = { };
      "Mod+Ctrl+WheelScrollRight".action.move-column-right = { };
      "Mod+Ctrl+WheelScrollLeft".action.move-column-left = { };

      "Mod+Ctrl+Left".action.move-column-left = { };
      "Mod+Ctrl+H".action.move-column-left = { };
      "Mod+Ctrl+Right".action.move-column-right = { };
      "Mod+Ctrl+L".action.move-column-right = { };
      "Mod+Ctrl+Up".action.move-window-up = { };
      "Mod+Ctrl+K".action.move-window-up = { };
      "Mod+Ctrl+Down".action.move-window-down = { };
      "Mod+Ctrl+J".action.move-window-down = { };

      "Mod+Home".action.focus-column-first = { };
      "Mod+End".action.focus-column-last = { };
      "Mod+Ctrl+Home".action.move-column-to-first = { };
      "Mod+Ctrl+End".action.move-column-to-last = { };

      "Mod+Shift+Left".action.focus-monitor-left = { };
      "Mod+Shift+Right".action.focus-monitor-right = { };
      "Mod+Shift+Up".action.focus-monitor-up = { };
      "Mod+Shift+Down".action.focus-monitor-down = { };

      "Mod+Shift+Ctrl+Left".action.move-column-to-monitor-left = { };
      "Mod+Shift+Ctrl+Right".action.move-column-to-monitor-right = { };
      "Mod+Shift+Ctrl+Up".action.move-column-to-monitor-up = { };
      "Mod+Shift+Ctrl+Down".action.move-column-to-monitor-down = { };

      # ─── Workspace switching ───
      "Mod+WheelScrollDown" = {
        cooldown-ms = 150;
        action.focus-workspace-down = { };
      };
      "Mod+WheelScrollUp" = {
        cooldown-ms = 150;
        action.focus-workspace-up = { };
      };
      "Mod+Ctrl+WheelScrollDown" = {
        cooldown-ms = 150;
        action.move-column-to-workspace-down = { };
      };
      "Mod+Ctrl+WheelScrollUp" = {
        cooldown-ms = 150;
        action.move-column-to-workspace-up = { };
      };

      "Mod+Alt+Up".action.focus-workspace-up = { };
      "Mod+Alt+Down".action.focus-workspace-down = { };
      "Mod+Alt+Left".action.focus-column-left = { };
      "Mod+Alt+Right".action.focus-column-right = { };

      "Mod+Shift+WheelScrollDown".action.focus-column-right = { };
      "Mod+Shift+WheelScrollUp".action.focus-column-left = { };
      "Mod+Ctrl+Shift+WheelScrollDown".action.move-column-right = { };
      "Mod+Ctrl+Shift+WheelScrollUp".action.move-column-left = { };

      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+5".action.focus-workspace = 5;
      "Mod+6".action.focus-workspace = 6;
      "Mod+7".action.focus-workspace = 7;
      "Mod+8".action.focus-workspace = 8;
      "Mod+9".action.focus-workspace = 9;
      "Mod+0".action.focus-workspace = 10;

      "Mod+Shift+1".action.move-column-to-workspace = 1;
      "Mod+Shift+2".action.move-column-to-workspace = 2;
      "Mod+Shift+3".action.move-column-to-workspace = 3;
      "Mod+Shift+4".action.move-column-to-workspace = 4;
      "Mod+Shift+5".action.move-column-to-workspace = 5;
      "Mod+Shift+6".action.move-column-to-workspace = 6;
      "Mod+Shift+7".action.move-column-to-workspace = 7;
      "Mod+Shift+8".action.move-column-to-workspace = 8;
      "Mod+Shift+9".action.move-column-to-workspace = 9;
      "Mod+Shift+0".action.move-column-to-workspace = 10;

      "Mod+Tab".action.focus-workspace-previous = { };
      "Mod+Shift+Tab".action.focus-window-previous = { };

      # ─── Layout controls ───
      "Mod+F".action.set-column-width = "100%";
      "Mod+Shift+F".action.expand-column-to-available-width = { };
      "Mod+C".action.center-column = { };
      "Mod+Shift+C".action.center-visible-columns = { };
      "Mod+Minus".action.set-column-width = "-10%";
      "Mod+Equal".action.set-column-width = "+10%";
      "Mod+Shift+Minus".action.set-window-height = "-10%";
      "Mod+Shift+Equal".action.set-window-height = "+10%";

      # ─── Modes ───
      "Mod+T".action.toggle-window-floating = { };
      "Mod+Ctrl+F".action.fullscreen-window = { };
      "Mod+W".action.toggle-column-tabbed-display = { };

      # ─── Screenshots ───
      "Mod+Shift+S".action.spawn = [
        "bash" "-c"
        "area=$(slurp); if [ -n \"$area\" ]; then grim -g \"$area\" - | tee >(wl-copy) | env GDK_BACKEND=x11 swappy -f -; fi"
      ];
      "Print".action.screenshot-screen.show-pointer = false;
      "Mod+Ctrl+Shift+S".action.screenshot-window = { };

      # ─── Emergency escape ───
      "Mod+Escape" = {
        allow-inhibiting = false;
        action.toggle-keyboard-shortcuts-inhibit = { };
      };

      # ─── Exit / Power ───
      "Ctrl+Alt+Delete".action.quit = { };
      "Mod+Shift+P".action.power-off-monitors = { };
      "Mod+Grave" = {
        repeat = false;
        action.toggle-overview = { };
      };

      # ─── Clipboard ───
      "Mod+V".action.spawn = [ "noctalia" "msg" "panel-toggle" "clipboard" ];
      "Mod+Alt+V".action.spawn = [ "sh" "-c" "cliphist list | fuzzel --dmenu | cliphist decode | wl-copy" ];

      # ─── File search ───
      "Mod+Alt+D".action.spawn = [
        "sh" "-c"
        "sel=$(fd --type f . \"$HOME\" | fuzzel --dmenu) && xdg-open \"$sel\""
      ];
    };
  };
}
