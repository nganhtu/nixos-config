{ config, pkgs, noctalia-pkg, ... }:

{
  imports = [ ./modules/niri.nix ];

  home.username = "nat";
  home.homeDirectory = "/home/nat";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  home.packages = [ noctalia-pkg ];

  programs.noctalia-shell.enable = true;
}
