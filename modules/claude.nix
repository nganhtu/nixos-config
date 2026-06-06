{ ... }:

{
  home.file.".claude/statusline-command.sh" = {
    source = ../claude/statusline.sh;
    executable = true;
  };

  home.file.".claude/settings.json".text = builtins.toJSON {
    theme = "dark";
    statusLine = {
      type = "command";
      command = "sh /home/nat/.claude/statusline-command.sh";
    };
  };
}
