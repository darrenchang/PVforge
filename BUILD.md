1. Clone the repository and all the submodules
    ```bash
    git clone https://github.com/darrenchang/pxvirt.git; \
    git submodule update --init --recursive
    ``

2. Build all .deb packages
    ```bash
    ./build_pve.sh 2>&1 | tee log.txt
    ```
    When the build finishes, `./target/` holds every installable deb plus
    `install.sh`.

3. Install on a target arm64 Debian machine

    Copy the `target/` folder to the machine and run:
    ```bash
    sudo ./install.sh
    ```
    It installs the whole Proxmox VE stack (including the `proxmox-ve`
    meta package), fixes the Debian-installer `127.0.1.1` hostname entry
    in `/etc/hosts` so pve-cluster can start, installs `polkitd`, and
    writes a PVE-style `vmbr0` bridge config unless NetworkManager or
    systemd-networkd manages the machine. Uninstallable or conflicting
    packages (`zfs-dracut`, `proxmox-backup-client-static`, the ISO
    installer, rust dev packages, …) are excluded automatically.

