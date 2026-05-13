#!/bin/sh
# ipv6.sh — polybar IPv6 indicator
#
# IPv6 present → short indicator showing only the last 16-bit group
#                e.g. "6:cf0c" — unique enough to confirm which prefix
#                you have without burning 45 chars of bar space.
# IPv6 absent  → orange "no IPv6" warning (matches i3status degraded color).
#
# Interval: 30 s is sufficient; prefix assignments change slowly.

addr=$(ip -6 addr show scope global 2>/dev/null \
    | awk '/inet6/ { split($2, a, "/"); print a[1]; exit }')

if [ -n "$addr" ]; then
    # Extract the last colon-separated group for a compact indicator
    last=$(printf '%s' "$addr" | awk -F: '{ print $NF }')
    printf 'ipv6:%s\n' "$last"
else
    printf '%%{F#ff8800}no IPv6%%{F-}\n'
fi
