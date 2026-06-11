{ pkgs, inputs, ... }:
let
  # PHP 8.1 (EOL) lấy từ nix-phps.
  php = (import inputs.nixpkgs {
    inherit (pkgs.stdenv) system;
    overlays = [ inputs.phps.overlays.default ];
    config.allowInsecurePredicate = _: true;
  }).php81.withExtensions ({ enabled, all }:
    enabled ++ (with all; [ pdo_pgsql ]));
in
{
  languages.php = {
    enable = true;
    package = php;
  };

  # App PHP thuần, chạy built-in server — thay CMD `php -S 0.0.0.0:3000`.
  # Không có composer install trong Dockerfile.bak (không phải Laravel).
  processes.serve.exec = "php -S 0.0.0.0:3000";
}
