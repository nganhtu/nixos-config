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
        home-manager.nixosModules.home-manager
        {
          # niri-stable (niri-flake) còn ghim cứng ở v25.08, thiếu fix IME-trong-popup
          # (GTK4 popup có ô nhập liệu đóng ngay khi mở nếu đang chạy fcitx5 — do
          # Smithay chỉ cho 1 keyboard grab, popup grab với IME grab đụng nhau).
          # Fix nằm trong v26.04+. Dùng niri-unstable (theo dõi main) để có fix này.
          nixpkgs.overlays = [ niri-flake.overlays.niri ];
        }
        ({ pkgs, ... }: {
          programs.niri.package = pkgs.niri-unstable;
        })
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
