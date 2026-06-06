{ config, pkgs, ... }:

{
  # Không dùng programs.fuzzel.settings vì cần giữ directive `include` ở
  # top-level (ngoài section) để noctalia push colors vào themes/noctalia
  # runtime. Home-manager's INI generator không expose global section.
  # Fuzzel binary đã cài qua environment.systemPackages.
  xdg.configFile."fuzzel/fuzzel.ini".text = ''
    [main]
    font=CaskaydiaCove NF:size=9,LXGW WenKai TC:weight=bold:size=9,Noto Serif KR:weight=bold:size=9
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
}
