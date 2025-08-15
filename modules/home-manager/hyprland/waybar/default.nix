{
  config,
  pkgs,
  ...
}: let
  kuma-waybar = pkgs.callPackage ./kuma-waybar.nix {};
  spotifatius = pkgs.callPackage ../spotifatius.nix {};
in {
  sops.secrets.uptime-kuma-env = {
    sopsFile = config.secrets.workstation.uptime-kuma-env;
    mode = "0400";
    key = "data";
  };
  sops.secrets.spotifatius-env = {
    sopsFile = config.secrets.workstation.spotifatius-env;
    mode = "0400";
    key = "data";
  };

  home = {
    packages = [
      kuma-waybar
      pkgs.wttrbar
    ];

    file = {
      ".config/spotifatius/config.toml".text = ''
        format = "{title} {separator} {artist}"
      '';

      ".config/waybar/config".text = builtins.toJSON {
        position = "top";
        modules-left = ["custom/osicon" "cpu" "load" "memory" "disk" "custom/spotify"];
        modules-center = ["clock"];
        modules-right = ["idle_inhibitor" "custom/kuma-waybar" "pulseaudio" "bluetooth" "network" "custom/power"];

        clock = {
          format = "{:%a %d - %I:%M:%S %p}";
          interval = 1;
        };

        "custom/osicon" = {
          format = "";
          tooltip = true;
          tooltip-format = "NixOS";
          interval = "once";
        };

        cpu = {
          format = "{usage}%";
          interval = 2;
          tooltip = true;
          tooltip-format = "Usage: {cpu}\nCores: {cores}";
          min-length = 4;
          align = 1;
        };

        load = {
          interval = 2;
          format = "{load1:2.2f} {load5:2.2f} {load15:2.2f}  ";
        };

        memory = {
          format = "{used:.0f}GB/{total:.0f}GB 󰍛";
          tooltip = true;
          tooltip-format = "RAM used: {used} / {total} ({percentage}%)";
        };

        disk = {
          format = "{percentage_free}%  ";
          tooltip = true;
          tooltip-format = "Free space: {free} / {total} ({percentage_free}%)";
        };

        "custom/kuma-waybar" = {
          exec = "${kuma-waybar}/bin/kuma-waybar --format=waybar --env=${config.sops.secrets.uptime-kuma-env.path}";
          interval = 60;
          on-click = "${kuma-waybar}/bin/kuma-waybar open --env=${config.sops.secrets.uptime-kuma-env.path}";
          max-length = 40;
          format = "  {}";
        };

        "wlr/taskbar" = {
          format = "{icon}";
          all-outputs = true;
          active-first = true;
          tooltip-format = "{name}";
          on-click = "activate";
          on-click-middle = "close";
          ignore-list = ["wofi"];
        };

        idle_inhibitor = {
          format = "";
        };

        pulseaudio = {
          format = "{volume}% {icon}";
          format-muted = " {format_source}";
          format-icons = {default = ["" ""];};
        };

        bluetooth = {
          format = " {status}";
          format-connected = " {device_alias}";
          format-connected-battery = " {device_alias} {device_battery_percentage}%";
          tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
          tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
          tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
        };

        network = {
          format = "{ifname}";
          format-ethernet = "{ipaddr} 󰈀";
          format-disconnected = " ";
          tooltip-format = "{ifname} via {gwaddr}";
          tooltip-format-ethernet = "{ifname} {ipaddr}/{cidr}";
          tooltip-format-disconnected = "Disconnected";
          max-length = 50;
        };

        "custom/power" = {
          format = "⏻";
          on-click = "${pkgs.wlogout}/bin/wlogout --protocol layer-shell";
        };

        "custom/spotify" = {
          format = "  {}";
          return-type = "json";
          on-click-right = "source ${config.sops.secrets.spotifatius-env.path}; ${spotifatius}/bin/spotifatius toggle-liked";
          exec = "source ${config.sops.secrets.spotifatius-env.path} ; ${spotifatius}/bin/spotifatius monitor";
          max-length = 108;
        };
      };

      ".config/waybar/style.css".source = ./style.css;
    };
  };
}
