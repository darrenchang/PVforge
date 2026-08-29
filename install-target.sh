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
# configuration (the install replaces ifupdown with ifupdown2):
#   - The /etc/network/interfaces.new snapshot the ifupdown2 postinst leaves
#     behind is removed: pvenetcommit.service would otherwise install that
#     copy of the pre-install config over /etc/network/interfaces on the next
#     boot and undo everything below.
#   - If NetworkManager (desktop) or systemd-networkd manages the machine, it
#     is left in charge and nothing is changed.
#   - allow-hotplug stanzas are rewritten to auto: ifupdown2 ignores
#     allow-hotplug at boot, and Debian's installer uses it for the primary
#     NIC - without the rewrite the machine drops off the network on the
#     first reboot.
#   - If the default-route interface uses DHCP (Debian's default), it is
#     converted to a PVE-style vmbr0 bridge holding the current address and
#     gateway statically (same layout the Proxmox ISO installer creates), so
#     the address stays in sync with the /etc/hosts entry pmxcfs needs. A
#     static interface config is left alone; a machine with no config for the
#     interface gets the vmbr0 stanza appended. The config is written but not
#     applied, so the current session keeps its connectivity; it takes effect
#     on reboot or with 'systemctl restart networking'.
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
#
# The check must look at /etc/hosts itself, NOT getent/DNS: many routers
# resolve DHCP hostnames, so at install time the name may resolve via DNS
# while /etc/hosts still says 127.0.1.1. On the next boot pmxcfs starts
# before the network (or with DNS unreachable), sees only the loopback entry,
# and fails - taking pvestatd, pve-firewall, pve-ha-* and
# pve-guests/pve-manager down with it.
configure_hosts() {
  local hn cur ip
  hn=$(hostname)
  cur=$(awk -v hn="$hn" \
    '$1 !~ /^#/ { for (i = 2; i <= NF; i++) if ($i == hn) { print $1; exit } }' \
    /etc/hosts 2>/dev/null)
  case "$cur" in
    127.*|::1|"") ;;
    *)
      echo "/etc/hosts maps $hn to $cur - fine."
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
  # bind mount, e.g. in containers. Only the address is swapped so the FQDN
  # alias Debian's installer writes ("127.0.1.1 host.domain host") survives.
  local content
  if grep -qE '^127\.0\.1\.1[[:space:]]' /etc/hosts; then
    content=$(sed "s/^127\.0\.1\.1\([[:space:]]\)/$ip\1/" /etc/hosts)
  else
    content=$(cat /etc/hosts; printf '%s\t%s' "$ip" "$hn")
  fi
  printf '%s\n' "$content" > /etc/hosts
  echo "Mapped hostname $hn to $ip in /etc/hosts (backup: /etc/hosts.pxvirt-bak)"
  echo "so pve-cluster (pmxcfs) can start. If this address is a plain DHCP"
  echo "lease, give the machine a static IP or DHCP reservation."
}

