{ ... }:

{
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";

    settings = {
      mgr = {
        show_hidden = true;
        sort_by = "natural";
        sort_dir_first = true;
      };
    };
  };
}
