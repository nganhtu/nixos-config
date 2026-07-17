# Eldritch dark (kitten themes, jacobrreed — upstream github.com/eldritch-theme/kitty).
# Đây là 1 theme trong bộ sưu tập modules/themes/ — theme ĐANG DÙNG chọn ở
# modules/palette.nix, đừng import file này ở nơi khác. focusRing KHÔNG nằm ở
# đây, palette.nix ghép cố định #ccccff cho mọi theme.
# Tên theo ANSI: black/red/.../white + bright*.
{
  background  = "#171928";
  foreground  = "#ebfafa";
  selectionBg = "#bf4f8e";

  # Màu UI ngoài bảng ANSI.
  border        = "#a48cf2";  # active_border_color gốc theme (viền active = inactive)
  cursorText    = "#f8f8f2";  # cursor_text_color gốc theme
  url           = "#04d1f9";  # url_color gốc theme
  tabInactiveFg = "#7081d0";  # brightBlack (color8) gốc theme

  black         = "#21222c";
  red           = "#f9515d";
  green         = "#37f499";
  yellow        = "#e9f941";
  blue          = "#9071f4";
  magenta       = "#f265b5";
  cyan          = "#04d1f9";
  white         = "#ebfafa";
  brightBlack   = "#7081d0";
  brightRed     = "#f16c75";
  brightGreen   = "#69f8b3";
  brightYellow  = "#f1fc79";
  brightBlue    = "#a48cf2";
  brightMagenta = "#fd92ce";
  brightCyan    = "#66e4fd";
  brightWhite   = "#ffffff";
}
