# Creating a Proxmox LXC From Scratch

- Pull a recent [LXD Container Image](https://hydra.nixos.org/job/nixos/release-24.11/nixos.lxdContainerImage.x86_64-linux) and store it on Proxmox as a CT template if you haven't already
- To create a container image, SSH directly into a node and create it. Adjust options as necessary. Note, the example below is to create an unprivileged container. If you need an NFS client mount, set `unprivleged` to 0 or omit.

```bash
# Example below creates with ID 100 (set in both the create call and the --rootfs options), 4GB RAM and 100GB disk
pct create 100 \
    --arch amd64 local:vztmpl/nixos-system-x86_64-linux.tar.xz \
    --ostype unmanaged \
    --description nixos \
    --hostname nixos \
    --net0 name=eth0,bridge=vmbr3,ip=dhcp,firewall=1 \
    --storage cephpool1 \
    --memory 4096 \
    --rootfs cephpool1:100 \
    --unprivileged 1 \
    --features nesting=1 \
    --cmode console \
    --onboot 1 \
    --start 1
```

- Connect into the new container via console as root and pull in authorized SSH keys

```bash
mkdir -p ~/.ssh && curl "https://github.com/fred-drake.keys" > ~/.ssh/authorized_keys
```

- In the init version of the colmena configuration, set `colmena.deployment.targetHost` to the IP address that it loads up with, and `colmena.deployment.targetUser` to `root`.
- Run the init version of the colmena target with `just colmena <TARGET_NAME>-init`. This is because secrets must be pushed before any applications are deployed.
- If your IP address is changing, it will hang while restarting services at the very end. Just hit `CTRL-C`.
- Upon success, change the `targetHost` and `targetUser` back to their permanent settings, and run the regular colmena target to ensure everything works idempotently.
- Push your `id_infrastructure` key to `/home/default`, so secrets will work.
