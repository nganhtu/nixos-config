{
  description = "NixOS — Niquesse (Niri + Noctalia)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia-v4 = {
      url = "github:noctalia-dev/noctalia-shell/v4.7.7";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, niri-flake, noctalia, noctalia-v4, ... }:
  let
    system = "x86_64-linux";
  in {
    nixosConfigurations.Niquesse = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./hosts/niquesse/configuration.nix
        niri-flake.nixosModules.niri
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "hm-bak";
          home-manager.users.nat = import ./home/nat.nix;
          home-manager.extraSpecialArgs = {
            noctalia-pkg = noctalia.packages.${system}.default;
            noctalia-version = 5;
          };
          home-manager.sharedModules = [
            noctalia.homeModules.default
          ];
        }
      ];
    };

    nixosConfigurations.Niquesse-v4 = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./hosts/niquesse/configuration.nix
        niri-flake.nixosModules.niri
        noctalia-v4.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "hm-bak";
          home-manager.users.nat = import ./home/nat.nix;
          home-manager.extraSpecialArgs = {
            noctalia-pkg = noctalia-v4.packages.${system}.default;
            noctalia-version = 4;
          };
        }
      ];
    };
  };
}
