#!/bin/bash
# Install the built Proxmox debs on a (clean) arm64 Debian machine and set up
# everything a Proxmox VE node needs (proxmox-ve meta package, /etc/hosts,
# polkitd, network config).
#
# build_pve.sh ships this script as ./target/install.sh next to the debs;
# there it runs without arguments. It can also be pointed at a deb tree:
#   ./install-target.sh <dir with the debs copied from the image's /deb/proxmox/>
#
# The full deb tree is not co-installable as-is, so a few packages are
# skipped, mirroring packages/install.sh used inside the builder image:
#   *-dbgsym                      debug symbols, not needed at runtime
#   zfs-dracut                    depends on dracut, which conflicts with
#                                 initramfs-tools needed by zfs-initramfs;
#                                 install it manually instead of zfs-initramfs
#                                 if the machine uses dracut
#   zfs-test                      test suite, not needed at runtime
#   proxmox-backup-client-static  conflicts with proxmox-backup-client
#   *-build-deps                  mk-build-deps helper packages that only
#                                 pull in build tooling
#   librust-*                     build-time rust source packages; the tree
#                                 also carries two incompatible librust-pwt
#                                 versions (0.8 for yew-comp, 0.9 from
#                                 debcargo-conf), so they cannot all be
#                                 installed together anyway
#   proxmox-wasm-builder          build tool, the only package depending on
#                                 the librust packages above
#   pve-installer/*               the ISO installer environment; it must not
#                                 be installed on a running system — its
#                                 rdnssd dependency Conflicts with
#                                 network-manager, killing desktop networking
#   pve-headers                   transitional package depending on
#                                 proxmox-default-headers, which this arm64
#                                 port does not build
#
# After installing, the script makes sure the machine keeps a working network
# configuration:
#   - If NetworkManager is installed (desktop), it is left in charge and
#     nothing is changed.
#   - Otherwise, if /etc/network/interfaces does not already cover the
#     default-route interface, a PVE-style vmbr0 bridge with the interface's
#     current address and gateway is appended (same layout the Proxmox ISO
#     installer creates). The config is written but not applied, so the
#     current session keeps its connectivity; it takes effect on reboot or
#     with 'systemctl restart networking'.
set -e

DEB_DIR=$(realpath "${1:-$(dirname "$0")}")

if ! find "$DEB_DIR" -name '*.deb' | grep -q .; then
  echo "No .deb files found under $DEB_DIR" >&2
  exit 1
fi

# pmxcfs (pve-cluster) refuses to start when the hostname resolves only to a
# loopback address, which is exactly what Debian's installer writes
# (127.0.1.1). Map the hostname to the machine's real IP before installing so
# the PVE services can start.
configure_hosts() {
  local hn cur ip
  hn=$(hostname)
  cur=$(getent hosts "$hn" 2>/dev/null | awk '{print $1; exit}')
  case "$cur" in
    127.*|::1|"") ;;
    *)
      echo "Hostname $hn resolves to $cur - /etc/hosts is fine."
      return
      ;;
  esac

  ip=$(ip -4 route get 1.1.1.1 2>/dev/null \
    | awk '{for(i=1;i<=NF;i++) if($i=="src") {print $(i+1); exit}}')
  [ -z "$ip" ] && ip=$(hostname -I 2>/dev/null | awk '{print $1}')
  case "$ip" in
    ''|127.*)
      echo "WARNING: hostname $hn resolves to '$cur' and no usable IP was found." >&2
      echo "WARNING: pve-cluster (pmxcfs) will not start until /etc/hosts maps $hn to a real IP." >&2
      return
      ;;
  esac

  cp -a /etc/hosts /etc/hosts.pxvirt-bak
  # rewrite in place (no rename) so this also works where /etc/hosts is a
  # bind mount, e.g. in containers
  local content
  if grep -qE '^127\.0\.1\.1[[:space:]]' /etc/hosts; then
    content=$(sed "s/^127\.0\.1\.1[[:space:]].*/$ip\t$hn/" /etc/hosts)
  else
    content=$(cat /etc/hosts; printf '%s\t%s' "$ip" "$hn")
  fi
  printf '%s\n' "$content" > /etc/hosts
  echo "Mapped hostname $hn to $ip in /etc/hosts (backup: /etc/hosts.pxvirt-bak)"
  echo "so pve-cluster (pmxcfs) can start. If this address is a plain DHCP"
  echo "lease, give the machine a static IP or DHCP reservation."
}

configure_network() {
  if dpkg -s network-manager >/dev/null 2>&1; then
    echo "NetworkManager is installed - leaving network configuration to it."
    return
  fi
  if [ -n "$(find /etc/systemd/network -name '*.network' 2>/dev/null)" ] \
     && systemctl is-active --quiet systemd-networkd 2>/dev/null; then
    echo "systemd-networkd manages this machine - leaving network configuration to it."
    return
  fi

  local iface addr gw
  iface=$(ip -4 route show default 2>/dev/null \
    | awk '{for(i=1;i<=NF;i++) if($i=="dev") {print $(i+1); exit}}')
  if [ -z "$iface" ]; then
    echo "WARNING: no default-route interface found; not touching /etc/network/interfaces." >&2
    return
  fi
  if grep -qE "^[[:space:]]*iface[[:space:]]+(vmbr0|$iface)[[:space:]]" /etc/network/interfaces 2>/dev/null; then
    echo "/etc/network/interfaces already configures $iface or vmbr0 - leaving it untouched."
    return
  fi

  addr=$(ip -4 -o addr show dev "$iface" scope global 2>/dev/null | awk '{print $4; exit}')
  gw=$(ip -4 route show default 2>/dev/null \
    | awk '{for(i=1;i<=NF;i++) if($i=="via") {print $(i+1); exit}}')
  if [ -z "$addr" ]; then
    echo "WARNING: $iface has no IPv4 address; not touching /etc/network/interfaces." >&2
    return
  fi

  cp -a /etc/network/interfaces "/etc/network/interfaces.pxvirt-bak" 2>/dev/null || true
  {
    echo ""
    echo "# Added by install-target.sh: keep the current connection ($iface) working"
    echo "# under ifupdown2 via a PVE-style bridge."
    echo "auto $iface"
    echo "iface $iface inet manual"
    echo ""
    echo "auto vmbr0"
    echo "iface vmbr0 inet static"
    echo "	address $addr"
    [ -n "$gw" ] && echo "	gateway $gw"
    echo "	bridge-ports $iface"
    echo "	bridge-stp off"
    echo "	bridge-fd 0"
  } >> /etc/network/interfaces
  echo "Wrote vmbr0 bridge config for $iface ($addr) to /etc/network/interfaces"
  echo "(backup: /etc/network/interfaces.pxvirt-bak)."
  echo "It takes effect on reboot, or now with: systemctl restart networking"
}

mapfile -t DEBS < <(find "$DEB_DIR" -name '*.deb' \
  | grep -v -- '-dbgsym_\|zfs-dracut_\|zfs-test_\|proxmox-backup-client-static_\|-build-deps_\|/librust-\|proxmox-wasm-builder_\|/pve-installer/\|/pve-headers_')

configure_hosts

apt update
# polkitd (from the Debian repos) ships /usr/bin/pkttyagent, which systemctl
# and the PVE services expect to exist; desktop installs have it via
# NetworkManager, but fresh minimal/server systems do not, and pve-manager
# does not declare the dependency.
apt install -y --allow-downgrades -o Dpkg::Options::="--force-confnew" "${DEBS[@]}" polkitd

configure_network
