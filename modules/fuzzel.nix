{ config, pkgs, ... }:

{
  # xdg.configFile thay programs.fuzzel: giữ `include` top-level cho noctalia push theme.
  xdg.configFile."fuzzel/fuzzel.ini" = {
    force = true;
    text = ''
    [main]
    font=Google Sans Code:size=9,LXGW WenKai:weight=bold:size=9,Noto Sans CJK KR:weight=bold:size=9,Noto Sans CJK JP:weight=bold:size=9
    prompt="󰅍  Clipboard history: "
    icon-theme=Papirus

    lines=20
    width=100
    horizontal-pad=20
    vertical-pad=20
    inner-pad=10

    border-width=2
    border-radius=12

    include=~/.config/fuzzel/themes/noctalia
  '';
  };
}
