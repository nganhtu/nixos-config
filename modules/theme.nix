{ pkgs, ... }:

{
  home.pointerCursor = {
    enable = true;
    package = pkgs.apple-cursor;
    name = "macOS";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  gtk = {
    enable = true;
    font = {
      # "Segoe UI" (static): Chrome không load được family này (rơi về fallback
      # xấu) — bản Variable thì được. GTK/Pango load cả hai như nhau.
      name = "Segoe UI Variable";
      size = 12;
    };
    cursorTheme = {
      package = pkgs.apple-cursor;
      name = "macOS";
      size = 24;
    };
    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };
    theme = {
      package = pkgs.gnome-themes-extra;
      name = "Adwaita";
    };
    gtk4.theme = null;
  };
}
