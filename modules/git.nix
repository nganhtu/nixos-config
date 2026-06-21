{ ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "ashytuna";
        email = "ashytuna@gmail.com";
      };

      # Credential helper trỏ binary qua PATH (`!gh`/`!glab`), KHÔNG hardcode /nix/store
      # → miễn nhiễm GC + version bump (xem lịch sử store-path-chết của gh/glab).
      # List [ "" "..." ]: dòng rỗng reset helper kế thừa, rồi set bản PATH.
      credential = {
        "https://github.com".helper = [ "" "!gh auth git-credential" ];
        "https://gist.github.com".helper = [ "" "!gh auth git-credential" ];
        "https://gitlab.onschool.edu.vn".helper = [ "" "!glab auth git-credential" ];
      };
    };
  };
}
