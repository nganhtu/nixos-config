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

}
