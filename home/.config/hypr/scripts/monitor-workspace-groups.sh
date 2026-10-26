#!/usr/bin/env bash
# Give each monitor its own workspace group (1-10, 11-20, 21-30, ...).
# Only moves monitors whose active workspace group is already taken by another monitor,
# processed left to right, so existing layouts are left untouched.

GROUP=10
SOCK="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

hl() { hyprctl eval "$1" >/dev/null; }

fix_groups() {
    local mons focused name ws g used=" " free
    mons=$(hyprctl monitors all -j | jq -r '[.[] | select(.name != "FALLBACK" and .disabled != true)] | sort_by(.x) | .[] | "\(.name) \(.activeWorkspace.id)"')
    focused=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

    while read -r name ws; do
        [ -z "$name" ] && continue
        g=$(( (ws - 1) / GROUP ))
        if [[ "$used" == *" $g "* ]]; then
            free=0
            while [[ "$used" == *" $free "* ]]; do free=$((free + 1)); done
            hl "hl.dispatch(hl.dsp.focus({ monitor = \"$name\" }))"
            hl "hl.dispatch(hl.dsp.focus({ workspace = $((free * GROUP + 1)) }))"
            g=$free
        fi
        used+="$g "
    done <<< "$mons"

    [ -n "$focused" ] && hl "hl.dispatch(hl.dsp.focus({ monitor = \"$focused\" }))"
}

sleep 1
fix_groups

socat -U - UNIX-CONNECT:"$SOCK" | while read -r line; do
    case "$line" in
        monitoradded*|monitoraddedv2*)
            sleep 1
            fix_groups
            ;;
    esac
done
