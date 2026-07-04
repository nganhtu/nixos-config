{ pkgs, ... }:

let
  # undmg: .dmg (Apple disk image) không phải archive libarchive/file-roller đọc được
  # → thunar-archive-plugin không tự nhận diện, phải custom action riêng.
  extractDmg = pkgs.writeShellApplication {
    name = "thunar-extract-dmg";
    runtimeInputs = [ pkgs.undmg pkgs.coreutils ];
    text = ''
      for f in "$@"; do
        f=$(readlink -f "$f")
        dir=$(dirname "$f")
        base=$(basename "$f" .dmg)
        out="$dir/$base"
        mkdir -p "$out"
        (cd "$out" && undmg "$f")
      done
    '';
  };

  # Font .dmg của Apple (SF Pro, SF Mono, New York...) chỉ chứa 1 file .pkg
  # (flat package, định dạng xar) chứ không phải font rời. Bóc thêm 2 lớp:
  # xar -x → Payload (gzip hoặc pbzx tuỳ kích thước) → cpio -id → lọc *.ttf/*.otf/*.ttc.
  extractAppleFonts = pkgs.writeShellApplication {
    name = "thunar-extract-apple-fonts";
    runtimeInputs = [
      pkgs.undmg
      pkgs.xar
      pkgs.cpio
      pkgs.pbzx
      pkgs.gzip
      pkgs.findutils
      pkgs.coreutils
    ];
    text = ''
      for f in "$@"; do
        f=$(readlink -f "$f")
        dir=$(dirname "$f")
        base=$(basename "$f" .dmg)
        work=$(mktemp -d)
        trap 'rm -rf "$work"' EXIT

        (cd "$work" && undmg "$f")

        pkg=$(find "$work" -iname "*.pkg" -print -quit)
        if [ -z "$pkg" ]; then
          echo "thunar-extract-apple-fonts: không thấy .pkg trong $f" >&2
          continue
        fi

        xardir="$work/xar"
        mkdir -p "$xardir"
        (cd "$xardir" && xar -xf "$pkg")

        outdir="$dir/$base Fonts"
        mkdir -p "$outdir"

        while IFS= read -r -d "" payload; do
          payload_out=$(mktemp -d)
          magic=$(head -c4 "$payload" | od -An -tx1 | tr -d " \n")
          if [ "$magic" = "1f8b0800" ]; then
            (cd "$payload_out" && zcat "$payload" | cpio -id --quiet)
          else
            (cd "$payload_out" && pbzx "$payload" | cpio -id --quiet)
          fi
          find "$payload_out" -type f \( -iname "*.ttf" -o -iname "*.otf" -o -iname "*.ttc" \) -exec mv -t "$outdir" {} +
          rm -rf "$payload_out"
        done < <(find "$xardir" -iname Payload -print0)

        rm -rf "$work"
        trap - EXIT
      done
    '';
  };
in
{
  home.packages = [
    extractDmg
    extractAppleFonts
  ];

  # Custom action Thunar (right-click). uca.xml do HM quản → read-only; thêm action
  # mới qua GUI sẽ không lưu được. Dùng %F (không phải %f) để action còn hiện khi
  # chọn nhiều file cùng lúc — Thunar ẩn action nếu command chỉ có placeholder %f.
  xdg.configFile."Thunar/uca.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <actions>
    <action>
    	<icon>kitty</icon>
    	<name>Open Kitty Here</name>
    	<submenu></submenu>
    	<unique-id>1717718400000000-1</unique-id>
    	<command>kitty --directory %f</command>
    	<description>Open a kitty terminal in this directory</description>
    	<range></range>
    	<patterns>*</patterns>
    	<startup-notify/>
    	<directories/>
    </action>
    <action>
    	<icon>utilities-archiver</icon>
    	<name>Extract DMG Here</name>
    	<submenu></submenu>
    	<unique-id>1783300000000-2</unique-id>
    	<command>thunar-extract-dmg %F</command>
    	<description>Extract Apple .dmg disk image(s) into same-named folder(s)</description>
    	<range></range>
    	<patterns>*.dmg</patterns>
    	<startup-notify/>
    	<other-files/>
    </action>
    <action>
    	<icon>font-x-generic</icon>
    	<name>Extract Fonts from DMG</name>
    	<submenu></submenu>
    	<unique-id>1783300000000-3</unique-id>
    	<command>thunar-extract-apple-fonts %F</command>
    	<description>Extract .ttf/.otf/.ttc fonts out of an Apple font installer .dmg (dmg → pkg → xar → cpio)</description>
    	<range></range>
    	<patterns>*.dmg</patterns>
    	<startup-notify/>
    	<other-files/>
    </action>
    </actions>
  '';
}
