# Bliss palette — nguồn màu CHUNG, DUY NHẤT của repo: kitty (modules/kitty.nix),
# theme tuxedo (modules/tuxedo.nix), focus-ring niri (modules/niri.nix). Sửa ở
# đây, tất cả đổi theo khi nrs. KHÔNG viết mã hex ở bất kỳ file nào khác.
# Tên theo ANSI: black/red/.../white + bright*.
{
  background  = "#16181f";
  foreground  = "#eaeaea";
  selectionBg = "#55596d";

  # Màu UI ngoài bảng ANSI.
  border        = "#8080ff";  # viền cửa sổ kitty (active = inactive)
  focusRing     = "#ccccff";  # focus-ring niri
  cursorText    = "#2b2b2b";  # chữ nằm dưới con trỏ kitty
  url           = "#005bbb";
  tabInactiveFg = "#676767";

  black         = "#000000";
  red           = "#ff6f8d";
  green         = "#93ff8d";
  yellow        = "#fffc9b";
  blue          = "#80afff";
  magenta       = "#b1b9f9";
  cyan          = "#95dfff";
  white         = "#c7c7c7";
  brightBlack   = "#969696";
  brightRed     = "#ff7894";
  brightGreen   = "#9aff95";
  brightYellow  = "#fffda9";
  brightBlue    = "#9dc0ff";
  brightMagenta = "#dcdcff";
  brightCyan    = "#a5def7";
  brightWhite   = "#feffff";
}
