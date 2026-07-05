{ pkgs, ... }:

let
  # Key pad tay đủ 6 ký tự (không dùng display.key.width — với logo ảnh kitty
  # fastfetch không nhảy cột như logo ascii nên width không có tác dụng).
  title = {
    type = "title";
    color = {
      user = "95";
      at = "92";
      host = "94";
    };
  };

  logo = {
    type = "kitty";
    width = 32;
    padding = {
      top = 1;
      left = 2;
      right = 3;
    };
  };

  info = [
    { type = "os"; key = "os    "; keyColor = "91"; }
    { type = "kernel"; key = "krn   "; keyColor = "93"; }
    { type = "uptime"; key = "up    "; keyColor = "92"; }
    { type = "packages"; key = "pkg   "; keyColor = "96"; }
    { type = "disk"; key = "dsk   "; keyColor = "95"; folders = "/"; }
  ];

  localModules = [ title "break" ] ++ info ++ [
    { type = "wm"; key = "wm    "; keyColor = "91"; }
    { type = "shell"; key = "sh    "; keyColor = "93"; }
    { type = "terminal"; key = "term  "; keyColor = "92"; }
    "break"
    { type = "theme"; key = "thm   "; keyColor = "96"; }
    { type = "icons"; key = "ico   "; keyColor = "94"; }
    { type = "cursor"; key = "cur   "; keyColor = "95"; }
    { type = "font"; key = "fnt   "; keyColor = "91"; }
    { type = "terminalfont"; key = "tfnt  "; keyColor = "93"; }
  ];
in
{
  # chafa: vẽ ảnh bằng ký tự khối màu cho terminal không có kitty graphics
  # (herdr...) — ff dùng làm fallback qua --logo-type data-raw.
  home.packages = [ pkgs.chafa ];

  # KHÔNG dùng config.jsonc — fastfetch trần phải giữ nguyên bản gốc (yêu cầu
  # user). Config của ta nằm ở ff/chafa/ssh.jsonc, chỉ hàm ff (shell.nix) gọi
  # qua --config. Nguồn ảnh do ff truyền qua --logo, random mỗi lần mở shell.
  # type kitty = gửi ảnh in-band qua tty; kitty-direct chỉ gửi path nên chết
  # qua ssh. Bề ngang: 32 (ảnh) + 5 (padding) + 6 (key) + info ≤ 93 cột.
  # Cột key viết tắt nhiều màu thay cho block colors cũ.
  xdg.configFile."fastfetch/ff.jsonc".text = builtins.toJSON {
    inherit logo;
    display.separator = "";
    modules = localModules;
  };

  # Bản cho nhánh chafa (herdr/terminal không graphics): tfnt không detect
  # được ở đó → thêm mem bù dòng, CHỈ bản này (kitty giữ nguyên).
  xdg.configFile."fastfetch/chafa.jsonc".text = builtins.toJSON {
    inherit logo;
    display.separator = "";
    modules = localModules ++ [
      { type = "memory"; key = "mem   "; keyColor = "92"; }
    ];
  };

  # Config cho phiên ssh (ff tự chọn khi có $SSH_CONNECTION): các module GUI
  # (wm/theme/icons/cursor/font) không detect được qua ssh → thay bằng block
  # phần cứng. Logo kitty-icat: `kitten icat` tự lo stream ảnh qua ssh, ổn định
  # hơn đường tự encode của fastfetch (hay tịt vì đo pixel cell qua pty fail).
  # icat tự đặt vị trí ảnh lần nữa sau khi fastfetch đã dời con trỏ theo padding
  # → lệch kép: bỏ top/left, dồn hết khoảng cách vào right (chữ vẫn ở cột 37).
  xdg.configFile."fastfetch/ssh.jsonc".text = builtins.toJSON {
    logo = logo // {
      type = "kitty-icat";
      padding = {
        top = 0;
        left = 0;
        right = 5;
      };
    };
    display.separator = "";
    modules = [ title "break" ] ++ info ++ [
      { type = "shell"; key = "sh    "; keyColor = "93"; }
      { type = "terminal"; key = "term  "; keyColor = "92"; }
      "break"
      { type = "host"; key = "hw    "; keyColor = "96"; }
      # Mặc định kèm "(12+4) @ 4.60 GHz" → dòng dài 99 cột, vượt 93.
      { type = "cpu"; key = "cpu   "; keyColor = "94"; format = "{name}"; }
      { type = "memory"; key = "mem   "; keyColor = "95"; }
      { type = "locale"; key = "loc   "; keyColor = "91"; }
      { type = "battery"; key = "bat   "; keyColor = "93"; }
      { type = "localip"; key = "ip    "; keyColor = "92"; defaultRouteOnly = true; }
    ];
  };
}