# On its first installation ifupdown2's postinst runs a "proxmox
# compatibility" pass: it parses /etc/network/interfaces with PVE::INotify and
# writes the normalized result to /etc/network/interfaces.new ("Saved in
# /etc/network/interfaces.new for hot-apply or next reboot"). pve-manager's
# pvenetcommit.service moves interfaces.new over interfaces on EVERY boot, so
# this stale snapshot of the pre-install config would silently replace
# whatever configure_network writes below on the first reboot - the vmbr0
# bridge and the pinned address disappear again and the machine falls back to
# the old DHCP setup (or worse, a config this script never saw). The snapshot
# only restates what is already in place, so it is safe to drop.
drop_stale_interfaces_new() {
  local f=/etc/network/interfaces.new
  [ -e "$f" ] || return 0
  mkdir -p /etc/network/.pxvirt-bak
  mv -f "$f" /etc/network/.pxvirt-bak/interfaces.new
  echo "Removed $f left behind by the ifupdown2 postinst (kept in"
  echo "/etc/network/.pxvirt-bak/): pvenetcommit.service would have installed"
  echo "it over /etc/network/interfaces on the next boot."
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

  # Backups must NOT be placed in /etc/network/interfaces.d/: Debian's
  # 'source /etc/network/interfaces.d/*' line would source them too,
  # resurrecting the very stanzas that were rewritten.
  local bakdir=/etc/network/.pxvirt-bak
  mkdir -p "$bakdir"

  # ifupdown2 (which replaces ifupdown during the install) ignores
  # allow-hotplug stanzas at boot: 'ifquery --all' - what networking.service
  # brings up - skips them entirely. Debian's installer writes exactly that
  # for the primary NIC, so without this rewrite the machine drops off the
  # network on the first reboot after installing.
  local f
  for f in /etc/network/interfaces /etc/network/interfaces.d/*; do
    [ -f "$f" ] || continue
    if grep -qE '^[[:space:]]*allow-hotplug[[:space:]]' "$f"; then
      [ -e "$bakdir/$(basename "$f")" ] || cp -a "$f" "$bakdir/$(basename "$f")"
      sed -i 's/^\([[:space:]]*\)allow-hotplug[[:space:]]/\1auto /' "$f"
      echo "Rewrote allow-hotplug -> auto in $f (backup in $bakdir/)"
      echo "because ifupdown2 does not bring allow-hotplug interfaces up at boot."
    fi
  done

  local iface addr gw
  iface=$(ip -4 route show default 2>/dev/null \
    | awk '{for(i=1;i<=NF;i++) if($i=="dev") {print $(i+1); exit}}')
  if [ -z "$iface" ]; then
    echo "WARNING: no default-route interface found; not touching /etc/network/interfaces." >&2
    return
  fi
  if grep -qE '^[[:space:]]*iface[[:space:]]+vmbr0[[:space:]]' \
       /etc/network/interfaces /etc/network/interfaces.d/* 2>/dev/null; then
    echo "vmbr0 is already configured - leaving the network config untouched."
    return
  fi

  # How is the default-route interface configured today?
  #   dhcp     -> converted below: the address moves onto a static vmbr0
  #               (same layout the Proxmox ISO installer creates), so the IP
  #               stays pinned to what configure_hosts wrote into /etc/hosts.
  #   static/… -> deliberately configured; left alone (network keeps working,
  #               only the vmbr0 bridge has to be added manually later).
  #   (none)   -> vmbr0 config is appended.
  local method
  method=$(cat /etc/network/interfaces /etc/network/interfaces.d/* 2>/dev/null \
    | awk -v ifn="$iface" \
        '$1 == "iface" && $2 == ifn && $3 == "inet" { print $4; exit }')
  if [ -n "$method" ] && [ "$method" != "dhcp" ]; then
    echo "$iface is configured with method '$method' - leaving it untouched."
    echo "Add a vmbr0 bridge for it manually if guests need bridged networking."
    return
  fi

  addr=$(ip -4 -o addr show dev "$iface" scope global 2>/dev/null | awk '{print $4; exit}')
  gw=$(ip -4 route show default 2>/dev/null \
    | awk '{for(i=1;i<=NF;i++) if($i=="via") {print $(i+1); exit}}')
  if [ -z "$addr" ]; then
    echo "WARNING: $iface has no IPv4 address; not touching /etc/network/interfaces." >&2
    return
  fi

  # Comment out the existing stanzas for $iface: as a bridge port it must not
  # carry addresses itself anymore.
  local tmp
  for f in /etc/network/interfaces /etc/network/interfaces.d/*; do
    [ -f "$f" ] || continue
    grep -qE "^[[:space:]]*(auto|allow-hotplug|iface)[[:space:]]+$iface([[:space:]]|\$)" "$f" || continue
    [ -e "$bakdir/$(basename "$f")" ] || cp -a "$f" "$bakdir/$(basename "$f")"
    tmp=$(mktemp)
    awk -v ifn="$iface" '
      function is_hdr(l) {
        return l ~ /^(auto|allow-hotplug|iface|mapping|source|source-directory)([ \t]|$)/
      }
      {
        if ($0 ~ "^(auto|allow-hotplug)[ \t]+" ifn "[ \t]*$") { print "#pxvirt# " $0; next }
        if ($0 ~ "^iface[ \t]+" ifn "[ \t]") { skip = 1; print "#pxvirt# " $0; next }
        if (skip) {
          if (is_hdr($0)) { skip = 0 }
          else { if ($0 ~ /^[ \t]*$/) print; else print "#pxvirt# " $0; next }
        }
        print
      }' "$f" > "$tmp" && cat "$tmp" > "$f"
    rm -f "$tmp"
  done

  # the loops above back up every file they modify; make sure the main file
  # has a backup even when it did not mention $iface at all
  [ -e "$bakdir/interfaces" ] \
    || cp -a /etc/network/interfaces "$bakdir/interfaces" 2>/dev/null || true
  {
    echo ""
    echo "# Added by install-target.sh: keep the current connection ($iface) working"
    echo "# under ifupdown2 via a PVE-style bridge. The previous ($method) config for"
    echo "# $iface was commented out ('#pxvirt#'); its address is pinned statically"
    echo "# here so it stays in sync with the /etc/hosts entry pmxcfs relies on."
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
  echo "Wrote vmbr0 bridge config for $iface ($addr) to /etc/network/interfaces."
  echo "If this address came from a plain DHCP lease, give the machine a DHCP"
  echo "reservation (or adjust the address in /etc/network/interfaces and"
  echo "/etc/hosts) so it cannot collide with other leases."
  echo "It takes effect on reboot, or now with: systemctl restart networking"

  if command -v ifquery >/dev/null 2>&1 && ! ifquery -a >/dev/null 2>&1; then
    echo "WARNING: 'ifquery -a' rejects the new /etc/network/interfaces -" >&2
    echo "WARNING: check it before rebooting (backups: $bakdir/)." >&2
  fi
  if [ -e /etc/network/interfaces.new ]; then
    echo "WARNING: /etc/network/interfaces.new exists; pvenetcommit.service will" >&2
    echo "WARNING: install it over /etc/network/interfaces on the next boot." >&2
  fi
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

drop_stale_interfaces_new
configure_network
