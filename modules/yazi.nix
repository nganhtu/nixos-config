{ ... }:

{
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
    initLua = ./yazi-init.lua;

    settings = {
      mgr = {
        show_hidden = true;
        sort_by = "natural";
        sort_dir_first = true;
        linemode = "size_and_mtime";
      };
    };
  };
}
