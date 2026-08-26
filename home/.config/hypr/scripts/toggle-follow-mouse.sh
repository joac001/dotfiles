#!/usr/bin/env bash
# Toggle input:follow_mouse (focus-follows-mouse) at runtime. This config uses
# Hyprland's Lua provider, which rejects the legacy `hyprctl keyword` IPC for
# live changes -- so this goes through `hyprctl eval` with the equivalent
# hl.config() snippet instead (see variables.lua/input.lua for the default).

current=$(hyprctl getoption input:follow_mouse -j | jq -r '.int')
new=$((1 - current))

hyprctl eval "hl.config({input = {follow_mouse = $new}})" >/dev/null

if [ "$new" = "1" ]; then
    caelestia shell toaster info "Foco al pasar el mouse" "Activado" input-mouse-symbolic
else
    caelestia shell toaster info "Foco al pasar el mouse" "Desactivado" input-mouse-symbolic
fi
