{ pkgs, inputs, ... }:
let
  # PHP 8.4 (còn support) lấy từ nix-phps cho nhất quán với các project PHP khác.
  php = (import inputs.nixpkgs {
    inherit (pkgs.stdenv) system;
    overlays = [ inputs.phps.overlays.default ];
    config.allowInsecurePredicate = _: true;  # 8.4 không insecure; để cho nhất quán
  }).php84.withExtensions ({ enabled, all }:
    enabled ++ (with all; [ pdo_pgsql mbstring exif pcntl bcmath gd zip ]));
in
{
  languages.php = {
    enable = true;
    package = php;
  };

  # Redis — thay service redis trong docker-compose.
  services.redis.enable = true;

  # Cổng host docker-compose publish là 8088 (8088:8000).
  processes.serve.exec = "php artisan serve --host=0.0.0.0 --port=8088";

  enterShell = ''
    [ -d vendor ] || composer install
  '';
}
