{ config, pkgs, lib, ... }:

let
  proprietary-fonts = pkgs.runCommand "proprietary-fonts" { } ''
    mkdir -p $out/share/fonts/truetype
    find ${../../assets/fonts} -type f \( -name '*.ttf' -o -name '*.ttc' -o -name '*.otf' \) \
      -exec cp -L {} $out/share/fonts/truetype/ \;
  '';

  # Kernel nft-only + cgroup v2: withNftables (net.sh dùng nft, không iptables-legacy)
  # + mount cgroup2 rw vào /acct cho libprocessgroup. waydroid#1065.
  waydroid-fixed = (pkgs.waydroid.override { withNftables = true; }).overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      echo 'lxc.mount.entry = none acct cgroup2 rw,nosuid,nodev,noexec,relatime,nsdelegate,memory_recursiveprot 0 0' \
        >> $out/lib/waydroid/data/configs/config_base
    '';
  });
in
{
  imports = [ ./hardware-configuration.nix ./nvidia.nix ];

  # Bootloader — cài vào đường dẫn fallback removable (\EFI\BOOT\BOOTX64.EFI) để
  # vẫn boot được nếu Lenovo Vantage update BIOS xoá sạch NVRAM. Removable loại trừ
  # với canTouchEfiVariables nên phải tắt cái sau.
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.timeout = 3;
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    efiInstallAsRemovable = true;
    useOSProber = true;
    configurationLimit = 25;
    default = "saved";
  };

  networking.hostName = "Niquesse";
  networking.networkmanager.enable = true;
  networking.nftables.enable = true;

  # docker.service là thứ duy nhất kéo network-online.target, mà nó lại nằm trên
  # critical chain tới graphical.target → chờ DHCP xong chặn thẳng màn đăng nhập.
  systemd.services.NetworkManager-wait-online.enable = false;

  time.timeZone = "Asia/Ho_Chi_Minh";
  time.hardwareClockInLocalTime = true;

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS        = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT    = "en_US.UTF-8";
    LC_MONETARY       = "en_US.UTF-8";
    LC_NAME           = "en_US.UTF-8";
    LC_NUMERIC        = "en_US.UTF-8";
    LC_PAPER          = "en_US.UTF-8";
    LC_TELEPHONE      = "en_US.UTF-8";
    LC_TIME           = "en_US.UTF-8";
  };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [ fcitx5-bamboo fcitx5-gtk ];
  };

  # Login Wayland-native: greetd + tuigreet vào thẳng niri. Không X server →
  # không có handoff X→Wayland để race gây hard-lock lúc đăng nhập trên GPU lai.
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --time-format '%H:%M  %A %d/%m/%Y' --greeting '${config.networking.hostName}' --asterisks --remember --cmd niri-session";
      user = "greeter";
    };
  };
  console.keyMap = "us";

  services.printing.enable = true;

  services.btrfs.autoScrub.enable = true;
  services.fstrim.enable = true;
  zramSwap.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  programs.niri.enable = true;

  # niri-flake bật portal gnome (cho screencast) nhưng config.common rỗng + thiếu
  # backend gtk → Electron/VSCode gọi FileChooser không có impl, dialog mở ra im lặng.
  xdg.portal = {
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common = {
      default = [ "gnome" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
    };
  };

  fonts.fontconfig.defaultFonts.monospace = [ "Monaspace Neon NF" "LXGW WenKai Mono" "Noto Sans Mono CJK KR" "Noto Sans Mono CJK JP" ];
  fonts.fontconfig.defaultFonts.sansSerif = [ "Segoe UI Variable" "LXGW WenKai" "Noto Sans CJK KR" "Noto Sans CJK JP" ];
  fonts.fontconfig.defaultFonts.serif = [ "Noto Serif" "LXGW WenKai" "Noto Serif CJK KR" "Noto Serif CJK JP" ];

  # Monaspace + Symbols Nerd Font: bản tải thẳng từ source (assets/fonts/monaspace,
  # assets/fonts/symbol-nerd-fonts), KHÔNG dùng nerd-fonts.monaspace/symbols-only
  # của nixpkgs nữa — proprietary-fonts tự find mọi ttf/otf dưới assets/fonts/.
  fonts.packages = with pkgs; [
    nerd-fonts.caskaydia-cove
    lxgw-wenkai
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    fira-code
    inconsolata
    corefonts
    proprietary-fonts
  ];

  hardware.bluetooth.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # VAAPI cho Intel Alder Lake iGPU: hardware encode (wf-recorder) + decode (VLC/Chrome).
  hardware.graphics.extraPackages = with pkgs; [ intel-media-driver ];
  hardware.graphics.enable32Bit = true;

  programs.steam.enable = true;

  # Gập máy không suspend (cả khi dùng pin, cắm sạc, lẫn docked).
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };

  virtualisation.docker.enable = true;
  virtualisation.waydroid.enable = true;
  virtualisation.waydroid.package = waydroid-fixed;
  systemd.services.waydroid-container.serviceConfig.Delegate = true;
  services.tailscale.enable = true;

  # CỐ Ý KHÔNG dùng port 22: Tailscale SSH (đang bật) chiếm sẵn port 22 trên IP
  # tailnet và xác thực bằng danh tính tailnet, bỏ qua authorized_keys → client
  # dùng key sẽ treo rồi lỗi. Các port khác đi thẳng vào network stack như thường
  # nên 2222 sống chung được: máy khác trong tailnet vẫn ssh port 22 không cần
  # key, còn client dùng key thì vào 2222.
  #
  # Chỉ key, và openFirewall = false + chỉ mở trên tailscale0 — KHÔNG hở ra
  # wifi/LAN. Đừng nới hai điều này.
  services.openssh = {
    enable = true;
    ports = [ 2222 ];
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 2222 ];

  # KHÔNG chạy lúc boot — cổng đóng sẵn, mở tay bằng `sshup` khi cần (shell.nix).
  # wantedBy rỗng ⇒ unit thành "static": vẫn `systemctl start` được, chỉ không tự
  # bật. (KHÔNG dùng startWhenNeeded: socket-activation vẫn để cổng lắng nghe.)
  systemd.services.sshd.wantedBy = lib.mkForce [ ];

  # Public key của client muốn SSH vào (sshd đọc cả ~/.ssh/authorized_keys).
  # Rỗng + PasswordAuthentication=false ⇒ chưa ai vào được.
  users.users.nat.openssh.authorizedKeys.keys = [ ];

  programs.zsh.enable = true;

  programs.nh = {
    enable = true;
    flake = "/home/nat/nixos-config";
    clean.enable = true;
    clean.extraArgs = "--keep 25";
  };

  users.users.nat = {
    isNormalUser = true;
    description = "Natyusha";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" "docker" "kvm" ];
  };

  nixpkgs.config = {
    allowUnfree = true;
    # Required by vue-language-server 3.2.9 on this nixpkgs revision.
    permittedInsecurePackages = [ "pnpm-10.34.0" ];
  };

  environment.systemPackages = with pkgs; [
    vim wget google-chrome helix claude-code kitty brightnessctl
    git gh
    wl-clipboard cliphist
    grim slurp swappy fuzzel
    xwayland-satellite
    file-roller
    jq
    android-tools
    hw-probe

    # CLI tools (Giai đoạn 4)
    lsd bat tealdeer dust gdu fzf ripgrep fd fastfetch tmux htop glab delta herdr
    nix-tree
    nvtopPackages.intel
    asciinema wf-recorder vlc
    ueberzugpp imagemagick

    # App GUI (Giai đoạn 5b)
    spotify discord libreoffice-fresh pavucontrol
    ristretto postman parsec-bin vscode figma-linux

    # Dev / LSP / formatters (Giai đoạn 5c) — helix tự nhận qua PATH
    nodejs typescript
    nixd nixfmt
    jdt-language-server google-java-format
    pyright ruff
    rust-analyzer rustfmt
    gopls
    typescript-language-server vscode-langservers-extracted prettier
    tailwindcss-language-server vue-language-server svelte-language-server
    bash-language-server shfmt
    lua-language-server taplo yaml-language-server marksman
    clang-tools
    dockerfile-language-server
    intelephense phpactor php

    # IDE & tools nặng (Giai đoạn 6)
    jetbrains.idea jetbrains.phpstorm
    antigravity antigravity-cli
    github-desktop
    codex
    universal-android-debloater
  ];

  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
      thunar-media-tags-plugin
    ];
  };
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  environment.variables.TERMINAL = "kitty";

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    # devenv ép setting restricted `system` → cần trusted-user (không whitelist
    # được trong config như substituter). devenv tự thêm cache runtime khi đã trusted.
    trusted-users = [ "root" "nat" ];
    substituters = [ "https://noctalia.cachix.org" ];
    trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  system.stateVersion = "25.11";
}
