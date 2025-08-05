{
  config,
  pkgs,
  ...
}: let
  kuma-waybar = pkgs.callPackage ./kuma-waybar.nix {};
in {
  sops.secrets.uptime-kuma-env = {
    sopsFile = config.secrets.workstation.uptime-kuma-env;
    mode = "0400";
    key = "data";
  };

  home = {
    packages = [
      kuma-waybar
      pkgs.wttrbar
    ];

    file = {
      ".config/waybar/config".text = builtins.toJSON {
        position = "top";
        modules-left = ["custom/osicon" "clock" "cpu" "load" "memory" "disk" "custom/weather"];
        modules-right = ["custom/kuma-waybar" "idle_inhibitor" "pulseaudio" "bluetooth" "network" "custom/power"];

        clock = {
          format = "{:%d - %H:%M:%S}";
          interval = 1;
        };

        "custom/osicon" = {
          format = "";
          tooltip = true;
          tooltip-format = "NixOS";
          interval = "once";
        };

        cpu = {
          format = "{usage:2}%";
          interval = 2;
          tooltip = true;
          tooltip-format = "Usage: {cpu}\nCores: {cores}";
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

        "custom/weather" = {
          exec = "${pkgs.wttrbar}/bin/wttrbar --fahrenheit --nerd --ampm -m -l en";
          format = "{} °";
          tooltip = true;
          interval = 3600;
          return-type = "json";
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
          format = "{icon}";
          format-icons = {
            activated = "";
            deactivated = "";
          };
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
      };

      ".config/waybar/style.css".source = ./style.css;
    };
  };
}
