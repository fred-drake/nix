# Nix Flake Configuration for macOS Development Environments

## Overview

This repository contains Nix flake configurations for setting up my personal MacOS environments.  It contains the default configurations, as well as flakes for development environments specific to their use cases.

This is a long work in progress.  Currently this is combined with my [personal dotfiles repo](https://github.com/fred-drake/dotfiles) which uses chezmoi.  My objective is to move everything over to this and sunset that repository.

Currently home-manager and darwin modules are used to generate their respective configurations.

## Limitations

- Many applications for MacOS are not available in the Nixpkgs, so these must be installed using Homebrew.  As the Nix repository matures, this should lessen.
- VSCode's .NET extensions won't allow the debugger to be run in [Cursor](https://www.cursor.com), so as an ugly workaround I am using Cursor for my primary IDE for the rich AI assistance support, and loading vanilla VSCode whenever step-through debugging is necessary.  I also have a wrapper calling cursor in `~/bin` which allows me to use VSCode's extensions directly.  It is definitely a hack, but would no longer be needed when a Nix package for Cursor becomes available.

## MacOS Setup

### Nix setup
When first receiving a new MacOS device (or if wiping the current one to the default install), perform the following:

1. If you enabled FileVault during the install, perform a reboot.
2. Open a Terminal session and install nix: `sh <(curl -L https://nixos.org/nix/install)`
3. Install Homebrew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
4. Close the window and re-open the terminal session for the nix and brew installations to be recognized.
5. Create an `~/.age` directory and copy your super secret key into it.
6. Create a file called called `~/machine_id` with a string based on the device.  This is for chezmoi to recognize which machine it is for various templates.  This step will probably no longer be needed when chezmoi is deprecated.
    - Macbook Air: `echo "macbook" > ~/machine_id`
    - Macbook Pro: `echo "macbookpro" > ~/machine_id`
    - Mac Studio: `echo "studio" > ~/machine_id`
7. Open a nix shell with chezmoi and git: `nix-shell -p chezmoi git`
8. Pull the dotfiles repo with chezmoi: `chezmoi init https://github.com/fred-drake/dotfiles.git`
9. Apply one time initialization: `chezmoi -c ~/.local/share/chezmoi/home/dot_config/chezmoi/chezmoi-initial.yaml apply`
10. Apply the remaining changes: `chezmoi apply`
11. Pull this nix repo into `~/nix`: `git clone https://github.com/fred-drake/nix`
12. Change into this nix directory: `cd ~/nix`
13. Build the flake based on your system.  This will take a while the first time.
    - Macbook Pro: `nix --extra-experimental-features "nix-command flakes" build .#darwinConfigurations.Freds-MacBook-Pro.system`
    - Mac Studio: TBD
14. Run the initial switch into the flake.  This will take a long while the first time: `./result/sw/bin/darwin-rebuild switch --flake ~/nix`
15. Reboot the machine to ensure all Mac settings were applied.

### Post-setup That Can't Be Automated Yet

1. Allow Apple Watch to be unlock the computer or sudo: `Settings -> Touch ID & Password -> Use Apple Watch to unlock applications and your Mac`
2. Open Raycast and import configuration from iCloud Drive
3. Disable spotlight search: `Settings -> Keyboard shortcuts -> Disable Spotlight Search`.  Raycast will now be the default search tool when hitting Cmd+Space.
