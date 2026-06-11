{ pkgs, ... }:
{
  languages.javascript = {
    enable = true;
    package = pkgs.nodejs_20;
    yarn.enable = true;
  };

  # yarn install lần đầu — thay RUN yarn install --frozen-lockfile.
  enterShell = ''
    [ -d node_modules ] || yarn install --frozen-lockfile
  '';

  # Dev server — thay CMD `yarn dev`.
  processes.dev.exec = "yarn dev";
}
