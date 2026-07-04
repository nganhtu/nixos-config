{ config, pkgs, noctalia-pkg, agenix-pkg, ... }:

{
  imports = [
    ../modules/niri.nix
    ../modules/kitty.nix
    ../modules/helix.nix
    ../modules/btop.nix
    ../modules/fuzzel.nix
    ../modules/theme.nix
    ../modules/claude.nix
    ../modules/shell.nix
    ../modules/thunar.nix
    ../modules/yazi.nix
    ../modules/mangohud.nix
    ../modules/direnv.nix
    ../modules/git.nix
  ];

  home.username = "nat";
  home.homeDirectory = "/home/nat";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  home.packages = [ noctalia-pkg agenix-pkg ];

  # `docker compose` v2 plugin: docker CLI chỉ tìm trong ~/.docker/cli-plugins
  # (các path /usr/... không có trên NixOS).
  home.file.".docker/cli-plugins/docker-compose".source =
    "${pkgs.docker-compose}/libexec/docker/cli-plugins/docker-compose";

  # figma-linux upstream không khai MimeType → portal không nhận ra handler cho figma://.
  # Override desktop entry để thêm, rồi đăng ký default.
  xdg.desktopEntries.figma-linux = {
    name = "Figma Linux";
    exec = "figma-linux %U";
    icon = "figma-linux";
    comment = "Unofficial Figma desktop application for Linux";
    mimeType = [ "x-scheme-handler/figma" ];
  };
  xdg.mimeApps.defaultApplications."x-scheme-handler/figma" = "figma-linux.desktop";

}
