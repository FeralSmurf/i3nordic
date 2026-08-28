#!/bin/sh

PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/battery-monitor.pid"

# Prevent duplicate instances from running simultaneously
if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null; then
    exit 0
fi

echo "$$" > "$PIDFILE"
trap 'rm -f "$PIDFILE"; exit 0' INT TERM EXIT

while true; do
    sleep_time=300

    for bat in /sys/class/power_supply/BAT*; do
        [ -d "$bat" ] || continue

        [ -f "$bat/status" ] && read -r status < "$bat/status"
        [ -f "$bat/capacity" ] && read -r capacity < "$bat/capacity"

        if [ "$status" = "Discharging" ]; then
            if [ "$capacity" -le 5 ]; then
                notify-send -u critical -i battery-empty "Battery Critical" "Battery level is ${capacity}%. Connect charger immediately!"
            elif [ "$capacity" -le 10 ]; then
                notify-send -u critical -i battery-caution "Battery Critical" "Battery level is ${capacity}%. Connect charger now."
            elif [ "$capacity" -le 20 ]; then
                notify-send -u normal -i battery-low "Battery Low" "Battery level is ${capacity}%."
            fi
        else
            # Battery is plugged in / charging / full: sleep longer to conserve CPU wakeups
            sleep_time=600
        fi
    done

    sleep "$sleep_time" &
    wait $!
done
