{
  pkgs,
  inputs,
  config,
  ...
}: let
  home = config.home.homeDirectory;
  # spotifatius = pkgs.callPackage ./spotifatius.nix {};  # Temporarily disabled due to CMake build issues
in {
  imports = [./waybar];

  services.mako = {
    enable = true;

    settings = {
      # Position at top center
      anchor = "top-center";
      default-timeout = 4000;

      # Dimensions
      width = 550;
      height = 100;
      margin = "20";
      padding = "15";
      border-size = 2;
      border-radius = 10;

      # Tokyo Night theme colors
      background-color = "#1a1b26";
      text-color = "#c0caf5";
      border-color = "#7aa2f7";
      progress-color = "#7aa2f7";

      # Typography
      font = "JetBrainsMono Nerd Font 12";

      # Icons
      icons = true;
      max-icon-size = 64;

      # Behavior
      layer = "overlay";
      sort = "-time";

      # Grouping
      group-by = "summary";
    };

    # Extra config for urgency styling using raw config
    extraConfig = ''
      [urgency=low]
      background-color=#1a1b26
      text-color=#9ece6a
      border-color=#9ece6a
      default-timeout=3000

      [urgency=normal]
      background-color=#1a1b26
      text-color=#c0caf5
      border-color=#7aa2f7
      default-timeout=4000

      [urgency=high]
      background-color=#1a1b26
      text-color=#f7768e
      border-color=#f7768e
      default-timeout=0
    '';
  };

  # GTK configuration for dark mode
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  # Qt configuration for dark mode
  qt = {
    enable = true;
    platformTheme.name = "gtk3";
    style.name = "adwaita-dark";
  };

  # Set dark mode for xdg-desktop-portal
  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
    config.common = {
      default = ["gtk"];
      "org.freedesktop.impl.portal.Settings" = ["gtk"];
    };
    xdgOpenUsePortal = true;
  };

  # dconf settings for GNOME/GTK apps
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Adwaita-dark";
    };
  };

  # home.file.".config/wlogout/layout".source = ./wlogout-config;

  home = {
    packages = [
      pkgs.playerctl
      # spotifatius  # Temporarily disabled due to CMake build issues
      pkgs.nerd-fonts.jetbrains-mono
    ];
  };

  home.file = {
    ".config/wlogout/layout".text = ''
      {
          "label" : "lock",
          "action" : "${pkgs.hyprlock}/bin/hyprlock",
          "text" : "Lock",
          "keybind" : "l"
      }
      {
          "label" : "hibernate",
          "action" : "systemctl hibernate",
          "text" : "Hibernate",
          "keybind" : "h"
      }
      {
          "label" : "logout",
          "action" : "loginctl terminate-user $USER",
          "text" : "Logout",
          "keybind" : "e"
      }
      {
          "label" : "shutdown",
          "action" : "systemctl poweroff",
          "text" : "Shutdown",
          "keybind" : "s"
      }
      {
          "label" : "suspend",
          "action" : "systemctl suspend",
          "text" : "Suspend",
          "keybind" : "u"
      }
      {
          "label" : "reboot",
          "action" : "systemctl reboot",
          "text" : "Reboot",
          "keybind" : "r"
      }
    '';

    ".config/wofi/style.css".source = ./wofi.css;
    ".config/hypr/hyprlock.conf".source = ./hyprlock.conf;
    ".config/hypr/weather.sh" = {
      source = ./weather.sh;
      executable = true;
    };

    ".config/hypr/hyprpaper.conf".text = ''
      preload = ${home}/Pictures/wallpaper/wp6746982-tokyo-night-wallpapers.jpg
      wallpaper = ,${home}/Pictures/wallpaper/wp6746982-tokyo-night-wallpapers.jpg
    '';
  };

  services.hypridle = {
    enable = true;

    settings = {
      general = {
        lock_cmd = "${pkgs.hyprlock}/bin/hyprlock"; # command to run when locking the screen
        before_sleep_cmd = "${pkgs.hyprlock}/bin/hyprlock"; # command to run before system sleeps
        after_sleep_cmd = "hyprctl dispatch dpms on"; # command after waking up (turns screen on)
        ignore_dbus_inhibit = false;
      };

      listener = [
        {
          timeout = 600; # 10 minutes idle time
          on-timeout = "${pkgs.hyprlock}/bin/hyprlock"; # lock screen on this timeout
        }
        {
          timeout = 900; # 15 minutes
          on-timeout = "hyprctl dispatch dpms off"; # turn off screen after timeout
          on-resume = "hyprctl dispatch dpms on"; # turn on screen on resume
        }
      ];
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages."${pkgs.stdenv.hostPlatform.system}".hyprland;

    portalPackage = pkgs.xdg-desktop-portal-hyprland;

    settings = {
      # Window rules
      windowrule = [
        "match:class .*, suppress_event maximize"
        "match:class ^$, match:title ^$, match:xwayland 1, suppress_event activatefocus"
      ];
      ################
      ### MONITORS ###
      ################

      # See https://wiki.hyprland.org/Configuring/Monitors/
      monitor = ",preferred,auto,auto";

      ###################
      ### MY PROGRAMS ###
      ###################

      # See https://wiki.hyprland.org/Configuring/Keywords/

      # Set programs that you use
      "$terminal" = "ghostty";
      "$fileManager" = "nautilus";
      "$menu" = "wofi --show drun";

      #################
      ### AUTOSTART ###
      #################

      # Autostart necessary processes (like notifications daemons, status bars, etc.)
      # Or execute your favorite apps at launch like this:

      # exec-once = $terminal
      # exec-once = nm-applet &
      # exec-once = waybar & hyprpaper & firefox
      # exec-once = "bash ~/.config/hypr/start.sh";
      exec-once = [
        # "swww init &"
        # "swww img ~/Pictures/night-desert.png &"
        # Add pkgs.networkmanagerapplet for this
        # nm-applet --indicator &
        # "waybar &"
        # "dunst &"
        "${pkgs.hyprpaper}/bin/hyprpaper"
        "tmux setenv -g HYPRLAND_INSTANCE_SIGNATURE $HYPRLAND_INSTANCE_SIGNATURE"
      ];

      #############################
      ### ENVIRONMENT VARIABLES ###
      #############################

      # See https://wiki.hyprland.org/Configuring/Environment-variables/

      env = [
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
        "HYPRCURSOR_THEME,rose-pine-hyprcursor"
        # Dark mode settings
        "GTK_THEME,Adwaita-dark"
        "GNOME_THEME,Adwaita:dark"
        "QT_STYLE_OVERRIDE,Adwaita-Dark"
        "QT_QPA_PLATFORMTHEME,gtk3"
        # Gaming performance optimizations
        "SDL_VIDEODRIVER,wayland"
        "__GL_VRR_ALLOWED,0"
        "WLR_DRM_NO_ATOMIC,1"
      ];

      #####################
      ### LOOK AND FEEL ###
      #####################

      # Refer to https://wiki.hyprland.org/Configuring/Variables/

      # https://wiki.hyprland.org/Configuring/Variables/#general
      general = {
        "gaps_in" = 5;
        "gaps_out" = 5;

        "border_size" = 1;

        # https://wiki.hyprland.org/Configuring/Variables/#variable-types for info about colors
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";

        # Set to true enable resizing windows by clicking and dragging on borders and gaps
        "resize_on_border" = false;

        # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
        "allow_tearing" = false;

        "layout" = "dwindle";
      };

      # https://wiki.hyprland.org/Configuring/Variables/#decoration
      decoration = {
        rounding = 10;
        rounding_power = 2;

        # Change transparency of focused and unfocused windows
        active_opacity = "1.0";
        inactive_opacity = "1.0";

        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };

        # https://wiki.hyprland.org/Configuring/Variables/#blur
        blur = {
          enabled = false; # Disabled for gaming performance
          size = 3;
          passes = 1;

          vibrancy = 0.1696;
        };
      };

      # https://wiki.hyprland.org/Configuring/Variables/#animations
      animations = {
        enabled = false; # Disabled for gaming performance

        # Default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more

        bezier = [
          "easeOutQuint,0.23,1,0.32,1"
          "easeInOutCubic,0.65,0.05,0.36,1"
          "linear,0,0,1,1"
          "almostLinear,0.5,0.5,0.75,1.0"
          "quick,0.15,0,0.1,1"
        ];

        animation = [
          "global, 1, 10, default"
          "border, 1, 5.39, easeOutQuint"
          "windows, 1, 4.79, easeOutQuint"
          "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
          "windowsOut, 1, 1.49, linear, popin 87%"
          "fadeIn, 1, 1.73, almostLinear"
          "fadeOut, 1, 1.46, almostLinear"
          "fade, 1, 3.03, quick"
          "layers, 1, 3.81, easeOutQuint"
          "layersIn, 1, 4, easeOutQuint, fade"
          "layersOut, 1, 1.5, linear, fade"
          "fadeLayersIn, 1, 1.79, almostLinear"
          "fadeLayersOut, 1, 1.39, almostLinear"
          "workspaces, 1, 1.94, almostLinear, fade"
          "workspacesIn, 1, 1.21, almostLinear, fade"
          "workspacesOut, 1, 1.94, almostLinear, fade"
        ];
      };

      # Ref https://wiki.hyprland.org/Configuring/Workspace-Rules/
      # "Smart gaps" / "No gaps when only"
      # uncomment all if you wish to use that.
      # workspace = w[tv1], gapsout:0, gapsin:0
      # workspace = f[1], gapsout:0, gapsin:0
      # windowrule = bordersize 0, floating:0, onworkspace:w[tv1]
      # windowrule = rounding 0, floating:0, onworkspace:w[tv1]
      # windowrule = bordersize 0, floating:0, onworkspace:f[1]
      # windowrule = rounding 0, floating:0, onworkspace:f[1]

      # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
      dwindle = {
        pseudotile = true; # Master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
        preserve_split = true; # You probably want this
      };

      # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
      master = {
        new_status = "master";
      };

      # https://wiki.hyprland.org/Configuring/Variables/#misc
      misc = {
        force_default_wallpaper = 0; # 0 disables the anime mascot wallpapers, 1 enables, -1 follows disable_hyprland_logo
        disable_hyprland_logo = true; # Disables the random hyprland logo / anime girl background
        vfr = true; # Enable variable frame rate for better gaming performance
        vrr = 2; # Enable variable refresh rate (2 = fullscreen only, better for gaming)
      };

      #############
      ### INPUT ###
      #############

      # https://wiki.hyprland.org/Configuring/Variables/#input
      input = {
        kb_layout = "us";
        kb_variant = "";
        kb_model = "";
        kb_options = "";
        kb_rules = "";

        follow_mouse = 1;

        sensitivity = 0; # -1.0 - 1.0, 0 means no modification.

        touchpad = {
          natural_scroll = false;
        };
      };

      # https://wiki.hyprland.org/Configuring/Variables/#gestures
      # Now throws error that no longer exists 2025-08-30
      # gestures = {
      #   workspace_swipe = false;
      # };

      # Example per-device config
      # See https://wiki.hyprland.org/Configuring/Keywords/#per-device-input-configs for more
      device = {
        name = "epic-mouse-v1";
        sensitivity = -0.5;
      };

      ###################
      ### KEYBINDINGS ###
      ###################

      # See https://wiki.hyprland.org/Configuring/Keywords/
      "$mainMod" = "ALT"; # Sets "Windows" key as main modifier

      # Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
      bind = [
        "$mainMod, C, killactive,"
        "$mainMod, M, exit,"
        "$mainMod, E, exec, $fileManager"
        "$mainMod, V, togglefloating,"
        "SUPER, SPACE, exec, $menu"
        # "$mainMod, P, pseudo, # dwindle"  # Disabled to allow alt-p in helix
        # "$mainMod, SHIFT, J, togglesplit, # dwindle"

        "$mainMod CTRL, A, exec, $terminal"
        "$mainMod CTRL, Z, exec, zen"
        "$mainMod CTRL, O, exec, obsidian --disable-gpu"
        # "$mainMod CTRL ALT, L, exec, ${spotifatius}/bin/spotifatius toggle-liked"  # Temporarily disabled
        "$mainMod CTRL, L, exec, localsend_app"

        ", Print, exec, ${pkgs.hyprshot}/bin/hyprshot --mode region -o ${home}/Screenshots"

        # Move focus with mainMod + arrow keys
        "$mainMod, H, movefocus, l"
        "$mainMod, L, movefocus, r"
        "$mainMod, K, movefocus, u"
        "$mainMod, J, movefocus, d"

        # Swap windows with mainMod + arrow keys
        "$mainMod SHIFT, H, swapwindow, l"
        "$mainMod SHIFT, L, swapwindow, r"
        "$mainMod SHIFT, J, swapwindow, d"
        "$mainMod SHIFT, K, swapwindow, u"

        # Switch workspaces with mainMod + [0-9]
        "$mainMod, A, workspace, 1"
        "$mainMod, Z, workspace, 2"
        "$mainMod, S, workspace, 3"
        "$mainMod, O, workspace, 4"
        "$mainMod, W, workspace, 5"
        "$mainMod, D, workspace, 6"
        "$mainMod, F, workspace, 7"
        "$mainMod, G, workspace, 8"
        "$mainMod, Q, workspace, 9"
        "$mainMod, R, workspace, 10"

        # Move active window to a workspace with mainMod + SHIFT + [0-9]
        "$mainMod SHIFT, A, movetoworkspace, 1"
        "$mainMod SHIFT, Z, movetoworkspace, 2"
        "$mainMod SHIFT, S, movetoworkspace, 3"
        "$mainMod SHIFT, O, movetoworkspace, 4"
        "$mainMod SHIFT, W, movetoworkspace, 5"
        "$mainMod SHIFT, D, movetoworkspace, 6"
        "$mainMod SHIFT, F, movetoworkspace, 7"
        "$mainMod SHIFT, G, movetoworkspace, 8"
        "$mainMod SHIFT, Q, movetoworkspace, 9"
        "$mainMod SHIFT, R, movetoworkspace, 10"

        # Example special workspace (scratchpad)
        # "$mainMod, S, togglespecialworkspace, magic"
        # "$mainMod SHIFT, S, movetoworkspace, special:magic"
      ];

      # Move/resize windows with mainMod + LMB/RMB and dragging
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
      # Laptop multimedia keys for volume and LCD brightness
      bindel = [
        ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ",XF86MonBrightnessUp, exec, brightnessctl s 10%+"
        ",XF86MonBrightnessDown, exec, brightnessctl s 10%-"
      ];
      # Requires playerctl
      bindl = [
        ", XF86AudioNext, exec, playerctl -p spotify next"
        ", XF86AudioPause, exec, playerctl -p spotify play-pause"
        ", XF86AudioPlay, exec, playerctl -p spotify play-pause"
        ", XF86AudioPrev, exec, playerctl -p spotify previous"
      ];

      ##############################
      ### WINDOWS AND WORKSPACES ###
      ##############################

      # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
      # See https://wiki.hyprland.org/Configuring/Workspace-Rules/ for workspace rules

      # Example windowrule
      # windowrule = float,class:^(kitty)$,title:^(kitty)$
    };
  };
}
