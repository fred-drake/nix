# Nix Flake Configuration for macOS Development Environments

## Overview

This repository contains Nix flake configurations for setting up my personal MacOS environments.  It contains the default configurations, as well as flakes for development environments specific to their use cases.

Setup boils down to three things:
- Your super secret key, which unlocks all of your stored secrets
- Applying the [secrets repo](https://github.com/fred-drake/secrets) using [chezmoi](https://github.com/twpayne/chezmoi)
- Applying the remainder using [nix](https://github.com/NixOS/nix)

There are a [few](https://github.com/Mic92/sops-nix) [methods](https://github.com/ryantm/agenix) for storing secrets inside of your nix ecosystem but in the end they feel like going against the grain of what nix natively tries to be.  Nix focuses heavily on separation and declaritive systems, but not on security. Thus, every solution feels like a hack.  So the goal of this here is to sequester all secretive information into one non-nix repository, and use nix for everything else.

Currently home-manager and darwin modules are used to generate their respective configurations.

## Limitations

Many applications for MacOS are not available in the Nixpkgs, so these must be installed using Homebrew integration through [nix-darwin](https://github.com/LnL7/nix-darwin).  As the Nix repository matures beyond the Linux world, this should lessen.

## Flake Development Environment
With `direnv`, going into the flake directory will execute the flake in the `./development` directory.  This will install VSCode with the global extensions.

## VSCode Extensions
There is a procedure in this flake to add and update VSCode extensions.  It is heavier-weight than merely clicking "Install" but it yields declarability with the control of updating to the latest version without waiting for third-party updates.

1. Add the publisher and extension name in `vscode/vscode-extensions.toml`
2. Go into the `development/nix4vscode` directory (a git submodule)
3. Run `nix develop -c $SHELL` which will run `nix4vscode`'s environment flake, including a rust environment
4. Run `cargo run -- ../vscode-extensions.toml` which will update all extensions to their latest versions
5. Commit the updated `vscode-extensions.toml` file

If you are simply wanting to refresh extensions to the latest without adding new ones, skip step 1.

## MacOS Setup

### Nix setup
When first receiving a new MacOS device (or if wiping the current one to the default install), perform the following:

1. If you enabled FileVault during the install, perform a reboot.
2. Open a Terminal session and install nix: `sh <(curl -L https://nixos.org/nix/install)`
3. Install Homebrew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
4. Close the window and re-open the terminal session for the nix and brew installations to be recognized.
5. Create an `~/.age` directory and copy your super secret key into it.
7. Open a nix shell with chezmoi and git: `nix-shell -p chezmoi git`
8. Pull the secrets repo with chezmoi: `chezmoi init https://github.com/fred-drake/secrets.git`
9. Apply the files: `chezmoi apply`
10. Pull this nix repo into `~/nix`: `git clone https://github.com/fred-drake/nix`
11. Change into this nix directory: `cd ~/nix`
12. Build the flake based on your system.  This will take a while the first time.
    - Macbook Pro: `nix --extra-experimental-features "nix-command flakes" build .#darwinConfigurations.Freds-MacBook-Pro.system`
    - Mac Studio: `nix --extra-experimental-features "nix-command flakes" build .#darwinConfiguratiions.Freds-Mac-Studio.system`
13. Run the initial switch into the flake.  This will take a long while the first time: `./result/sw/bin/darwin-rebuild switch --flake ~/nix`
14. Reboot the machine to ensure all Mac settings were applied.

### Post-setup That Can't Be Automated Yet

1. Allow Apple Watch to be unlock the computer or sudo: `Settings -> Touch ID & Password -> Use Apple Watch to unlock applications and your Mac`
2. Open Raycast and import configuration from iCloud Drive
3. Disable spotlight search: `Settings -> Keyboard shortcuts -> Disable Spotlight Search`.  Raycast will now be the default search tool when hitting Cmd+Space.
