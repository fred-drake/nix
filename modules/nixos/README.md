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

# Epson Scanner (ES-400)

## Device Setup on Proxmox Host

### 1. Create Udev Rule

Create a udev rule at `/etc/udev/rules.d/99-epson-scanner-lxc.rules` on the Proxmox host:

```bash
# Epson ES-400 Scanner for LXC container 120
# Container GID 59 (scanner) maps to host GID 100059
# Create stable symlink and set permissions for LXC passthrough
SUBSYSTEM=="usb", ATTRS{idVendor}=="04b8", ATTRS{idProduct}=="0156", SYMLINK+="epson-scanner", GROUP="100059", MODE="0660"
```

**Note:** The GROUP is set to `100059` because unprivileged LXC containers use UID/GID mapping. The container's GID 59 (scanner group) maps to host GID 100059.

### 2. Apply Udev Changes

```bash
udevadm control --reload-rules
udevadm trigger --subsystem-match=usb --attr-match=idVendor=04b8
```

Verify the symlink and permissions:
```bash
ls -la /dev/epson-scanner
# Should show: lrwxrwxrwx 1 root root 15 ... /dev/epson-scanner -> bus/usb/003/XXX

ls -la /dev/bus/usb/003/XXX  # Use actual device number
# Should show: crw-rw---- 1 root 100059 ...
```

## Passing Through to LXC Container

### 1. Configure LXC Container

Edit `/etc/pve/lxc/120.conf` (replace 120 with your container ID):

```bash
# Pass through the epson-scanner device with proper UID/GID mapping
dev0: /dev/epson-scanner,uid=0,gid=59,mode=0660

# Allow access to USB character devices
lxc.cgroup2.devices.allow: c 189:* rwm

# Mount the entire USB bus 003 directory (adjust bus number if needed)
lxc.mount.entry: /dev/bus/usb/003 dev/bus/usb/003 none bind,optional,create=dir 0 0
```

**Important Notes:**
- The `gid=59` maps to the scanner group inside the container
- The `lxc.mount.entry` mounts the entire USB bus directory, which is needed for SANE to auto-detect the scanner
- If the scanner is on a different USB bus (e.g., 004), update the mount entry accordingly

### 2. Restart Container

```bash
pct stop 120
pct start 120
```

### 3. Verify Inside Container

SSH into the container and verify:

```bash
# Check device permissions
ls -la /dev/epson-scanner
# Should show: crw-rw---- 1 root scanner ...

# Check USB devices
ls -la /dev/bus/usb/003/
# Should show scanner device with proper permissions

# List available scanners
scanimage -L
# Should show: device `epsonscan2:ES-400:...` and `epsonds:libusb:003:XXX`
```

## Using the Scanner

The scanner configuration includes two commands:

**Simple Scan (600 DPI, PDF):**
```bash
scan
```
- Single page from ADF or flatbed
- Output: `/home/default/scans/scan-TIMESTAMP.pdf`

**Duplex Scan (600 DPI, PDF, both sides):**
```bash
scan-duplex
```
- Multiple pages from ADF, both sides
- Merges into single PDF
- Output: `/home/default/scans/scan-duplex-TIMESTAMP.pdf`

## Troubleshooting

**Scanner not detected:**
- Check USB device number hasn't changed: `readlink /dev/epson-scanner` on host
- Verify permissions on host: `ls -la /dev/bus/usb/003/XXX`
- Restart container: `pct stop 120 && pct start 120`

**Device I/O errors:**
- Scanner may have moved to different USB bus
- Check if USB bus mount in LXC config matches actual bus
- Power cycle the scanner

**Permissions issues:**
- Verify udev rule is applying: `udevadm test /sys/devices/.../usb3/3-X`
- Check user is in scanner group: `groups` (should include scanner)
- Trigger udev: `udevadm trigger --subsystem-match=usb --attr-match=idVendor=04b8`
