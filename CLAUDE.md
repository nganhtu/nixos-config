# CLAUDE.md — NixOS rebuild of CachyOS + Niri + Noctalia

> File này là ngữ cảnh thường trực cho Claude Code. Đọc kỹ trước khi làm bất cứ việc gì.
> Mục tiêu tổng: tái tạo môi trường CachyOS + Niri + Noctalia cũ trên NixOS, **declarative triệt để** bằng flake + Home Manager thuần.

---

## 0. Nguyên tắc làm việc (đọc trước)

- **Declarative là trên hết.** Không `nix-env -i`, không sửa tay `/etc`, không `git clone` plugin thủ công, không `curl | sh`. Mọi thứ vào file `.nix` rồi `nixos-rebuild switch`.
- **Dotfiles: Home Manager THUẦN.** User đã chốt: dịch toàn bộ config (kdl/conf/ini) sang cú pháp Nix, KHÔNG symlink file gốc, KHÔNG giữ bare repo. Đây là quyết định cuối, không đề xuất lại.
- **Làm theo giai đoạn, mỗi giai đoạn rebuild + kiểm tra trước khi sang giai đoạn sau.** Không nhồi tất cả vào một lần rebuild. Xem CHECKLIST.md.
- **Khi không chắc cú pháp/option Nix:** tra `search.nixos.org`, `mynixos.com`, hoặc đọc file thật mà module sinh ra — KHÔNG bịa option. (Lịch sử: đã từng bịa `xdg.terminal`, `efi` protocol sai cho limine. Verify trước khi viết.)
- **Mọi thay đổi bootloader phải cẩn thận** — máy dual-boot Windows. Xem mục Phần cứng.
- Giữ commit nhỏ, message rõ. Sau mỗi giai đoạn hoàn thành, commit.

---

## 1. Trạng thái hiện tại (ĐÃ XONG, đừng làm lại)

- NixOS đã cài qua GUI installer, desktop tạm thời = **XFCE** (dùng làm "bàn làm việc" để dựng niri, sẽ gỡ sau).
- Bootloader hiện tại = **GRUB + os-prober**, dual-boot Windows OK. (Đã thử Limine chainload nhưng panic, tạm gác — xem Phần cứng & Giai đoạn 7.)
- Đã set: `networking.hostName` (khác "nixos" mặc định), `nixpkgs.config.allowUnfree = true`, kitty đã cài.
- GRUB: timeout 3s, `default saved` + `savedefault` (nhớ lựa chọn cuối).
- Config hiện nằm ở `/etc/nixos/configuration.nix` dạng cổ điển (CHƯA phải flake).

---

## 2. Phần cứng & layout đĩa (QUAN TRỌNG cho bootloader)

- 2 ổ NVMe 512GB.
- **Ổ 1 (nvme1n1)** = Windows. Có ESP riêng: `nvme1n1p1`, vfat FAT32, label `SYSTEM_DRV`, **FS UUID `1EC6-4D7E`**, chứa `/EFI/Microsoft/Boot/bootmgfw.efi`. Các phân vùng khác: p2, p3 (ntfs `Laurelin`), p4 (ntfs `WINRE_DRV`).
- **Ổ 2 (nvme0n1)** = một phần Windows (ntfs `Telperion` ở p1) + 2 phân vùng cho NixOS:
  - nvme0n1p2 → **btrfs** (không label) UUID `9ecd5758-9d28-4f60-a5ce-8027ce2e3543` → `/` (subvol mặc định), `/home` (subvol=home), `/nix` (subvol=nix). `/nix/store` bind từ `/nix`.
  - nvme0n1p3 → vfat 4GB UUID `B34C-B10B` → `/boot` (ESP NixOS, hiện 4% dùng)
  - **(Lịch sử)** Bản cài đầu (2026-05-24) dùng UUID `e99b7bcd-aa2c-4ecf-ba65-c24d65a148b1` (root) + `61DD-4ABF` (boot) + subvol `@`/`@home`. User cài lại NixOS ngày 2026-06-06, layout/UUID thay đổi như trên.
