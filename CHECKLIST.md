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
- [x] Viết lại `update` cho NixOS: `nix flake update` + rebuild qua `nh os switch` + docker prune + tldr update + journal vacuum + `nh clean all --keep 10`. (2026-06-14: `nrs`/`update` chuyển sang `nh os switch`; GC dùng `nh clean`, giữ 10 generation đồng bộ với `programs.nh.clean` timer + GRUB.)
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
- [x] steam (2026-06-10): `programs.steam.enable` + `hardware.graphics.enable32Bit`. Nvidia proprietary (open kernel module Ampere) qua `hosts/niquesse/nvidia.nix` — PRIME offload (`nvidia-offload %command%`), fine-grained power **TẮT tạm 2026-06-14** (trước cho dGPU tự ngủ — xem ⚠ task treo bên dưới). Bỏ blacklist nouveau. BusID: Intel `PCI:0:2:0`, Nvidia `PCI:1:0:0`. Test `nvidia-smi`/offload OK.
- [x] App GUI (5b): spotify, discord, libreoffice, pavucontrol, ristretto, postman, parsec-bin, vlc, **vscode** (cài lại 2026-06-14 — trước gỡ vì "không hoạt động" do Electron Wayland; nay đã có `NIXOS_OZONE_WL=1`/`ELECTRON_OZONE_PLATFORM_HINT` nên chạy được; gotcha: extension ship binary prebuilt như Todo-Tree (`vscode-ripgrep`) lỗi trên NixOS → trỏ `todo-tree.ripgrep` = `/run/current-system/sw/bin/rg`). Gỡ obs (wf-recorder thay thế). Thêm asciinema, wf-recorder, vlc.
- [x] Dev/LSP/formatters (5c): nixd+nixfmt (Nix), jdtls+google-java-format (Java), pyright+ruff (Python), rust-analyzer+rustfmt (Rust), gopls (Go), typescript-language-server+vscode-langservers-extracted+prettier (TS/JS/HTML/CSS/JSON), tailwindcss-language-server + vue-language-server (Volar) + svelte-language-server (frontend), bash-language-server+shfmt (Bash), lua-language-server (Lua), taplo (TOML), yaml-language-server (YAML), marksman (Markdown), clang-tools (C/C++), dockerfile-language-server (Dockerfile), intelephense+phpactor (PHP). Helix `languages.toml`: pyright, nixd, phpactor (chỉ rename-symbol), tailwind (html/css/jsx/tsx/vue/svelte), vuels (tsdk=`pkgs.typescript`). (2026-06-14: đổi nil→nixd; thêm phpactor + frontend LSP.)
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
- [x] ~~btrfs snapper / impermanence~~ → BỎ (user chốt 2026-06-14: đã có thói quen backup. Trên NixOS rollback hệ thống đã có generation; dữ liệu quý trong `/home` đều nằm sẵn ở git/Nix; snapshot cùng ổ ≠ backup → biên lợi ích thấp. Ngoài ra `/` mount từ top-level subvolid 5 nên không rollback-swap sạch được).
- [x] ~~Gỡ XFCE~~ → BỎ (user chốt 2026-06-10: giữ XFCE làm desktop dự phòng).
- [x] Tiện ích (2026-06-11):
  - **mangohud** — overlay FPS/GPU/nhiệt lúc chơi. Bật trong game: Steam launch option `nvidia-offload mangohud %command%`; toggle overlay `Shift_R+F12`.
  - **nh** — lệnh rebuild mặc định (hàm `nrs`/`update` đều gọi `nh os switch`; hiện diff package trước khi activate). GC qua `nh clean all --keep 10`; số generation giữ lại đồng bộ **10** ở `programs.nh.clean` timer + `update()` + GRUB `configurationLimit`. Debug build fail: `--no-nom` ra output phẳng, `nix log <drv>` lấy full log. (cập nhật 2026-06-14)
  - **agenix** — secret thật đã dời sang repo riêng `~/ons-nix` (xem README). Ở nixos-config CHỈ giữ **CLI `agenix`** (`agenix-pkg` trong `home/nat.nix`) để quản secret của ons-nix. Đã gỡ `agenix.nixosModules.default` + `secrets/secrets.nix` (scaffold rỗng, không giải mã gì) — 2026-06-14, "dọn vừa".
