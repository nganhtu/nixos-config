{ config, pkgs, ... }:

{
  programs.kitty = {
    enable = true;

    font = {
      name = "MonaspiceAr Nerd Font";
      size = 12;
    };

    extraConfig = ''
      modify_font cell_height 110%
      modify_font baseline -1
      font_features MonaspiceArNF-Regular +ss01 +ss02 +ss03 +ss04 +ss05 +ss07 +ss08 +ss09 +ss10 +case
      font_features MonaspiceArNF-Bold +ss01 +ss02 +ss03 +ss04 +ss05 +ss07 +ss08 +ss09 +ss10 +case
      font_features MonaspiceArNF-Italic +ss01 +ss02 +ss03 +ss04 +ss05 +ss07 +ss08 +ss09 +ss10 +case
      font_features MonaspiceArNF-BoldItalic +ss01 +ss02 +ss03 +ss04 +ss05 +ss07 +ss08 +ss09 +ss10 +case
    '';

    settings = {
      # nnn preview-tui: kitty split + icat image preview
      allow_remote_control = "yes";
      listen_on = "unix:/tmp/kitty%i";
      active_border_color = "#ccccff";
      inactive_border_color = "#ccccff";

      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";

      background_opacity = "0.8";
      dynamic_background_opacity = "yes";
      confirm_os_window_close = 0;

      cursor_trail = 1;

      linux_display_server = "auto";

      scrollback_lines = 2000;
      wheel_scroll_min_lines = 1;

      enable_audio_bell = "no";

      window_padding_width = 4;

      # ─── Cherry Midnight (nullxception) ───
      foreground = "#bdc3df";
      background = "#101017";
      selection_foreground = "#101017";
      selection_background = "#bdc3df";

      cursor = "#bdc3df";
      cursor_text_color = "#101017";

      url_color = "#85b6ff";

      tab_bar_background = "#101017";
      active_tab_foreground = "#bdc3df";
      active_tab_background = "#33333f";
      inactive_tab_foreground = "#dedeff";
      inactive_tab_background = "#101017";

      color0  = "#33333f";
      color1  = "#ff568e";
      color2  = "#64de83";
      color3  = "#efff73";
      color4  = "#73a9ff";
      color5  = "#946ff7";
      color6  = "#62c6da";
      color7  = "#dedeff";
      color8  = "#43435a";
      color9  = "#ff69a2";
      color10 = "#73de8a";
      color11 = "#f3ff85";
      color12 = "#85b6ff";
      color13 = "#a481f7";
      color14 = "#71c2d9";
      color15 = "#ebebff";
    };
  };
}
