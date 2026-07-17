{ ... }:

{
  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
  };

  programs.zoxide.enable = true;

  programs.lazygit = {
    enable = true;
    settings.git.pagers = [
      {
        colorArg = "always";
        pager = "delta --paging=never";
      }
    ];
  };

  programs.zsh = {
    enable = true;

    oh-my-zsh = {
      enable = true;
      theme = "natys";
      custom = "${../assets/shell}";
      plugins = [ "git" ];
    };

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 10000;
      save = 10000;
    };

    shellAliases = {
      ls = "lsd";
      l = "ls -l";
      la = "ls -a";
      lla = "ls -la";
      lt = "ls --tree";
      sulla = "sudo lsd -la";
      sult = "sudo lsd --tree";

      cat = "bat";

      vi = "nvim";
      suvi = "sudo -E nvim";
      suhx = "sudo -E hx";

      doco = "docker compose";
      docodul = "docker compose down && docker compose up -d && docker compose logs -f";
      docobuild = "COMPOSE_BAKE=true docker compose build";

      dv = "devenv";
      dvu = "devenv up";
      dvpr = "devenv processes";

      gitcfnganhtu = ''git config user.name "nganhtu" && git config user.email "ng.anh.tu.1123@gmail.com"'';
      gitcfashytuna = ''git config user.name "ashytuna" && git config user.email "ashytuna@gmail.com"'';
      gitcftuna = ''git config user.name "tuna" && git config user.email "tuna@onschool.edu.vn"'';

      sshup = "sudo systemctl start sshd";
      sshdown = "sudo systemctl stop sshd";

      upsync = "update_and_merge_sync";
    };

    # Script zsh thật (modules/shell-init.zsh) — tách khỏi Nix string để khỏi
    # phải escape ''${...} thành ${...} và editor/shellcheck nhận đúng cú pháp.
    initContent = builtins.readFile ./shell-init.zsh;
  };

}
