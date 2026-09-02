# VEforge — a build system for Proxmox VE

VEforge takes the source code from [Proxmox](https://git.proxmox.com/) and
compiles the complete Proxmox VE stack for **arm64** machines running
**Debian 13 (trixie)** — including **Ceph** (20.x "Tentacle"), **Proxmox
Backup Server**, and **pve-manager** (the web UI), plus everything they
depend on (pve-cluster/pmxcfs, qemu-server, pve-container/LXC, pve-firewall,
pve-network/SDN, pve-ha-manager, ifupdown2, ZFS, the Rust and yew GUI
stacks, …). In total ~96 source packages are built inside a Docker buildx
pipeline and collected into a ready-to-install `./target/` folder.

Upstream Proxmox only ships amd64 packages; this project rebuilds them
(with a small set of arm64/bootstrapping patches under `packages/`) so the
full PVE experience runs on arm64 boards and servers. No Proxmox kernel is
built — the stack runs on Debian's stock arm64 kernel.

## Requirements

- **Build host:** an arm64 Linux machine with Docker + buildx, plenty of
  CPU/RAM, and >100 GB free disk. A full build takes several hours (Ceph
  alone is a big chunk); subsequent builds reuse the Docker layer cache.
- **Target machine:** a fresh arm64 **Debian 13** installation (netinst is
  fine). 4 GB RAM is enough for the base stack.

## Building

1. Clone the repository and all submodules:

   ```bash
   git clone https://github.com/darrenchang/veforge.git
   cd veforge
   git submodule update --init --recursive
   ```

2. Build all `.deb` packages:

   ```bash
   ./build_pve.sh 2>&1 | tee log.txt
   ```

   When the build finishes, `./target/` holds every installable deb plus
   `install.sh`.

   To rebuild a single package inside a running builder container, see
   `quick-run.sh`.

## Installing on a target machine

Copy the `target/` folder to the arm64 Debian 13 machine and run:

```bash
sudo ./install.sh
```

The script installs the whole Proxmox VE stack (including the `proxmox-ve`
meta package) and takes care of the pitfalls of a fresh Debian install:

- rewrites the Debian-installer `127.0.1.1` `/etc/hosts` entry to the
  machine's real IP so pve-cluster (pmxcfs) can start;
- installs `polkitd` (needed by the PVE services, missing on minimal
  installs);
- rewrites `allow-hotplug` interfaces to `auto` (ifupdown2, which replaces
  ifupdown, ignores `allow-hotplug` at boot);
- converts a DHCP-configured default interface into a PVE-style `vmbr0`
  bridge with the current address pinned statically (machines managed by
  NetworkManager or systemd-networkd are left alone);
- removes the stale `/etc/network/interfaces.new` snapshot left by the
  ifupdown2 postinst, which `pvenetcommit.service` would otherwise install
  over the network config on the next boot.

Non-co-installable or build-only packages (`zfs-dracut`,
`proxmox-backup-client-static`, the ISO installer environment, `librust-*`
dev packages, …) are excluded automatically.

Reboot when the install finishes, then open the web UI at
`https://<machine-ip>:8006` (login `root@pam` with the system root
password). If the machine's IP came from a plain DHCP lease, give it a
static lease/reservation — the address is now pinned in
`/etc/network/interfaces` and `/etc/hosts`.

## Notes and known quirks

### Containers and VMs

- LXC containers need **arm64 templates**. The stock template list is
  mostly amd64; `pveam available | grep arm64` lists usable ones (e.g.
  `debian-13-standard_*_arm64.tar.zst`). An amd64 template fails at start
  with `Exec format error`.
- KVM acceleration requires bare metal (or a host CPU/kernel with arm64
  nested virtualization, which most boards do not have). Inside a VM,
  create guests with `qm set <vmid> --kvm 0` (software emulation).

### Mounting CephFS with a kernel older than Linux 7.0

Ceph Tentacle generates the new **AES-256 (aes256k)** cephx keys by
default. The in-kernel CephFS client only learned this key type in
**Linux 7.0** — on older kernels (Debian 13 ships 6.12) a kernel mount
fails with `libceph: secret too big 32`. If you want to mount CephFS
there, use a legacy **AES-128** key for the mount client.

One-time setup on the Ceph cluster — allow the legacy cipher and create a
dedicated client key (keep `aes256k` as the preferred cipher for
everything else):

```bash
ceph mon set auth_allowed_ciphers aes,aes256k
ceph config set mon mon_auth_allow_insecure_key true
ceph auth get-or-create client.cephfs-legacy \
    mon 'allow r' mds 'allow rw fsname=cephfs' osd 'allow rw tag cephfs data=cephfs' \
    --key-type aes
ceph config set mon mon_auth_allow_insecure_key false
```

Then add the storage. `--keyring` is required — without it PVE silently
uses the admin key (which is aes256k) no matter which `--username` you
pass:

```bash
ceph auth print-key client.cephfs-legacy > /root/cephfs-legacy.secret
pvesm add cephfs ceph-fs --monhost 192.168.102.30 --content iso \
    --username cephfs-legacy --keyring /root/cephfs-legacy.secret; \
rm /root/cephfs-legacy.secret
```

Replace the IP with your own Ceph monitor address.

Alternatives: add `--fuse 1` to mount via `ceph-fuse` (userspace, supports
aes256k, somewhat slower), or run a ≥ 7.0 kernel and skip all of this.
RBD storages with `krbd 0` (the default) are unaffected. The same applies
to `krbd 1`, which uses the kernel client too.

## Repository layout

| Path | Purpose |
| --- | --- |
| `build_pve.sh` | one-shot build: buildx bake + assemble `./target/` |
| `docker-bake.hcl`, `docker/` | builder images (`builder-base`, `pve-builder`) |
| `packages/<name>/` | one directory per source package: upstream source as a git submodule plus `autobuild.sh` and arm64 patches |
| `packages/deptree.mmd` | build-order dependency notes |
| `install-target.sh` | shipped as `target/install.sh` |
| `quick-run.sh` | rebuild a single package in a running builder container |

## License

AGPL-3.0 (see `LICENSE`), matching the upstream Proxmox sources this
project builds.

## Support

If VEforge saves you time, you can support its development:

[![Buy Me A Coffee](https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png)](https://www.buymeacoffee.com/darrenchang)

## Origins and credits

This project is a fork of [jiangcuo/pxvirt](https://github.com/jiangcuo/pxvirt)
by jiangcuo and the Lierfang Support Team, which pioneered porting Proxmox VE
to non-amd64 architectures (arm64 and loong64) and provides the foundation of
the packaging and patch tree used here. This fork builds on that work with its
own Docker buildx pipeline, the `./target/` + `install.sh` install flow, and
additional arm64 fixes. Both projects ultimately build the AGPL-licensed
sources published by [Proxmox](https://git.proxmox.com/).

This fork is an independent community project: it is not affiliated with or
endorsed by Proxmox Server Solutions GmbH, and it does not provide the
commercial support offered by the upstream PXVIRT project.
