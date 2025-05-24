{config, ...}: let
  dir = ".config/tmuxinator";
in {
  home.file = {
    "${dir}/ultrawide.yml".text = builtins.toJSON {
      name = "ultrawide";
      root = "~/";
      windows = [
        {
          nix = {
            root = "~/nix";
            layout = "even-horizontal";
            panes = ["claude-code" "nvim" ""];
          };
        }
        {
          nix-secrets = {
            root = "~/Source/github.com/fred-drake/nix-secrets/";
            layout = "even-horizontal";
            panes = ["claude-code" "nvim" ""];
          };
        }
        {
          brainrush-web = {
            root = "~/Source/gitea.${config.soft-secrets.networking.domain}/brainrush/brainrush-web";
            layout = "even-horizontal";
            panes = ["claude-code" "nvim" ""];
          };
        }
        {
          brainrush-chat = {
            root = "~/Source/gitea.${config.soft-secrets.networking.domain}/brainrush/brainrush-chat";
            layout = "even-horizontal";
            panes = ["claude-code" "nvim" ""];
          };
        }
        {
          brainrush-user = {
            root = "~/Source/gitea.${config.soft-secrets.networking.domain}/brainrush/brainrush-user";
            layout = "even-horizontal";
            panes = ["claude-code" "nvim" ""];
          };
        }
      ];
    };
    "${dir}/nix.yml".text = builtins.toJSON {
      name = "nix";
      root = "~/nix";
      windows = [
        {nvim = "nvim";}
        {claude = "claude-code";}
        {shell = "";}
      ];
    };
    "${dir}/nix-secrets.yml".text = builtins.toJSON {
      name = "nix-secrets";
      root = "~/Source/github.com/fred-drake/nix-secrets/";
      windows = [
        {nvim = "nvim";}
        {claude = "claude-code";}
        {shell = "";}
      ];
    };
    "${dir}/brainrush-web.yml".text = builtins.toJSON {
      name = "brainrush-web";
      root = "~/Source/gitea.${config.soft-secrets.networking.domain}/brainrush/brainrush-web";
      windows = [
        {nvim = "nvim";}
        {claude = "claude-code";}
        {shell = "";}
      ];
    };
    "${dir}/brainrush-chat.yml".text = builtins.toJSON {
      name = "brainrush-chat";
      root = "~/Source/gitea.${config.soft-secrets.networking.domain}/brainrush/brainrush-chat";
      windows = [
        {nvim = "nvim";}
        {claude = "claude-code";}
        {shell = "";}
      ];
    };
    "${dir}/brainrush-user.yml".text = builtins.toJSON {
      name = "brainrush-user";
      root = "~/Source/gitea.${config.soft-secrets.networking.domain}/brainrush/brainrush-user";
      windows = [
        {nvim = "nvim";}
        {claude = "claude-code";}
        {shell = "";}
      ];
    };
  };
}
