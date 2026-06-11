{ pkgs, inputs, ... }:
{
  languages.javascript = {
    enable = true;
    # node 18 đã bị gỡ khỏi nixpkgs hiện tại → lấy từ release nixos-24.11.
    package = inputs.nixpkgs-2411.legacyPackages.${pkgs.stdenv.system}.nodejs_18;
  };

  # npm install lần đầu. webpack@4 + flatpickr cần có sẵn trong package.json
  # (Dockerfile.bak `npm install --save` thêm chúng vào).
  enterShell = ''
    [ -d node_modules ] || npm install
  '';

  # Dev server — thay CMD `npm run dev`.
  processes.dev.exec = "npm run dev";
}
