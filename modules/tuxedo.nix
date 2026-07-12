{ config, lib, ... }:

let
  palette = import ./palette.nix;
in
{
  # Không có TODO_DIR, tuxedo mở ./todo.txt theo cwd (không có thì mở sample).
  # Ép nó luôn dùng ~/todo.txt + ~/done.txt — cũng là 2 file được sync.
  home.sessionVariables.TODO_DIR = config.home.homeDirectory;

  # Custom theme "Bliss" fork từ built-in Terminal: cùng nguồn palette với kitty
  # (modules/palette.nix) nên không khai màu hai lần. Khác Terminal ở chỗ tách
  # được highlight (selected) khỏi done — Terminal gộp cả hai vào slot ANSI 8.
  # Theme file app chỉ ĐỌC → symlink read-only an toàn (khác config.toml).
  # bg/panel/statusbar = reset để giữ nền trong suốt (kitty background_opacity).
  xdg.configFile."tuxedo/themes/bliss.toml".text = ''
    name = Bliss
    bg = reset
    panel = reset
    border = ${palette.brightBlack}
    fg = ${palette.foreground}
    dim = ${palette.brightBlack}
    accent = ${palette.cyan}
    cursor = ${palette.selectionBg}
    selection = ${palette.brightBlack}
    statusbar = reset
    status_fg = reset
    mode_fg = ${palette.black}
    mode_bg = ${palette.cyan}
    pri_a = ${palette.red}
    pri_b = ${palette.yellow}
    pri_c = ${palette.green}
    pri_d = ${palette.blue}
    pri_other = ${palette.magenta}
    project = ${palette.green}
    context = ${palette.yellow}
    due = ${palette.yellow}
    overdue = ${palette.red}
    today = ${palette.red}
    done = ${palette.brightMagenta}
    selected = ${palette.selectionBg}
    matched = ${palette.yellow}
  '';

  # tuxedo tự ghi config.toml (theme/density/sort/toggle/share-server/filters) →
  # KHÔNG symlink read-only qua xdg.configFile (sẽ đóng băng hết state runtime).
  # Chỉ pin vài key mình muốn cố định, để nguyên phần còn lại cho app tự quản.
  # Mỗi lần nrs sẽ ghi lại các key này; runtime vẫn đổi được trong phiên (vd H),
  # chỉ là nrs kế đưa về giá trị pin.
  home.activation.tuxedoConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cfg="${config.xdg.configHome}/tuxedo/config.toml"
    run mkdir -p "$(dirname "$cfg")"
    run touch "$cfg"
    pin() {
      if grep -q "^$1 = " "$cfg"; then
        run sed -i "s|^$1 = .*|$1 = $2|" "$cfg"
      else
        run sh -c 'printf "%s = %s\n" "$1" "$2" >> "$3"' _ "$1" "$2" "$cfg"
      fi
    }
    pin theme Bliss
    pin show_done true
  '';
}