- ESP Windows (ổ 1 nvme1n1) và bootloader NixOS (ổ 2 nvme0n1) ở **2 ổ vật lý khác nhau** → cô lập tốt. Hiện đang dùng GRUB+os-prober nên không vấn đề.
- **GRUB cài vào đường dẫn fallback removable** (`efiInstallAsRemovable = true` + `canTouchEfiVariables = false`, từ 2026-06-13): ghi vào `\EFI\BOOT\BOOTX64.EFI` trên ESP NixOS thay vì tạo entry NVRAM tên `nixos`. Lý do: Lenovo Vantage update BIOS có thể xoá sạch NVRAM → mất entry boot; fallback path firmware luôn boot được kể cả khi NVRAM trống. Hai option này loại trừ nhau (removable bỏ qua efibootmgr nên không được phép đụng EFI vars). An toàn vì ESP NixOS ở ổ riêng, không đè lên fallback của Windows (ổ khác).
- **Tuyệt đối không format/đụng** các phân vùng ntfs (Windows). Chỉ thao tác trên nvme0n1p2 và nvme0n1p3.
- **Cần làm trong Windows (nhắc user, Claude Code không làm được):** tắt Fast Startup; cân nhắc tắt BitLocker / lưu recovery key.
- **Đồng hồ lệch dual-boot:** đặt `time.hardwareClockInLocalTime = true;` trong NixOS HOẶC RTC=UTC trong Windows.
- **/boot chỉ 4GB** → BẮT BUỘC giới hạn số generation giữ lại (GRUB: `configurationLimit`; nếu sau này quay lại Limine: `maxGenerations`). Nếu không sẽ tràn /boot và rebuild lỗi hết chỗ.

---

## 3. Filesystem

- **CẬP NHẬT (2026-06-06):** Root là **btrfs** (không label, UUID `9ecd5758-9d28-4f60-a5ce-8027ce2e3543`). Subvol: top-level cho `/`, `home` cho `/home`, `nix` cho `/nix`. KHÔNG format lại.

---

## 4. Kiến trúc đích

```
nixos-config/
├── flake.nix
├── hosts/
│   └── niquesse/
│       ├── configuration.nix          # system: bootloader, services, system packages
│       └── hardware-configuration.nix # giữ nguyên cái GUI installer sinh ra
├── home/
│   └── nat.nix                        # Home Manager: dotfiles dịch sang Nix
├── modules/                           # HM modules dùng chung
│   ├── niri.nix
│   ├── kitty.nix
│   ├── helix.nix
│   ├── shell.nix
│   └── ...
├── fonts/                             # font assets (google-sans, windows)
├── shell/                             # oh-my-zsh custom theme
├── claude/                            # statusline script
├── CLAUDE.md                          # file này
└── CHECKLIST.md                       # kế hoạch
```

### Flake inputs cần có
- `nixpkgs` → **nixos-unstable** (Noctalia/Quickshell cần unstable; desktop bits đổi nhanh).
- `home-manager` (follows nixpkgs).
- `niri` → `github:sodiboo/niri-flake` (bleeding-edge + module). **Dùng `niri-unstable` chứ không phải mặc định `niri-stable`** (2026-07-04): niri-flake ghim `niri-stable` cứng ở tag `v25.08`, thiếu fix "IME trong popup" (GTK4 popup có ô nhập liệu — vd rename trong Nautilus/Thunar, dialog tìm kiếm — đóng ngay khi mở nếu đang chạy fcitx5, do Smithay chỉ cho 1 keyboard grab và popup-grab đụng IME-grab). Fix nằm trong v26.04+. Cấu hình ở `flake.nix`: thêm `nixpkgs.overlays = [ niri-flake.overlays.niri ];` rồi `programs.niri.package = pkgs.niri-unstable;`. Cache riêng `niri.cachix.org` (host cả stable lẫn unstable) do niri-flake's nixosModule tự bật, không cần khai substituter tay. **Đổi package niri KHÔNG có tác dụng ngay** — niri đang chạy không tự thay binary giữa chừng, phải đăng xuất/đăng nhập lại (hoặc reboot) mới nhận bản mới.
- `noctalia` → **v5** (`github:noctalia-dev/noctalia`, follows nixpkgs). Đã migrate từ v4.7.7 sang v5 ngày 2026-06-09. Docs v5: https://docs.noctalia.dev/v5/getting-started/nixos/ — chỉ còn `homeModules.default` (KHÔNG có `nixosModules`), option `programs.noctalia`, binary `noctalia`, IPC `noctalia msg <command>`. Xem mục 9.
- **Cachix:** thêm substituter `https://noctalia.cachix.org` + trusted-public-key `noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=` để KHỎI build Qt/Quickshell từ source.

