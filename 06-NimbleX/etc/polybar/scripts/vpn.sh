#!/bin/sh
# vpn.sh — polybar dynamic VPN indicator
#
# Detects active VPN connections without any hardcoded interface names
# or paths, making this config safe to distribute with a distro.
#
# Detection layers (in order):
#   1. NetworkManager (nmcli) — returns the human-readable connection name
#      for any active VPN or WireGuard connection managed by NM.
#   2. Interface scan fallback — finds tun*, tap*, wg*, ppp* interfaces
#      that are UP, covering OpenVPN, WireGuard, PPP, and other tunnels
#      not managed by NetworkManager.
#
# Output:
#   VPN active   → "VPN: <name>" (polybar renders this in the module's
#                  format-foreground color, set to cyan in config.ini)
#   No VPN       → empty string → polybar hides the module entirely,
#                  taking zero bar space. This is intentional.
#
# Interval: 10 s — fast enough to catch connect/disconnect events.

# ── Layer 1: NetworkManager ──────────────────────────────────────────
if command -v nmcli > /dev/null 2>&1; then
    # nmcli -t gives machine-readable colon-separated output:
    #   NAME:TYPE:STATE
    # We want TYPE = vpn or wireguard, STATE = activated.
    vpn_names=$(nmcli --color no -t -f NAME,TYPE,STATE con show --active 2>/dev/null \
        | awk -F: '$2 == "vpn" || $2 == "wireguard" { if ($3 == "activated") print $1 }')

    if [ -n "$vpn_names" ]; then
        # Join all names with ", "
        result=$(printf '%s\n' "$vpn_names" \
            | awk 'NR>1 { printf ", " } { printf "%s", $0 } END { print "" }')
        printf 'VPN: %s\n' "$result"
        exit 0
    fi
fi

# ── Layer 2: Interface scan fallback ────────────────────────────────
# Matches tun0, tun1, tap0, wg0, wg1, ppp0, etc.
ifaces=$(ip link show up 2>/dev/null \
    | awk -F'[ :]+' '/^[0-9]+:/ { iface=$2 }
                     /state UP/  { print iface }' \
    | grep -E '^(tun|tap|wg|ppp)[0-9]' \
    | paste -sd ', ' -)

if [ -n "$ifaces" ]; then
    printf 'VPN: %s\n' "$ifaces"
fi

# No VPN found — output nothing so polybar hides the module.
