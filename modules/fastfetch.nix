{ lib, pkgs, ... }:

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

  # Màu key chia vòng 6 màu bright theo đúng thứ tự hiển thị của từng config —
  # thêm/bớt/đảo module thoải mái, màu tự chan đều lại. Title không có key nên
  # giữ nguyên màu riêng ở trên.
  palette = [ "91" "92" "93" "94" "95" "96" ];
  colorize = mods:
    (builtins.foldl'
      (acc: m:
        if builtins.isAttrs m && m ? key then {
          i = acc.i + 1;
          out = acc.out ++ [ (m // { keyColor = builtins.elemAt palette (lib.mod acc.i 6); }) ];
        } else {
          i = acc.i;
          out = acc.out ++ [ m ];
        })
      { i = 0; out = [ ]; }
      mods).out;

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
    { type = "os"; key = "os    "; }
    { type = "kernel"; key = "krn   "; }
    { type = "packages"; key = "pkg   "; }
    { type = "btrfs"; key = "btrfs "; }
  ];

  # fastfetch không có module mạng gộp wifi+ethernet (wifi chỉ biết wifi,
  # localip chỉ ra iface+IP) → module command chạy nmcli: wifi ra SSID,
  # dây ra "ethernet", cắm cả hai ra "ethernet + <SSID>".
  net = {
    type = "command";
    key = "net   ";
    text = ''nmcli -t -f NAME,TYPE connection show --active | awk -F: '$2~/wireless/{v[n++]=$1} $2~/ethernet/{v[n++]="ethernet"} END{for(i=0;i<n;i++) printf "%s%s", (i?" + ":""), v[i]; print ""}' '';
  };

  localModules = [ title "break" ] ++ info ++ [
    { type = "wm"; key = "wm    "; }
    { type = "shell"; key = "sh    "; }
    { type = "terminal"; key = "term  "; }
    net
    "break"
    { type = "theme"; key = "thm   "; }
    { type = "icons"; key = "ico   "; }
    { type = "cursor"; key = "cur   "; }
    { type = "font"; key = "fnt   "; }
    { type = "terminalfont"; key = "tfnt  "; }
  ];
in
{
  # chafa: vẽ ảnh bằng ký tự khối màu cho terminal không có kitty graphics
  # (herdr, tty...) — ff dùng làm fallback qua --logo-type data-raw.
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
    modules = colorize localModules;
  };

  # Bản cho nhánh chafa (herdr/terminal không graphics): tfnt không detect
  # được ở đó → thêm mem bù dòng, CHỈ bản này (kitty giữ nguyên).
  xdg.configFile."fastfetch/chafa.jsonc".text = builtins.toJSON {
    inherit logo;
    display.separator = "";
    modules = colorize (localModules ++ [
      { type = "memory"; key = "mem   "; }
    ]);
  };

  # Config cho phiên ssh (ff tự chọn khi có $SSH_CONNECTION) và tty: các module
  # GUI (wm/theme/icons/cursor/font) không detect được ở đó → thay bằng block
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
    modules = colorize ([ title "break" ] ++ info ++ [
      { type = "shell"; key = "sh    "; }
      { type = "terminal"; key = "term  "; }
      net
      "break"
      { type = "host"; key = "hw    "; }
      # Mặc định kèm "(12+4) @ 4.60 GHz" → dòng dài 99 cột, vượt 93.
      { type = "cpu"; key = "cpu   "; format = "{name}"; }
      { type = "memory"; key = "mem   "; }
      { type = "locale"; key = "loc   "; }
      { type = "battery"; key = "bat   "; }
      # Bù dòng cho block 1 ngắn đi (bỏ up) — giữ 16 dòng cân với art tty.
      { type = "loadavg"; key = "load  "; }
    ]);
  };
}
