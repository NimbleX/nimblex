#!/bin/sh
# load.sh — 1-minute load average with 4-tier color coding
#
# Thresholds (as a fraction of logical CPU count):
#   < 50%  — white  (normal)
#   >= 50% — yellow (getting busy)
#   >= 75% — orange (high)
#   >= 100%— red    (all cores saturated)

load1=$(cut -d' ' -f1 /proc/loadavg)

# Count logical CPUs; fall back to 1 if nproc is unavailable
cpus=$(nproc 2>/dev/null \
    || grep -c '^processor' /proc/cpuinfo 2>/dev/null \
    || printf '1')

# awk returns 0=normal, 1=yellow, 2=orange, 3=red
tier=$(awk -v l="$load1" -v c="$cpus" 'BEGIN {
    r = l + 0
    if      (r >= c * 1.00) print 3
    else if (r >= c * 0.75) print 2
    else if (r >= c * 0.50) print 1
    else                    print 0
}')

case "$tier" in
    3) printf '%%{F#ff3333}load: %s%%{F-}\n' "$load1" ;;
    2) printf '%%{F#ff8800}load: %s%%{F-}\n' "$load1" ;;
    1) printf '%%{F#ffee00}load: %s%%{F-}\n' "$load1" ;;
    *) printf 'load: %s\n'                   "$load1" ;;
esac
