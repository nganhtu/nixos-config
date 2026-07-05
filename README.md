# nixos-config

A laptop NixOS setup built around **niri** (scrollable-tiling Wayland compositor) and the **Noctalia** shell — with **every dotfile translated to Nix**. No symlinked config files, no bare-repo, no imperative drift: one `nixos-rebuild` reproduces the whole machine.

| Layer | Choice |
|---|---|
| OS | NixOS unstable (flake + Home Manager) |
| Compositor | [niri](https://github.com/sodiboo/niri-flake) |
| Shell / bar | [Noctalia v5](https://github.com/noctalia-dev/noctalia) |
| Terminal | Kitty |
| Editor | Helix |
| File manager | yazi / Thunar |
| Launcher | Fuzzel |
| Input method | Fcitx5 + Bamboo (Vietnamese) |
| Theme | adw-gtk3 · Papirus icons · macOS cursor |

## Why this config

- **Declarative to the bone** — niri's ~100 keybinds, layout, window rules and animations live in `programs.niri.settings`, not a symlinked KDL. Same for kitty, helix, fuzzel, yazi, zsh. Nothing is hand-placed in `$HOME`.
- **Runtime theming that stays alive** — Noctalia v5 derives its whole palette from the wallpaper at runtime; colors are deliberately kept *out* of Nix so re-theming never needs a rebuild.
- **Hybrid graphics, properly** — Intel iGPU + NVIDIA PRIME offload, with VAAPI hardware encode/decode on the Intel side.
- **Hardware screen recording** — the `screenrec` helper wraps wf-recorder with VAAPI h264 at 60fps, optional area select and app/mic audio.
- **One-command upkeep** — `update` / `nrs` drive [nh](https://github.com/nix-community/nh): flake update → rebuild with a package diff → prune → unified GC.
- **Resilient boot** — GRUB installed to the removable fallback path (`\EFI\BOOT\BOOTX64.EFI`), so it survives a Lenovo BIOS NVRAM wipe; dual-boots Windows across two physical disks via os-prober.
- **Storage care** — btrfs monthly autoScrub, zram swap, Nix store auto-optimise, fstrim.
- **Vietnamese input** everywhere via fcitx5 + Bamboo (Wayland frontend).

## Documentation

- **[Key bindings](docs/keybinds.md)** — the full niri binding set.
- **[Shell aliases & functions](docs/shell.md)** — zsh helpers (`update`, `screenrec`, `diskusage`, …).
- **[CLAUDE.md](CLAUDE.md)** — design decisions, hardware layout and rationale.
- **[CHECKLIST.md](CHECKLIST.md)** — staged build log.

## Structure

```
├── flake.nix                              # inputs + nixosConfigurations
├── hosts/<hostname>/
│   ├── configuration.nix                  # system: bootloader, services, packages, fonts
│   ├── hardware-configuration.nix         # generated, do not edit
│   └── nvidia.nix                         # PRIME offload + power management
├── home/<user>.nix                        # Home Manager entry point
├── modules/                               # shared HM modules
│   ├── niri.nix      kitty.nix    helix.nix
│   ├── shell.nix     yazi.nix     thunar.nix
│   ├── fuzzel.nix    btop.nix     theme.nix
│   ├── fastfetch.nix direnv.nix   git.nix
│   └── mangohud.nix  claude.nix   fcitx5.nix
└── assets/
    ├── shell/themes/                      # oh-my-zsh custom theme
    ├── claude/                            # statusline script
    └── fonts/{google-sans,google-sans-code,windows}/
```

## Applying

```sh
nrs                                                          # rebuild (nh os switch)
update                                                       # flake update → rebuild → prune → GC
sudo nixos-rebuild switch --flake ~/nixos-config#<hostname>  # plain fallback
```

> Use the absolute path `~/nixos-config#<hostname>`, not `.#<hostname>` — running under `sudo` from elsewhere resolves `.` wrong.

[nh](https://github.com/nix-community/nh) shows a package diff before activating and renders build output with nix-output-monitor; `nh clean all` is unified GC (also run weekly by `programs.nh.clean`). Debugging a failed build: nh still prints the failing derivation's log tail, and `nix log <drv>` gives the full log; add `--no-nom` for plain output.

## Extras

- **[mangohud](https://github.com/flightlessmango/MangoHud)** — in-game FPS/GPU/temperature overlay. Add `nvidia-offload mangohud %command%` to a Steam game's launch options; toggle with `Shift_R+F12`.
- **[agenix](https://github.com/ryantm/agenix)** — the CLI is kept for editing agenix-encrypted secrets (stored outside this repo).

## Fonts

`assets/fonts/windows/` holds Windows fonts (Segoe UI, Calibri, …) bundled by the `proprietary-fonts` derivation in `hosts/<hostname>/configuration.nix` — personal copies kept in this private repo, not for redistribution. `google-sans/` and `google-sans-code/` are under the SIL Open Font License (see each directory's `OFL.txt`).
