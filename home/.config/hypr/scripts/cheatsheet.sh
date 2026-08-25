#!/usr/bin/env bash
# Ayuda memoria de atajos: lee las descripciones nativas que Hyprland guarda
# para cada bind (ver keybinds.lua, create_bind(..., desc)) y las muestra en
# un fuzzel. Al depender de "hyprctl binds -j" en vez de una lista escrita a
# mano, nunca queda desactualizado: si se agrega/cambia un atajo con
# descripción en keybinds.lua, aparece acá automáticamente.

# Toggle: si ya está abierto, este mismo atajo lo cierra.
pkill -x fuzzel && exit 0

mods() {
    local mask=$1 out=""
    (( mask & 64 )) && out+="SUPER + "
    (( mask & 4 )) && out+="CTRL + "
    (( mask & 8 )) && out+="ALT + "
    (( mask & 1 )) && out+="SHIFT + "
    printf '%s' "$out"
}

list_binds() {
    hyprctl binds -j |
        jq -r '.[] | select(.description != "" and .submap == "") | [.modmask, .key, .description] | @tsv' |
        while IFS=$'\t' read -r modmask key desc; do
            printf '%s%s  →  %s\n' "$(mods "$modmask")" "$key" "$desc"
        done
}

list_binds | fuzzel --dmenu --prompt "Atajos: " --width 70 --lines 30 >/dev/null