---

## 5. Repo dotfiles cũ (nguồn để dịch sang Nix)

Repo: https://github.com/nganhtu/cachyusha_dotfiles (bare-repo style, file nằm thẳng ở $HOME).
Clone về tham chiếu, KHÔNG dùng trực tiếp — dịch nội dung sang Nix.

Nội dung đã backup:
- `.config/niri/` — config.kdl (include 8 file) + cfg/{animation,autostart,keybinds,input,display,layout,rules,misc}.kdl + noctalia.kdl. **Đây là phần dịch tốn công nhất.**
- `.config/kitty/` — kitty.conf + themes/noctalia.conf.
- `.config/helix/` — config.toml + themes/transparent_focus_nova.toml.
- `.config/btop/` — btop.conf + themes/nord.theme. **LƯU Ý kiểu dịch (2026-07-04):** btop.conf và fcitx5 (config/bamboo.conf) là file do TOOL TỰ GHI (dump đủ mọi key kể cả default) chứ không phải config tay → trong Nix CHỈ giữ key khác default (đã verify từng key với source đúng version: btop 1.4.7 btop_config.cpp, fcitx5 5.1.21 globalconfig.cpp, fcitx5-bamboo 1.0.10 bambooconfig.h). Cả hai app đều fallback default cho key thiếu (đã kiểm chứng thực nghiệm với fcitx5). Riêng fcitx5 `profile` là DATA (danh sách IM) không phải setting — giữ nguyên khối, không trim.
- `.config/fuzzel/` — fuzzel.ini + themes/noctalia. icon-theme Papirus. Font fallback (đã dịch sang tên family thật trong nixpkgs, các tên `*TC`/`Noto Serif KR` repo cũ KHÔNG tồn tại): `Google Sans Code` → `LXGW WenKai` (Trung) → `Noto Sans CJK KR` (Hàn) → `Noto Sans CJK JP` (Nhật). Kitty dùng `symbol_map` ép dải Unicode: CJK→`LXGW WenKai Mono`, Hangul→`Noto Sans Mono CJK KR`, kana→`Noto Sans Mono CJK JP`, Hy Lạp+Cyrillic→`CaskaydiaCove Nerd Font Mono`. Han unification: kanji dùng chung codepoint chữ Hán nên hiện glyph kiểu Trung (LXGW), chỉ kana tách được sang font Nhật.
- `.zshrc`, `.zprofile` — oh-my-zsh theme `ys`, plugins (git, archlinux, zsh-autosuggestions, zsh-syntax-highlighting), RẤT NHIỀU alias/function công việc.

### Chi tiết niri cần dịch sang `programs.niri.settings` (Nix)
- **input.kdl:** numlock on; touchpad tap + natural-scroll; mouse accel-profile flat speed 1.0; focus-follows-mouse; workspace-auto-back-and-forth. (xkb layout để mặc định.)
- **misc.kdl:** prefer-no-csd; screenshot-path null; environment vars (QT_QPA_PLATFORM=wayland, QT_QPA_PLATFORMTHEME=gtk3, QT_WAYLAND_DISABLE_WINDOWDECORATION=1, XDG_CURRENT_DESKTOP=niri, fcitx5 vars: QT_IM_MODULE/XMODIFIERS/INPUT_METHOD/SDL_IM_MODULE=fcitx5, _JAVA_AWT_WM_NONREPARENTING=1, ELECTRON_OZONE_PLATFORM_HINT=auto); cursor macOS size 24; debug honor-xdg-activation-with-invalid-serial; hotkey-overlay skip-at-startup; recent-windows binds. NOTE: nhiều env var này NixOS/niri-flake/fcitx5 module tự set — đối chiếu tránh set trùng/sai.
- **display.kdl:** eDP-1 mode 1920x1080@60.008 scale 1 (DP-1 đang bị disable `/-`). LƯU Ý: tên output theo máy, verify bằng `niri msg outputs`.
- **layout.kdl:** gaps 4; center-focused-column never; **background-color transparent (BẮT BUỘC cho noctalia set wallpaper)**; preset-column-widths 1/3,1/2,2/3; focus-ring width 2.
- **rules.kdl:** corner-radius 8 clip-to-geometry; kitty default width 0.5; steam floating rules; **layer-rule noctalia-wallpaper place-within-backdrop true**.
- **animation.kdl:** dịch nguyên các spring/duration (workspace-switch, window-open/close, view-movement, resize, overview, screenshot-ui...).
- **noctalia.kdl:** ~~hardcode màu~~ → **BỎ block này hoàn toàn**, để noctalia tự push màu qua IPC khi đổi wallpaper. (Quyết định 2026-06-06.)
- **autostart.kdl:** `qs -c noctalia-shell` (noctalia), `fcitx5 -d`, `wl-paste --watch cliphist store`. → chuyển thành `spawn-at-startup` trong niri settings. KHÔNG chạy noctalia qua systemd (docs cảnh báo lag + IPC bug).
- **keybinds.kdl:** ~100 bind. Format Nix: action là LIST không phải string (vd `spawn = ["kitty"]`; ipc call = `["qs" "-c" "noctalia-shell" "ipc" "call" "launcher" "toggle"]`). Binds tham chiếu binary: `kitty`, `google-chrome-stable`, `thunar`, `grim`/`slurp`/`swappy`, `cliphist`, `fuzzel`, `wl-copy` → đảm bảo các package được cài, nếu thiếu bind gãy.

