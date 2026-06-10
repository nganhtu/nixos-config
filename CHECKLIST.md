# CHECKLIST.md — Kế hoạch tái tạo môi trường (NixOS)

> Đọc CLAUDE.md trước. Làm tuần tự. Mỗi giai đoạn: rebuild + kiểm tra "tiêu chí xong" trước khi sang giai đoạn sau. Commit sau mỗi giai đoạn.
> Quy ước: `[ ]` chưa làm, `[~]` đang làm, `[x]` xong, `[!]` chặn/cần hỏi user.

---

## GIAI ĐOẠN 0 — Xác nhận & chuẩn bị (làm 1 lần)

- [x] Chạy `lsblk -f` xác nhận layout đĩa — tên ổ bị hoán đổi trong CLAUDE.md, đã sửa. Windows=nvme1n1, NixOS=nvme0n1.
- [x] Xác nhận filesystem root: **btrfs** (label Ithilien). KHÔNG format lại.
- [x] Hỏi user toàn bộ mục 10: username=nat, ppd, bỏ bare-repo, bỏ nvim, IDE tạm bỏ, fonts đã có zip, GRUB giữ.
- [!] Nhắc user (việc trong Windows): tắt Fast Startup; lưu BitLocker recovery key. ← User cần tự làm trong Windows.
- [x] Backup `/etc/nixos/` hiện tại: `sudo cp -r /etc/nixos /etc/nixos.bak`.
- [x] Clone repo dotfiles cũ về tham chiếu: `~/ref-dotfiles` (via gh auth).

**Xong khi:** đã có đủ câu trả lời để không phải đoán, có bản backup.

---

## GIAI ĐOẠN 1 — Flake + Home Manager (nền móng)

- [x] Tạo repo git mới `~/nixos-config`, copy `hardware-configuration.nix` từ `/etc/nixos`.
- [x] Viết `flake.nix`: inputs nixpkgs(unstable) + home-manager + niri(sodiboo) + noctalia; output `nixosConfigurations.Ithilien`.
- [x] Thêm cachix noctalia (substituter + trusted-public-key) vào `nix.settings`.
- [x] Bật `nix.settings.experimental-features = ["nix-command" "flakes"];`.
- [x] Chuyển nội dung `configuration.nix` hiện tại vào flake (GRUB, hostname, fcitx5, allowUnfree, v.v.).
- [x] Gắn home-manager module + tạo `home.nix` tối thiểu (stateVersion + username).
- [x] `time.hardwareClockInLocalTime = true;` (fix lệch giờ dual-boot).
- [x] `git init`, commit đầu. Rebuild bằng flake thành công, reboot sạch.

**Xong khi:** rebuild từ flake thành công, máy vẫn boot & dùng bình thường (vẫn XFCE), GRUB dual-boot còn nguyên.

---

## GIAI ĐOẠN 2 — Desktop core: niri + Noctalia

- [x] `programs.niri.enable = true;` (qua niri-flake nixosModules.niri).
- [x] Cài noctalia: `noctalia.packages.x86_64-linux.default` qua extraSpecialArgs → home.packages.
- [x] spawn-at-startup: binary là `noctalia-shell` (không phải `qs -c noctalia-shell`). Phải set `QS_CONFIG_PATH = "${noctalia-pkg}/share/noctalia-shell"` trong niri environment.
- [x] fcitx5 đã có từ Giai đoạn 1, OK.
- [x] bluetooth, upower, power-profiles-daemon enabled.
- [x] Rebuild + đăng nhập niri: Noctalia bar hiện, kitty mở được (Mod+Return).

**Xong khi:** đăng nhập vào niri, Noctalia bar hiện, mở được kitty (dù keybind tạm), fcitx5 gõ tiếng Việt OK. XFCE vẫn còn (chưa gỡ).

---

## GIAI ĐOẠN 3 — Dịch dotfiles niri sang Nix (phần nặng nhất) ✅

