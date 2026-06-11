{ pkgs, inputs, ... }:
let
  # PHP 8.1 (EOL) lấy từ nix-phps.
  php = (import inputs.nixpkgs {
    inherit (pkgs.stdenv) system;
    overlays = [ inputs.phps.overlays.default ];
    config.allowInsecurePredicate = _: true;
  }).php81.withExtensions ({ enabled, all }:
    enabled ++ (with all; [ pdo_mysql pdo_pgsql bcmath gd zip ]));
in
{
  languages.php = {
    enable = true;
    package = php;
  };

  # libreoffice cho xuất file (Dockerfile.bak cài libreoffice --no-install-recommends).
  packages = [ pkgs.libreoffice ];

  # Cổng host docker-compose publish (8080:8080).
  processes.serve.exec = "php artisan serve --host=0.0.0.0 --port=8080";

  enterShell = ''
    [ -d vendor ] || composer install
  '';
}
