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
- Ngoài 3 subvol mount trong `hardware-configuration.nix`, top-level còn `tmp`, `var/tmp`, `srv`, `var/lib/portables`, `var/lib/machines` — nằm sẵn dưới subvol gốc nên tự xuất hiện đúng đường dẫn, không cần khai `fileSystems`. **`/tmp` do đó nằm TRÊN ĐĨA, không phải tmpfs** (và `nix-daemon` chạy `PrivateTmp=no`, không set `TMPDIR` → rác build đổ thẳng vào đó). Không có snapshot; không dùng snapper/btrbk.

### Sự cố ENOSPC 2026-08-08 — `df` VÔ DỤNG để chẩn đoán, phải nhìn `Unallocated`

btrfs cấp phát không gian theo **chunk**, và **không tự trả chunk về khi xoá file** — chỗ trống nằm kẹt rải rác *bên trong* chunk đã cấp. Khi `Device unallocated` cạn, metadata không xin được chunk mới → **mọi thao tác ghi trả `ENOSPC`** dù `df` vẫn báo còn hàng chục GB.

Lúc sự cố: `Device allocated 200.00GiB / 200.00GiB`, `Unallocated 1.00MiB`, `Metadata DUP 2.75/3.00GiB (91.55%)` — trong khi `Free (estimated)` 31.27GiB và `df` báo còn 31GB trống.

**Triệu chứng KHÔNG trỏ về nguyên nhân** (đây là cái bẫy chính):
- `nh os switch` chết giữa chừng vì hết chỗ.
- Reboot xong **mọi generation** đều fail đăng nhập với `Error: authentication error: pam_open_session:: SYSTEM_ERR` — vì PAM/logind không ghi nổi `/run`, `/var/log/wtmp`; activation script của generation nào cũng cần ghi `/etc`. Rất dễ tưởng nhầm là hỏng config → **đừng bới config, kiểm `Unallocated` trước.**
- Máy vẫn lên multi-user, tailscaled vẫn online, nhưng SSH trả `System error` (cùng lỗi PAM).

**Cứu (từ USB live, mount `-o subvolid=5`):** xoá `/tmp/*`, `/var/tmp/*`, `/var/log/journal/*`, `~/.cache/*` để tạo chỗ trống trong chunk → `btrfs balance start -dusage=20` rồi `-dusage=50` (bậc thang; `-dusage=0` không ăn thua vì không chunk nào rỗng hẳn, và balance sẽ `ENOSPC` nếu không có chunk đích) → `nixos-enter` + `nix-collect-garbage`.

**Chỉ báo theo dõi:** `sudo btrfs filesystem usage /`, dòng `Unallocated`. Dưới ~5GiB là sắp kẹt. Đã nối vào cuối hàm `update` (`modules/shell-init.zsh`).

**Đã vá declarative** (`hosts/niquesse/configuration.nix`): `systemd.services/timers.btrfs-balance` (ngày 15 hàng tháng, `-dusage=50 -musage=30`, tránh trùng `btrfs-scrub` mùng 1) — đây là thứ DUY NHẤT sửa nguyên nhân gốc; `boot.tmp.cleanOnBoot`; `services.journald.extraConfig = "SystemMaxUse=500M"` (mặc định không chặn trần = 10% fs = 20GiB); `nh clean --keep 10 --keep-since 14d` + `grub.configurationLimit = 10`.

**Xoá file KHÔNG trả lại `Unallocated`** — đã đo trực tiếp: dọn 44GiB Steam làm `Data used` tụt 147.91→103.58GiB nhưng `Data total` đứng nguyên 167.94GiB và `Unallocated` không đổi một byte. Chỉ balance mới thu hồi được.

**KHÔNG dùng `boot.tmp.useTmpfs`** (đã cân nhắc và bác): RAM 15GiB → tmpfs mặc định 7.5GiB, build nặng (Rust/Java/Android) sẽ chết vì đầy tmpfs rồi kéo cả máy vào swap. `cleanOnBoot` đạt cùng mục đích, không có mặt trái.

**KHÔNG thêm `nix.gc.automatic`** — `programs.nh.clean.enable` đã sinh `nh-clean.timer` chạy hàng tuần. Thêm `nix.gc` là dựng bộ GC thứ hai với chính sách đá nhau (theo tuổi vs theo số bản).

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

### Overlay `libdisplay-info_0_2` — workaround TẠM, nhớ gỡ (2026-08-22)

nixpkgs xoá alias `libdisplay-info_0_2` ngày 2026-08-04 (`pkgs/top-level/aliases.nix`, lý do "unused in Nixpkgs"), xoá luôn file `pkgs/by-name/li/libdisplay-info/0.2.nix`; chỉ còn `0.3.nix` + `package.nix` (0.4.0). niri-flake `flake.nix` vẫn tham chiếu `libdisplay-info_0_2` (dòng 90 arg, 103 `assert version == "0.2.0"`, 125 buildInputs) → mọi `nix flake update` kéo nixpkgs ≥ 2026-08-04 làm `nh os switch` chết ở khâu eval.

- **`libdisplay-info_0_2 ? libdisplay-info` KHÔNG cứu được.** nixpkgs không xoá hẳn attribute mà thay bằng `throw` stub → attribute **vẫn tồn tại**, `callPackage` vẫn tìm thấy và truyền vào, giá trị mặc định không bao giờ kích hoạt. Đừng mất công sửa theo hướng "để default lo".
- **Triệu chứng đánh lạc hướng:** stack trace dừng ở `system.build.toplevel` → `xdg.portal.extraPortals` → `programs.niri.package`, trông như lỗi portal. Không phải.
- **Pin 0.2 của niri-flake vốn đã lỗi thời:** `Cargo.toml` của niri (cả rev `7f26c3ee` đang chạy lẫn `feb3e43f` mới) đều khai `libdisplay-info = "0.3.0"`, và nixpkgs tự đóng gói niri 26.04 dùng `libdisplay-info_0_3`. Fix upstream đúng nghĩa chỉ là đổi `_0_2`→`_0_3`.
- **Cách vá tại chỗ** (`flake.nix`, overlay đặt TRƯỚC `niri-flake.overlays.niri`): `libdisplay-info_0_3.overrideAttrs` đổi `version` + `src` về tag `0.2.0` (hash `sha256-6xmWBrPHghjok43eIDGeshpUEQTuwWLXNHg7CnBUt3Q=`). Cả 0.2/0.3/0.4 dùng chung `generic.nix` trong nixpkgs nên recipe y hệt → ra đúng derivation vẫn chạy trước giờ, assert pass, không đánh cược ABI. **Cố ý không trỏ thẳng sang 0.3** dù hợp `Cargo.toml` hơn: sẽ phải nói dối `assert` bằng `// { version = "0.2.0"; }`.
- **Nhắc gỡ:** `update()` (`modules/shell-init.zsh`) curl `flake.nix` của niri-flake trên `main` **trước** `nix flake update`; hết chuỗi `libdisplay-info_0_2` thì in hướng dẫn rồi `return 1` — dừng hẳn, chưa đụng `flake.lock`, gỡ overlay + mục này xong chạy lại. Phân biệt "upstream đã vá" với "mất mạng" bằng `${pipestatus[1]}` (exit code của curl, không phải grep): curl fail → không chặn, kẻo mất mạng là `update` từ chối chạy kèm thông báo sai.

---

## 5. Repo dotfiles cũ (nguồn để dịch sang Nix)

Repo: https://github.com/nganhtu/cachyusha_dotfiles (bare-repo style, file nằm thẳng ở $HOME).
Clone về tham chiếu, KHÔNG dùng trực tiếp — dịch nội dung sang Nix.