- [x] Dịch `input.kdl` → programs.niri.settings.input.
- [x] Dịch `layout.kdl` (background-color transparent + preset widths).
- [x] Dịch `animation.kdl` (.kind wrapper cho spring/easing theo schema niri-flake mới).
- [x] Dịch `rules.kdl` (window-rule kitty/steam + layer-rule noctalia-wallpaper + swappy floating).
- [x] Dịch `display.kdl` (eDP-1 1920x1080@144.001Hz — user chọn 144 thay 60).
- [x] Dịch `misc.kdl` (cursor macOS 24 + apple-cursor pkg, debug honor-xdg-activation, env Qt/Electron/fcitx5/Java, screenshot-path null).
- [x] Dịch `keybinds.kdl` (~100 bind; action LIST; noctalia-shell ipc trực tiếp; hotkey-overlay.title không phải hotkey-overlay-title).
- [x] Đảm bảo binary: kitty, google-chrome, thunar, grim, slurp, swappy, cliphist, fuzzel, wl-clipboard — đã thêm vào configuration.nix.
- [x] noctalia.kdl: **bỏ block** — để noctalia tự push màu qua IPC (quyết định 2026-06-06).
- [x] Dịch kitty config + theme **Cherry Midnight** (state thực tế dotfiles, không phải noctalia như CLAUDE.md cũ).
- [x] Dịch helix config + theme transparent_focus_nova.
- [x] Dịch btop + fuzzel config (nord theme btop shipped sẵn; fuzzel.ini qua xdg.configFile để giữ include).
- [x] Fonts system-wide: nerd-fonts.caskaydia-cove, lxgw-wenkai, noto-fonts-cjk-sans/serif (sớm hơn Stage 6 vì fuzzel/kitty cần).
- [x] xwayland-satellite niri-managed → swappy GDK_BACKEND=x11 tự resize panel.

**Tồn (chuyển sang phase sau / quan sát):**
- Brightness keys (XF86MonBrightnessUp/Down) không emit trên laptop này — bind vẫn để, im lặng.

**Xong khi:** ✅ niri hành xử giống hệt CachyOS cũ — keybind, layout, animation, screenshot, clipboard, launcher đều chạy.

---

## GIAI ĐOẠN 4 — Shell + CLI (zsh) ✅

- [x] `programs.zsh.enable` + oh-my-zsh + autosuggestion + syntaxHighlighting. Theme fork từ `ys` → `natys` (sao file vào `shell/themes/`, `oh-my-zsh.custom = ../shell`).
- [x] Bỏ plugin `archlinux`.
- [x] Bê alias dùng được: lsd, `cat=bat`, `vi=nvim`/`suvi`, `suhx`, docker (`doco/docodul/docobuild`), `gitcfX`, `cdc`, `upsync`, fzf, history 10000.
- [x] Viết lại `update` cho NixOS: docker prune + tldr update + journal vacuum + `nix flake update` + `nixos-rebuild switch` + `nix-collect-garbage --delete-older-than 14d` (giữ 14 ngày để có đường lui khi rebuild fail).
- [x] fastfetch đổi `-l Arch` → `-l NixOS`.
- [x] `syncdotfiles`/bare-repo: bỏ hẳn (user chốt).
- [x] nvim: giữ `alias vi=nvim` (chưa cài, dùng khi cần thì cài).
- [x] CLI tools: lsd, bat, tealdeer, dust, gdu, fzf, ripgrep, fd, fastfetch, tmux, htop, glab, nvtopPackages.intel. (btop+gh đã có.)
- [x] Rebuild + đăng nhập lại, login shell = zsh.

**Tồn:**
- `alias hx=helix` cũ trỏ về binary `helix` không tồn tại (nixpkgs ship binary tên `hx`). Đã bỏ alias `hx`, giữ `suhx=sudo -E hx`.

**Xong khi:** ✅ mở terminal, zsh + prompt + plugin + alias hoạt động, `update` chạy đúng kiểu NixOS.

---

## GIAI ĐOẠN 5 — Toàn bộ package & services

