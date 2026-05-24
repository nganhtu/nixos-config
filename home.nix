{ config, pkgs, ... }:

{
  home.username = "nat";
  home.homeDirectory = "/home/nat";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
