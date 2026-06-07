{ config, pkgs, ... }:

let
  proprietary-fonts = pkgs.runCommand "proprietary-fonts" { } ''
    mkdir -p $out/share/fonts/truetype
    find ${./fonts} -type f \( -name '*.ttf' -o -name '*.ttc' -o -name '*.otf' \) \
      -exec cp -L {} $out/share/fonts/truetype/ \;
  '';
in
{
  imports = [ ./hardware-configuration.nix ];

  # Nvidia dGPU: nouveau Vulkan deadlock làm treo compositor lúc khởi động.
  # Tạm tắt cả dGPU; Stage 5 sẽ thay bằng nvidia proprietary nếu cần Steam.
  boot.blacklistedKernelModules = [ "nouveau" ];

  # Bootloader
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 3;
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    useOSProber = true;
    configurationLimit = 10;
    default = "saved";
  };

  networking.hostName = "Ithilien";
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

  # Desktop tạm thời — sẽ gỡ ở Giai đoạn 6 sau khi niri ổn định
  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.xfce.enable = true;
  services.xserver.xkb = { layout = "us"; variant = ""; };

  services.printing.enable = true;

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

  users.users.nat = {
    isNormalUser = true;
    description = "Natyusha";
    extraGroups = [ "networkmanager" "wheel" ];
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
    substituters = [ "https://noctalia.cachix.org" ];
    trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  system.stateVersion = "25.11";
}