Nội dung đã backup:
- `.config/niri/` — config.kdl (include 8 file) + cfg/{animation,autostart,keybinds,input,display,layout,rules,misc}.kdl + noctalia.kdl. **Đây là phần dịch tốn công nhất.**
- `.config/kitty/` — kitty.conf + themes/noctalia.conf.
- `.config/helix/` — config.toml + themes/transparent_focus_nova.toml.
- `.config/btop/` — btop.conf + themes/nord.theme. **LƯU Ý kiểu dịch (2026-07-04):** btop.conf và fcitx5 (config/bamboo.conf) là file do TOOL TỰ GHI (dump đủ mọi key kể cả default) chứ không phải config tay → trong Nix CHỈ giữ key khác default (đã verify từng key với source đúng version: btop 1.4.7 btop_config.cpp, fcitx5 5.1.21 globalconfig.cpp, fcitx5-bamboo 1.0.10 bambooconfig.h). Cả hai app đều fallback default cho key thiếu (đã kiểm chứng thực nghiệm với fcitx5). Riêng fcitx5 `profile` là DATA (danh sách IM) không phải setting — giữ nguyên khối, không trim.
- `.config/fuzzel/` — fuzzel.ini + themes/noctalia. icon-theme Papirus. **KHÔNG đặt `prompt=` trong fuzzel.ini** (2026-08-22): key đó là global, mà fuzzel ở repo này chỉ chạy dạng `--dmenu` từ 2 bind niri khác nhau (clipboard `Mod+Alt+V`, tìm file `Mod+Alt+D`) → prompt global làm bind tìm file hiện chữ "Clipboard history". Prompt truyền riêng qua `--prompt` tại từng bind trong `modules/niri.nix`. Glyph `󰅍` (U+F014D) và `󰍉` (U+F0349) có sẵn trong chính `Monaspace Xenon NF` (`fc-match "Monaspace Xenon NF:charset=F0349"` ra chính nó) → KHÔNG cần thêm `Symbols Nerd Font Mono` vào danh sách font như repo tham chiếu. Lưu ý `prompt=` trong `themes/noctalia` là **màu** (dưới `[colors]`), khác key. Font chính `Monaspace Xenon NF`, CJK fallback **chỉ còn `LXGW WenKai Mono`** (2026-08-08). Kitty dùng `symbol_map` ép dải Unicode: toàn bộ CJK+kana+Hangul→`LXGW WenKai Mono`, Hy Lạp+Cyrillic→`CaskaydiaCove Nerd Font Mono`. Han unification: kanji dùng chung codepoint chữ Hán nên hiện glyph kiểu Trung.
  - **CHỦ ĐÍCH: một kiểu chữ CJK duy nhất trên toàn máy** (quyết định của user 2026-08-08). Trước đó kitty ép Hangul→`Noto Sans Mono CJK KR` và kana→`Noto Sans Mono CJK JP` trong khi fuzzel để LXGW nuốt cả hai → cùng một chuỗi tiếng Hàn ra 2 kiểu chữ khác nhau ở 2 app. Nay mọi nơi đều LXGW. **Đừng thêm lại Noto vào bất kỳ danh sách font nào.**
  - Đo bằng fontTools (`LXGWWenKaiMono-Regular.ttf`, 46.510 codepoint): Hangul Syllables **11.172/11.172**, Hangul Compat Jamo **94/94**, Hiragana **93/93**, Katakana **96/96**, Katakana Phonetic Ext **16/16**, Halfwidth/Fullwidth **225/225**, CJK Unified **20.992/20.992**, CJK Ext A **6.592/6.592** — tất cả **100% codepoint đã gán**. (Tính cả ô trống của bảng mã thì Hiragana ra 96,88% trông như thiếu; U+3040/3097/3098 vốn không tồn tại trong Unicode.)
  - **LXGW thiếu 4 khối** → cố ý KHÔNG symbol_map trong kitty, để rơi xuống fontconfig: **Hangul Jamo `U+1100-11FF` (0/256)** + Jamo Ext-A `U+A960-A97F` + Ext-B `U+D7B0-D7FF` (dạng **NFD** của tiếng Hàn — tên file từ macOS chuẩn hoá NFD nên có gặp thật); Kana Supplement `U+1B000-1B0FF` (hentaigana); CJK Compat Ideographs `U+F900-FAFF` (368/472); CJK Ext B (4%, chữ Nôm). Vì vậy symbol_map Hangul chỉ tới `U+AC00-D7A3` chứ KHÔNG phải `-D7FF`.
  - **`noto-fonts-cjk-sans`/`-serif` VẪN CÀI, chỉ bỏ khỏi `defaultFonts`.** fontconfig tự quét mọi font đã cài khi danh sách tường minh không phủ — đã verify: `fc-match "monospace:charset=1B001"` ra `Noto Serif Hentaigana`, `charset=FA70` ra `InconsolataGo Nerd Font Mono`, cả hai đều KHÔNG có trong `defaultFonts`. Gỡ package = 4 khối trên thành ô tofu, mà chỉ tiết kiệm 117MB → không đáng.
  - **fuzzel KHÔNG ép được theo dải như kitty** — nó chỉ có danh sách fallback tuần tự, font đứng trước mà có glyph là thắng. Đây là lý do phải kéo kitty về LXGW chứ không phải ngược lại: không có cách nào bắt fuzzel dùng Noto cho riêng Hangul mà vẫn giữ LXGW cho Hán (Noto CJK KR phủ luôn chữ Hán nên sẽ cướp mất).
  - **`weight=bold` trong fuzzel: ĐÃ BỎ, đừng thêm lại** (2026-08-08). Bê nguyên từ repo CachyOS cũ từ commit dịch đầu tiên, gắn cho cả 3 font CJK trong khi font Latin để Regular → chữ CJK đậm hẳn so với Latin. Nặng hơn: `LXGW WenKai Mono` KHÔNG có mặt Bold (chỉ Light/Medium/Regular) nên fontconfig vừa nhảy lên Medium vừa bật `embolden: True` = fake-bold tổng hợp (`fc-match "LXGW WenKai Mono:weight=bold"` → `style=Medium weight=200 embolden:True`). fuzzel ăn cờ này thật — `libfcft.so.4` có tham chiếu `FT_GlyphSlot_Embolden`.
  - **Repo tham chiếu dùng `LXGW WenKai Mono TC` (phồn thể) — CỐ Ý KHÔNG theo** (đã cân nhắc và bác 2026-07-31). Đo bằng fontTools: bản TC là **tập con** của bản SC, chỉ 25.618 codepoint so với 46.510, thiếu 20.892 cái — riêng Hán Ext A chỉ phủ **11%** (747/6.592). Chữ hiếm sẽ tụt xuống Noto → lẫn 2 kiểu chữ trong cùng một dòng. Bản SC còn khớp tự dạng với kitty `symbol_map` + `defaultFonts`. TC chỉ hơn ở một điểm tình cờ: nó KHÔNG có Hangul (0/11.172) nên tiếng Hàn tự rơi xuống Noto = giống kitty — không đáng đánh đổi.
  - Ghi để khỏi đi lại: giản thể/phồn thể là **codepoint khác nhau** (国 U+56FD ≠ 國 U+570B), font TC vẫn chứa đủ codepoint giản thể phổ thông nên KHÔNG có chuyện "gõ giản thể ra phồn thể" — khác biệt thật chỉ là hình nét ở codepoint dùng chung (đã verify outline khác nhau ở 骨/直/令/戶/食/国). Và **chữ Nôm không phải lý do để chọn TC**: chữ Nôm thật (𧵑, 𠊛, 𤾓, 𠳒) nằm ở Ext B, KHÔNG font nào trong LXGW SC/TC lẫn Noto CJK có.
