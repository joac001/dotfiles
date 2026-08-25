local vars = require("variables")
local fn   = require("utils.functions")


-- Flags
local locked           = { locked = true }
local mouse            = { mouse = true }
local release          = { release = true }
local repeating        = { repeating = true }
local locked_repeating = { locked = true, repeating = true }

local function normalise_keybind(key)
    return key:gsub("%s+", ""):lower()
end

local function valid_keybind(key)
    return type(key) == "string" and key:match("%S") ~= nil
end

local function repeating_unless_mouse(key)
    return not normalise_keybind(key):find("mouse", 1, true) and repeating or nil
end

local function flatten_keybinds(keybinds, keys)
    keys = keys or {}

    if type(keybinds) == "table" then
        for _, keybind in pairs(keybinds) do
            flatten_keybinds(keybind, keys)
        end
    elseif valid_keybind(keybinds) then
        keys[#keys + 1] = keybinds
    end

    return keys
end

-- `desc` (optional) is stored as Hyprland's native bind description, which is
-- what scripts/cheatsheet.sh reads via `hyprctl binds -j` to build the
-- keybind help menu. It's merged into a fresh table per-key so it never
-- mutates the shared flag tables above (locked, mouse, release, ...).
local function create_bind(keybinds, action, flags, desc)
    local get_flags = type(flags) == "function" and flags or function()
        return flags
    end

    for _, key in ipairs(flatten_keybinds(keybinds)) do
        local opts = get_flags(key)

        if desc then
            local merged = {}
            if type(opts) == "table" then
                for k, v in pairs(opts) do
                    merged[k] = v
                end
            end
            merged.description = desc
            opts = merged
        end

        hl.bind(key, action, opts)
    end
end

local function extend_keybind(base, suffix)
    return valid_keybind(base) and base .. " + " .. suffix or nil
end

-- Launcher
local launcher_default = normalise_keybind("SUPER + SUPER_L")
create_bind(
    vars.kbLauncher,
    hl.dsp.global("caelestia:launcher"),
    function(key)
        return normalise_keybind(key) == launcher_default and release or nil
    end,
    "Abrir el launcher de aplicaciones"
)

-- Misc
create_bind(vars.kbSession, hl.dsp.global("caelestia:session"), nil, "Abrir el menu de sesion (apagar/reiniciar/cerrar sesion)")
create_bind(vars.kbShowSidebar, hl.dsp.global("caelestia:sidebar"), nil, "Mostrar/ocultar la sidebar")
create_bind(vars.kbClearNotifs, hl.dsp.global("caelestia:clearNotifs"), locked, "Borrar todas las notificaciones")
create_bind(vars.kbShowPanels, hl.dsp.global("caelestia:showall"), nil, "Mostrar/ocultar launcher, dashboard y osd")
create_bind(vars.kbLock, hl.dsp.global("caelestia:lock"), nil, "Bloquear la pantalla")

-- Restore lock
create_bind(vars.kbRestoreLock, function()
    hl.dispatch(hl.dsp.exec_cmd("caelestia shell -d"))
    hl.dispatch(hl.dsp.global("caelestia:lock"))
end, nil, "Restaurar la pantalla de bloqueo tras un crash del shell")

-- Cheatsheet
create_bind(
    vars.kbCheatsheet,
    hl.dsp.exec_cmd("~/.config/hypr/scripts/cheatsheet.sh"),
    nil,
    "Mostrar esta lista de atajos de teclado"
)

-- Kill/restart
create_bind("CTRL + SUPER + SHIFT + R", hl.dsp.exec_cmd("qs -c caelestia kill"), release, "Matar el shell de Caelestia")
create_bind(
    "CTRL + SUPER + ALT + R",
    hl.dsp.exec_cmd("qs -c caelestia kill; sleep .1; caelestia shell -d"),
    release,
    "Reiniciar el shell de Caelestia"
)

for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    create_bind(extend_keybind(vars.kbGoToWs, key), fn.wsaction("focus", "", i), nil, "Ir al workspace " .. i)
    create_bind(extend_keybind(vars.kbMoveWinToWs, key), fn.wsaction("move", "", i), nil, "Mover ventana al workspace " .. i)
    create_bind(extend_keybind(vars.kbGoToWsGroup, key), fn.wsaction("focus", "group", i), nil, "Ir al grupo de workspaces " .. i)
    create_bind(extend_keybind(vars.kbMoveWinToWsGroup, key), fn.wsaction("move", "group", i), nil, "Mover ventana al grupo de workspaces " .. i)
end

-- Go to workspace -1/+1
create_bind(vars.kbPrevWs, hl.dsp.focus({ workspace = "-1" }), repeating_unless_mouse, "Ir al workspace anterior")
create_bind(vars.kbNextWs, hl.dsp.focus({ workspace = "+1" }), repeating_unless_mouse, "Ir al workspace siguiente")

-- Go to workspace group -1/+1
create_bind(vars.kbPrevWsGroup, hl.dsp.focus({ workspace = "-10" }), repeating_unless_mouse, "Ir al grupo de workspaces anterior")
create_bind(vars.kbNextWsGroup, hl.dsp.focus({ workspace = "+10" }), repeating_unless_mouse, "Ir al grupo de workspaces siguiente")

-- Move window to workspace -1/+1
create_bind(vars.kbMoveWinToWsNext, hl.dsp.window.move({ workspace = "+1" }), repeating_unless_mouse, "Mover ventana al workspace siguiente")
create_bind(vars.kbMoveWinToWsPrev, hl.dsp.window.move({ workspace = "-1" }), repeating_unless_mouse, "Mover ventana al workspace anterior")

-- Move window to/from special workspace
create_bind(vars.kbMoveWinToWsSpecial, hl.dsp.window.move({ workspace = "special:special" }), nil, "Mover ventana al workspace especial")
create_bind(vars.kbMoveWinFromWsSpecial, hl.dsp.window.move({ workspace = "e+0" }), nil, "Sacar ventana del workspace especial")

-- Window groups
create_bind(vars.kbWindowCycleNext, hl.dsp.window.cycle_next(), repeating, "Cambiar a la siguiente ventana (Alt+Tab)")
create_bind(vars.kbWindowCyclePrev, hl.dsp.window.cycle_next({ next = false }), repeating, "Cambiar a la ventana anterior (Alt+Tab)")
create_bind(vars.kbWindowGroupCycleNext, hl.dsp.group.next(), repeating, "Ciclar a la siguiente pestana del grupo de ventanas")
create_bind(vars.kbWindowGroupCyclePrev, hl.dsp.group.prev(), repeating, "Ciclar a la pestana anterior del grupo de ventanas")
create_bind(vars.kbToggleGroup, hl.dsp.group.toggle(), nil, "Agrupar/desagrupar ventana en pestanas")
create_bind(vars.kbUngroup, hl.dsp.window.move({ out_of_group = true }), nil, "Sacar ventana del grupo")
create_bind(vars.kbGroupLockActive, hl.dsp.group.lock_active(), nil, "Bloquear el grupo de ventanas activo")

-- Window actions
local dir_es = { left = "izquierda", right = "derecha", up = "arriba", down = "abajo" }
for _, dir in ipairs({ "left", "right", "up", "down" }) do
    create_bind("SUPER + " .. dir, fn.directional_focus(dir), nil, "Enfocar ventana hacia la " .. dir_es[dir])
    create_bind("SUPER + SHIFT + " .. dir, fn.directional_move(dir), nil, "Mover ventana hacia la " .. dir_es[dir])
end

create_bind(vars.kbWindowDecreaseWidth, fn.resize_active_window(-10, 0), repeating, "Reducir el ancho de la ventana")
create_bind(vars.kbWindowIncreaseWidth, fn.resize_active_window(10, 0), repeating, "Aumentar el ancho de la ventana")
create_bind(vars.kbWindowDecreaseHeight, fn.resize_active_window(0, -10), repeating, "Reducir el alto de la ventana")
create_bind(vars.kbWindowIncreaseHeight, fn.resize_active_window(0, 10), repeating, "Aumentar el alto de la ventana")

create_bind({ vars.kbMoveWindow, "SUPER + mouse:272" }, hl.dsp.window.drag(), mouse, "Mover ventana con el mouse")
create_bind({ vars.kbResizeWindow, "SUPER + mouse:273" }, hl.dsp.window.resize(), mouse, "Redimensionar ventana con el mouse")
create_bind(vars.kbCenterWindow, hl.dsp.window.center(), nil, "Centrar la ventana")
create_bind(vars.kbNormalizeWindow, function()
    hl.dispatch(hl.dsp.window.resize(fn.resize_by_screen(55, 70)))
    hl.dispatch(hl.dsp.window.center())
end, nil, "Normalizar tamano y centrar la ventana")
create_bind(vars.kbWindowPip, function()
    local a = hl.get_active_window()
    if a then
        local pip = fn.move_actions(a) or {}
        if not a.floating then table.insert(pip, 1, hl.dsp.window.float()) end
        table.insert(pip, hl.dsp.window.pin({ action = "on", window = "address:" .. a.address }))

        for _, x in ipairs(pip) do
            hl.dispatch(x)
        end
    end
end, nil, "Convertir ventana en picture-in-picture")
create_bind(vars.kbPinWindow, hl.dsp.window.pin(), nil, "Fijar ventana en todos los workspaces")
create_bind(vars.kbWindowFullscreen, hl.dsp.window.fullscreen({ mode = "fullscreen" }), nil, "Pantalla completa")
create_bind(vars.kbWindowBorderedFullscreen, hl.dsp.window.fullscreen({ mode = "maximized" }), nil, "Maximizar (pantalla completa con bordes)")
create_bind(vars.kbToggleWindowFloating, hl.dsp.window.float(), nil, "Alternar ventana flotante/en mosaico")
create_bind(vars.kbCloseWindow, hl.dsp.window.close(), nil, "Cerrar ventana")

-- Special workspace toggles
create_bind(vars.kbSpecialWs, fn.toggle("specialws"), nil, "Abrir/cerrar el workspace especial")
create_bind(vars.kbSystemMonitorWs, fn.toggle("sysmon"), nil, "Abrir/cerrar el workspace del monitor del sistema")
create_bind(vars.kbMusicWs, fn.toggle("music"), nil, "Abrir/cerrar el workspace de musica")
create_bind(vars.kbCommunicationWs, fn.toggle("communication"), nil, "Abrir/cerrar el workspace de comunicacion")
create_bind(vars.kbTodoWs, fn.toggle("todo"), nil, "Abrir/cerrar el workspace de tareas")

-- Apps
create_bind(vars.kbTerminal, hl.dsp.exec_cmd(vars.terminal), nil, "Abrir terminal")
create_bind(vars.kbBrowser, hl.dsp.exec_cmd(vars.browser), nil, "Abrir navegador")
create_bind(vars.kbEditor, hl.dsp.exec_cmd(vars.editor), nil, "Abrir editor de codigo")
create_bind(vars.kbFileExplorer, hl.dsp.exec_cmd(vars.fileExplorer), nil, "Abrir explorador de archivos")
create_bind(vars.kbAudioSettings, hl.dsp.exec_cmd(vars.audioSettings), nil, "Abrir ajustes de audio")

-- Utilities
create_bind(vars.kbScreenshot, hl.dsp.exec_cmd("caelestia screenshot"), locked, "Capturar pantalla completa")
create_bind(vars.kbScreenshotFreeze, hl.dsp.global("caelestia:screenshotFreeze"), nil, "Capturar pantalla congelando la imagen")
create_bind(vars.kbScreenshotRegion, hl.dsp.global("caelestia:screenshot"), nil, "Capturar una region de la pantalla")
create_bind(vars.kbRecord, hl.dsp.exec_cmd("caelestia record"), nil, "Grabar pantalla")
create_bind(vars.kbRecordSound, hl.dsp.exec_cmd("caelestia record -s"), nil, "Grabar pantalla con audio")
create_bind(vars.kbRecordRegion, hl.dsp.exec_cmd("caelestia record -r"), nil, "Grabar una region de la pantalla")
create_bind(vars.kbColorPicker, hl.dsp.exec_cmd("hyprpicker -a"), nil, "Elegir un color de la pantalla")

-- Brightness
create_bind("XF86MonBrightnessUp", hl.dsp.global("caelestia:brightnessUp"), locked, "Subir brillo")
create_bind("XF86MonBrightnessDown", hl.dsp.global("caelestia:brightnessDown"), locked, "Bajar brillo")

-- Media
create_bind({ vars.kbMediaToggle, "XF86AudioPlay", "XF86AudioPause" }, hl.dsp.global("caelestia:mediaToggle"), locked, "Reproducir/pausar musica")
create_bind({ vars.kbMediaNext, "XF86AudioNext" }, hl.dsp.global("caelestia:mediaNext"), locked, "Siguiente cancion")
create_bind({ vars.kbMediaPrev, "XF86AudioPrev" }, hl.dsp.global("caelestia:mediaPrev"), locked, "Cancion anterior")
create_bind({ vars.kbMediaStop, "XF86AudioStop" }, hl.dsp.global("caelestia:mediaStop"), locked, "Detener musica")

-- Volume
create_bind({ vars.kbVolumeMute, "XF86AudioMute" }, hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), locked, "Silenciar/activar audio")
create_bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), locked, "Silenciar/activar microfono")
create_bind(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd(
        "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l " ..
        (vars.volumeMax / 100) .. " @DEFAULT_AUDIO_SINK@ " .. vars.volumeStep .. "%+"
    ),
    locked_repeating,
    "Subir volumen"
)
create_bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd(
        "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ " .. vars.volumeStep .. "%-"
    ),
    locked_repeating,
    "Bajar volumen"
)

