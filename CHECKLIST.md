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

## GIAI ĐOẠN 3 — Dịch dotfiles niri sang Nix (phần nặng nhất)

- [ ] Dịch `input.kdl` → programs.niri.settings.input.
- [ ] Dịch `layout.kdl` (nhớ background-color transparent + preset widths).
- [ ] Dịch `animation.kdl` (các spring/duration).
- [ ] Dịch `rules.kdl` (window-rule kitty/steam + layer-rule noctalia-wallpaper).
- [ ] Dịch `display.kdl` (verify tên output bằng `niri msg outputs`).
- [ ] Dịch `misc.kdl` (cursor macOS, debug honor-xdg-activation, hotkey-overlay skip, env).
- [ ] Dịch `keybinds.kdl` (~100 bind; action dạng LIST; ipc call noctalia dạng list).
- [ ] Đảm bảo binary mà bind gọi đều được cài: kitty, google-chrome, thunar, grim, slurp, swappy, cliphist, fuzzel, wl-clipboard.
- [ ] noctalia.kdl: quyết định hardcode màu hay để noctalia tự quản.
- [ ] Dịch kitty config + theme noctalia → `programs.kitty`.
- [ ] Dịch helix config + theme → `programs.helix`.
- [ ] Dịch btop + fuzzel config.
- [ ] Rebuild + kiểm tra từng nhóm keybind.

**Xong khi:** niri hành xử giống hệt CachyOS cũ — keybind, layout, animation, screenshot, clipboard, launcher đều chạy.

---

## GIAI ĐOẠN 4 — Shell + CLI (zsh)

- [ ] `programs.zsh.enable` + oh-my-zsh (theme `ys`, plugin git) + autosuggestion + syntaxHighlighting (KHÔNG git clone tay).
- [ ] Bỏ plugin `archlinux`.
- [ ] Bê alias dùng được: lsd/bat/helix, docker (doco...), git config, fzf, history, BAT_THEME, cdc, upsync.
- [ ] Viết lại `update` function cho NixOS (rebuild/flake update/gc/journal vacuum).
- [ ] fastfetch đổi logo NixOS.
- [ ] Quyết định (hỏi user): giữ `syncdotfiles`/bare-repo song song hay bỏ.
- [ ] Quyết định nvim (alias vi→nvim) — cài nvim hay đổi alias.
- [ ] Cài CLI tools: lsd, bat, tealdeer, dust, gdu, fzf, ripgrep, fd, fastfetch, tmux, htop, btop, nvtop, github-cli, glab.
- [ ] Rebuild.

**Xong khi:** mở terminal, zsh + prompt + plugin + alias hoạt động, `update` chạy đúng kiểu NixOS.

---

## GIAI ĐOẠN 5 — Toàn bộ package & services

- [ ] System services: docker (+ group), tailscale, adb (+ udev + group adbusers), steam (programs.steam), kvm group.
- [ ] TLP vs ppd theo quyết định user (nếu TLP: tắt power-profiles-daemon + settings CPU; nếu ppd: bỏ TLP).
- [ ] logind lid switch ignore (x3).
- [ ] App GUI: spotify, discord, libreoffice, obs-studio, pavucontrol, thunar(+gvfs,plugins,tumbler), file-roller, ristretto, postman, vscode, parsec.
- [ ] Dev/LSP/formatters: toàn bộ list mục 7 CLAUDE.md (jdtls, pyright, ruff, rust-analyzer, gopls, prettier, typescript-language-server, lua-language-server, taplo, yaml-language-server, marksman, shfmt, bash-language-server, vscode-langservers-extracted, rustfmt, google-java-format).
- [ ] GTK theme/cursor/font qua Home Manager `gtk` (adw-gtk-theme, apple-cursor, dark→light prefer-light).
- [ ] Rebuild theo từng nhóm nhỏ (đừng nhồi 1 lần) để dễ cô lập lỗi.

**Xong khi:** các app mở được, docker/tailscale/adb chạy, theme sáng + cursor macOS áp dụng.

---

## GIAI ĐOẠN 6 — Đuôi dài (khó / proprietary)

- [ ] Fonts proprietary: user cấp file (Google Sans, MS, Segoe) → đóng derivation hoặc home.file. Cài sẵn: fira-code, inconsolata, lxgw-wenkai, noto-cjk, nerd-fonts.caskaydia-cove.
- [ ] Noctalia settings declarative: chỉnh GUI ưng → copy state → bake vào `programs.noctalia-shell.settings`. Bật plugins (file-search, clipboard 500, tailscale). Color scheme. Wallpaper.
- [ ] Noctalia calendar: evolution-data-server + override calendarSupport (nếu cần).
- [ ] Package khó: antigravity (wrap/AppImage hoặc bỏ), uad, payload-dumper-go, openai-codex, github-desktop, android-studio — verify từng cái trên search.nixos.org, wrap cái thiếu.
- [ ] JetBrains (license + canary nếu cần).
- [ ] Thunar custom action `kitty --directory %f` (uca.xml qua xdg.configFile).
- [ ] helix.desktop override (`kitty helix`, Terminal=false) qua xdg.desktopEntries.
- [ ] Gỡ XFCE (đã không cần bàn-làm-việc tạm nữa) — cẩn thận giữ display manager.
- [ ] Cân nhắc Stylix cho theme toàn hệ thống (tùy chọn).
- [ ] Cân nhắc btrfs snapper / impermanence (tùy chọn, nếu dùng btrfs).

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

## Ghi chú vận hành
- Lỗi rebuild → đọc kỹ message, đừng `--force`. Rollback: chọn generation cũ ở GRUB, hoặc `nixos-rebuild switch --rollback`.
- /boot 4GB: theo dõi `df -h /boot`; nếu gần đầy giảm số generation + `nix-collect-garbage -d`.
- Commit mỗi giai đoạn để dễ `git bisect` khi hỏng.
