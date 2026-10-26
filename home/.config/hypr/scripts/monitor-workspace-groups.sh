#!/usr/bin/env bash
# Give each monitor its own workspace group (1-10, 11-20, 21-30, ...), ordered left to right.
# At startup monitors are laid out edge to edge (desktop only) and every monitor is placed
# in the group matching its position. On hotplug only monitors whose group is already
# taken by another monitor are moved.
#
# Left-to-right order: optional file ~/.config/caelestia/monitor-order (not in the repo,
# machine specific), one substring of the monitor description per line. Connector names
# (DP-2, HDMI-A-2, ...) change between boots, descriptions don't. Monitors not listed
# go after the listed ones, ordered by their current x.

GROUP=10
SOCK="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
ORDER_FILE="$HOME/.config/caelestia/monitor-order"

hl() { hyprctl eval "$1" >/dev/null; }
focus_monitor() { hl "hl.dispatch(hl.dsp.focus({ monitor = \"$1\" }))"; }
focus_ws()      { hl "hl.dispatch(hl.dsp.focus({ workspace = $1, on_current_monitor = true }))"; }

sorted_monitors() {
    local order='[]'
    [ -f "$ORDER_FILE" ] && order=$(jq -R 'select(length > 0)' "$ORDER_FILE" | jq -s .)
    hyprctl monitors all -j | jq --argjson order "$order" '
        [.[] | select(.name != "FALLBACK" and .disabled != true)]
        | map(. as $m | .rank = (([range(0; $order | length)] | map(select($m.description | contains($order[.]))) | .[0]) // (1000 + $m.x)))
        | sort_by(.rank)'
}

# Desktop only: lay monitors out edge to edge, top aligned.
reset_layout() {
    hyprctl monitors all -j | jq -e 'any(.[]; .name | startswith("eDP"))' >/dev/null && return
    local x=0 name w h r
    while read -r name w h r; do
        hl "hl.monitor({ output = \"$name\", mode = \"${w}x${h}@${r}\", position = \"${x}x0\", scale = 1 })"
        x=$((x + w))
    done < <(sorted_monitors | jq -r '.[] | "\(.name) \(.width) \(.height) \((.refreshRate * 100 | round) / 100)"')
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
reset_layout
fix_groups strict

socat -U - UNIX-CONNECT:"$SOCK" | while read -r line; do
    case "$line" in
        monitoradded*|monitoraddedv2*)
            sleep 1
            fix_groups collisions
            ;;
    esac
done
