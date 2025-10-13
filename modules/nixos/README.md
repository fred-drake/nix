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
- At this point you will have the base installation complete, with IP addresses, default user and its public keys for authentication.
- Copy over your `id_infrastructure` key to `/home/default`. This key is used to decrypt secrets in the secrets repository.
- Change the `targetHost` and `targetUser` back to their permanent settings, and re-run the init colmena target. This will push the necessary secrets to the server.
- Finally, run the regular colmena target, which will install the necessary applications. You will use this target for all subsequent updates. Note that if your server uses podman containers, you might get an error with the service. This should be a one time timing error, just re-run the target.

# Setting up Raspberry Pi with NixOS

## Get the SD Image From Hydra

1. Go to https://hydra.nixos.org/jobset/nixos/release-25.05
2. Look for a build containing sd_image or sd-image
3. Grab the latest release that passed checks

## Decompress the image

```bash
unzstd -d image-name-aarch64-linux.img.zst
```

## Write the uncompressed image to SD card at /dev/sdX

```bash
sudo dd if=image-name-aarch64-linux.img of=/dev/sdX bs=4096 conv=fsync status=progress
```

## If you need to enable WiFi

```bash
wpa_passphrase 'SSID' 'passphrase' > /tmp/wpa.conf
sudo wpa_supplicant -B -i wlan0 -c /tmp/wpa.conf
```

## Set up a temporary password for nixos user
```bash
passwd
```

You can now SSH into the machine.  Follow the steps above for changing `colmena.deployment.targetHost` and in this case `colmena.deployment.targetUser` to `nixos`.

# Epson Scanner

## Device setup on Proxmox host

For the proxmox node connected to the Epson scanner, you will need to create a file `/etc/udev/rules.d/99-epson-scanner.rules` on the proxmox host with this content
```bash
SUBSYSTEM=="usb", ATTRS{idVendor}=="04b8", ATTRS{idProduct}=="0156", SYMLINK+="epson-scanner", MODE="0660", GROUP="scanner"
```

Then enable the changes on the proxmox host:
```bash
udevadm control --reload-rules
udevadm trigger
```

You will now have a symlink `/dev/epson-scanner` that you can use to passthrough.

## Passing through to LXC container

After your container has been created, add the following (in this example, we assume you are using container ID 120):
```bash
pct set 120 -dev0 /dev/epson-scanner,mode=0660
```

Then restart your container.