---

## 6. Map imperative → declarative (từ note cài CachyOS cũ)

| CachyOS (cũ) | NixOS (declarative) |
|---|---|
| `paru -S <pkg>` | `environment.systemPackages` / `home.packages` |
| `systemctl enable docker` + `usermod -aG docker` | `virtualisation.docker.enable=true` + `users.users.<u>.extraGroups=["docker"]` |
| `systemctl enable --now tailscaled && tailscale up` | `services.tailscale.enable=true` (up vẫn chạy tay 1 lần) |
| adb + android-udev | `environment.systemPackages = [ pkgs.android-tools ];` (NixOS unstable mới: systemd 258 tự xử lý uaccess, `programs.adb.enable` đã bị bỏ, không cần group `adbusers`) |
| steam (pkg) | `programs.steam.enable=true` (KHÔNG chỉ cài package) |
| `usermod -aG kvm` | `users.users.<u>.extraGroups += ["kvm"]` |
| sửa `/etc/tlp.conf` | `services.tlp.enable=true` + `services.tlp.settings={...}` + **`services.power-profiles-daemon.enable=false`** (xung đột TLP!) |
| TLP values | CPU_MAX_PERF_ON_AC=60, CPU_BOOST_ON_AC=0, CPU_ENERGY_PERF_POLICY_ON_AC="balance_power" |
| sửa `/etc/systemd/logind.conf` | `services.logind.lidSwitch="ignore"` + lidSwitchExternalPower + lidSwitchDocked |
| oh-my-zsh `curl\|sh` + git clone plugins | `programs.zsh.oh-my-zsh.enable` + `autosuggestion.enable` + `syntaxHighlighting.enable` |
| nwg-look (gtk theme/cursor/font) | Home Manager `gtk={theme;cursorTheme;font;}` |
| fcitx5 + bamboo | `i18n.inputMethod={enable=true;type="fcitx5";fcitx5.waylandFrontend=true;fcitx5.addons=[fcitx5-bamboo fcitx5-gtk];}` |
| gsettings prefer-light | `gtk` / dconf settings trong Home Manager |
| Thunar custom action `kitty --directory %f` | `xdg.configFile` cho `Thunar/uca.xml` (làm sau cùng) |
| sửa helix.desktop → `kitty helix` | `xdg.desktopEntries` override |

### TLP vs power-profiles-daemon — đánh đổi cần user quyết
TLP cho tinh chỉnh CPU chi tiết (note cũ dùng TLP) NHƯNG xung đột power-profiles-daemon, mà Noctalia widget PowerProfile cần ppd hoặc tuned. → Hỏi user: giữ TLP (mất widget power profile) hay đổi ppd (mất tinh chỉnh CPU). Note cũ nghiêng TLP.

---

## 7. Package — phân loại theo độ khó

