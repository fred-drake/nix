{
  enable = true;
  settings = {
    live_config_reload = true;
    working_directory = "None";

    colors.bright = {
      black = "0x565656";
      blue = "0x49a4f8";
      cyan = "0x99faf2";
      green = "0xc0e17d";
      magenta = "0xa47de9";
      red = "0xec5357";
      white = "0xffffff";
      yellow = "0xf9da6a";
    };

    colors.normal = {
      black = "0x2e2e2e";
      blue = "0x47a0f3";
      cyan = "0x64dbed";
      green = "0xabe047";
      magenta = "0x7b5cb0";
      red = "0xeb4129";
      white = "0xe5e9f0";
      yellow = "0xf6c744";
    };

    colors.primary = {
      background = "0x101421";
      foreground = "0xfffbf6";
    };

    cursor.style = {
      blinking = "Off";
      shape = "Block";
    };

    font = {
      builtin_box_drawing = true;
      size = 14.0;
    };

    font.bold = {
      family = "Hack Nerd Font";
      style = "Bold";
    };

    font.bold_italic = {
      family = "Hack Nerd Font";
      style = "Bold Italic";
    };

    font.italic = {
      family = "Hack Nerd Font";
      style = "Italic";
    };

    font.normal = {
      family = "Hack Nerd Font";
      style = "Regular";
    };

    shell = {
      program = "/etc/profiles/per-user/fdrake/bin/fish";
    };

    window = {
      decorations = "full";
      dynamic_title = true;
      opacity = 0.95;
      title = "Alacritty";
    };

    window.class = {
      general = "Alacritty";
      instance = "Alacritty";
    };

    window.padding = {
      x = 5;
      y = 5;
    };
  };
}
