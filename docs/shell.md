# Shell — aliases & functions

zsh + oh-my-zsh (`natys` theme), defined in [`modules/shell.nix`](../modules/shell.nix). Also wired in: [zoxide](https://github.com/ajeetdsouza/zoxide), [lazygit](https://github.com/jesseduffield/lazygit) with a delta pager, fzf key bindings, and `EDITOR=hx`.

## Aliases
| Alias | Expands to | Purpose |
|---|---|---|
| `ls` | `lsd` | icons + colors |
| `l` | `ls -l` | long listing |
| `la` | `ls -a` | include hidden |
| `lla` | `ls -la` | long + hidden |
| `lt` | `ls --tree` | tree view |
| `sulla` | `sudo lsd -la` | long + hidden, as root |
| `sult` | `sudo lsd --tree` | tree, as root |
| `cat` | `bat` | syntax-highlighted pager |
| `ssh` | `kitten ssh` | kitty's ssh (ships terminfo) |
| `vi` | `nvim` | |
| `suvi` | `sudo -E nvim` | edit as root, keep env |
| `suhx` | `sudo -E hx` | helix as root |
| `doco` | `docker compose` | |
| `docodul` | `docker compose down && up -d && logs -f` | recreate stack, follow logs |
| `docobuild` | `COMPOSE_BAKE=true docker compose build` | build with bake |

## Functions
| Function | What it does |
|---|---|
| `nrs` | Rebuild the system: `nh os switch` |
| `update` | Full maintenance pass: flake update → rebuild → docker prune → journal vacuum (1 week) → GC (`nh clean all --keep 10`) |
| `diskusage [path]` | Interactive disk usage with [gdu](https://github.com/dundee/gdu) (defaults to `/`) |
| `screenrec [-r] [-a\|-m]` | Screen recording, VAAPI h264 @ 60fps → `~/Videos/`. `-r` pick an area (slurp), `-a` capture app audio, `-m` capture mic |
| `docobash <svc>` / `docosh <svc>` | `docker compose exec` into a service (bash / sh, uid 1000) |
| `watch_cpu` | Live per-core CPU MHz |
| `check_hmwon` | List hwmon temperature sensors |

---
[← Back to README](../README.md)
