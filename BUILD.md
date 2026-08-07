1. Clone the repository and all the submodules
    ```bash
    git clone https://github.com/darrenchang/pxvirt.git; \
    git submodule update --init --recursive
    ``

2. Build all .deb packages
    ```bash
    ./build.sh 2>&1 | tee log.txt
    ```

3. Install on a target arm64 Debian machine

    Copy the `/deb/proxmox/` directory out of the finished image to the
    target machine, then install with the helper script (it skips the
    packages that cannot be co-installed, e.g. `zfs-dracut` vs
    `zfs-initramfs` and `proxmox-backup-client-static` vs
    `proxmox-backup-client`):
    ```bash
    ./install-target.sh /path/to/proxmox
    ```

