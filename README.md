# Nix Flake Configuration for macOS Development Environments

## Overview

This repository contains Nix flake configurations for setting up my personal MacOS environments. It contains the default configurations, as well as flakes for development environments specific to their use cases.

Setup boils down to three things:

- Your super secret key, which unlocks all of your stored secrets
- Applying the [secrets repo](https://github.com/fred-drake/secrets) using [chezmoi](https://github.com/twpayne/chezmoi)
- Applying the remainder using [nix](https://github.com/NixOS/nix)

There are a [few](https://github.com/Mic92/sops-nix) [methods](https://github.com/ryantm/agenix) for storing secrets inside of your nix ecosystem but in the end they feel like going against the grain of what nix natively tries to be. Nix focuses heavily on separation and declaritive systems, but not on security. Thus, every solution feels like a hack. So the goal of this here is to sequester all secretive information into one non-nix repository, and use nix for everything else.

Currently home-manager and darwin modules are used to generate their respective configurations.

## Limitations

Many applications for MacOS are not available in the Nixpkgs, so these must be installed using Homebrew integration through [nix-darwin](https://github.com/LnL7/nix-darwin). As the Nix repository matures beyond the Linux world, this should lessen.

## Flake Development Environment

With `direnv`, going into the flake directory will execute the flake in the `./development` directory.

## MacOS Setup

### Nix setup

When first receiving a new MacOS device (or if wiping the current one to the default install), perform the following:

1. If you enabled FileVault during the install, perform a reboot.
2. Open a Terminal session and install nix: `sh <(curl -L https://nixos.org/nix/install)`
3. Install Homebrew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
4. Close the window and re-open the terminal session for the nix and brew installations to be recognized.
5. Create an `~/.age` directory and copy your super secret key into it.
6. Open a nix shell with chezmoi and git: `nix-shell -p chezmoi git`
7. Pull the secrets repo with chezmoi: `chezmoi init https://github.com/fred-drake/secrets.git`
8. Set the SOPS key file: `export SOPS_AGE_KEY_FILE=~/.age/personal-key.txt`
9. Apply the files: `chezmoi apply`
10. Pull this nix repo into `~/nix`: `git clone https://github.com/fred-drake/nix`
11. Change into this nix directory: `cd ~/nix`
12. Build the flake based on your system. This will take a while the first time.
    - Macbook Pro: `nix --extra-experimental-features "nix-command flakes" build .#darwinConfigurations.Freds-MacBook-Pro.system`
    - Mac Studio: `nix --extra-experimental-features "nix-command flakes" build .#darwinConfiguratiions.Freds-Mac-Studio.system`
    - My better half's Mac Mini: `nix --extra-experimental-features "nix-command flakes" build .#darwinConfiguratiions.Laisas-Mac-mini.system`
13. Run the initial switch into the flake. This will take a long while the first time: `./result/sw/bin/darwin-rebuild switch --flake ~/nix`
14. Reboot the machine to ensure all Mac settings were applied.

### Post-setup That Can't Be Automated Yet

1. Allow Apple Watch to be unlock the computer or sudo: `Settings -> Touch ID & Password -> Use Apple Watch to unlock applications and your Mac`
2. Open Raycast and import configuration from iCloud Drive
3. Disable spotlight search: `Settings -> Keyboard shortcuts -> Disable Spotlight Search`. Raycast will now be the default search tool when hitting Cmd+Space.