- `.zshrc`, `.zprofile` — oh-my-zsh theme `ys`, plugins (git, archlinux, zsh-autosuggestions, zsh-syntax-highlighting), RẤT NHIỀU alias/function công việc.

### Chi tiết niri cần dịch sang `programs.niri.settings` (Nix)
- **input.kdl:** numlock on; touchpad tap + natural-scroll; mouse accel-profile flat speed 1.0; focus-follows-mouse; workspace-auto-back-and-forth. (xkb layout để mặc định.)
- **misc.kdl:** prefer-no-csd; screenshot-path null; environment vars (QT_QPA_PLATFORM=wayland, QT_QPA_PLATFORMTHEME=gtk3, QT_WAYLAND_DISABLE_WINDOWDECORATION=1, XDG_CURRENT_DESKTOP=niri, fcitx5 vars: QT_IM_MODULE/XMODIFIERS/INPUT_METHOD/SDL_IM_MODULE=fcitx5, _JAVA_AWT_WM_NONREPARENTING=1, ELECTRON_OZONE_PLATFORM_HINT=auto); cursor macOS size 24; debug honor-xdg-activation-with-invalid-serial; hotkey-overlay skip-at-startup. NOTE: nhiều env var này NixOS/niri-flake/fcitx5 module tự set — đối chiếu tránh set trùng/sai. **`recent-windows` CỐ Ý không dịch** — repo này dùng thẳng `focus-workspace-previous` (Mod+Tab) + `focus-window-previous` (Mod+Shift+Tab) của niri lõi; Alt+Tab để trống (đụng Parsec sang Windows).
- **display.kdl:** eDP-1 mode 1920x1080@60.008 scale 1 (DP-1 đang bị disable `/-`). LƯU Ý: tên output theo máy, verify bằng `niri msg outputs`.
- **layout.kdl:** gaps 4; center-focused-column never; **background-color transparent (BẮT BUỘC cho noctalia set wallpaper)**; preset-column-widths 1/3,1/2,2/3; focus-ring width 2 (KHÔNG set màu — xem mục palette.nix).
- **rules.kdl:** corner-radius 8 clip-to-geometry; kitty default width 0.5; steam floating rules; **layer-rule noctalia-wallpaper place-within-backdrop true**.
- **animation.kdl:** dịch nguyên các spring/duration (workspace-switch, window-open/close, view-movement, resize, overview, screenshot-ui...).
- **noctalia.kdl:** ~~hardcode màu~~ → **BỎ block này hoàn toàn** (2026-06-06), nhưng **PHẢI `include` file noctalia sinh ra** — xem mục 9g. Lý do ghi hồi đó ("noctalia tự push màu qua IPC") là SAI: v5 ghi file rồi nhờ include.
- **autostart.kdl:** `qs -c noctalia-shell` (noctalia), `fcitx5 -d`, `wl-paste --watch cliphist store`. → chuyển thành `spawn-at-startup` trong niri settings. KHÔNG chạy noctalia qua systemd (docs cảnh báo lag + IPC bug).
- **keybinds.kdl:** ~100 bind. Format Nix: action là LIST không phải string (vd `spawn = ["kitty"]`; ipc call = `["qs" "-c" "noctalia-shell" "ipc" "call" "launcher" "toggle"]`). Binds tham chiếu binary: `kitty`, `google-chrome-stable`, `thunar`, `grim`/`slurp`/`swappy`, `cliphist`, `fuzzel`, `wl-copy` → đảm bảo các package được cài, nếu thiếu bind gãy.

### Ristretto tự mở maximized (2026-07-04) — window-rule cho app xin maximize/fullscreen lúc mở
Ristretto (Image Viewer) xin maximize ngay khi mở, khiến cửa sổ chiếm hết màn hình mà không có gaps/bo góc (nhìn giống fullscreen dù `niri msg windows` không báo `is_floating`/fullscreen). Root cause xác nhận qua thực nghiệm (`niri msg action fullscreen-window` toggle qua lại + so kích thước tile): trên niri unstable, yêu cầu `xdg_toplevel maximize` của client được map sang trạng thái **"maximized-to-edges"** (sát mép, không gaps/bo góc) — khác với "full-width" thường (`open-maximized`, giờ chỉ còn nghĩa 100% chiều rộng nhưng vẫn giữ gaps/bo góc). Chỉ rule `open-maximized-to-edges false` mới chặn được trạng thái sát-mép này; `open-fullscreen false` (chặn true wayland-fullscreen) không đủ.

