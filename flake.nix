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

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { self, nixpkgs, home-manager, niri-flake, noctalia, agenix, ... }:
  let
    system = "x86_64-linux";
  in {
    nixosConfigurations.Niquesse = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./hosts/niquesse/configuration.nix
        niri-flake.nixosModules.niri
        agenix.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.nat = import ./home/nat.nix;
          home-manager.extraSpecialArgs = {
            noctalia-pkg = noctalia.packages.${system}.default;
            agenix-pkg = agenix.packages.${system}.default;
          };
          home-manager.sharedModules = [
            noctalia.homeModules.default
            { programs.noctalia.enable = true; }
          ];
        }
      ];
    };

  };
}