- [x] docker: `virtualisation.docker.enable` + group `docker` + `docker-compose` v2 plugin qua `home.file.".docker/cli-plugins/docker-compose"`.
- [x] tailscale: `services.tailscale.enable` (tailscale up chạy tay 1 lần khi cần).
- [x] kvm: thêm group `kvm` cho user.
- [x] adb + fastboot: `android-tools` trong systemPackages.
- [x] logind lid switch: ignore cả ba (`HandleLidSwitch`, `HandleLidSwitchExternalPower`, `HandleLidSwitchDocked`).
- [ ] TLP: tạm bỏ qua (máy tản nhiệt tốt, không cần tinh chỉnh CPU). ppd giữ nguyên.
- [x] steam (2026-06-10): `programs.steam.enable` + `hardware.graphics.enable32Bit`. Nvidia proprietary (open kernel module Ampere) qua `hosts/niquesse/nvidia.nix` — PRIME offload (`nvidia-offload %command%`), fine-grained power (dGPU tự ngủ). Bỏ blacklist nouveau. BusID: Intel `PCI:0:2:0`, Nvidia `PCI:1:0:0`. Test `nvidia-smi`/offload OK.
- [x] App GUI (5b): spotify, discord, libreoffice, pavucontrol, ristretto, postman, parsec-bin, vlc. Gỡ obs (wf-recorder thay thế) + vscode (không hoạt động). Thêm asciinema, wf-recorder, vlc.
- [x] Dev/LSP/formatters (5c): nil+nixfmt (Nix), jdtls+google-java-format (Java), pyright+ruff (Python), rust-analyzer+rustfmt (Rust), gopls (Go), typescript-language-server+vscode-langservers-extracted+prettier (TS/JS/HTML/CSS/JSON), bash-language-server+shfmt (Bash), lua-language-server (Lua), taplo (TOML), yaml-language-server (YAML), marksman (Markdown), clang-tools (C/C++), dockerfile-language-server (Dockerfile), intelephense+php (PHP). Pyright wire vào Helix languages.toml.
- [x] Bonus: VAAPI Intel iGPU (intel-media-driver), hàm `screenrec` (wf-recorder hardware encode), NIXOS_OZONE_WL=1 (Chrome Wayland + screen-share qua portal), unmask xdg-desktop-portal.

**Xong khi (5a+5b+5c ✅):** docker/tailscale/adb chạy, app GUI mở được, LSP đầy đủ cho 14 ngôn ngữ, screen-share + quay màn hình hoạt động.

---

## GIAI ĐOẠN 6 — Đuôi dài (khó / proprietary)

