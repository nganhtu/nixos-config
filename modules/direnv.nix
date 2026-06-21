{ pkgs, ... }:

{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    # ons-nix .envrc dùng `use devenv`; hàm use_devenv không có trong direnv/nix-direnv,
    # devenv tự in qua `devenv direnvrc`. Nạp vào direnvrc (sau lib/ của nix-direnv) →
    # có cả use_flake lẫn use_devenv.
    stdlib = ''eval "$(${pkgs.devenv}/bin/devenv direnvrc)"'';
  };

  home.packages = [ pkgs.devenv ];
}
