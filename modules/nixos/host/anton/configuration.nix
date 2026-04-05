{pkgs, ...}: {
  networking.hostName = "anton";

  # WSL2 GPU: symlinks NVIDIA/CUDA libs from /usr/lib/wsl/lib/ into nix store
  wsl.useWindowsDriver = true;

  # Enable OpenGL/Vulkan userspace (required for wsl.useWindowsDriver extraPackages)
  hardware.graphics.enable = true;

  environment = {
    # WSL NVIDIA libs: LD_LIBRARY_PATH for libnvidia-ml.so, PATH for nvidia-smi.
    variables.LD_LIBRARY_PATH = "/usr/lib/wsl/lib";
    extraInit = ''
      export PATH="/usr/lib/wsl/lib:$PATH"
    '';

    # CUDA development packages
    systemPackages = with pkgs; [
      cudaPackages.cudatoolkit
      cudaPackages.cudnn
    ];
  };

  # Fish doesn't source extraInit, so also add via fish shellInit.
  programs = {
    fish.shellInit = ''
      fish_add_path /usr/lib/wsl/lib
    '';

    # nix-ld for dynamically linked CUDA binaries (e.g. pip-installed PyTorch)
    nix-ld.enable = true;
  };

  # Cachix for pre-built CUDA packages (avoid multi-hour builds)
  nix.settings = {
    extra-substituters = [
      "https://cuda-maintainers.cachix.org"
      "https://nix-community.cachix.org"
      "https://nixpkgs-unfree.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
    ];
  };
}