-- Sleep
create_bind(vars.kbSleep, hl.dsp.exec_cmd(vars.sleepGestureCmd), locked, "Suspender el sistema")

-- Clipboard and emoji picker
create_bind(vars.kbClipboard, hl.dsp.exec_cmd("pkill fuzzel || caelestia clipboard"), nil, "Abrir historial del portapapeles")
create_bind(vars.kbClipboardDel, hl.dsp.exec_cmd("pkill fuzzel || caelestia clipboard -d"), nil, "Borrar una entrada del historial del portapapeles")
create_bind(vars.kbEmoji, hl.dsp.exec_cmd("pkill fuzzel || caelestia emoji -p"), nil, "Abrir selector de emojis")
create_bind(
    vars.kbClipboardPasteLatest,
    hl.dsp.exec_cmd('sleep 0.5s && ydotool type -d 1 "$(cliphist list | head -1 | cliphist decode)"'),
    locked,
    "Pegar la ultima entrada del portapapeles"
)

-- Testing
create_bind(
    "SUPER + ALT + F12",
    hl.dsp.exec_cmd(
        "notify-send -u low -i dialog-information-symbolic 'Test notification' " ..
        [["Here's a really long message to test truncation and wrapping\nYou can middle click or flick this notification to dismiss it!"]] ..
        " -a 'Shell' -A 'Test1=I got it!' -A 'Test2=Another action'"
    )
)
