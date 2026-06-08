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
      # Pin v4: v5 là bản rewrite (Wayland+OpenGL ES, bỏ Quickshell) đổi binary/IPC/config.
      url = "github:noctalia-dev/noctalia-shell/v4.7.7";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, niri-flake, noctalia, ... }:
  let
    system = "x86_64-linux";
    noctalia-pkg = noctalia.packages.${system}.default;
  in {
    nixosConfigurations.Niquesse = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./hosts/niquesse/configuration.nix
        niri-flake.nixosModules.niri
        noctalia.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "hm-bak";
          home-manager.users.nat = import ./home/nat.nix;
          home-manager.extraSpecialArgs = { inherit noctalia-pkg; };
          home-manager.sharedModules = [
            noctalia.homeModules.default
          ];
        }
      ];
    };
  };
}
