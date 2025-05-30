{config, ...}: let
  dir = ".config/tmuxinator";
in {
  home.file = {
    "${dir}/fredpc.yml".text = builtins.toJSON {
      name = "fredpc";
      root = "~/";
      windows = [
        {
          nix = {
            root = "~/nix";
            layout = "even-horizontal";
            panes = ["claude" "nvim" ""];
          };
        }
        {
          br-infra = {
            root = "~/Source/gitea.${config.soft-secrets.networking.domain}/BrainRush/infrastructure";
            layout = "even-horizontal";
            panes = ["claude" "nvim" ""];
          };
        }
        {
          br-secrets = {
            root = "~/Source/gitea.${config.soft-secrets.networking.domain}/BrainRush/nix-secrets";
            layout = "even-horizontal";
            panes = ["claude" "nvim" ""];
          };
        }
      ];
    };
    "${dir}/nixosaarch64vm.yml".text = builtins.toJSON {
      name = "nixosaarch64vm";
      root = "~/";
      windows = [
        {
          nix = {
            root = "~/nix";
            layout = "even-horizontal";
            panes = ["claude" "nvim" ""];
          };
        }
      ];
    };
    "${dir}/mac-studio.yml".text = builtins.toJSON {
      name = "mac-studio";
      root = "~/";
      windows = [
        {
          nix = {
            root = "~/nix";
            layout = "even-horizontal";
            panes = ["claude" "nvim" ""];
          };
        }
        {
          nix-sec = {
            root = "~/Source/github.com/fred-drake/nix-secrets/";
            layout = "even-horizontal";
            panes = ["claude" "nvim" ""];
          };
        }
        {
          br-web = {
            root = "~/Source/gitea.${config.soft-secrets.networking.domain}/brainrush/brainrush-web";
            layout = "even-horizontal";
            panes = ["claude" "nvim" ""];
          };
        }
        {
          br-chat = {
            root = "~/Source/gitea.${config.soft-secrets.networking.domain}/brainrush/brainrush-chat";
            layout = "even-horizontal";
            panes = ["claude" "nvim" ""];
          };
        }
        {
          br-user = {
            root = "~/Source/gitea.${config.soft-secrets.networking.domain}/brainrush/brainrush-user";
            layout = "even-horizontal";
            panes = ["claude" "nvim" ""];
          };
        }
        {
          mcp-textbook = {
            root = "~/Source/gitea.${config.soft-secrets.networking.domain}/brainrush/mcp-textbook";
            layout = "even-horizontal";
            panes = ["claude" "nvim" ""];
          };
        }
      ];
    };
    "${dir}/nix.yml".text = builtins.toJSON {
      name = "nix";
      root = "~/nix";
      windows = [
        {nvim = "nvim";}
        {claude = "claude";}
        {shell = "";}
      ];
    };
    "${dir}/nix-secrets.yml".text = builtins.toJSON {
      name = "nix-secrets";
      root = "~/Source/github.com/fred-drake/nix-secrets/";
      windows = [
        {nvim = "nvim";}
        {claude = "claude";}
        {shell = "";}
      ];
    };
    "${dir}/brainrush-web.yml".text = builtins.toJSON {
      name = "brainrush-web";
      root = "~/Source/gitea.${config.soft-secrets.networking.domain}/brainrush/brainrush-web";
      windows = [
        {nvim = "nvim";}
        {claude = "claude";}
        {shell = "";}
      ];
    };
    "${dir}/brainrush-chat.yml".text = builtins.toJSON {
      name = "brainrush-chat";
      root = "~/Source/gitea.${config.soft-secrets.networking.domain}/brainrush/brainrush-chat";
      windows = [
        {nvim = "nvim";}
        {claude = "claude";}
        {shell = "";}
      ];
    };
    "${dir}/brainrush-user.yml".text = builtins.toJSON {
      name = "brainrush-user";
      root = "~/Source/gitea.${config.soft-secrets.networking.domain}/brainrush/brainrush-user";
      windows = [
        {nvim = "nvim";}
        {claude = "claude";}
        {shell = "";}
      ];
    };
    "${dir}/mcp-textbook.yml".text = builtins.toJSON {
      name = "mcp-textbook";
      root = "~/Source/gitea.${config.soft-secrets.networking.domain}/brainrush/mcp-textbook";
      windows = [
        {nvim = "nvim";}
        {claude = "claude";}
        {shell = "";}
      ];
    };
  };
}
