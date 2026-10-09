#!/usr/bin/env bash
# Enable the laptop panel only when no external monitor is connected.
# Disable it when at least one external monitor is present.

PANEL="eDP-1"
SOCK="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

apply_state() {
    local externals
    externals=$(hyprctl monitors all -j | jq -r --arg panel "$PANEL" \
        '[.[] | select(.name != $panel and .name != "FALLBACK")] | length')

    if [ "$externals" -gt 0 ]; then
        hyprctl eval "hl.monitor({output=\"$PANEL\", disabled=true})" >/dev/null
    else
        hyprctl eval "hl.monitor({output=\"$PANEL\", disabled=false, mode=\"preferred\", position=\"auto\", scale=1})" >/dev/null
    fi
}

apply_state

socat -U - UNIX-CONNECT:"$SOCK" | while read -r line; do
    case "$line" in
        monitoradded*|monitorremoved*|monitoraddedv2*|monitorremovedv2*)
            sleep 0.5
            apply_state
            ;;
    esac
done