- [x] **Migrate Noctalia v4.7.7 → v5 (2026-06-09).** flake input → `github:noctalia-dev/noctalia` (bỏ pin); bỏ `noctalia.nixosModules.default` (v5 chỉ có homeModules); `programs.noctalia-shell`→`programs.noctalia` (`home/nat.nix`); `modules/niri.nix`: bỏ `QS_CONFIG_PATH`, spawn `noctalia`, đổi toàn bộ IPC sang `noctalia msg <command>`. Map IPC lấy từ `noctalia msg --help` của binary thật (xem CLAUDE.md mục 9). **file-search bị bỏ ở v5** → Mod+Alt+D thay bằng `fd | fuzzel | xdg-open`.
- [x] **Test từng keybind noctalia sau rebuild v5** (2026-06-10): launcher/session/lock/clipboard/volume/brightness/media chạy đúng với cú pháp `noctalia msg`. Issue IPC v4 đã hết.
- [x] Fonts proprietary: Google Sans + Google Sans Code + Windows fonts đóng vào `proprietary-fonts` derivation (`fonts/` trong repo). Cài sẵn: fira-code, inconsolata, lxgw-wenkai, noto-cjk, nerd-fonts.caskaydia-cove, corefonts.
- [x] ~~Noctalia settings/colors/plugins declarative bake~~ → BỎ HẾT (user chốt: noctalia tự update palette + quản plugin lúc runtime; bake `plugins.json` thành symlink read-only sẽ chặn bật/tắt plugin trong app). Chỉ giữ `programs.noctalia-shell.enable`. Wallpaper: home.file (làm sau nếu cần).
- [x] ~~Noctalia calendar: evolution-data-server~~ → BỎ (user chốt 2026-06-10: khung lịch noctalia đã đủ, không cần đổ event thật).
- [x] Package khó (2026-06-10): tất cả có sẵn nixpkgs, build OK, đã thêm vào systemPackages. `jetbrains.idea` (LƯU Ý: `idea-ultimate` đã bị rename → `idea`, bản này chính là Ultimate), `jetbrains.phpstorm`, `antigravity` (native, KHÔNG fhs) + `antigravity-cli`, `github-desktop`, `codex`, `universal-android-debloater`. Bỏ: `payload-dumper-go`, `jetbrains.pycharm`, `jetbrains.webstorm`, `android-studio`.
- [x] File manager (2026-06-10): chuyển từ nnn sang **yazi** (`modules/yazi.nix`, `programs.yazi`). Preview ảnh/video/pdf native qua kitty protocol, không cần plugin/FIFO. Gỡ `modules/nnn.nix` + `assets/nnn/` (605 dòng plugin); dời `EDITOR`/`VISUAL=hx` sang `shell.nix`. Thunar giữ làm GUI fallback.
- [x] Thunar custom action `kitty --directory %f` (uca.xml qua xdg.configFile — `modules/thunar.nix`). uca.xml read-only → không thêm action qua GUI được nữa.
- [x] helix.desktop override (`kitty hx`, Terminal=false) qua xdg.desktopEntries (`modules/helix.nix`).
- [x] ~~Stylix theme toàn hệ thống~~ → BỎ (user chốt 2026-06-10: trùng vai noctalia + theme tay đã đủ, dễ đập nhau với cơ chế runtime).
- [ ] Cân nhắc btrfs snapper / impermanence (tùy chọn, nếu dùng btrfs). ← GIỮ.
- [x] ~~Gỡ XFCE~~ → BỎ (user chốt 2026-06-10: giữ XFCE làm desktop dự phòng).

**Xong khi:** môi trường đầy đủ ngang CachyOS cũ; chỉ còn tinh chỉnh.

---

## GIAI ĐOẠN 7 — (Tùy chọn) Quay lại Limine

- [ ] Chỉ làm nếu user muốn bỏ GRUB. Hiện GRUB+os-prober chạy tốt, không bắt buộc.
- [ ] Đọc `/boot` config GRUB sinh ra để hiểu layout, rồi `sudo cat` file limine.conf mẫu để lấy đúng cú pháp path.
- [ ] Limine chainload Windows: thử `protocol: efi_chainload`, path theo PARTUUID (lấy `lsblk -o NAME,PARTUUID /dev/nvme0n1`) thay vì FS UUID `1EC6-4D7E`. Verify cú pháp bằng file limine.conf thật, KHÔNG đoán.
- [ ] `maxGenerations` giới hạn (/boot 4GB).
- [ ] Test boot cả NixOS lẫn Windows. Đường lui: F12 firmware menu luôn boot Windows được.

**Xong khi:** menu Limine chọn được cả 2 OS, HOẶC user quyết định giữ GRUB.

---

## README

- [x] Viết README.md: hướng dẫn sử dụng config này bằng tiếng Anh (stack, cấu trúc, cách rebuild, lưu ý fonts).

---

## Ghi chú vận hành
- Lỗi rebuild → đọc kỹ message, đừng `--force`. Rollback: chọn generation cũ ở GRUB, hoặc `nixos-rebuild switch --rollback`.
- /boot 4GB: theo dõi `df -h /boot`; nếu gần đầy giảm số generation + `nix-collect-garbage -d`.
- Commit mỗi giai đoạn để dễ `git bisect` khi hỏng.
