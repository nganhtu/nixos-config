{ config, pkgs, ... }:

let
  proprietary-fonts = pkgs.runCommand "proprietary-fonts" { } ''
    mkdir -p $out/share/fonts/truetype
    find ${../../assets/fonts} -type f \( -name '*.ttf' -o -name '*.ttc' -o -name '*.otf' \) \
      -exec cp -L {} $out/share/fonts/truetype/ \;
  '';
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
    configurationLimit = 10;
    default = "saved";
  };

  networking.hostName = "Niquesse";
  networking.networkmanager.enable = true;

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
      command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --time-format '%H:%M  %A %d/%m/%Y' --greeting '${config.networking.hostName}' --asterisks --remember --cmd niri-session";
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

  fonts.fontconfig.defaultFonts.monospace = [ "Google Sans Code" ];

  fonts.packages = with pkgs; [
    nerd-fonts.caskaydia-cove
    nerd-fonts.monaspace
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
  services.tailscale.enable = true;

  programs.zsh.enable = true;

  programs.nh = {
    enable = true;
    flake = "/home/nat/nixos-config";
    clean.enable = true;
    clean.extraArgs = "--keep 10";
  };

  users.users.nat = {
    isNormalUser = true;
    description = "Natyusha";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" "docker" "kvm" ];
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim wget google-chrome helix claude-code kitty brightnessctl
    git gh
    wl-clipboard cliphist
    grim slurp swappy fuzzel
    xwayland-satellite
    file-roller
    jq
    android-tools

    # CLI tools (Giai đoạn 4)
    lsd bat tealdeer dust gdu fzf ripgrep fd fastfetch tmux htop glab delta
    nix-tree
    nvtopPackages.intel
    asciinema wf-recorder vlc
    ueberzugpp imagemagick

    # App GUI (Giai đoạn 5b)
    spotify discord libreoffice-fresh pavucontrol
    ristretto postman parsec-bin vscode

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
    substituters = [ "https://noctalia.cachix.org" ];
    trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  system.stateVersion = "25.11";
}
