local vars = require("variables")
local fn   = require("utils.functions")

hl.on("hyprland.start", function()
    -- Keyring and auth
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

    -- Clipboard history
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Auto delete trash 30 days old
    hl.exec_cmd("trash-empty 30")

    -- Cursors
    hl.exec_cmd("hyprctl setcursor " .. vars.cursorTheme .. " " .. vars.cursorSize)
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme " .. vars.cursorTheme)
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size " .. vars.cursorSize)

    -- Location provider and night light
    hl.exec_cmd("/usr/lib/geoclue-2.0/demos/agent")
    hl.exec_cmd("sleep 1 && gammastep")

    -- Forward bluetooth media commands to MPRIS
    hl.exec_cmd("mpris-proxy")

    -- Auto enable/disable laptop panel based on external monitor presence
    -- (only on machines that actually have an eDP panel, e.g. a laptop)
    local has_edp = false
    local drm = io.popen("ls /sys/class/drm 2>/dev/null")
    if drm then
        for line in drm:lines() do
            if line:find("eDP") then
                has_edp = true
            end
        end
        drm:close()
    end
    if has_edp then
        hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/auto-laptop-monitor.sh")
    end

    -- One workspace group (1-10, 11-20, ...) per monitor, so monitors don't share workspaces
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/monitor-workspace-groups.sh")

    -- Start shell
    hl.exec_cmd("caelestia shell -d")

    -- Startup apps
    hl.exec_cmd(vars.terminal)
    hl.exec_cmd(vars.browser)
    hl.exec_cmd("discord")
    hl.exec_cmd("slack")
    hl.exec_cmd("spicetify watch -s") -- Launches Spotify with the Spicetify theme applied, same as SUPER+M
end)

-- Resizer listeners
local function apply_resizer_rules(win)
    local float_center = {
        hl.dsp.window.float({ action = "on", window = win }),
        hl.dsp.window.center({ window = win }),
    }
    local pip_actions = fn.move_actions(win) or {}

    -- Bitwarden
    fn.resizer(win, "Bitwarden", 20, 54, float_center, true, "class")                                       -- Native app
    fn.resizer(win, "^Extension: %(Bitwarden Password Manager%) %- Bitwarden", 20, 54, float_center, false) -- Firefox
    fn.resizer(win, "nngceckbapebfimnlniiiahkandclblb", 20, 54, float_center, true, "class")                -- Chromium

    -- Picture in picture
    fn.resizer(win, "Picture[- ]in[- ][Pp]icture", 0, 0, pip_actions, false)
end

hl.on("window.title", apply_resizer_rules)
hl.on("window.open", apply_resizer_rules)
