{ config, pkgs, ... }:

{
  programs.kitty = {
    enable = true;

    font = {
      name = "MonaspiceAR NFM";
      size = 12;
    };

    extraConfig = ''
      modify_font cell_height 110%
      modify_font baseline -1
      font_features MonaspiceArNFM-Regular -calt +ss01 +ss02 +ss03 +ss04 +ss05 +ss07 +ss08 +ss09 +ss10 +case
      font_features MonaspiceArNFM-Bold -calt +ss01 +ss02 +ss03 +ss04 +ss05 +ss07 +ss08 +ss09 +ss10 +case
      font_features MonaspiceRnNFM-Regular -calt +ss01 +ss02 +ss03 +ss04 +ss05 +ss07 +ss08 +ss09 +ss10 +case
      font_features MonaspiceRnNFM-Bold -calt +ss01 +ss02 +ss03 +ss04 +ss05 +ss07 +ss08 +ss09 +ss10 +case

      symbol_map U+3000-U+303F,U+3400-U+4DBF,U+4E00-U+9FFF,U+F900-U+FAFF,U+FF00-U+FFEF LXGW WenKai Mono
      symbol_map U+1100-U+11FF,U+3130-U+318F,U+A960-U+A97F,U+AC00-U+D7FF Noto Sans Mono CJK KR
      symbol_map U+3040-U+309F,U+30A0-U+30FF,U+31F0-U+31FF Noto Sans Mono CJK JP
      symbol_map U+0370-U+03FF,U+1F00-U+1FFF,U+0400-U+052F CaskaydiaCove Nerd Font Mono
    '';

    settings = {
      # kitty remote control (socket riêng mỗi instance)
      allow_remote_control = "yes";
      listen_on = "unix:/tmp/kitty%i";
      active_border_color = "#ccccff";
      inactive_border_color = "#ccccff";

      bold_font = "auto";
      italic_font = "postscript_name=MonaspiceRnNFM-Regular";
      bold_italic_font = "postscript_name=MonaspiceRnNFM-Bold";

      background_opacity = "0.8";
      dynamic_background_opacity = "yes";
      confirm_os_window_close = 0;

      cursor_trail = 1;
      mouse_hide_wait = "-1.0";

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
