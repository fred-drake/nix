{
  pkgs,
  config,
  ...
}: {
  # ============================================
  # BOOT CONFIGURATION FOR GPU PASSTHROUGH
  # ============================================
  boot = {
    # IOMMU kernel parameters
    kernelParams = [
      "intel_iommu=on"
      "iommu=pt" # Passthrough mode for better performance
    ];

    # VFIO modules
    kernelModules = [
      "vfio"
      "vfio_iommu_type1"
      "vfio_pci"
      "kvmfr"
    ];

    extraModulePackages = with config.boot.kernelPackages; [
      kvmfr
    ];

    initrd.kernelModules = [
      "vfio"
      "vfio_iommu_type1"
      "vfio_pci"
    ];

    # Bind RTX 3090 to vfio-pci at boot (before nvidia driver loads)
    # RTX 3090: 10de:2204 (GPU), 10de:1aef (Audio)
    # kvmfr: 128MB for Looking Glass
    extraModprobeConfig = ''
      softdep nvidia pre: vfio-pci
      options vfio-pci ids=10de:2204,10de:1aef
      options kvmfr static_size_mb=128
    '';
  };

  # ============================================
  # LIBVIRTD AND QEMU CONFIGURATION
  # ============================================
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true; # Required for GPU passthrough

      # Enable TPM support for Windows 11 (OVMF is included by default)
      swtpm.enable = true;

      # Verbatim QEMU config for GPU passthrough
      verbatimConfig = ''
        cgroup_device_acl = [
          "/dev/null", "/dev/full", "/dev/zero",
          "/dev/random", "/dev/urandom",
          "/dev/ptmx", "/dev/kvm",
          "/dev/rtc", "/dev/hpet",
          "/dev/vfio/vfio",
          "/dev/vfio/1",
          "/dev/vfio/2",
          "/dev/vfio/3",
          "/dev/vfio/4",
          "/dev/kvmfr0"
        ]
        relaxed_acs_check = 1
      '';
    };

    # No hook needed - RTX 3090 is bound to vfio-pci at boot
  };

  # ============================================
  # VIRT-MANAGER AND TOOLS
  # ============================================
  programs.virt-manager.enable = true;

  environment.systemPackages = with pkgs; [
    virt-viewer
    spice-gtk
    OVMF
    looking-glass-client
    scream
    pciutils
  ];

  # ============================================
  # POLKIT RULES FOR LIBVIRT
  # ============================================
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.libvirt.unix.manage" &&
          subject.isInGroup("libvirtd")) {
        return polkit.Result.YES;
      }
    });
  '';

  # ============================================
  # NETWORKING FOR VMs
  # ============================================
  networking.firewall.trustedInterfaces = ["virbr0"];

  # Allow Scream audio (UDP multicast)
  networking.firewall.allowedUDPPorts = [4010];

  # ============================================
  # LOOKING GLASS - kvmfr device permissions
  # ============================================
  services.udev.extraRules = ''
    SUBSYSTEM=="kvmfr", OWNER="fdrake", GROUP="libvirtd", MODE="0660"
  '';
}
