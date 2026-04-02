{pkgs, ...}: {
  networking.hostName = "anton";

  # WSL2 GPU: symlinks NVIDIA/CUDA libs from /usr/lib/wsl/lib/ into nix store
  wsl.useWindowsDriver = true;

  # Enable OpenGL/Vulkan userspace (required for wsl.useWindowsDriver extraPackages)
  hardware.graphics.enable = true;

  # WSL NVIDIA libs need to be in PATH (nvidia-smi) and LD_LIBRARY_PATH (libnvidia-ml.so)
  environment.extraInit = ''
    export PATH="/usr/lib/wsl/lib:$PATH"
    export LD_LIBRARY_PATH="/usr/lib/wsl/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  '';

  # CUDA development packages
  environment.systemPackages = with pkgs; [
    cudaPackages.cudatoolkit
    cudaPackages.cudnn
  ];

  # nix-ld for dynamically linked CUDA binaries (e.g. pip-installed PyTorch)
  programs.nix-ld.enable = true;

  # Cachix for pre-built CUDA packages (avoid multi-hour builds)
  nix.settings = {
    extra-substituters = [
      "https://cuda-maintainers.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
  };
}
