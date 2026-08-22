{ config, pkgs, ... }:

{
  # xdg.configFile thay programs.fuzzel: giữ `include` top-level cho noctalia push theme.
  xdg.configFile."fuzzel/fuzzel.ini" = {
    force = true;
    text = ''
    [main]
    font=Monaspace Xenon NF:size=9:fontfeatures=-calt:fontfeatures=ss01:fontfeatures=ss02:fontfeatures=ss03:fontfeatures=ss04:fontfeatures=ss05:fontfeatures=ss07:fontfeatures=ss08:fontfeatures=ss09:fontfeatures=ss10:fontfeatures=case,LXGW WenKai Mono:size=9
    icon-theme=Papirus

    line-height=24px
    lines=20
    width=100
    horizontal-pad=20
    vertical-pad=20
    inner-pad=10

    include=~/.config/fuzzel/themes/noctalia

    # width/radius thuộc section [border], KHÔNG phải [main] — khai trong [main]
    # thì fuzzel bỏ qua (cảnh báo "not a valid option") và dùng default 1px/10.
    # Đặt sau include để dòng include vẫn nằm trong [main].
    [border]
    width=2
    radius=12
  '';
  };
}
