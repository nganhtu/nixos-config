{ ... }:

{
  # Lớp config đọc-chỉ của noctalia v5 = ~/.config/noctalia/*.toml. State runtime
  # (màu từ wallpaper, toggle trong bar) nằm riêng ở ~/.local/state/noctalia/
  # settings.toml, nên symlink read-only ở đây KHÔNG đóng băng thứ gì.
  #
  # Chrome gửi web notification (YouTube…) với urgency=critical + expire_timeout=0
  # — cả hai theo spec freedesktop nghĩa là "đừng bao giờ tự tắt", nên chúng nằm
  # lì tới khi bấm x. allow_permanent=false ép timeout 0 về mặc định (6s).
  #
  # PHẢI là bảng có tên [notification.filter.<tên>] (schema dùng namedMap).
  # Viết [[notification.filter]] thì noctalia bỏ qua trong im lặng, `noctalia
  # config validate` vẫn báo hợp lệ.
  xdg.configFile."noctalia/notifications.toml".text = ''
    [notification.filter.chrome-no-permanent]
    match = "chrome"
    allow_permanent = false
  '';
}