**Vấn đề:** `open-maximized-to-edges` CHƯA có trong schema niri-flake tại thời điểm này (niri-flake PR #1382 thêm option này chưa merge) → không thể viết qua `programs.niri.settings.window-rules`. Workaround: nối thẳng node KDL thô vào `programs.niri.config` (mặc định = `options.programs.niri.config.default`, tức bản KDL render sẵn từ `settings`), dùng cấu trúc `kdl.nix` (`{ name; arguments; properties; children; }`) — xem `modules/niri.nix`. Khi niri-flake merge option này vào schema, nên dọn về lại `window-rules` bình thường cho gọn.

### Extract .dmg trong Thunar (2026-07-05)
`.dmg` (Apple disk image) không phải archive libarchive/file-roller đọc được → `thunar-archive-plugin` không tự nhận diện, không có sẵn "Extract Here". `modules/thunar.nix` định nghĩa 2 script qua `pkgs.writeShellApplication` (có shellcheck, tự wrap PATH runtime deps) rồi gắn vào 2 custom action Thunar (pattern `*.dmg`):
- **`thunar-extract-dmg`** — generic, gọi `pkgs.undmg` (chỉ giải nén, không mount/convert img như `dmg2img`), extract ra thư mục con cùng tên file.
- **`thunar-extract-apple-fonts`** — riêng cho dmg font Apple (SF Pro/SF Mono/SF Compact/New York...): bên trong dmg font Apple KHÔNG phải font rời mà là 1 file `.pkg` (flat package, định dạng `xar`, khác archive thường). Chuỗi bóc: `undmg` → `xar -xf` ra `<Component>.pkg/Payload` → Payload nén gzip (file nhỏ) hoặc pbzx (file lớn, tự phát hiện qua 4 byte magic `1f8b0800`) → giải nén rồi `cpio -id` → lọc `*.ttf`/`*.otf`/`*.ttc` gom vào `<tên dmg> Fonts/`. Cần `pkgs.xar` + `pkgs.cpio` + `pkgs.pbzx` (đều có sẵn nixpkgs). Đã test full pipeline với cả 4 file thật (NY 50 font, SF-Mono 12, SF-Compact 38, SF-Pro 47) — chạy đúng, kể cả chọn nhiều file `.dmg` cùng lúc.

**Cả 2 action dùng `%F` (không phải `%f`)** trong `<command>` — Thunar ẩn action khỏi menu khi multi-select nếu command chỉ chứa placeholder số ít (`%f`/`%d`/`%n`); script nhận nhiều đường dẫn qua `"$@"` và loop. Bên trong mỗi script còn phải tự `readlink -f` lại `$f` trước khi `cd` sang thư mục tạm — nếu không, đường dẫn tương đối (Thunar luôn truyền tuyệt đối nên không gặp thực tế, nhưng khi tự test bằng glob tương đối thì `undmg` segfault thẳng thay vì báo lỗi rõ ràng).

### fastfetch ảnh vuông — ff/ffcache (2026-07-05)
Bố cục: ảnh vuông random (`~/Pictures/square/` quét đệ quy mọi thư mục con, cache thumbnail giữ nguyên cấu trúc con) bên trái → key viết tắt 6 ký tự nhiều màu (thay block `colors`) → info; tổng ≤93 cột. `modules/fastfetch.nix` sinh **3 config**: `ff.jsonc` (kitty local), `chafa.jsonc` (= ff + `mem`, cho terminal không graphics — `tfnt` không detect được ở đó), `ssh.jsonc` (bỏ module GUI vì chết qua ssh, thay block phần cứng `hw/cpu/mem/loc/bat/load`, cpu `format={name}` kẻo tràn 93 cột). Dòng `net` (cuối block 1, sau `term`): fastfetch KHÔNG có module mạng gộp wifi+ethernet → module `command` chạy nmcli (wifi ra SSID, dây ra "ethernet", cả hai ra "ethernet + SSID"). Dung lượng đĩa dùng module `btrfs` (kèm % allocated) thay `disk`. **CỐ Ý không dùng `config.jsonc`** — `fastfetch` trần giữ nguyên bản gốc; chỉ hàm `ff` (`modules/shell-init.zsh`, chạy mỗi lần mở shell) gọi config qua `--config`. `ffcache` resize sẵn toàn bộ về 512px PNG (`~/.cache/fastfetch-thumbs`, ~150MB), là một bước trong `update`; `ff` cũng tự cache lười từng ảnh (magick).

Gotchas đã kiểm chứng (đừng thử lại đường cũ):
- `display.key.width` KHÔNG tác dụng với logo ảnh (chỉ logo ascii mới nhảy cột `ESC[nG`) → pad space thẳng vào chuỗi key.
- Logo type `kitty` = gửi in-band qua tty; `kitty-direct` gửi path (chết ssh chắc chắn). Thực tế qua tailscale ssh type `kitty` vẫn tịt (đo pixel-cell qua pty fail → chừa khoảng trống rỗng) → ssh dùng `kitty-icat`. icat tự định vị ảnh lần nữa sau khi fastfetch đã dời con trỏ theo padding → ssh.jsonc phải đặt `top=0,left=0`, dồn khoảng cách vào `right` kẻo lệch kép.
- **herdr không hiển thị ảnh thật được, cả local lẫn --remote** (đã probe `kitten icat --detect-support` trong pane thật: herdr không trả lời cả query pixel — điều kiện tiên quyết của mọi giao thức ảnh; binary đóng/nén, không có option nào). herdr đặt `TERM=xterm-256color` nhưng KITTY_* vẫn leak vào env — detect bằng TERM, đừng dùng KITTY_*. Fallback: **chafa CLI** render block-art màu bơm qua `--logo-type data-raw` (type `chafa` builtin của fastfetch KHÔNG dùng được — chung đường tính pixel nên cũng chết trong herdr). `--stretch -s 33x15` vì cell font hiện tại hẹp hơn tỉ lệ 1:2 chafa giả định (để tự tính thì ảnh vuông ra hình gầy).
- **Cache ảnh của fastfetch lệch 1 dòng (bug upstream, ≤2.65.1 và master 2026-07):** đường cache (`printCachedPixel`) tính `logoHeight = height + paddingTop` còn đường render mới (`printImagePixels`) là `... - 1` → ảnh nào đã có trong `~/.cache/fastfetch/images/` là cursor-up thừa 1, cả block chữ đè lên dòng lệnh + thừa 1 dòng trống cuối. Biểu hiện "lúc bị lúc không" khi spam `ff` = ảnh random lúc trúng cache lúc không, KHÔNG phải race. Fix: `--logo-recache` (ép đường render mới, luôn nhất quán) trong nhánh kitty của `ff`. Chuỗi giấu/hiện con trỏ của chafa cũng làm fastfetch đo data-raw sai +3 cột → mọi lời gọi chafa trong `ff` phải có `--polite on`.
- **tty ảo (`TERM=linux`, fbcon):** font kernel (VGA 8x16, 256 glyph CP437) KHÔNG có khối 1/8 của `--symbols block` (▅▆▔▊...) → ra rừng `#`. Nhánh tty trong `ff` ép `--symbols vhalf+hhalf+solid+stipple -c 16` (chỉ 8 glyph CP437: ▀▄▌▐█░▒▓, tty vẽ được thật) + `-s 30x15` KHÔNG --stretch (cell 8x16 chuẩn 1:2). Config mượn luôn `ssh.jsonc` — module GUI (wm/thm/ico/cur/fnt) chết trong tty y như qua ssh, block phần cứng thì chạy đủ — NHƯNG phải override qua CLI `--logo-width 30 --logo-padding-top 1 --logo-padding-left 2 --logo-padding-right 3`: padding gốc (`top/left=0`, chỉnh cho kitty-icat) làm ảnh sát mép, còn `width=32` kế thừa > art 30 làm hở thêm 2 cột gap (data-raw lấy max(width, art) làm bề rộng logo). Muốn đẹp hơn nữa chỉ còn `services.kmscon` (thay cả console) — không đáng.

### palette.nix — nguồn màu DUY NHẤT của repo (2026-07-12, tách theme 2026-07-17)
`modules/palette.nix` = attrset màu đặt tên theo ANSI (`black`/`red`/…/`brightWhite` + `background`/`foreground`/`selectionBg`) **+ nhóm UI ngoài ANSI** (`border`, `cursorText`, `url`, `tabInactiveFg`). Nơi tiêu thụ duy nhất còn lại là `kitty.nix`.

**Bộ sưu tập theme ở `modules/themes/*.nix`** (mỗi file = 1 theme trọn vẹn, VD `eldritch-dark.nix`, `bliss.nix`). `palette.nix` chỉ làm đúng 1 việc: `import ./themes/<tên>.nix`. Đổi theme = sửa đúng dòng đó, không đụng gì khác.

**`focusRing` ĐÃ BỎ (2026-08-23)** — trước đó `palette.nix` ghép cố định `#ccccff` (tím nhạt) cho `layout.focus-ring.active.color` của niri. User bỏ pin màu này: `modules/niri.nix` giờ chỉ khai `width = 2`, màu do template niri của noctalia cấp (mục 9g). Đừng thêm lại field `focusRing` vào palette hay theme.

**QUY TẮC: KHÔNG viết mã hex ở bất kỳ file nào khác ngoài `palette.nix` và `modules/themes/*.nix`.** Thêm màu mới thì thêm vào theme đang dùng rồi trỏ tới, đừng hardcode tại chỗ dùng. Kiểm bằng `grep -rniE '#[0-9a-f]{6}' --include='*.nix' .` — chỉ được ra 2 nơi trên. Trong kitty, KEY option vẫn là `color0..15` nhưng VALUE trỏ palette theo tên ANSI.

### herdr sidebar command-status (2026-07-12, initContent tách file 2026-07-17, herdr 0.7.4 + label động 2026-07-26)
`modules/shell-init.zsh` (block trong đó, chỉ chạy khi `$HERDR_PANE_ID`): hiện lệnh foreground đang chạy dở của mỗi space lên sidebar herdr qua zsh preexec/precmd hook (báo space "không sẵn sàng nhận lệnh"). File này là script zsh thật — `modules/shell.nix` chỉ còn `initContent = builtins.readFile ./shell-init.zsh;` (tách ra để khỏi phải escape `''${...}` thành `${...}` trong Nix string, editor/shellcheck nhận đúng cú pháp).
- **API herdr 0.7.4 = 2 lời gọi tách rời** (đổi từ ≤0.7.3, port 2026-07-26 theo repo tham chiếu commit `0f8b2d7`+`f5b2cc2`): `report-agent` bỏ hẳn `--custom-status`, giờ chỉ set trạng thái. Shell trần không phải "agent" → state-label của nó KHÔNG render nếu thiếu report-agent. Chuỗi đúng: `herdr pane report-agent <pane> --source shell --agent <LABEL> --state working|blocked` "phong" pane thành agent tạm (chấm cạnh space phần SPACES), rồi `herdr pane report-metadata <pane> --source shell --state-label <STATE>=<lệnh>` gắn text nhãn (entry `<LABEL> · <lệnh>` phần AGENTS). `--state` phải thuộc enum idle/working/blocked/unknown. **`state_labels` bám theo `(pane_id, source)` và KHÔNG tự dọn khi `release-agent`** → release phải gọi kèm `--clear-state-labels` tường minh, kẻo nhãn rò sang lệnh kế.
- **LABEL = basename lệnh đang chạy** (vd `docker`/`npm`/`git`), đổi mỗi lệnh (từ 2026-07-26, trước đó cố định `$`) — để phân biệt với AI agent thật (claude…, hiện ở AGENTS với tên riêng); text state-label = dòng lệnh. Vì label không còn hằng số, phải truyền tay qua `_herdr_report`/`_herdr_release`/`_herdr_watch` và dùng lại ĐÚNG giá trị đó lúc release (herdr match theo source+label, sai → release nhầm agent). Budget cắt riêng cho label: `_herdr_label_max=10`.
- **ĐỪNG dùng glyph Nerd Font làm LABEL** (bài học cũ, vẫn giữ dù giờ label là tên lệnh ASCII an toàn — nhớ lại nếu sau này muốn thêm tiền tố glyph vào label). Từng dùng U+F120 (`>_`) và mất rất nhiều công vì nó. U+F120 nằm trong **Private Use Area**, chỉ Symbols Nerd Font có. Sidebar (kitty) render được nhưng **sai advance width** → trông dính vào separator `·`. Notification thì noctalia lấy font qua `fc-match sans-serif` = **Segoe UI Variable**, font này KHÔNG có U+F120 → shaper fallback và **nuốt luôn dấu cách** hai bên → ra `>_needs attention`. Đã thử chữa bằng word-joiner U+2060 (zero-width, không phải whitespace, chốt cuối để herdr khỏi trim trailing space): vá được sidebar nhưng notification VẪN hỏng. Nghiệm đúng: **chọn ký tự có trong CẢ Monaspace (kitty) LẪN Segoe UI Variable (notification)** — `$` và `»` đạt; `❯` `▸` KHÔNG (thiếu ở Segoe). Kiểm bằng `fc-list ":charset=<hex>" family | grep -i "<tên font>"` (lưu ý: gộp `:charset=..:family=..` trong một pattern KHÔNG chạy). Ký tự "sạch" thì label trần là đủ, không cần chèn gì.
- **herdr CẮT trailing whitespace của LABEL** lúc lưu (đã verify bằng bytes) — nhớ điều này nếu cần padding. `release-agent` phải dùng ĐÚNG label đã report (herdr match theo source+label).
- **1 PANE CHỈ GIỮ 1 AGENT RECORD** — `report-agent` không cộng thêm entry, nó THAY. Chạy `claude` trong pane thì herdr tự nhận diện (không cần hook; `~/.claude/settings.json` rỗng vẫn nhận) và tự quản label + state; shell mà cũng `report-agent` thì đè mất label (thành tên lệnh), state kẹt `working` (với shell, `claude -c` chỉ là lệnh foreground đang chạy) và **mất luôn notification** của claude. → preexec so lệnh với danh sách `herdr integration` (claude, codex, cursor, opencode…); trúng thì **chỉ** `report-metadata --state-label working=<lệnh>` (herdr giữ nguyên agent/state, chỉ nhận state-label), rồi `--clear-state-labels` khi agent thoát. Detector của herdr KHÔNG tự set state-label — muốn thấy `claude · claude -c` thì phần `claude -c` phải do shell góp vào.
- **3 TRẠNG THÁI, phân biệt bằng termios + wchan** (watcher nền 2s/lần, chỉ gọi herdr khi state ĐỔI):
  - `idle` — tty ở chế độ **raw** (`-icanon`): một TUI đã chiếm terminal và đang sẵn sàng nhận phím (helix, yazi, btop). Nó KHÔNG chặn ta → space vẫn dùng được.
  - `blocked` — **canonical** VÀ (tắt `echo` HOẶC tiến trình foreground có `wchan == wait_woken`). Tắt echo = prompt mật khẩu: **`sudo` là setuid root nên `/proc/<pid>/wchan` bị che (=0)**, còn `ptrace_scope=1` chặn `/proc/<pid>/syscall` từ tiến trình anh em → **termios là tín hiệu DUY NHẤT** bắt được nó. `wait_woken` = kẹt trong `read()` trên tty (prompt y/N); hiếm gặp ngoài ca này vì zle/TUI/poll đều ra `poll_schedule_timeout`.
  - `working` — còn lại: lệnh batch đang chạy. **Đã verify `nom` (nrs) giữ tty canonical** suốt lúc vẽ tiến độ build → KHÔNG bị nhận nhầm thành idle. Đây là điều kiện tiên quyết của cả cách phân biệt này, đừng bỏ qua nếu đổi trình build.
- **Cắt text state-label ở 16 ký tự + `…`** (`_herdr_max`), label riêng ở 10 (`_herdr_label_max`). `sidebar_width` của herdr mặc định **26 cột** (auto-scale 18–36, không phơi qua API) và herdr **cắt cụt KHÔNG thêm dấu gì** → chuỗi dài hơn bị xén mất luôn cái `…` của ta. Lệnh lỗi có tiền tố `✗` phải fit LẠI sau khi ghép.
- **Đừng tự phát tiếng khi báo blocked** — herdr đã tự phát khi agent đổi state ở space nền (`[ui.sound] enabled = true` mặc định). Toast của ta phải `--sound none`, không thì kêu 2 lần.
- Lifecycle: preexec bật watcher (report working sau ~1s để lệnh <1s không kịp nhấp nháy); precmd release khi OK, hoặc nháy blocked 3s rồi release khi lỗi ($?≠0). Race guard: lệnh mới hủy timer nháy-lỗi còn treo + release ngay (kẻo release nhầm lệnh mới / kẹt blocked). Giữ notification khi lệnh ≥20s xong ở space KHÔNG focus.

### natys — dòng response sau mỗi lệnh (2026-08-23)

Theme zsh `assets/shell/themes/natys.zsh-theme` (bản `ys` đổi tên) in một dòng nghiêng giữa output và prompt kế: `󰘍  <mã> [(SIGNAL)] · <thời gian>`. Thay hẳn `C:%?` cũ ở cuối dòng info. Bố cục: trống → dòng response → trống → dòng `#` → `$`; dòng `\n` mở đầu PROMPT gốc đóng vai dòng trống thứ hai.

- **CHỈ đặt tên cho dải `128+N`.** Mã 1/2/126/127 không có tên chuẩn hoá — 2 là "sai cú pháp" với hầu hết app nhưng là "lỗi thật" với `grep`/`diff`, còn 64–78 (`sysexits.h`) chỉ đúng nếu app theo convention BSD. Gán bừa tên còn tệ hơn để số trần. Tên signal lấy từ mảng `$signals` sẵn có của zsh, **lệch 1 index**: mã `N` → `$signals[N-127]`.
- **`$?` KHÔNG reset khi Enter dòng rỗng** (đã đo: `false` rồi Enter liên tục vẫn ra `?=1`). Không có cờ bật ở `preexec` thì dòng response in lại y hệt mỗi lần Enter. Cùng lý do, Ctrl-C ở prompt trống (=130) cũng không sinh dòng nào.
- **`%{...%}` VẪN có tác dụng khi nằm trong biến được `prompt_subst` thay vào** (đã test riêng) → dựng sẵn cả chuỗi màu trong `precmd` là an toàn, không cần `$(...)` trong PROMPT. Bắt `local ret=$?` ở dòng ĐẦU hook và `return $ret` ở mọi lối ra; `_herdr_precmd` cũng làm vậy nên hai hook sống chung được bất kể thứ tự.
- **`%f` chứ không phải `$reset_color`** để tắt màu giữa dòng — `reset_color` (`\e[0m`) tắt luôn italic.
- **Màu đi qua `%F{red|green|yellow}` + `%F{8}`, tức ANSI** → kitty đã map `color0..15` sang `palette.nix` nên bám palette là tự động. **Đừng viết escape truecolor hex vào theme**: vừa phạm quy tắc hex của repo vừa chết trong tty.
- **Vàng = dừng có chủ đích** (130 Ctrl-C, 143 TERM, 148 Ctrl-Z), không phải hỏng — tô đỏ hết thì dùng vài hôm là mắt bỏ qua màu đỏ. **137 (KILL) để ĐỎ**: trên máy 15GiB này gần như luôn là OOM-killer lúc build. `141` (SIGPIPE) hiếm khi lọt vào `$?` vì `$?` lấy mã của lệnh CUỐI pipeline — nó nằm trong `$pipestatus`.
- **Italic qua `$terminfo[sitm]`/`[ritm]`** (zsh không có prompt escape cho italic). Trong `TERM=linux` hai key này không tồn tại → tự no-op, không phun rác. Glyph `󰘍` (U+F060D `md-subdirectory_arrow_right`) là PUA nên tty ra tofu → có nhánh fallback `->` khi `TERM=linux`.

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
- **Apple fonts (2026-07-05):** SF Pro, SF Compact, SF Mono, New York — giải nén từ `.dmg` gốc (xem mục "Extract .dmg trong Thunar") vào `assets/fonts/apple/`. Derivation `proprietary-fonts` (`hosts/niquesse/configuration.nix`) tự `find` mọi `.ttf/.otf/.ttc` dưới `assets/fonts/` nên KHÔNG cần sửa gì để cài thêm — chỉ cần `git add` file mới rồi rebuild (flake chỉ thấy file đã git-tracked). Đã verify bằng fontTools: cả 4 họ phủ đầy đủ tiếng Việt (90/90 ký tự dấu tổ hợp sẵn + dấu rời), KHÔNG có Trung/Nhật/Hàn (CJK do Apple tách riêng qua PingFang/Hiragino/Apple SD Gothic Neo, không nằm trong các file này — fontconfig tự fallback sang Noto/LXGW đã cài cho phần CJK). Chỉ **SF Mono** là monospace thật (`isFixedPitch`); SF Pro/SF Compact/New York đều proportional.
  - Áp dụng làm default: SF Pro Text từng là sans mặc định (2026-07-05), **nhưng từ 2026-07-11 đã đổi sang `"Segoe UI Variable"`** — `modules/theme.nix` `gtk.font.name` + `fonts.fontconfig.defaultFonts.sansSerif` ở `hosts/niquesse/configuration.nix`. Đây là font mà **mọi app dùng generic "sans-serif" sẽ nhận, kể cả notification của noctalia** (noctalia không set font riêng → `fc-match sans-serif`). Hệ quả: ký tự đưa vào notification PHẢI có trong Segoe UI Variable — glyph Nerd Font (PUA, vd U+F120) KHÔNG có, shaper fallback rồi nuốt dấu cách xung quanh. **Cố ý KHÔNG đổi kitty** khi đổi default monospace (kitty có symbol_map/ligature/font_features riêng, đổi dễ gãy) — quyết định của user 2026-07-05, vẫn giữ khi đổi tiếp sang Monaspace 2026-07-07 (xem bullet dưới).
  - **Segoe UI Variable chứ KHÔNG phải "Segoe UI" static:** họ static gồm ~8 file, trong đó Light/Semilight/Semibold/Black đều khai THÊM family `"Segoe UI"` và đều có `Regular` trong danh sách style → dưới family "Segoe UI" có tận 5 mặt chữ cùng nhận là Regular. GTK/Pango khớp theo weight nên chọn đúng; **Chrome thì rối và rơi về fallback xấu**. Bản Variable là 1 file, 1 family, named-instance gọn → Chrome nuốt được.
- **Monaspace + Symbols Nerd Font (2026-07-07):** đổi từ `nerd-fonts.monaspace`/`nerd-fonts.symbols-only` (nixpkgs) sang bản tải thẳng từ source, đặt vào `assets/fonts/monaspace/` (5 family: Argon/Krypton/Neon/Radon/Xenon, mỗi family nhiều weight/width) và `assets/fonts/symbol-nerd-fonts/`. Lý do: không muốn phụ thuộc bản patch của nixpkgs nữa. Bỏ 2 package khỏi `fonts.packages` — `proprietary-fonts` tự nhặt (đã có cơ chế `find`). **Tên family đổi** so với bản nixpkgs (nixpkgs viết tắt `MonaspiceAr/Kr/Ne/Rn/Xe NFM`, bản source đầy đủ `Monaspace Argon/Krypton/Neon/Radon/Xenon NF`, chỉ 1 variant mỗi family — không còn hậu tố NFM/NFP vì bản source vốn đã monospace) → phải sửa lại `modules/kitty.nix` (`font.name`, mọi dòng `font_features`, `italic_font`/`bold_italic_font` postscript_name) theo tên mới, kitty vẫn giữ nguyên cặp Argon (chính) + Radon (nghiêng, dùng style Regular/Bold của Radon làm slot italic/bold-italic — đúng kiểu phối "duo style" chính thức của Monaspace). Riêng `Symbols Nerd Font`/`Symbols Nerd Font Mono` giữ **nguyên tên family** giữa 2 nguồn nên `symbol_map` trong kitty.nix không cần sửa. `fonts.fontconfig.defaultFonts.monospace` đổi từ `"SF Mono"` sang `"Monaspace Neon NF"` (Neon = family "mặc định" chính thức của bộ Monaspace) — SF Mono không có glyph Nerd Font nên app dùng generic monospace mà cần icon (vd TUI không set font riêng) trước đó ra ô trống.
- **Chuỗi CJK fallback cho app fontconfig (2026-07-31, bỏ Noto 2026-08-08):** `fonts.fontconfig.defaultFonts` ở `hosts/niquesse/configuration.nix` nối CJK sau font Latin cho cả 3 generic — sans `Segoe UI Variable` → `LXGW WenKai`; mono `Monaspace Neon NF` → `LXGW WenKai Mono`; serif `Noto Serif` → `LXGW WenKai`. Mục đích: GTK/Qt/browser hiện chữ Hán **cùng kiểu với kitty**. Font Latin PHẢI đứng đầu, không thì chữ Latin bị kéo sang LXGW. (`Noto Serif` trong dòng serif là font **Latin** từ gói `noto-fonts`, không liên quan CJK — đừng bỏ nhầm.)
  - Máy này **không cài MS CJK font** (YaHei/JhengHei) nên KHÔNG có vụ tranh chấp với `65-nonlatin.conf` như repo tham chiếu — không cần drop file XML `binding="strong"`, `defaultFonts` là đủ (đã verify `fc-match "sans-serif:charset=4e2d"` ra LXGW WenKai, còn `charset=41` vẫn Segoe UI Variable).
  - Các entry `Noto * CJK KR/JP` đã bị gỡ khỏi cả 3 dòng — xem mục 5 (`.config/fuzzel/`) để biết số đo phủ glyph và vì sao vẫn giữ package.

**Bỏ hẳn (CachyOS-specific, vô nghĩa trên NixOS):** mọi `cachyos-*` (cachyos-niri-noctalia, cachyos-alacritty-config, cachyos-fish-config...), paru, fish + cachyos-fish-config (user đã gỡ fish bên cũ).

---

## 8. zshrc — chú ý khi dịch

Bê được nguyên: alias lsd/bat/helix, docker aliases (doco, docodul, docobuild, docobash, docosh), git config aliases (gitcfnganhtu/ashytuna/tuna), `syncdotfiles`/`dotfiles` (NHƯNG bare-repo workflow này mâu thuẫn với Home Manager thuần — hỏi user có còn muốn giữ không, hay bỏ vì giờ config quản bằng Nix), `upsync`/`update_and_merge_sync`, fzf keybindings, history settings, BAT_THEME. (`cdc` từng bê nguyên, đã bỏ 2026-07-17 vì không dùng nữa.)

**PHẢI sửa/bỏ (Arch-specific):**
- `update` function (paru -Syu, cachyos-rate-mirrors, pacman cache, SpotX) → viết lại cho NixOS: cổng chặn niri-flake (mục 4, overlay `libdisplay-info_0_2`) → `nix flake update` → rebuild qua **`nh os switch`** (hàm `nrs`/`update` đều dùng nh, KHÔNG gọi `nixos-rebuild` trực tiếp nữa) → docker prune → journal vacuum → GC qua **`nh clean all --keep 10 --keep-since 14d`** (đồng bộ với `programs.nh.clean` timer + GRUB `configurationLimit`; `--keep-since` là lưới an toàn khi rebuild nhiều lần trong tuần) → in `btrfs filesystem usage /` (xem mục 3). Debug build fail: `nh os switch --no-nom` ra output phẳng, `nix log <drv>` lấy full log.
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

### 9a. Config v5: 2 tầng TOML, và settings.json là RÁC (2026-07-12)
- **`~/.config/noctalia/settings.json` KHÔNG được đọc nữa** (di sản v4/Quickshell, mtime đứng im từ trước ngày migrate). Đừng đọc nó để suy ra hành vi — mọi key trong đó (`respectExpireTimeout`, `normalUrgencyDuration`…) **không tồn tại trong source v5**. Đã mất công đi nhầm đường vì file này.
- v5 đọc **TOML**, 2 tầng: **config đọc-chỉ** = `~/.config/noctalia/*.toml` (mọi file .toml, sort theo tên) → **state runtime** = `~/.local/state/noctalia/settings.toml` (noctalia TỰ GHI: màu từ wallpaper, toggle trong bar) đè lên. Hai file KHÁC NHAU → symlink read-only vào `~/.config/noctalia/` **an toàn**, không đóng băng state (khác hẳn ca app tự ghi đè lên chính file config nó đọc — lúc đó symlink read-only sẽ khoá cứng mọi thay đổi runtime). Đây là lý do `modules/noctalia.nix` không phạm luật "không bake settings" ở trên: nó chỉ đặt tầng config, không đụng tầng state.
- Debug notification: log `~/.cache/noctalia/noctalia.log` ghi từng cái — `notification added #N origin=external from="<app>" urgency=<u> timeout=<ms>ms` + `notification expired #N`. Đủ để xác minh mà KHÔNG cần nhìn màn hình. Dump config đang hiệu lực: `noctalia config export merged|full`; kiểm cú pháp: `noctalia config validate`; nạp lại: `noctalia msg config-reload`.

### 9a-bis. Notification Chrome không tự tắt — filter allow_permanent (2026-07-12)
Chrome gửi web notification (YouTube…) với **`urgency=critical` + `expire_timeout=0`**; theo spec freedesktop `0` = *never expire* → nằm lì tới khi bấm x. KHÔNG phải bug noctalia. Fix ở `modules/noctalia.nix`:
```toml
[notification.filter.chrome-no-permanent]
match = "chrome"
allow_permanent = false     # ép timeout 0 → mặc định 6s
```
- **Cú pháp BẮT BUỘC là bảng có tên `[notification.filter.<tên>]`** (schema dùng `namedMap`, tên filter lấy từ KEY). Viết `[[notification.filter]]` (array-of-tables) thì noctalia **bỏ qua trong im lặng** mà `noctalia config validate` vẫn báo "Config is valid" — bẫy đã dính.
- `match` = lowercase+trim, so exact với app_name/desktop-entry/category **hoặc substring của app_name** → `"chrome"` trúng `"Google Chrome"`.
- `allow_permanent=false` chỉ đụng notification có `timeout==0`; loại khác của Chrome (timeout 6000) không bị ảnh hưởng. Muốn đổi thời gian thì dùng `override_duration` (ms) — nhưng nó áp cho MỌI notification khớp filter, không chỉ cái vĩnh viễn.

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

Lưu ý VSCode: config để **imperative** ở `~/.config/Code/User/settings.json`, KHÔNG đưa vào HM `programs.vscode` (HM symlink read-only → GUI không sửa được settings, settings-sync gãy). Font đã chỉnh khớp kitty (fallback CJK → `LXGW WenKai Mono` rồi `CaskaydiaCove Nerd Font Mono`, ss01–ss10, tắt calt) — **file này nằm ngoài repo, sửa tay khi đổi font ở `modules/kitty.nix`** (đã đồng bộ lần cuối 2026-08-08 khi bỏ Noto). VSCode KHÔNG có option baseline lẫn font-nghiêng-riêng (Radon cursive) → 2 thứ này của kitty không tái tạo được.

---

## 9d. direnv + devenv (ons-nix) — TRUSTED-USER bắt buộc (2026-06-21)

Môi trường dev Onschool (repo riêng `~/src/nganhtu/ons-nix`) dựng bằng **devenv** qua **direnv**: mỗi project có `.envrc` chỉ ghi `use devenv`. Chuỗi mắc xích:

- `use devenv` KHÔNG phải hàm có sẵn của direnv lẫn nix-direnv. devenv tự in ra qua `devenv direnvrc` (146 dòng, định nghĩa `use_devenv`). Phải nạp vào **global direnvrc**.
- `modules/direnv.nix`: `programs.direnv.enable` (tự hook zsh) + `nix-direnv.enable` (cho `use flake` ad-hoc) + `stdlib = ''eval "$(${pkgs.devenv}/bin/devenv direnvrc)"''`. `devenv` vào `home.packages`. Thứ tự direnv nạp: builtin → `lib/*.sh` (nix-direnv) → `direnvrc` (devenv) → helper `_nix_*` của devenv thắng, nhưng tương thích vì devenv chép từ nix-direnv. Cả `use flake` lẫn `use devenv` chạy.

**`nix.settings.trusted-users = [ "root" "nat" ]` LÀ BẮT BUỘC, không phải tùy chọn.** devenv ép setting restricted `system` khi gọi daemon; nat không trusted → daemon từ chối (`ignoring the client-specified setting 'system', because it is a restricted setting and you are not a trusted user`) → `Failed to get drvPath`. Khác substituter (có `trusted-substituters` để whitelist), setting `system` **không whitelist được** — chỉ mở qua `trusted-users`, all-or-nothing. Đây cũng là yêu cầu cứng trong docs cài devenv trên NixOS. KHÔNG có cách chạy devenv mà giữ nat non-trusted.

**Hệ quả bảo mật (cân nhắc kỹ trước khi nhân rộng):** trusted-user ≈ **root không cần mật khẩu** cho MỌI tiến trình chạy dưới nat — kể cả coding agent, kể cả `.envrc`/`devenv.yaml` từ repo lạ vừa `cd` vào. Quyền *thực* của nat không tăng (nat vốn có `sudo`/`wheel`/`nixos-rebuild`), cái mất là **lưới an toàn** chống build-input độc hại + đường root giờ passwordless. Trên laptop cá nhân 1 người, tự review repo của mình → chấp nhận được. Giảm blast radius: chỉ `direnv allow` repo tin tưởng, review `.envrc`/`devenv.yaml` trước khi allow.

**Substituter:** khi đã trusted, devenv tự thêm `devenv.cachix.org` runtime → **KHÔNG khai** trong `nix.settings.substituters` (khai vào sẽ ra cảnh báo `already present`). nixpkgs/nix-phps nằm sẵn trên `cache.nixos.org`.

**Lỗi transient `.links`:** `auto-optimise-store = true` thỉnh thoảng fail hardlink dedup khi devenv đổ nhiều path song song (`linking ... to /nix/store/.links/...`). Chạy lại `direnv allow`/`devenv build` là qua. **Từ 2026-08-08 đã tắt `auto-optimise-store`, đổi sang `nix.optimise.automatic`** (cùng thuật toán hardlink, chỉ dời khỏi đường build sang timer riêng 03:45 — module nixpkgs sẵn `Nice=19`/`IOSchedulingClass=idle`/`ConditionACPower`) → không mất dedup mà hết cả lỗi này lẫn áp lực metadata lúc build.

---

## 9e. Git config declarative qua HM (2026-06-21)

`~/.gitconfig` giờ do Home Manager quản: `modules/git.nix` (`programs.git`) → sinh `~/.config/git/config` (XDG). Identity mặc định `ashytuna`. Credential helper PATH-based: `!gh auth git-credential` (github + gist), `!glab auth git-credential` (gitlab.onschool.edu.vn).

- **`~/.gitconfig` global ĐÃ XÓA** — vì nó override file XDG. **ĐỪNG tạo lại bằng tay**, **ĐỪNG chạy `gh auth setup-git`/`glab auth` setup-git** — chúng ghi credential helper bằng **absolute `/nix/store` path** vào `~/.gitconfig`, path đó chết sau GC + version bump → push/pull gãy (đã dính 2 lần: gh rồi glab). Helper PATH-based trong HM miễn nhiễm việc này.
- Đổi danh tính **per-repo** vẫn dùng alias `gitcfnganhtu`/`gitcfashytuna`/`gitcftuna` (shell.nix) — chúng `git config` (KHÔNG `--global`) → ghi `.git/config` của repo, không đụng global HM-managed nên không gãy.

---

## 9f. SSH vào máy — sshd port 2222, đóng sẵn (2026-07-12)

**BA TẦNG khác nhau, đừng lẫn** (đã lẫn một lần rồi):

| tầng | là gì | công tắc |
|---|---|---|
| daemon `tailscaled` | tiến trình nền | `systemctl start/stop tailscaled` |
| **kết nối tailnet** | máy có trong mạng riêng không (IP `100.x`, MagicDNS) | `tailscale up` / `down` |
| **Tailscale SSH** | tailscaled **chiếm port 22**, xác thực bằng danh tính tailnet, **bỏ qua `authorized_keys`** | `tailscale set --ssh=true/false` |

- **sshd ở port 2222, KHÔNG phải 22** — vì Tailscale SSH (đang bật) đã chiếm 22 trên IP tailnet. Client dùng key mà trỏ vào 22 sẽ **treo ~60s rồi lỗi auth**, không phải bug của ta. Các port khác đi thẳng vào network stack như thường → 2222 sống chung được với Tailscale SSH: **không phải tắt cái nào cả**. (Docs của các app terminal mobile hay bảo "tắt Tailscale SSH đi" là vì họ mặc định port 22.)
- **KHÔNG tự bật lúc boot:** `systemd.services.sshd.wantedBy = lib.mkForce [ ];` → unit thành "static", `systemctl start` vẫn được. **KHÔNG dùng `startWhenNeeded`** (socket-activation) nếu muốn "đóng": nó vẫn để cổng lắng nghe. Mở/đóng: `sshup` / `sshdown` (shell.nix).
- **`systemctl is-enabled sshd` trả `linked`** (unit NixOS không có `[Install]`) → vô dụng để biết có tự bật hay không. Hỏi thẳng: `[[ -e /etc/systemd/system/multi-user.target.wants/sshd.service ]]`. `netstatus` (`modules/shell-init.zsh`) in đủ 3 tầng + sshd + số khoá.
- Chỉ key (`PasswordAuthentication = false`), `openFirewall = false` + `networking.firewall.interfaces.tailscale0.allowedTCPPorts` → **không hở ra wifi/LAN**. Đừng nới.
- sshd đọc **cả hai** nguồn khoá: `/etc/ssh/authorized_keys.d/nat` (từ `users.users.nat.openssh.authorizedKeys.keys`) **lẫn** `~/.ssh/authorized_keys` (`authorizedKeysInHomedir` mặc định `true`) → tool ngoài ghi vào `~/.ssh/` vẫn có tác dụng.

---

## 9g. Template noctalia → niri: phải tự khai `include` (2026-08-23)

Bật template `niri` trong noctalia (`[theme.templates] builtin_ids = [ "niri" ]`) thì nó ghi màu-theo-wallpaper ra `~/.config/niri/noctalia.kdl` (focus-ring, border, shadow, tab-indicator, insert-hint, recent-windows.highlight). **File đó không tự có tác dụng** — phải có node `include` trong config.kdl.

**Vì sao phải làm tay:** `post_hook` của template (`share/noctalia/assets/templates/niri/apply.sh`) vốn tự append `include "noctalia.kdl"` vào `~/.config/niri/config.kdl`, nhưng HM để file đó là **symlink read-only vào /nix/store** → hook fail im lặng. Template `fuzzel` (community) có `apply.sh` y hệt và cũng fail y hệt; fuzzel vẫn chạy chỉ vì dòng `include=` đã nằm sẵn trong `modules/fuzzel.nix` từ hồi bê repo CachyOS. **Đây là hệ quả cố hữu của declarative config, không phải bug** — mọi tool tự sửa file do HM quản đều đâm vào tường này.

**Khai ở `modules/niri.nix`** qua `programs.niri.config` (schema `settings` không mô hình hoá `include`, và sẽ không bao giờ — đây KHÔNG phải hàng tạm chờ upstream như `open-maximized-to-edges`):
- **Đặt ĐẦU danh sách**, trước `options.programs.niri.config.default` → node nào khai tường minh bên Nix cũng thắng màu noctalia. (Upstream append vào cuối vì họ muốn theming tool thắng; ở repo này file `.nix` mới là nguồn sự thật.) Hiện tại thứ tự chưa tạo khác biệt nào: niri merge `layout` **theo từng field** và node `layout` render từ `settings` không chứa field màu nào; chỗ giao duy nhất là `border` mà nó dùng `off |= part.off` (sticky) nên bất biến theo thứ tự.
- **`optional=true` BẮT BUỘC** — include thiếu file mà không optional là lỗi parse cứng, chết cả config.kdl (cài lại máy / tắt template là niri không lên nổi config).
- **Đường dẫn dạng `~/...` chứ không phải `"noctalia.kdl"` tương đối** như upstream: include tương đối resolve theo thư mục của file config, mà config.kdl của ta là symlink vào /nix/store → base dir có thể ra thư mục store (không có noctalia.kdl). `~` cắt đứt câu hỏi đó.

**Không sợ dẫm chân:** niri watch cả file được include → đổi wallpaper là viền đổi màu ngay, không cần reload. Và regex dò của `apply.sh` (`^\s*include(\s.*)?"([^"]*/)?noctalia\.kdl"(\s|$)`) khớp cả dạng `~/...` → hook thấy có sẵn thì return sớm, thôi fail.

**`border` vẫn tắt** dù noctalia có block `border { active-color … }`: quy tắc "có block border thì tự bật" của niri chỉ áp dụng ở `recursion == 0` (file gốc), không áp trong file được include.

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
