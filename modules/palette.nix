# Chọn theme đang dùng trong bộ sưu tập modules/themes/ + ghép focusRing cố
# định. Đây là nguồn màu CHUNG, DUY NHẤT của repo: kitty (modules/kitty.nix),
# theme tuxedo (modules/tuxedo.nix), focus-ring niri (modules/niri.nix). Đổi
# theme: chỉ sửa dòng `theme = import ...` bên dưới, KHÔNG cần đụng gì khác.
# KHÔNG viết mã hex ở bất kỳ file nào khác ngoài palette.nix và modules/themes/*.nix.
let
  theme = import ./themes/eldritch-dark.nix;
in
theme // {
  # focusRing CỐ Ý tách khỏi các theme trong modules/themes/ — luôn #ccccff dù
  # đổi theme nào, khỏi phải sửa lại mỗi lần.
  focusRing = "#ccccff";
}
