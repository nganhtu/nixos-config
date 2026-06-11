{ pkgs, inputs, ... }:
{
  languages.javascript = {
    enable = true;
    # node 14 đã bị gỡ từ lâu → lấy từ release nixos-22.05.
    # Nếu attr sai khi build, thử `nodejs_14` thay cho `nodejs-14_x`.
    package = inputs.nixpkgs-2205.legacyPackages.${pkgs.stdenv.system}.nodejs-14_x;
  };

  enterShell = ''
    [ -d node_modules ] || npm install
  '';

  # Dev server — thay CMD `npm run dev`.
  processes.dev.exec = "npm run dev";
}