**Map sạch (có sẵn nixpkgs):** helix, thunar (+gvfs, archive-plugin, tumbler), file-roller, ristretto, lsd, kitty, github-cli, glab, docker(+buildx,compose), bat, zip, tealdeer, nodejs/npm, spotify, dust, libreoffice, obs-studio, adw-gtk-theme, brightnessctl, capitaine-cursors, niri, qt6-wayland, seatd, wlr-randr, xwayland-satellite, discord, pavucontrol, android-tools(adb), htop, btop, nvtop, wl-clipboard, cliphist, fuzzel, steam, grim, slurp, swappy, gdu, baobab, tailscale, tmux, tlp, ripgrep, fd, fzf, fastfetch, eza. LSP/formatters: nixd+nixfmt, jdt-language-server, google-java-format, prettier, typescript(-language-server), vscode-langservers-extracted, shfmt, bash-language-server, ruff, pyright, rust-analyzer, rustfmt, taplo, yaml-language-server, marksman, lua-language-server, gopls, clang-tools, dockerfile-language-server, intelephense+phpactor (PHP), tailwindcss-language-server + vue-language-server (Volar) + svelte-language-server (frontend). (Cập nhật 2026-06-14: đổi nil→nixd; thêm phpactor + tailwind/vue/svelte, wire vào `modules/helix.nix`.) Cursor: `apple-cursor` (macOS cursor). nerd-fonts.caskaydia-cove.

**Cần option đặc biệt (không chỉ cài package):** steam (programs.steam), docker (virtualisation), tailscale (services), fcitx5 (i18n.inputMethod), niri (programs.niri qua flake), noctalia (programs.noctalia, v5).

**Unfree (cần allowUnfree, đã bật):** spotify, discord, steam, vscode, google-chrome, jetbrains.*, parsec, postman, android-studio.

**KHÓ / có thể chưa có trong nixpkgs — cần wrap hoặc bỏ qua lúc đầu:**
- `antigravity`, `antigravity-ide`, `antigravity-cli` (IDE Google mới) → gần như chắc chưa có, cần tự package (AppImage/FHS) hoặc tạm bỏ.
- `universal-android-debloater-bin` (uad) → kiểm tra, có thể phải wrap.
- `payload-dumper-go` → kiểm tra search.nixos.org.
- `openai-codex`, `parsec` → verify, parsec đôi khi cần override.
- JetBrains **Canary/EAP** (phpstorm, intellij ultimate, android-studio-canary) → nixpkgs thường chỉ stable; canary phải override version hoặc flake riêng. Cần license.
- `vscode-langservers-extracted` ok, nhưng `github-desktop` verify.

**Fonts proprietary — KHÔNG có nixpkgs, phải tự đóng gói / `home.file`:**
- Google Sans (font hệ thống user muốn), Segoe UI variable (`ttf-segoe-ui-variable`), MS fonts (`ttf-ms-fonts` → thử `corefonts`/`vistafonts` trước; phần còn lại tự thêm). Cascadia/CaskaydiaCove → `nerd-fonts.caskaydia-cove` (có sẵn).
- File font Windows + Google Sans + Cascadia user lưu trên Google Drive — user phải cung cấp file, Claude Code đóng vào derivation hoặc đặt `home.file.".local/share/fonts/..."`.
- Có sẵn: fira-code, inconsolata, lxgw-wenkai, noto-fonts, noto-fonts-cjk-sans, noto-fonts-cjk-serif (Korean nằm trong cjk).

**Bỏ hẳn (CachyOS-specific, vô nghĩa trên NixOS):** mọi `cachyos-*` (cachyos-niri-noctalia, cachyos-alacritty-config, cachyos-fish-config...), paru, fish + cachyos-fish-config (user đã gỡ fish bên cũ).

---

## 8. zshrc — chú ý khi dịch

Bê được nguyên: alias lsd/bat/helix, docker aliases (doco, docodul, docobuild, docobash, docosh), git config aliases (gitcfnganhtu/ashytuna/tuna), `syncdotfiles`/`dotfiles` (NHƯNG bare-repo workflow này mâu thuẫn với Home Manager thuần — hỏi user có còn muốn giữ không, hay bỏ vì giờ config quản bằng Nix), `upsync`/`update_and_merge_sync`, `cdc`, fzf keybindings, history settings, BAT_THEME.

