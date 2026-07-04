{ config, pkgs, ... }:

{
  programs.btop = {
    enable = true;

    # btop dlopen libnvidia-ml.so.1 lúc chạy; trên NixOS lib nằm ở driver link
    # nên cần thêm vào LD_LIBRARY_PATH thì panel GPU Nvidia mới hiện.
    package = pkgs.btop.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
      postInstall = (old.postInstall or "") + ''
        wrapProgram $out/bin/btop \
          --prefix LD_LIBRARY_PATH : ${pkgs.addDriverRunpath.driverLink}/lib
      '';
    });

    # Chỉ ghi setting KHÁC default (đối chiếu source btop v1.4.7
    # btop_config.cpp); key thiếu → btop tự dùng default biên dịch sẵn.
    settings = {
      color_theme = "nord";
      theme_background = false;
      shown_boxes = "cpu mem net proc gpu0 gpu1";
    };
  };
}
