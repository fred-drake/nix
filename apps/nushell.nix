{pkgs, ...}: {
  home.shell.enableNushellIntegration = true;
  programs = {
    atuin.enableNushellIntegration = true;
    carapace.enableNushellIntegration = true;
    direnv.enableNushellIntegration = true;
    # eza.enableNushellIntegration = true;
    oh-my-posh.enableNushellIntegration = true;
    # pay-respects.enableNushellIntegration = true;
    yazi.enableNushellIntegration = true;
    zoxide.enableNushellIntegration = true;
  };

  programs.nushell = {
    enable = true;
    shellAliases = {
      cm = "chezmoi";
      df = "duf";
      docker = "podman";
      k = "kubectl";
      mc = "yy";
      t = "tmuxinator";
      telnet = "nc -zv";
      man = "batman";
      lg = "lazygit";
      ranger = "yy";
      zed = "`/Applications/Zed Preview.app/Contents/MacOS/cli`";
    };
    extraConfig = ''
      # Plugins
      # plugin add ${pkgs.nushellPlugins.skim}/bin/nu_plugin_skim
      # plugin add ${pkgs.nushellPlugins.query}/bin/nu_plugin_query
      # plugin add ${pkgs.nushellPlugins.gstat}/bin/nu_plugin_gstat
      # plugin add ${pkgs.nushellPlugins.formats}/bin/nu_plugin_formats
      # plugin add ${pkgs.nushellPlugins.highlight}/bin/nu_plugin_highlight

      # function aliases
      def la [] { ls -a }
      def ll [] { ls -l }
      def lla [] { ls -la }
      def lat [] { ls -a | sort-by modified }
      def llat [] { ls -la | sort-by modified }
      def lart [] { ls -a | sort-by modified | reverse }
      def llart [] { ls -la | sort-by modified | reverse }
      def glance-restart [] { ps | where name == "glance" | get pid.0 | kill -s 1 $in }
      def mcpm-aider [...args] { podman run -i --rm -v ./mcp-config.json:/root/.config/claude/claude_desktop_config.json docker.io/fdrake/mcpm-aider ...$args }

      let hostname = (sys host | get hostname)
      if $hostname != "nixosaarch64vm" {
        $env.DOCKER_HOST = "unix:///var/run/docker.sock"
      }

      let carapace_completer = {|spans|
      carapace $spans.0 nushell ...$spans | from json
      }
      $env.config = {
       show_banner: false,
       completions: {
         case_sensitive: false # case-sensitive completions
         quick: true    # set to false to prevent auto-selecting completions
         partial: true    # set to false to prevent partial filling of the prompt
         algorithm: "fuzzy"    # prefix or fuzzy
         external: {
           # set to false to prevent nushell looking into $env.PATH to find more suggestions
           enable: true
           # set to lower can improve completion performance at the cost of omitting some options
           max_results: 100
           completer: $carapace_completer # check 'carapace_completer'
         }
       }
      }
      $env.PATH = ($env.PATH |
      split row (char esep) |
      append /usr/bin/env |
      append ~/.local/bin
      )

      # Aider defaults
      $env.AIDER_MODEL = "deepseek/deepseek-reasoner"
      $env.AIDER_DARK_MODE = "True"

      source-env ~/.llm_api_keys.nu
    '';
    settings = {
      edit_mode = "vi";
      completions.external.enable = true;
      completions.external.max_results = 200;
      show_banner = false;
    };
  };
}
