# GPU passthrough feature — contributes to both NixOS and Home Manager
# via deferredModules. Applies to hosts with my.hasGpuPassthrough = true.
_: {
  # NixOS-level: VFIO, libvirtd, QEMU, kvmfr, Looking Glass
  my.modules.nixos.gpu-passthrough = {
    config,
    lib,
    pkgs,
    ...
  }:
    lib.mkIf config.my.hasGpuPassthrough {
      # IOMMU and VFIO kernel parameters
      boot = {
        kernelParams = [
          "intel_iommu=on"
          "iommu=pt"
        ];

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

      # Libvirtd and QEMU
      virtualisation.libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = true;
          swtpm.enable = true;
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
      };

      programs.virt-manager.enable = true;

      environment.systemPackages = with pkgs; [
        virt-viewer
        spice-gtk
        OVMF
        looking-glass-client
        scream
        pciutils
      ];

      # Polkit rules for libvirt
      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (action.id == "org.libvirt.unix.manage" &&
              subject.isInGroup("libvirtd")) {
            return polkit.Result.YES;
          }
        });
      '';

      # Networking for VMs
      networking.firewall.trustedInterfaces = ["virbr0"];
      networking.firewall.allowedUDPPorts = [4010]; # Scream audio

      # Looking Glass - kvmfr device permissions
      services.udev.extraRules = ''
        SUBSYSTEM=="kvmfr", KERNEL=="kvmfr0", RUN+="${pkgs.coreutils}/bin/chown ${config.my.username}:libvirtd /dev/kvmfr0", RUN+="${pkgs.coreutils}/bin/chmod 0660 /dev/kvmfr0"
      '';
    };

  # HM-level: Scream audio receiver user service
  my.modules.home-manager.gpu-passthrough = {
    config,
    lib,
    pkgs,
    osConfig ? {},
    ...
  }: let
    hasGpuPassthrough = (osConfig.my or {}).hasGpuPassthrough or config.my.hasGpuPassthrough;
  in
    lib.mkIf hasGpuPassthrough {
      systemd.user.services.scream = {
        Unit = {
          Description = "Scream audio receiver for Windows VM";
          After = ["pipewire.service" "pipewire-pulse.service"];
        };
        Service = {
          ExecStartPre = "${pkgs.bash}/bin/bash -c 'until ${pkgs.iproute2}/bin/ip link show virbr0 2>/dev/null; do sleep 1; done'";
          ExecStart = "${pkgs.scream}/bin/scream -i virbr0 -o pulse";
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install = {
          WantedBy = ["default.target"];
        };
      };
    };
}