**PHẢI sửa/bỏ (Arch-specific):**
- `update` function (paru -Syu, cachyos-rate-mirrors, pacman cache, SpotX) → viết lại cho NixOS: `nix flake update` → rebuild qua **`nh os switch`** (hàm `nrs`/`update` đều dùng nh, KHÔNG gọi `nixos-rebuild` trực tiếp nữa) → docker prune → journal vacuum → GC qua **`nh clean all --keep 25`** (giữ 25 generation, đồng bộ với `programs.nh.clean` timer + GRUB `configurationLimit`). Debug build fail: `nh os switch --no-nom` ra output phẳng, `nix log <drv>` lấy full log.
- oh-my-zsh plugin `archlinux` → bỏ.
- fastfetch `-l Arch` → đổi logo NixOS.
- `alias ssh="kitten ssh"`, `alias cat='bat'`, `alias vi='nvim'` (CHÚ Ý: note cũ cài `vi` + helix, nhưng zshrc alias vi→nvim; xác nhận user dùng nvim hay không, nvim chưa thấy trong package list).

---

## 9. Cảnh báo Noctalia (từ docs chính thức)

- **Đang dùng v5** (migrate 2026-06-09). v5 = bản viết lại (Wayland+OpenGL ES, bỏ Quickshell, standalone — không cần `qs`). Binary `noctalia`. Flake chỉ còn `homeModules.default` (đã bỏ `noctalia.nixosModules.default` khỏi flake), option home `programs.noctalia`. Config TOML ở `~/.config/noctalia/` (settings.toml), KHÔNG còn `QS_CONFIG_PATH`.
- Chạy bằng **spawn-at-startup trong niri** (`{ command = [ "noctalia" ]; }`). v5 có systemd service (`programs.noctalia.systemd.enable`) nhưng ta dùng spawn-at-startup.
- niri keybind gọi noctalia phải truyền **list**, không phải string.
- **IPC v5 = `noctalia msg <command>`** (KHÔNG còn `ipc call <target> <method>`). Lấy danh sách đầy đủ bằng `noctalia msg --help` (cần instance đang chạy). Map các bind hiện dùng:
  - launcher: `noctalia msg panel-toggle launcher` (panel khác: clipboard, control-center, session, wallpaper, polkit, tray-drawer)
  - lock: `noctalia msg session lock` (session action: lock/suspend/logout/reboot/shutdown)
  - session menu: `noctalia msg panel-toggle session`
  - volume: `volume-up` / `volume-down` / `volume-mute` ; mic: `mic-mute`
  - brightness: `brightness-up` / `brightness-down`
  - media: `noctalia msg media <next|previous|toggle|stop>`
  - clipboard: `noctalia msg panel-toggle clipboard`
  - **file-search KHÔNG còn** (v4 `plugin:file-search` bị bỏ) → Mod+Alt+D thay bằng `fd | fuzzel | xdg-open`.
- **Không bake settings/colors.** User chốt (2026-06-06): noctalia auto-update palette từ wallpaper, bake vào Nix sẽ chết chức năng này. Chỉ giữ `programs.noctalia.enable = true;`. Không set `.settings`.
- Để widget wifi/bt/power/battery chạy: cần `networking.networkmanager.enable`, `hardware.bluetooth.enable`, `services.upower.enable`, và ppd HOẶC tuned (xung đột TLP — xem mục 6).
- Calendar / wallpaper: cú pháp v5 có thể khác v4 — verify trước khi cấu hình (chưa làm).

---

## 9b. Waydroid (cài 2026-06-18, GApps) — 2 fix non-obvious + giới hạn

Bật `virtualisation.waydroid.enable`. Image init bằng tay (imperative, không tránh được vì Nix không đóng gói AOSP image): `sudo waydroid init -s GAPPS -f`. Trên kernel/systemd hiện tại phải có **2 fix**, nếu không container không boot:

