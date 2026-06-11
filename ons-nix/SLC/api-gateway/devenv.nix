{ pkgs, ... }:
{
  languages.java = {
    enable = true;
    jdk.package = pkgs.jdk21;
    maven.enable = true;
  };

  # App chính — thay CMD `mvn clean install && mvn -pl start spring-boot:run`.
  # Cache ~/.m2 dùng thẳng của host (docker mount ~/.m2 vào container).
  processes.slc-be.exec = "mvn clean install -DskipTests && mvn -pl start spring-boot:run";

  # Monitoring sidecars — thay 2 service prometheus/grafana trong docker-compose.
  # prometheus.yml đã sửa target 'slc-be:8080' → 'localhost:8080' cho chạy native.
  processes.prometheus.exec =
    "${pkgs.prometheus}/bin/prometheus --config.file=./prometheus/prometheus.yml";

  # Grafana ở cổng 3003 (như docker-compose), data ghi vào .devenv/state/grafana.
  processes.grafana.exec = ''
    ${pkgs.grafana}/bin/grafana server \
      --homepath=${pkgs.grafana}/share/grafana \
      cfg:default.paths.data="$PWD/.devenv/state/grafana" \
      cfg:default.server.http_port=3003
  '';
}
