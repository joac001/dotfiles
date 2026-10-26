#!/usr/bin/env bash
# Give each monitor its own workspace group (1-10, 11-20, 21-30, ...), ordered left to right.
# At startup every monitor is placed in the group matching its x position. On hotplug
# only monitors whose group is already taken by another monitor are moved.
# The physical layout itself is set in hyprland/monitors.lua.

GROUP=10
SOCK="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

hl() { hyprctl eval "$1" >/dev/null; }
focus_monitor() { hl "hl.dispatch(hl.dsp.focus({ monitor = \"$1\" }))"; }
focus_ws()      { hl "hl.dispatch(hl.dsp.focus({ workspace = $1, on_current_monitor = true }))"; }

sorted_monitors() {
    hyprctl monitors all -j | jq '[.[] | select(.name != "FALLBACK" and .disabled != true)] | sort_by(.x)'
}

fix_groups() {
    local mode="$1" focused name ws g idx=0 used=" " free
    local -a moves=()
    focused=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

    while read -r name ws; do
        [ -z "$name" ] && continue
        g=$(( (ws - 1) / GROUP ))
        if [ "$mode" = strict ]; then
            [ "$g" -ne "$idx" ] && moves+=("$name $idx")
            used+="$idx "
        elif [[ "$used" == *" $g "* ]]; then
            free=0
            while [[ "$used" == *" $free "* ]]; do free=$((free + 1)); done
            moves+=("$name $free")
            used+="$free "
        else
            used+="$g "
        fi
        idx=$((idx + 1))
    done < <(sorted_monitors | jq -r '.[] | "\(.name) \(.activeWorkspace.id)"')

    # Park moving monitors on throwaway workspaces first so none steals a visible one.
    local m target
    for m in "${moves[@]}"; do
        read -r name target <<< "$m"
        focus_monitor "$name"; focus_ws $((1000 + target))
    done
    for m in "${moves[@]}"; do
        read -r name target <<< "$m"
        focus_monitor "$name"; focus_ws $((target * GROUP + 1))
    done

    [ -n "$focused" ] && focus_monitor "$focused"
}

sleep 1
fix_groups strict

socat -U - UNIX-CONNECT:"$SOCK" | while read -r line; do
    case "$line" in
        monitoradded*|monitoraddedv2*)
            sleep 1
            fix_groups collisions
            ;;
        configreloaded*)
            sleep 1
            fix_groups strict
            ;;
    esac
done