1. **net.sh treo (`iptables-legacy: table does not exist`).** Kernel chỉ build `nf_tables`, không có `ip_tables`; systemd 258 đã bỏ cgroup v1 nên `unified_cgroup_hierarchy=0` vô tác dụng (đừng thử lại). Fix: `virtualisation.waydroid.package = pkgs.waydroid.override { withNftables = true; }` → net.sh sinh với `LXC_USE_NFT=true` + `nft` trong PATH. Kèm `networking.nftables.enable = true` (để `use_nft()` thấy ruleset).
2. **surfaceflinger/zygote crash-loop (`createProcessGroup: Read-only file system`).** Host cgroup v2-only → Android không tạo nổi `/acct`. Fix: `overrideAttrs` append `lxc.mount.entry = none acct cgroup2 rw,...nsdelegate,memory_recursiveprot` vào `config_base` + `systemd.services.waydroid-container.serviceConfig.Delegate = true`. (waydroid#1065)

→ Cả hai gộp trong let-binding `waydroid-fixed` ở `configuration.nix`.

**LXC config CHỈ regen lúc init/upgrade, KHÔNG mỗi lần start.** Sau khi đổi package/`config_base` rồi `nrs`, phải chạy `sudo waydroid upgrade -o` (offline, không tải lại image) để config trên đĩa `/var/lib/waydroid/lxc/waydroid/config` cập nhật. Bỏ bước này = config cũ, fix không có tác dụng.

**Giới hạn cố hữu (KHÔNG sửa bằng .nix, fix đều imperative — đừng đề xuất trừ khi user xin):**
- Camera: image GApps không có camera HAL → "lỗi thiết lập phiên". 
- App ARM-only (vd TikTok): image chỉ ABI `x86_64,x86`, không libndk/houdini → Play Store lọc "không tương thích".
- Wallpaper picker thỉnh thoảng crash: preview render software-GL nặng, máy yếu. Máy cũ cũng vậy.

Dung lượng: `/var/lib/waydroid` ~5.8 GB (system.img 2.4G + vendor.img 536M + data còn lại).

---

## 9c. xdg-desktop-portal (fix VSCode/Electron, 2026-06-20)

niri-flake tự bật `xdg.portal` với **chỉ backend gnome** (cho screencast) và để `xdg.portal.config.common` **rỗng**. Hệ quả: `XDG_CURRENT_DESKTOP=niri` không khớp backend nào, interface `FileChooser` không có impl → mọi dialog "Open Folder"/chọn file của Electron (VSCode...) **mở ra im lặng, không có gì hiện**.

Fix ở `configuration.nix` (`xdg.portal`): thêm `pkgs.xdg-desktop-portal-gtk`, đặt `config.common.default = ["gnome"]` (giữ screencast), ép `config.common."org.freedesktop.impl.portal.FileChooser" = ["gtk"]`. Sau rebuild phải `systemctl --user restart xdg-desktop-portal*` (portal là user service, cache config cũ) rồi mở lại app.

File chooser là cửa sổ riêng app-id `xdg-desktop-portal-gtk`; niri tile mặc định nên nó chiếm nguyên cột → thêm window-rule `open-floating` cho app-id này ở `modules/niri.nix` (phủ cả VSCode lẫn Chrome vì chung backend gtk).

Lưu ý VSCode: config để **imperative** ở `~/.config/Code/User/settings.json`, KHÔNG đưa vào HM `programs.vscode` (HM symlink read-only → GUI không sửa được settings, settings-sync gãy). Font đã chỉnh khớp kitty (fallback CJK/Hàn/Nhật/Hy Lạp, ss01–ss10, tắt calt). VSCode KHÔNG có option baseline lẫn font-nghiêng-riêng (Radon cursive) → 2 thứ này của kitty không tái tạo được.

---

## 9d. direnv + devenv (ons-nix) — TRUSTED-USER bắt buộc (2026-06-21)

Môi trường dev Onschool (repo riêng `~/src/nganhtu/ons-nix`) dựng bằng **devenv** qua **direnv**: mỗi project có `.envrc` chỉ ghi `use devenv`. Chuỗi mắc xích:

- `use devenv` KHÔNG phải hàm có sẵn của direnv lẫn nix-direnv. devenv tự in ra qua `devenv direnvrc` (146 dòng, định nghĩa `use_devenv`). Phải nạp vào **global direnvrc**.
- `modules/direnv.nix`: `programs.direnv.enable` (tự hook zsh) + `nix-direnv.enable` (cho `use flake` ad-hoc) + `stdlib = ''eval "$(${pkgs.devenv}/bin/devenv direnvrc)"''`. `devenv` vào `home.packages`. Thứ tự direnv nạp: builtin → `lib/*.sh` (nix-direnv) → `direnvrc` (devenv) → helper `_nix_*` của devenv thắng, nhưng tương thích vì devenv chép từ nix-direnv. Cả `use flake` lẫn `use devenv` chạy.

**`nix.settings.trusted-users = [ "root" "nat" ]` LÀ BẮT BUỘC, không phải tùy chọn.** devenv ép setting restricted `system` khi gọi daemon; nat không trusted → daemon từ chối (`ignoring the client-specified setting 'system', because it is a restricted setting and you are not a trusted user`) → `Failed to get drvPath`. Khác substituter (có `trusted-substituters` để whitelist), setting `system` **không whitelist được** — chỉ mở qua `trusted-users`, all-or-nothing. Đây cũng là yêu cầu cứng trong docs cài devenv trên NixOS. KHÔNG có cách chạy devenv mà giữ nat non-trusted.

**Hệ quả bảo mật (cân nhắc kỹ trước khi nhân rộng):** trusted-user ≈ **root không cần mật khẩu** cho MỌI tiến trình chạy dưới nat — kể cả coding agent, kể cả `.envrc`/`devenv.yaml` từ repo lạ vừa `cd` vào. Quyền *thực* của nat không tăng (nat vốn có `sudo`/`wheel`/`nixos-rebuild`), cái mất là **lưới an toàn** chống build-input độc hại + đường root giờ passwordless. Trên laptop cá nhân 1 người, tự review repo của mình → chấp nhận được. Giảm blast radius: chỉ `direnv allow` repo tin tưởng, review `.envrc`/`devenv.yaml` trước khi allow.

**Substituter:** khi đã trusted, devenv tự thêm `devenv.cachix.org` runtime → **KHÔNG khai** trong `nix.settings.substituters` (khai vào sẽ ra cảnh báo `already present`). nixpkgs/nix-phps nằm sẵn trên `cache.nixos.org`.

**Lỗi transient `.links`:** `auto-optimise-store = true` thỉnh thoảng fail hardlink dedup khi devenv đổ nhiều path song song (`linking ... to /nix/store/.links/...`). Chạy lại `direnv allow`/`devenv build` là qua.

---

## 9e. Git config declarative qua HM (2026-06-21)

`~/.gitconfig` giờ do Home Manager quản: `modules/git.nix` (`programs.git`) → sinh `~/.config/git/config` (XDG). Identity mặc định `ashytuna`. Credential helper PATH-based: `!gh auth git-credential` (github + gist), `!glab auth git-credential` (gitlab.onschool.edu.vn).

- **`~/.gitconfig` global ĐÃ XÓA** — vì nó override file XDG. **ĐỪNG tạo lại bằng tay**, **ĐỪNG chạy `gh auth setup-git`/`glab auth` setup-git** — chúng ghi credential helper bằng **absolute `/nix/store` path** vào `~/.gitconfig`, path đó chết sau GC + version bump → push/pull gãy (đã dính 2 lần: gh rồi glab). Helper PATH-based trong HM miễn nhiễm việc này.
- Đổi danh tính **per-repo** vẫn dùng alias `gitcfnganhtu`/`gitcfashytuna`/`gitcftuna` (shell.nix) — chúng `git config` (KHÔNG `--global`) → ghi `.git/config` của repo, không đụng global HM-managed nên không gãy.

---

## 10. Các điểm cần HỎI USER (đừng đoán)

1. Filesystem root thực tế đang là gì (`lsblk -f`)? btrfs hay ext4?
2. TLP hay power-profiles-daemon? (ảnh hưởng widget power của Noctalia)
3. Có giữ workflow `syncdotfiles`/bare-repo song song không, hay bỏ hẳn (vì đã Home Manager thuần)?
4. Có dùng nvim không (zshrc alias vi→nvim nhưng package list không có)?
5. JetBrains/Antigravity: có license không, có cần canary/EAP không, hay tạm bỏ?
6. File font proprietary (Google Sans, MS, Cascadia) trên Drive — user cung cấp file để đóng gói.
7. Username thật (cho `users.users.<u>` và `home-manager.users.<u>`).
8. ~~Giai đoạn 7 (quay lại Limine): có muốn làm không, hay giữ GRUB?~~ → **ĐÃ CHỐT (2026-06-14): GIỮ GRUB.** Limine từng panic; systemd-boot không thấy Windows cross-disk (Windows ESP ở ổ riêng `nvme1n1`). GRUB+os-prober quét cross-disk là đúng việc cho layout 2 ESP/2 ổ.