- [x] Tiện ích (2026-06-14):
  - **Disk:** `gdu` là công cụ chính (`diskusage()` mở `gdu` interactive, mặc định duyệt cả cây `/`); `nix-tree` soi closure/store (vì sao path bị giữ). Gỡ `ncdu` + `dua` (trùng use case với gdu); `dust` giữ cho xem nhanh tĩnh. Cleanup store thật = `nh clean`.
  - **yazi:** linemode `size_and_mtime` (custom `modules/yazi-init.lua`) hiện size+ngày cạnh mỗi file; bỏ flavor noctalia tạo tay, về màu mặc định.
- [ ] ⚠ **TREO — NVIDIA freeze login (2026-06-14):** ở lightdm nhập pass + Enter → máy treo cứng, phải tắt nguồn (đã tái diễn ≥2 lần). Log lần treo: greeter mở xong rồi đứng ngay lúc dựng session, kèm `NVRM: GPU0 ... failed to get platform power mode from SBIOS` → nghi **race của runtime PM** (`powerManagement.finegrained`) khi SBIOS không trả lời handshake nguồn dGPU. **Đã TẮT `finegrained` trong `nvidia.nix` làm BƯỚC CHẨN ĐOÁN, không phải fix tối ưu.** Đánh đổi: dGPU không ngủ → **tốn pin (~5–10W idle, không phải "một chút")**. Theo dõi:
  - **Nếu HẾT treo** sau nhiều lần đăng nhập (≥5, gồm sau suspend) → xác nhận đúng nguyên nhân. Bước kế: lấy lại pin bằng cách **bật lại `finegrained`** + ép kernel bỏ qua bảng nguồn SBIOS (`boot.extraModprobeConfig` với `NVreg_DynamicPowerManagement`), rồi test.
  - **Nếu VẪN treo** → `finegrained = false` là **HƯỚNG SAI**: revert về `true` (đỡ tốn pin) rồi đào nguyên nhân khác (Xorg/lightdm greeter, modeset, version kernel/driver). Đừng để mặc `false` mà ăn pin oan.

- [x] Tinh chỉnh hệ thống (2026-06-14): `services.btrfs.autoScrub.enable` (scrub btrfs root định kỳ, bắt bitrot sớm), `zramSwap.enable` (đệm OOM — RAM 16GB chạy IDE nặng, trước không có swap), `nix.settings.auto-optimise-store` (dedup store bằng hardlink → đổi chút CPU lúc build lấy GB đĩa), `services.fstrim.enable` khai báo tường minh (vốn đã bật mặc định). Cân nhắc rồi BỎ: thermald, fwupd, battery charge-limit, đổi `description` (chưa cần).

**Xong khi:** môi trường đầy đủ ngang CachyOS cũ; chỉ còn tinh chỉnh.

---

## GIAI ĐOẠN 7 — Bootloader modern (Limine / systemd-boot)

- [x] **CHỐT 2026-06-14: GIỮ GRUB.** Đã cân nhắc cả Limine lẫn systemd-boot; cả hai đều thua GRUB cho layout 2 ESP ở 2 ổ:
  - **Limine:** lần trước chainload Windows → **panic** (xem CLAUDE.md mục 2).
  - **systemd-boot:** chỉ quét ESP của chính nó (+ XBOOTLDR) → **KHÔNG thấy Windows** vì Windows ESP ở ổ riêng `nvme1n1`. Đổi sang = mất entry Windows trong menu (phải F12). Chainload Windows ở ổ khác từ systemd-boot rất lằng nhằng.
  - **GRUB + os-prober** quét cross-disk → tự thấy Windows; đúng việc nhất. "Modern" không bù lại được mất Windows trong menu.
- [ ] (Để ngỏ) Nếu sau này gỡ Windows / dồn về 1 ESP → cân nhắc lại systemd-boot.

**Xong khi:** ✅ user quyết định giữ GRUB (2026-06-14).

---

## README

- [x] Viết README.md: hướng dẫn sử dụng config này bằng tiếng Anh (stack, cấu trúc, cách rebuild, lưu ý fonts).

---

## Ghi chú vận hành
- Lỗi rebuild → đọc kỹ message, đừng `--force`. Rollback: chọn generation cũ ở GRUB, hoặc `nixos-rebuild switch --rollback`.
- /boot 4GB: theo dõi `df -h /boot`; nếu gần đầy giảm số generation + `nix-collect-garbage -d`.
- Commit mỗi giai đoạn để dễ `git bisect` khi hỏng.
