-- User overrides, loaded before hyprland-gui.lua (HyprMod), so HyprMod
-- can't silently wipe these on the next app launch/reboot.

-- eDP-1 (built-in panel) is now managed dynamically by
-- ~/.config/hypr/scripts/auto-laptop-monitor.sh, which disables it only
-- while an external monitor is connected and re-enables it otherwise.
-- Do NOT hardcode a disabled=true rule here: it forced the panel off on
-- every boot regardless of dock state, which was the original bug.

-- Pin each external monitor to its own group of 10 workspaces (left to
-- right: DP-6, DP-7, HDMI-A-2), so SUPER+1..0 / CTRL+SUPER+1..0 behave the
-- same on every boot instead of depending on monitor detection order.
hl.workspace_rule({ workspace = "1", monitor = "DP-6", default = true, persistent = true })
hl.workspace_rule({ workspace = "11", monitor = "DP-7", default = true, persistent = true })
hl.workspace_rule({ workspace = "21", monitor = "HDMI-A-2", default = true, persistent = true })

-- Force directional focus/move (SUPER+arrows, SUPER+SHIFT+arrows) to jump to
-- the neighbouring monitor when there's no more window in that direction on
-- the current one. This is a Hyprland default already, but setting it
-- explicitly here since `hyprctl keyword` can't touch this Lua-parsed config
-- live for testing.
hl.config({
    binds = {
        window_direction_monitor_fallback = true,
    },
})
