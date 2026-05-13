#!/bin/sh
# battery.sh — polybar battery indicator
#
# Auto-discovers the first battery in /sys/class/power_supply/.
# Outputs nothing (empty) when no battery is present, so the module
# is hidden entirely on desktop machines — no "no BAT" clutter.
#
# Uses energy_full_design (or charge_full_design) as the divisor,
# matching how i3status calculates battery percentage.
#
# Output format:
#   Discharging: "BAT 57% 2:32"
#   Charging:    "CHR 57% 1:10"  (time to full)
#   Full:        "FULL 100%"
#
# Time-based colors (discharging only):
#   ≤ 30 min remaining → red   #ff3333
#   ≤ 60 min remaining → orange #ff8800
#   otherwise          → default

# ── Auto-detect battery ───────────────────────────────────────────────
BAT=$(ls -d /sys/class/power_supply/BAT* \
           /sys/class/power_supply/CMB* 2>/dev/null | head -1)
[ -n "$BAT" ] || exit 0   # desktop — hide module silently

# ── Read sysfs values ─────────────────────────────────────────────────
status=$(cat "$BAT/status" 2>/dev/null)

# Prefer energy (µWh) over charge (µAh)
if [ -f "$BAT/energy_now" ]; then
    now=$(cat  "$BAT/energy_now")
    full=$(cat "$BAT/energy_full_design")
    rate=$(cat "$BAT/power_now" 2>/dev/null)
    # For charging time-to-full use the actual current capacity, not design
    cap=$(cat  "$BAT/energy_full" 2>/dev/null)
else
    now=$(cat  "$BAT/charge_now")
    full=$(cat "$BAT/charge_full_design")
    rate=$(cat "$BAT/current_now" 2>/dev/null)
    cap=$(cat  "$BAT/charge_full" 2>/dev/null)
fi

# ── Percentage (vs design capacity, matching i3status) ───────────────
pct=$((now * 100 / full))
[ "$pct" -gt 100 ] && pct=100

# ── Remaining / time-to-full in H:MM ─────────────────────────────────
time_str=""
mins=0
if [ -n "$rate" ] && [ "$rate" -gt 0 ] 2>/dev/null; then
    if [ "$status" = "Discharging" ]; then
        # Time remaining = energy_now / power_now  (in hours)
        mins=$(awk -v n="$now" -v r="$rate" \
                   'BEGIN { printf "%d", n * 60 / r }')
    elif [ "$status" = "Charging" ]; then
        # Time to full = (energy_full_design - energy_now) / power_now
        # Use the same design capacity as the percentage so both figures
        # are consistent and match i3status behaviour.
        mins=$(awk -v c="$full" -v n="$now" -v r="$rate" \
                   'BEGIN { printf "%d", (c - n) * 60 / r }')
    fi

    if [ "$mins" -gt 0 ]; then
        h=$((mins / 60))
        m=$((mins % 60))
        # Zero-pad minutes
        [ "$m" -lt 10 ] && m="0${m}"
        time_str=" ${h}:${m}"
    fi
fi

# ── Build label ───────────────────────────────────────────────────────
case "$status" in
    Charging)    label="CHR ${pct}%${time_str}" ;;
    Discharging) label="BAT ${pct}%${time_str}" ;;
    Full)        label="FULL ${pct}%" ;;
    *)           label="${status} ${pct}%${time_str}" ;;
esac

# ── Color ─────────────────────────────────────────────────────────────
# Time-based thresholds take priority over percentage when available.
color=""
if [ "$status" = "Discharging" ]; then
    if [ "$mins" -gt 0 ] && [ "$mins" -le 30 ]; then
        color="#ff3333"   # red — critical (≤ 30 min)
    elif [ "$mins" -gt 0 ] && [ "$mins" -le 60 ]; then
        color="#ff8800"   # orange — low (≤ 60 min)
    elif [ "$pct" -le 20 ]; then
        color="#ff3333"   # red fallback when power_now unavailable
    fi
fi

if [ -n "$color" ]; then
    printf '%%{F%s}%s%%{F-}\n' "$color" "$label"
else
    printf '%s\n' "$label"
fi
