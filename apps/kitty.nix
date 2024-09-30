# Kitty Terminal Configuration
#
# This file defines the configuration for the Kitty terminal emulator.
# It includes settings for:
#   - Font and appearance
#   - Keybindings for window and tab management
#   - Window layout and background image
#   - Tab bar style
#   - Shell integration

{
  programs.kitty = {
    enable = true;
    font = {
      name = "MesloLGS NF";
      size = 14.0;
    };
    keybindings = {
      "super+alt+enter" = "launch --cwd=current";
      "super+alt+w" = "close_window";
      "super+alt+l" = "next_window";
      "super+alt+h" = "previous_window";
      "super+alt+1" = "first_window";
      "super+alt+2" = "second_window";
      "super+alt+3" = "third_window";
      "super+alt+4" = "fourth_window";
      "super+alt+5" = "fifth_window";
      "super+alt+6" = "sixth_window";
      "super+alt+7" = "seventh_window";
      "super+alt+8" = "eighth_window";
      "super+alt+9" = "ninth_window";
      "super+alt+0" = "tenth_window";
      "super+alt+o" = "next_layout";
      "super+l" = "next_tab";
      "super+h" = "previous_tab";
      "super+enter" = "new_tab";
      "super+t" = "new_tab";
      "super+1" = "goto_tab 1";
      "super+2" = "goto_tab 2";
      "super+3" = "goto_tab 3";
      "super+4" = "goto_tab 4";
      "super+5" = "goto_tab 5";
      "super+6" = "goto_tab 6";
      "super+7" = "goto_tab 7";
      "super+8" = "goto_tab 8";
      "super+9" = "goto_tab 9";
      "super+plus" = "change_font_size all +2.0";
      "super+minus" = "change_font_size all -2.0";
    };
    settings = {
      "window_margin_width" = 10;
      "single_window_margin_width" = 0;
      "background_image" = "~/Pictures/night-desert.png";
      "background_image_layout" = "scaled";
      "window_border_width" = 2;
      "background_tint" = "0.8";
      "background_tint_gaps" = -10;
      "enabled_layouts" = "tall:full_size=2, grid, *";
      "tab_bar_style" = "powerline";
      "tab_powerline_style" = "round";
      "tab_title_template" = "{index}: {title}";
    };
    shellIntegration.enableZshIntegration = true;
  };
}

