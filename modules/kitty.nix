{ config, pkgs, ... }:

let
  palette = import ./palette.nix;
in
{
  programs.kitty = {
    enable = true;

    font = {
      name = "Monaspace Argon NF";
      size = 12;
    };

    # Bản tải thẳng từ source (assets/fonts/monaspace) — mỗi family chỉ có 1
    # variant NF (đã monospace sẵn, không còn hậu tố NFM/NFP như bản
    # nerd-fonts.monaspace cũ của nixpkgs) → postscript name đổi từ
    # Monaspice<Ar|Kr|Ne|Rn|Xe>NFM-* sang Monaspace<FullName>NF-*.
    extraConfig = ''
      modify_font cell_height 110%
      modify_font baseline -1
      font_features MonaspaceArgonNF-Regular -calt +ss01 +ss02 +ss03 +ss04 +ss05 +ss07 +ss08 +ss09 +ss10 +case
      font_features MonaspaceArgonNF-Bold -calt +ss01 +ss02 +ss03 +ss04 +ss05 +ss07 +ss08 +ss09 +ss10 +case
      font_features MonaspaceArgonNF-Italic -calt +ss01 +ss02 +ss03 +ss04 +ss05 +ss07 +ss08 +ss09 +ss10 +case
      font_features MonaspaceArgonNF-BoldItalic -calt +ss01 +ss02 +ss03 +ss04 +ss05 +ss07 +ss08 +ss09 +ss10 +case
      font_features MonaspaceKryptonNF-Regular -calt +ss01 +ss02 +ss03 +ss04 +ss05 +ss07 +ss08 +ss09 +ss10 +case
      font_features MonaspaceKryptonNF-Bold -calt +ss01 +ss02 +ss03 +ss04 +ss05 +ss07 +ss08 +ss09 +ss10 +case
      font_features MonaspaceKryptonNF-Italic -calt +ss01 +ss02 +ss03 +ss04 +ss05 +ss07 +ss08 +ss09 +ss10 +case
      font_features MonaspaceKryptonNF-BoldItalic -calt +ss01 +ss02 +ss03 +ss04 +ss05 +ss07 +ss08 +ss09 +ss10 +case
      font_features MonaspaceNeonNF-Regular -calt +ss01 +ss02 +ss03 +ss04 +ss05 +ss07 +ss08 +ss09 +ss10 +case
      font_features MonaspaceNeonNF-Bold -calt +ss01 +ss02 +ss03 +ss04 +ss05 +ss07 +ss08 +ss09 +ss10 +case
      font_features MonaspaceNeonNF-Italic -calt +ss01 +ss02 +ss03 +ss04 +ss05 +ss07 +ss08 +ss09 +ss10 +case
      font_features MonaspaceNeonNF-BoldItalic -calt +ss01 +ss02 +ss03 +ss04 +ss05 +ss07 +ss08 +ss09 +ss10 +case
      font_features MonaspaceRadonNF-Regular -calt +ss01 +ss02 +ss03 +ss04 +ss05 +ss07 +ss08 +ss09 +ss10 +case
      font_features MonaspaceRadonNF-Bold -calt +ss01 +ss02 +ss03 +ss04 +ss05 +ss07 +ss08 +ss09 +ss10 +case
      font_features MonaspaceRadonNF-Italic -calt +ss01 +ss02 +ss03 +ss04 +ss05 +ss07 +ss08 +ss09 +ss10 +case
      font_features MonaspaceRadonNF-BoldItalic -calt +ss01 +ss02 +ss03 +ss04 +ss05 +ss07 +ss08 +ss09 +ss10 +case
      font_features MonaspaceXenonNF-Regular -calt +ss01 +ss02 +ss03 +ss04 +ss05 +ss07 +ss08 +ss09 +ss10 +case
      font_features MonaspaceXenonNF-Bold -calt +ss01 +ss02 +ss03 +ss04 +ss05 +ss07 +ss08 +ss09 +ss10 +case
      font_features MonaspaceXenonNF-Italic -calt +ss01 +ss02 +ss03 +ss04 +ss05 +ss07 +ss08 +ss09 +ss10 +case
      font_features MonaspaceXenonNF-BoldItalic -calt +ss01 +ss02 +ss03 +ss04 +ss05 +ss07 +ss08 +ss09 +ss10 +case

      symbol_map U+23FB-U+23FE,U+2630,U+2665,U+26A1,U+276C-U+2771,U+2B58,U+E000-U+E00A,U+E0A0-U+E0A3,U+E0B0-U+E0C8,U+E0CA,U+E0CC-U+E0D2,U+E0D4,U+E0D6-U+E0D7,U+E200-U+E2A9,U+E300-U+E3E3,U+E5FA-U+E6B8,U+E700-U+E8EF,U+EA60-U+EA88,U+EA8A-U+EA8C,U+EA8F-U+EAC7,U+EAC9,U+EACC-U+EB09,U+EB0B-U+EB4E,U+EB50-U+EC1E,U+ED00-U+EFCE,U+F000-U+F381,U+F400-U+F533,U+F0001-U+F1AF0 Symbols Nerd Font Mono
      symbol_map U+3000-U+303F,U+3400-U+4DBF,U+4E00-U+9FFF,U+F900-U+FAFF,U+FF00-U+FFEF LXGW WenKai Mono
      symbol_map U+1100-U+11FF,U+3130-U+318F,U+A960-U+A97F,U+AC00-U+D7FF Noto Sans Mono CJK KR
      symbol_map U+3040-U+309F,U+30A0-U+30FF,U+31F0-U+31FF Noto Sans Mono CJK JP
    '';

    settings = {
      # kitty remote control (socket riêng mỗi instance)
      allow_remote_control = "yes";
      listen_on = "unix:/tmp/kitty%i";
      active_border_color = "#8080ff";
      inactive_border_color = "#8080ff";

      bold_font = "auto";
      italic_font = "postscript_name=MonaspaceRadonNF-Regular";
      bold_italic_font = "postscript_name=MonaspaceRadonNF-Bold";

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

      # ─── Bliss (Joshua Jon / Eric Johnson) — màu từ modules/palette.nix ───
      foreground = palette.foreground;
      background = palette.background;
      selection_foreground = palette.brightWhite;
      selection_background = palette.selectionBg;

      cursor = palette.white;
      cursor_text_color = "#2b2b2b";

      url_color = "#005bbb";

      tab_bar_background = palette.black;
      active_tab_foreground = palette.brightWhite;
      active_tab_background = palette.white;
      inactive_tab_foreground = "#676767";
      inactive_tab_background = palette.black;

      color0  = palette.black;
      color1  = palette.red;
      color2  = palette.green;
      color3  = palette.yellow;
      color4  = palette.blue;
      color5  = palette.magenta;
      color6  = palette.cyan;
      color7  = palette.white;
      color8  = palette.brightBlack;
      color9  = palette.brightRed;
      color10 = palette.brightGreen;
      color11 = palette.brightYellow;
      color12 = palette.brightBlue;
      color13 = palette.brightMagenta;
      color14 = palette.brightCyan;
      color15 = palette.brightWhite;
    };
  };
}
