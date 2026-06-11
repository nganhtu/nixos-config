{ pkgs, inputs, ... }:
let
  # PHP 8.0 (EOL) lấy từ nix-phps. Import nixpkgs kèm overlay nix-phps;
  # allowInsecurePredicate vì 8.0/8.1 bị nixpkgs đánh dấu insecure.
  php = (import inputs.nixpkgs {
    inherit (pkgs.stdenv) system;
    overlays = [ inputs.phps.overlays.default ];
    config.allowInsecurePredicate = _: true;
  }).php80.withExtensions ({ enabled, all }:
    enabled ++ (with all; [ pdo_mysql bcmath gd zip ]));
in
{
  languages.php = {
    enable = true;
    package = php;
  };

  # Dev server — thay CMD `php artisan serve` trong Dockerfile.bak.
  # Cổng = cổng host docker-compose publish (8000:8000).
  processes.serve.exec = "php artisan serve --host=0.0.0.0 --port=8000";

  # Thiết lập lần đầu (thay block comment cuối Dockerfile.bak).
  scripts.bootstrap.exec = ''
    set -e
    composer install
    php artisan key:generate
    php artisan passport:install --force
    php artisan passport:client --personal
  '';

  enterShell = ''
    [ -d vendor ] || composer install
  '';
}
