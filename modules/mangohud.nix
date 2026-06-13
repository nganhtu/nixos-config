{ ... }:

{
  programs.mangohud = {
    enable = true;
    settings = {
      gpu_name = true;
      gpu_stats = true;
      gpu_temp = true;
      gpu_core_clock = true;
      gpu_power = true;
      cpu_stats = true;
      cpu_temp = true;
      ram = true;
      vram = true;
      fps = true;
      frametime = true;
      frame_timing = true;
      fps_limit = 0;
      position = "top-left";
      font_size = 20;
      background_alpha = "0.4";
      toggle_hud = "Shift_R+F12";
    };
  };
}
