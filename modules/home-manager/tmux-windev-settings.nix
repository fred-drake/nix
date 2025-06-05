{config, ...}: let
  home = config.home.homeDirectory;
  domain = config.soft-secrets.networking.domain;
in {
  home.file = {
    ".config/windev/config.json".text = builtins.toJSON [
      {
        name = "nix";
        dir = "${home}/nix";
        desc = "Nix configuration";
      }
      {
        name = "nix-secrets";
        dir = "${home}/Source/github.com/fred-drake/nix-secrets";
        desc = "Nix secrets";
      }
      {
        name = "br-infra";
        dir = "${home}/Source/gitea.${domain}/BrainRush/infrastructure";
        desc = "Brainrush infrastructure";
      }
      {
        name = "br-secrets";
        dir = "${home}/Source/gitea.${domain}/BrainRush/nix-secrets";
        desc = "Brainrush infrastructure secrets";
      }
      {
        name = "br-web";
        dir = "${home}/Source/gitea.${domain}/BrainRush/brainrush-web";
        desc = "Brainrush web app";
      }
      {
        name = "br-chat";
        dir = "${home}/Source/gitea.${domain}/BrainRush/brainrush-chat";
        desc = "Brainrush chat app";
      }
      {
        name = "br-user";
        dir = "${home}/Source/gitea.${domain}/BrainRush/brainrush-user";
        desc = "Brainrush user app";
      }
      {
        name = "br-textbook";
        dir = "${home}/Source/gitea.${domain}/BrainRush/mcp-textbook";
        desc = "Brainrush textbook MCP app";
      }
      {
        name = "br-cockpit";
        dir = "${home}/Source/gitea.${domain}/BrainRush/cockpit";
        desc = "Tool for powering the product locally";
      }
    ];
  };
}
