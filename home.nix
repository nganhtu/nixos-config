{ config, pkgs, noctalia-pkg, ... }:

{
  imports = [
    ./modules/niri.nix
    ./modules/kitty.nix
    ./modules/helix.nix
    ./modules/btop.nix
    ./modules/fuzzel.nix
    ./modules/theme.nix
    ./modules/claude.nix
    ./modules/shell.nix
  ];

  home.username = "nat";
  home.homeDirectory = "/home/nat";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  home.packages = [ noctalia-pkg ];

  programs.noctalia-shell.enable = true;
}
