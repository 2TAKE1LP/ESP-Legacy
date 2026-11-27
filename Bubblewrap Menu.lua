-- ============================================================================
-- BUBBLEWRAP MENU — Single-File Loader & Runtime (GTA V Legacy)
-- ============================================================================

local function bubblewrap_toast(msg)
    if notify and type(notify.push) == "function" then
        pcall(notify.push, "Bubblewrap Menu", tostring(msg), { time = 5000 })
    elseif type(print) == "function" then
        pcall(print, "[Bubblewrap Menu] " .. tostring(msg))
    end
end

if not (invoker and type(invoker.call) == "function" and util and type(util.create_thread) == "function") then
    bubblewrap_toast("Lexis API unavailable")
    return
end

if game and type(game.build) == "function" then
    local ok, build = pcall(game.build)
    if ok and type(build) == "string" and build:lower() == "enhanced" then
        bubblewrap_toast("This script is for GTA V Legacy")
        return
    end
end

-- ============================================================================
-- [GENERATOR] Native Lexis `dirs` & `file` API Provisioner (with io fallback)
-- ============================================================================
local Gen = {
    folder_name = "bubblewrap_menu",
    themes_folder = "themes",
    root = "C:\\Users\\FemBoy\\Lexis\\Grand Theft Auto V\\scripts\\bubblewrap_menu",
    themes_root = "C:\\Users\\FemBoy\\Lexis\\Grand Theft Auto V\\scripts\\bubblewrap_menu\\themes",
    dir_created = false,
    written_count = 0,
    backend_used = "none",
    last_error = nil,
    active_storage_path = nil,
    provisioned = false
}

function Gen.join(base, sub)
    if not base or base == "" then return sub or "" end
    if not sub or sub == "" then return base end
    local last = base:sub(-1)
    if last == "\\" or last == "/" then
        return base .. sub
    end
    return base .. "\\" .. sub
end

function Gen.get_script_root()
    if type(paths) == "table" and type(paths.script) == "string" and paths.script ~= "" then
        local clean = paths.script:gsub("/", "\\"):gsub("\\+$", "")
        local tail = clean:match("([^\\]+)$")
        if tail and tail:lower() == Gen.folder_name:lower() then
            return clean
        end
        return Gen.join(clean, Gen.folder_name)
    end
    if type(paths) == "table" and type(paths.game) == "string" and paths.game ~= "" then
        local g = paths.game:gsub("/", "\\"):gsub("\\+$", "")
        return Gen.join(Gen.join(g, "scripts"), Gen.folder_name)
    end
    return "C:\\Users\\FemBoy\\Lexis\\Grand Theft Auto V\\scripts\\bubblewrap_menu"
end

function Gen.ensure_dir(dir_path)
    if not dir_path or dir_path == "" then return false end
    local clean = dir_path:gsub("/", "\\"):gsub("\\+$", "")

    if type(dirs) == "table" then
        if type(dirs.exists) == "function" then
            local ok_ex, ex = pcall(dirs.exists, clean)
            if ok_ex and ex == true then
                return true
            end
        end
        if type(dirs.create) == "function" then
            local ok_cr, cr = pcall(dirs.create, clean)
            if ok_cr and cr == true then
                return true
            end
        end
    end

    if type(os) == "table" and type(os.execute) == "function" then
        pcall(os.execute, 'mkdir "' .. clean .. '" >nul 2>nul')
        return true
    end
    return false
end

function Gen.resolve_root()
    local target_dir = Gen.get_script_root()
    Gen.dir_created = Gen.ensure_dir(target_dir)
    Gen.root = target_dir
    Gen.themes_root = Gen.join(target_dir, Gen.themes_folder)
    Gen.ensure_dir(Gen.themes_root)
    return Gen.root
end

function Gen.target_file_path(file_name)
    local clean_name = tostring(file_name or ""):match("([^/\\]+)$") or "data.cfg"
    return Gen.join(Gen.root or Gen.get_script_root(), clean_name)
end

function Gen.write_file(file_path, content, overwrite)
    local root_dir = Gen.root or Gen.resolve_root()
    local raw_str = tostring(file_path or "")
    local win_path = raw_str:match("^%a:[\\/]") and raw_str:gsub("/", "\\")
        or Gen.join(root_dir, raw_str:match("([^/\\]+)$") or "data.cfg")
    local text_body = tostring(content or "")

    if type(file) == "table" and type(file.open) == "function" then
        if not overwrite and type(file.exists) == "function" then
            local ok_ex, ex = pcall(file.exists, win_path)
            if ok_ex and ex == true then
                Gen.active_storage_path = win_path
                Gen.backend_used = "lexis.file"
                Gen.last_error = nil
                return true
            end
        end

        if overwrite and type(file.remove) == "function" and type(file.exists) == "function" then
            local ok_ex, ex = pcall(file.exists, win_path)
            if ok_ex and ex == true then
                pcall(file.remove, win_path)
            end
        end

        local ok_o, handle = pcall(file.open, win_path, { append = false, create_if_not_exists = true })
        if ok_o and handle and handle.valid == true then
            local ok_w, w_err = pcall(function()
                handle.text = text_body
            end)
            if ok_w then
                Gen.written_count = Gen.written_count + 1
                Gen.active_storage_path = win_path
                Gen.backend_used = "lexis.file"
                Gen.last_error = nil
                return true
            else
                Gen.last_error = "file.text write failed: " .. tostring(w_err)
            end
        else
            Gen.last_error = "file.open invalid in " .. Gen.folder_name .. ": " .. tostring(win_path)
        end
    end

    if type(io) == "table" and type(io.open) == "function" then
        if not overwrite then
            local check_ok, check_f = pcall(io.open, win_path, "rb")
            if check_ok and check_f then
                pcall(check_f.close, check_f)
                Gen.active_storage_path = win_path
                Gen.backend_used = "io.open"
                Gen.last_error = nil
                return true
            end
        end

        local ok, f = pcall(io.open, win_path, "wb")
        if ok and f then
            local w_ok, w_err = pcall(function()
                f:write(text_body)
                f:flush()
                f:close()
            end)
            if w_ok then
                Gen.written_count = Gen.written_count + 1
                Gen.active_storage_path = win_path
                Gen.backend_used = "io.open"
                Gen.last_error = nil
                return true
            else
                Gen.last_error = "io write failed: " .. tostring(w_err)
                return false
            end
        end
    end

    if not Gen.last_error then
        Gen.last_error = "cannot open in " .. Gen.folder_name .. ": " .. tostring(win_path)
    end
    return false
end

function Gen.read_file(file_path)
    local raw_str = tostring(file_path or "")
    local win_path = raw_str:match("^%a:[\\/]") and raw_str:gsub("/", "\\")
        or Gen.target_file_path(raw_str)

    if type(file) == "table" and type(file.open) == "function" then
        local ok_o, handle = pcall(file.open, win_path, { append = false, create_if_not_exists = false })
        if ok_o and handle and handle.valid == true then
            local ok_r, raw = pcall(function() return handle.text end)
            if ok_r and type(raw) == "string" and raw ~= "" then
                return raw
            end
        end
    end

    if type(io) == "table" and type(io.open) == "function" then
        local ok, f = pcall(io.open, win_path, "rb")
        if ok and f then
            local raw = nil
            pcall(function()
                raw = f:read("*a")
                f:close()
            end)
            if type(raw) == "string" and raw ~= "" then
                return raw
            end
        end
    end

    return nil
end

function Gen.scan_theme_files()
    local exts = { jpg = true, jpeg = true, png = true, webp = true, bmp = true }
    local found = {}
    local seen = {}

    local function push_file(full_path)
        if type(full_path) ~= "string" or full_path == "" then return end
        local clean = full_path:gsub("/", "\\")
        local ext = (clean:match("%.([^%.]+)$") or ""):lower()
        if not exts[ext] then return end
        local key = clean:lower()
        if seen[key] then return end
        seen[key] = true
        local base = clean:match("([^\\]+)$") or clean
        local label = base:gsub("%.[^%.]+$", "")
        found[#found + 1] = {
            name = label,
            file = base,
            ext = ext,
            path = clean
        }
    end

    local tdir = Gen.themes_root or Gen.join(Gen.resolve_root(), Gen.themes_folder)
    Gen.ensure_dir(tdir)

    if type(dirs) == "table" and type(dirs.list) == "function" then
        local ok, list = pcall(dirs.list, tdir)
        if ok and type(list) == "table" then
            for _, item in pairs(list) do
                if type(item) == "string" then
                    push_file(item:match("^%a:[\\/]") and item or Gen.join(tdir, item))
                elseif type(item) == "table" then
                    local n = item.name or item.path
                    if type(n) == "string" then
                        push_file(n:match("^%a:[\\/]") and n or Gen.join(tdir, n))
                    end
                end
            end
        end
    end

    table.sort(found, function(a, b) return a.name:lower() < b.name:lower() end)
    return found
end

-- ============================================================================
-- [STAGE 1] Environment, Constants, Hashes, Bones & Styles
-- ============================================================================
local Env = {
    hashes = {
        player_id                    = 0x4F8644AF03D0E0D6,
        player_ped                   = 0xD80958FC74E988A6,
        player_active                = 0xB8DFD30D6973E135,
        get_player_ped               = 0x43A66C31C68491C0,
        entity_exists                = 0x7239B21A38F536BA,
        entity_coords                = 0x3FEF770D40960D5A,
        entity_health                = 0xEEF059FAD016D209,
        entity_max_health            = 0x15D757606D170C3C,
        bone_coords                  = 0x17C07FC640E86B4E,
        ped_dead                     = 0x3317DEDB88C95038,
        ped_in_vehicle               = 0x997ABD671D25CA0B,
        ped_armour                   = 0x9483AF821605B1D8,
        has_entity_clear_los         = 0xFCDFF7BC278B7883,
        get_aim_entity               = 0x2975C866E275C817,
        set_control_normal           = 0xE8A25867FBA3B05E,
        is_control_pressed           = 0xF3A21BC95369969C,
        screen_coords                = 0x34E82F05DF2974F5,
        draw_rect                    = 0x3A618A217E5154F0,
        disable_control_action       = 0xFE99B66D079CF6BC,
        enable_control_action        = 0x351220255D64C155,
        is_pause_menu_active         = 0x535DB43E6352AD21,
        get_active_screen_resolution = 0x873C9F3104101DD3
    },
    bones = {
        head   = 31086,
        neck   = 39317,
        spine2 = 24817,
        spine1 = 24816,
        pelvis = 11816,
        luarm  = 45509, llarm = 61163, lhand = 18905,
        ruarm  = 40269, rlarm = 28252, rhand = 57005,
        lthigh = 58271, lcalf = 63931, lfoot = 14201,
        rthigh = 51826, rcalf = 36864, rfoot = 52301
    },
    styles = {
        skeleton = { "Classic", "Joints", "Stripes", "Core", "Minimal", "Tapered", "CoreLine", "DoubleRail" },
        box      = { "Corners", "Double", "Brackets", "Fade", "Off" },
        aim_bone = { "Head", "Neck", "Spine", "Pelvis" },
        aim_prio = { "FOV", "Distance" },
        themes   = { "Midnight", "VioletVK", "Crimson", "Emerald", "Cyber", "Amber" }
    },
    blocked_controls = {
        0, 1, 2, 3, 4, 5, 6,
        21, 22, 23, 24, 25, 29, 30, 31, 32, 33, 34, 35, 36, 37, 44, 45,
        68, 69, 70, 75, 91, 92, 106, 114, 122, 135, 140, 141, 142, 143, 257, 263, 264
    }
}

function Gen.build_lua_sources()
    return {
        {
            name = "bubblewrap_menu_core.lua",
            code = [[
-- Bubblewrap Menu — bubblewrap_menu_core.lua
local Core = {}
Core.menu_name = "Bubblewrap Menu"
Core.folder_name = "bubblewrap_menu"
Core.styles = {
    skeleton = { "Classic", "Joints", "Stripes", "Core", "Minimal", "Tapered", "CoreLine", "DoubleRail" },
    box      = { "Corners", "Double", "Brackets", "Fade", "Off" },
    aim_bone = { "Head", "Neck", "Spine", "Pelvis" },
    aim_prio = { "FOV", "Distance" },
    themes   = { "Midnight", "VioletVK", "Crimson", "Emerald", "Cyber", "Amber" }
}
return Core
]]
        },
        {
            name = "bubblewrap_menu_esp.lua",
            code = [[
-- Bubblewrap Menu — bubblewrap_menu_esp.lua
return { module = "esp", menu = "Bubblewrap Menu", version = "1.0", target = "GTA V Legacy" }
]]
        },
        {
            name = "bubblewrap_menu_aim.lua",
            code = [[
-- Bubblewrap Menu — bubblewrap_menu_aim.lua
return { module = "aimbot", menu = "Bubblewrap Menu", version = "1.0", target = "GTA V Legacy" }
]]
        },
        {
            name = "bubblewrap_menu_trigger.lua",
            code = [[
-- Bubblewrap Menu — bubblewrap_menu_trigger.lua
return { module = "triggerbot", menu = "Bubblewrap Menu", version = "1.0", target = "GTA V Legacy" }
]]
        },
        {
            name = "bubblewrap_menu_ui.lua",
            code = [[
-- Bubblewrap Menu — bubblewrap_menu_ui.lua
return { module = "ui", menu = "Bubblewrap Menu", version = "1.0", tabs = { "Player", "Vehicle", "AimBot", "Trigger", "Colors", "Hotkeys", "Settings" } }
]]
        },
        {
            name = "bubblewrap_menu_config.lua",
            code = [[
-- Bubblewrap Menu — bubblewrap_menu_config.lua
local Config = {}
Config.sections = { "player", "vehicle", "aimbot", "triggerbot", "colors", "hotkeys", "settings" }
function Config.file_path(dir, section)
    return dir .. "\\bubblewrap_menu_" .. tostring(section) .. ".cfg"
end
return Config
]]
        }
    }
end

function Gen.generate_all_files(cfg_manager)
    if Gen.provisioned then return end
    Gen.written_count = 0
    Gen.last_error = nil
    local root_dir = Gen.resolve_root()

    local sources = Gen.build_lua_sources()
    for i = 1, #sources do
        local item = sources[i]
        Gen.write_file(Gen.join(root_dir, item.name), item.code, true)
    end

    local readme_path = Gen.join(Gen.themes_root, "README_THEMES.txt")
    Gen.write_file(readme_path,
        "Theme files placed here (.jpg, .jpeg, .png, .webp, .bmp) appear in Settings -> Themes.\n",
        false)

    if cfg_manager then
        cfg_manager.bind_root(root_dir)
        cfg_manager.ensure_all_section_files()
    end
    Gen.provisioned = true
end

-- ============================================================================
-- [STAGE 2] System Helpers, Natives & Screen Metrics
-- ============================================================================
local Sys = {
    script_dir = "",
    natives = nil,
    auto_w = 2560.0,
    auto_h = 1440.0,
    scr_w = 2560.0,
    scr_h = 1440.0,
    ui_scale = 1.0,
    res_label = "2560x1440 [2K]",
    font = nil,
    font_px = 0.0,
    now = 0.0,
    _sx = type(pointer_float) == "function" and pointer_float() or nil,
    _sy = type(pointer_float) == "function" and pointer_float() or nil,
    _aim_ent = type(pointer_int) == "function" and pointer_int() or nil
}

function Sys.clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

function Sys.clock()
    if type(os) == "table" and type(os.clock) == "function" then
        return os.clock()
    end
    return 0.0
end

function Sys.field(obj, key)
    if obj == nil then return nil end
    local ok, val = pcall(function() return obj[key] end)
    return ok and val or nil
end

function Sys.first_field(obj, keys)
    for i = 1, #keys do
        local val = Sys.field(obj, keys[i])
        if val ~= nil then return val end
    end
    return nil
end

function Sys.to_bool(v)
    if type(v) == "boolean" then return v end
    if type(v) == "number" then return v ~= 0 end
    local inner = Sys.first_field(v, { "bool", "value", "result" })
    if type(inner) == "boolean" then return inner end
    if type(inner) == "number" then return inner ~= 0 end
    return false
end

function Sys.to_number(v, keys)
    if type(v) == "number" then return v end
    return tonumber(Sys.first_field(v, keys or { "int", "float", "int64", "value", "result" }))
end

function Sys.to_string(v)
    if type(v) == "string" then return v end
    local inner = Sys.first_field(v, { "str", "string", "value", "text" })
    return type(inner) == "string" and inner or nil
end

function Sys.to_vec3(a, b, c)
    if type(a) == "number" and type(b) == "number" and type(c) == "number" then
        return { x = a, y = b, z = c }
    end
    if a == nil then return nil end
    local src = Sys.first_field(a, { "scr_vec3", "vector3", "vector", "vec3", "value" }) or a
    local x = tonumber(Sys.field(src, "x") or Sys.field(src, "X") or Sys.field(src, 1))
    local y = tonumber(Sys.field(src, "y") or Sys.field(src, "Y") or Sys.field(src, 2))
    local z = tonumber(Sys.field(src, "z") or Sys.field(src, "Z") or Sys.field(src, 3))
    if x and y and z and x == x and y == y and z == z then
        return { x = x, y = y, z = z }
    end
    return nil
end

function Sys.init_natives()
    if type(paths) == "table" and type(paths.script) == "string" and paths.script ~= "" then
        local d = paths.script
        if d:sub(-1) ~= "\\" and d:sub(-1) ~= "/" then d = d .. "\\" end
        Sys.script_dir = d
    end

    if type(_G.native) == "table" then Sys.natives = _G.native; return end
    if type(_G.natives) == "table" then Sys.natives = _G.natives; return end

    if type(require) == "function" then
        local ok, mod = pcall(require, "natives")
        if ok and type(mod) == "table" then
            _G.native = mod
            Sys.natives = mod
            return
        end
    end

    if type(dofile) == "function" then
        local list = {}
        if Sys.script_dir ~= "" then list[#list + 1] = Sys.script_dir .. "natives.lua" end
        if type(paths) == "table" and type(paths.game) == "string" then
            list[#list + 1] = paths.game .. "\\scripts\\natives.lua"
        end
        list[#list + 1] = "natives.lua"
        list[#list + 1] = ".\\natives.lua"

        for i = 1, #list do
            local ok, mod = pcall(dofile, list[i])
            if ok and type(mod) == "table" then
                _G.native = mod
                Sys.natives = mod
                return
            end
            if type(_G.native) == "table" then Sys.natives = _G.native; return end
            if type(_G.natives) == "table" then Sys.natives = _G.natives; return end
        end
    end
end

function Sys.native(name, hash, ...)
    local fn = Sys.natives and Sys.natives[name]
    if type(fn) == "function" then
        return fn(...)
    end
    return invoker.call(hash, ...)
end

function Sys.int(name, hash, ...)
    local ok, res = pcall(Sys.native, name, hash, ...)
    if not ok then return 0 end
    return Sys.to_number(res, { "int", "int64", "integer", "value", "result" }) or 0
end

function Sys.bool(name, hash, ...)
    local ok, res = pcall(Sys.native, name, hash, ...)
    return ok and Sys.to_bool(res) or false
end

function Sys.vec3(name, hash, ...)
    local ok, a, b, c = pcall(Sys.native, name, hash, ...)
    return ok and Sys.to_vec3(a, b, c) or nil
end

function Sys.detect_resolution()
    if type(pointer_int) == "function" then
        local px, py = pointer_int(), pointer_int()
        if px and py then
            local fn = Sys.natives and Sys.natives.get_active_screen_resolution
            local ok, res
            if type(fn) == "function" then
                ok, res = pcall(fn, px, py)
            else
                ok, res = pcall(invoker.call, Env.hashes.get_active_screen_resolution, px:address(), py:address())
            end
            if ok then
                local w = tonumber(px.value) or Sys.to_number(res)
                local h = tonumber(py.value)
                if w and h and w >= 800 and h >= 600 and w <= 7680 and h <= 4320 then
                    return w, h
                end
            end
        end
    end

    local sources = { _G.screen, _G.display, _G.graphics, _G.render, gui }
    for i = 1, #sources do
        local src = sources[i]
        if src then
            local w = tonumber(Sys.first_field(src, { "width", "screen_width", "res_x", "w" }))
            local h = tonumber(Sys.first_field(src, { "height", "screen_height", "res_y", "h" }))
            if w and h and w >= 800 and h >= 600 and w <= 7680 and h <= 4320 then
                return w, h
            end
        end
    end

    return 2560.0, 1440.0
end

function Sys.format_res(w, h)
    local iw, ih = math.floor(w + 0.5), math.floor(h + 0.5)
    if iw == 2560 and ih == 1440 then return "2560x1440 [2K]" end
    if iw == 1920 and ih == 1080 then return "1920x1080 [1080p]" end
    if iw == 3840 and ih == 2160 then return "3840x2160 [4K]" end
    return tostring(iw) .. "x" .. tostring(ih)
end

function Sys.ensure_font(target_px)
    local px = Sys.clamp(tonumber(target_px) or 22.0, 14.0, 56.0)
    if Sys.font and math.abs(px - Sys.font_px) < 1.5 then
        return Sys.font
    end
    if gui and type(gui.load_font) == "function" then
        local fonts = {
            "C:\\Windows\\Fonts\\bahnschrift.ttf",
            "C:\\Windows\\Fonts\\seguisb.ttf",
            "C:\\Windows\\Fonts\\arialbd.ttf",
            "C:\\Windows\\Fonts\\segoeui.ttf"
        }
        for i = 1, #fonts do
            local ok, f = pcall(gui.load_font, fonts[i], px)
            if ok and f then
                Sys.font = f
                Sys.font_px = px
                if type(gui.rebuild) == "function" then pcall(gui.rebuild) end
                break
            end
        end
    end
    return Sys.font
end

function Sys.is_paused()
    return Sys.bool("is_pause_menu_active", Env.hashes.is_pause_menu_active)
end

function Sys.block_game_input()
    for i = 1, #Env.blocked_controls do
        local c = Env.blocked_controls[i]
        pcall(Sys.native, "disable_control_action", Env.hashes.disable_control_action, 0, c, true)
        pcall(Sys.native, "disable_control_action", Env.hashes.disable_control_action, 1, c, true)
        pcall(Sys.native, "disable_control_action", Env.hashes.disable_control_action, 2, c, true)
    end
end

function Sys.restore_game_input()
    for i = 1, #Env.blocked_controls do
        local c = Env.blocked_controls[i]
        pcall(Sys.native, "enable_control_action", Env.hashes.enable_control_action, 0, c, true)
        pcall(Sys.native, "enable_control_action", Env.hashes.enable_control_action, 1, c, true)
        pcall(Sys.native, "enable_control_action", Env.hashes.enable_control_action, 2, c, true)
    end
end

function Sys.entity_exists(ent)
    return type(ent) == "number" and ent > 0 and Sys.bool("does_entity_exist", Env.hashes.entity_exists, ent)
end

function Sys.entity_coords(ent)
    return Sys.vec3("get_entity_coords", Env.hashes.entity_coords, ent, true)
end

function Sys.bone_coords(ped, bone_id)
    local v = Sys.vec3("get_ped_bone_coords", Env.hashes.bone_coords, ped, bone_id, 0.0, 0.0, 0.0)
    if not v then return nil end
    if math.abs(v.x) < 0.001 and math.abs(v.y) < 0.001 and math.abs(v.z) < 0.001 then
        return nil
    end
    return v
end

function Sys.world_to_screen(pos)
    if not pos or not Sys._sx or not Sys._sy then return nil end
    local fn = Sys.natives and Sys.natives.get_screen_coord_from_world_coord
    local ok, res
    if type(fn) == "function" then
        ok, res = pcall(fn, pos.x, pos.y, pos.z, Sys._sx, Sys._sy)
    else
        ok, res = pcall(invoker.call, Env.hashes.screen_coords, pos.x, pos.y, pos.z, Sys._sx:address(), Sys._sy:address())
    end
    if ok and Sys.to_bool(res) then
        local x, y = tonumber(Sys._sx.value), tonumber(Sys._sy.value)
        if x and y and x == x and y == y and x >= -5.0 and y >= -5.0 and x <= 6.0 and y <= 6.0 then
            return { x = x, y = y }
        end
    end
    return nil
end

function Sys.draw_world_rect(x, y, w, h, r, g, b, a)
    if w <= 0 or h <= 0 then return end
    pcall(Sys.native, "draw_rect", Env.hashes.draw_rect, x, y, w, h, r, g, b, a, false)
end

function Sys.clip_segment(x0, y0, x1, y1)
    local t0, t1 = 0.0, 1.0
    local dx, dy = x1 - x0, y1 - y0
    local edges = {
        { -dx, x0 },
        { dx,  1.0 - x0 },
        { -dy, y0 },
        { dy,  1.0 - y0 }
    }
    for i = 1, 4 do
        local p, q = edges[i][1], edges[i][2]
        if math.abs(p) < 1e-8 then
            if q < 0.0 then return nil end
        else
            local r = q / p
            if p < 0.0 then
                if r > t1 then return nil end
                if r > t0 then t0 = r end
            else
                if r < t0 then return nil end
                if r < t1 then t1 = r end
            end
        end
    end
    return x0 + t0 * dx, y0 + t0 * dy, x0 + t1 * dx, y0 + t1 * dy
end

function Sys.rainbow(phase)
    local p = phase or 0.0
    local r = math.floor(math.sin(p) * 127.5 + 127.5)
    local g = math.floor(math.sin(p + 2.0943951) * 127.5 + 127.5)
    local b = math.floor(math.sin(p + 4.1887902) * 127.5 + 127.5)
    return r, g, b
end

Sys.init_natives()
Sys.auto_w, Sys.auto_h = Sys.detect_resolution()
Sys.scr_w, Sys.scr_h = Sys.auto_w, Sys.auto_h

-- ============================================================================
-- [STAGE 3] Config Files (`bubblewrap_menu_<sec>.cfg`) in `scripts\bubblewrap_menu`
-- ============================================================================
local Cfg = {
    root = "C:\\Users\\FemBoy\\Lexis\\Grand Theft Auto V\\scripts\\bubblewrap_menu",
    sections = { "player", "vehicle", "aimbot", "triggerbot", "colors", "hotkeys", "settings" },
    schema = {
        enabled                = { type = "bool",   default = true,       section = "player" },
        names                  = { type = "bool",   default = true,       section = "player" },
        skeleton               = { type = "bool",   default = true,       section = "player" },
        skel_style             = { type = "choice", default = "Classic",  section = "player", choices = Env.styles.skeleton },
        bone_outline           = { type = "bool",   default = true,       section = "player" },
        rgb_skeleton           = { type = "bool",   default = false,      section = "player" },
        box                    = { type = "bool",   default = true,       section = "player" },
        box_style              = { type = "choice", default = "Corners",  section = "player", choices = Env.styles.box },
        health                 = { type = "bool",   default = true,       section = "player" },
        armour                 = { type = "bool",   default = true,       section = "player" },
        distance               = { type = "bool",   default = true,       section = "player" },
        show_self              = { type = "bool",   default = true,       section = "player" },
        range                  = { type = "number", default = 10000,      min = 10,   max = 10000, step = 10, section = "player" },
        size                   = { type = "number", default = 24,         min = 10,   max = 100,   step = 1,  section = "player" },
        skel_size              = { type = "number", default = 25,         min = 1,    max = 100,   step = 1,  section = "player" },
        bar_size               = { type = "number", default = 2,          min = 1,    max = 10,    step = 1,  section = "player" },
        name_offset_x          = { type = "number", default = 0.0,        min = -600, max = 600,   step = 1,  section = "player" },
        name_offset_y          = { type = "number", default = 0.0,        min = -400, max = 400,   step = 1,  section = "player" },
        box_offset_x           = { type = "number", default = 0.0,        min = -600, max = 600,   step = 1,  section = "player" },
        box_offset_y           = { type = "number", default = 0.0,        min = -400, max = 400,   step = 1,  section = "player" },
        hp_offset_x            = { type = "number", default = 0.0,        min = -600, max = 600,   step = 1,  section = "player" },
        hp_offset_y            = { type = "number", default = 0.0,        min = -400, max = 400,   step = 1,  section = "player" },
        arm_offset_x           = { type = "number", default = 0.0,        min = -600, max = 600,   step = 1,  section = "player" },
        arm_offset_y           = { type = "number", default = 0.0,        min = -400, max = 400,   step = 1,  section = "player" },

        veh_enabled            = { type = "bool",   default = true,       section = "vehicle" },
        veh_names              = { type = "bool",   default = true,       section = "vehicle" },
        veh_skeleton           = { type = "bool",   default = true,       section = "vehicle" },
        veh_skel_style         = { type = "choice", default = "Classic",  section = "vehicle", choices = Env.styles.skeleton },
        veh_bone_outline       = { type = "bool",   default = true,       section = "vehicle" },
        veh_rgb_skeleton       = { type = "bool",   default = false,      section = "vehicle" },
        veh_box                = { type = "bool",   default = true,       section = "vehicle" },
        veh_box_style          = { type = "choice", default = "Corners",  section = "vehicle", choices = Env.styles.box },
        veh_health             = { type = "bool",   default = true,       section = "vehicle" },
        veh_armour             = { type = "bool",   default = true,       section = "vehicle" },
        veh_distance           = { type = "bool",   default = true,       section = "vehicle" },
        veh_show_self          = { type = "bool",   default = true,       section = "vehicle" },
        veh_range              = { type = "number", default = 10000,      min = 10,   max = 10000, step = 10, section = "vehicle" },
        veh_size               = { type = "number", default = 26,         min = 10,   max = 100,   step = 1,  section = "vehicle" },
        veh_skel_size          = { type = "number", default = 25,         min = 1,    max = 100,   step = 1,  section = "vehicle" },
        veh_bar_size           = { type = "number", default = 2,          min = 1,    max = 10,    step = 1,  section = "vehicle" },
        veh_name_offset_x      = { type = "number", default = 0.0,        min = -600, max = 600,   step = 1,  section = "vehicle" },
        veh_name_offset_y      = { type = "number", default = 0.0,        min = -400, max = 400,   step = 1,  section = "vehicle" },
        veh_box_offset_x       = { type = "number", default = 0.0,        min = -600, max = 600,   step = 1,  section = "vehicle" },
        veh_box_offset_y       = { type = "number", default = 0.0,        min = -400, max = 400,   step = 1,  section = "vehicle" },
        veh_hp_offset_x        = { type = "number", default = 0.0,        min = -600, max = 600,   step = 1,  section = "vehicle" },
        veh_hp_offset_y        = { type = "number", default = 0.0,        min = -400, max = 400,   step = 1,  section = "vehicle" },
        veh_arm_offset_x       = { type = "number", default = 0.0,        min = -600, max = 600,   step = 1,  section = "vehicle" },
        veh_arm_offset_y       = { type = "number", default = 0.0,        min = -400, max = 400,   step = 1,  section = "vehicle" },

        aim_enabled            = { type = "bool",   default = false,      section = "aimbot" },
        aim_draw_fov           = { type = "bool",   default = true,       section = "aimbot" },
        aim_ignore_veh         = { type = "bool",   default = false,      section = "aimbot" },
        aim_vis_check          = { type = "bool",   default = false,      section = "aimbot" },
        aim_bone               = { type = "choice", default = "Head",     section = "aimbot", choices = Env.styles.aim_bone },
        aim_priority           = { type = "choice", default = "FOV",      section = "aimbot", choices = Env.styles.aim_prio },
        aim_fov                = { type = "number", default = 220,        min = 10,   max = 600,   step = 5,  section = "aimbot" },
        aim_smooth             = { type = "number", default = 6,          min = 1,    max = 50,    step = 1,  section = "aimbot" },
        aim_range              = { type = "number", default = 300,        min = 10,   max = 1000,  step = 10, section = "aimbot" },
        aim_key                = { type = "number", default = 0x02,       min = 1,    max = 254,   step = 1,  section = "aimbot" },

        trig_enabled           = { type = "bool",   default = false,      section = "triggerbot" },
        trig_only_aiming       = { type = "bool",   default = false,      section = "triggerbot" },
        trig_ignore_veh        = { type = "bool",   default = false,      section = "triggerbot" },
        trig_vis_check         = { type = "bool",   default = false,      section = "triggerbot" },
        trig_delay_ms          = { type = "number", default = 0,          min = 0,    max = 500,   step = 5,  section = "triggerbot" },
        trig_interval_ms       = { type = "number", default = 75,         min = 20,   max = 1000,  step = 10, section = "triggerbot" },
        trig_range             = { type = "number", default = 300,        min = 10,   max = 1000,  step = 10, section = "triggerbot" },

        menu_key               = { type = "number", default = 0x2D,       min = 1,    max = 254,   step = 1,  section = "hotkeys" },
        hotkey_hud_enabled     = { type = "bool",   default = true,       section = "hotkeys" },
        hotkey_hud_when_hidden = { type = "bool",   default = true,       section = "hotkeys" },
        hud_x                  = { type = "number", default = 16,         min = 0,    max = 4000,  step = 1,  section = "hotkeys" },
        hud_y                  = { type = "number", default = 16,         min = 0,    max = 2500,  step = 1,  section = "hotkeys" },

        res_mode               = { type = "choice", default = "2K",       section = "settings", choices = { "2K", "1080p", "4K", "auto" } },
        theme_name             = { type = "choice", default = "Midnight", section = "settings", choices = Env.styles.themes },
        ui_panel_alpha         = { type = "number", default = 188,        min = 80,   max = 255,   step = 1,  section = "settings" },
        theme_glow             = { type = "number", default = 140,        min = 0,    max = 255,   step = 1,  section = "settings" }
    },
    color_defaults = {
        skeleton = { r = 96,  g = 178, b = 255 },
        name     = { r = 244, g = 248, b = 255 },
        box      = { r = 120, g = 210, b = 255 },
        health   = { r = 62,  g = 224, b = 124 },
        armor    = { r = 88,  g = 158, b = 255 },
        fov      = { r = 96,  g = 205, b = 255 }
    },
    presets = {
        Midnight = {
            accent = { r = 64,  g = 142, b = 255 },
            glow   = { r = 42,  g = 98,  b = 210 },
            panel  = { r = 13,  g = 16,  b = 23  },
            header = { r = 19,  g = 24,  b = 35  },
            colors = {
                skeleton = { r = 96,  g = 178, b = 255 },
                name     = { r = 244, g = 248, b = 255 },
                box      = { r = 120, g = 210, b = 255 },
                health   = { r = 62,  g = 224, b = 124 },
                armor    = { r = 88,  g = 158, b = 255 },
                fov      = { r = 96,  g = 205, b = 255 }
            }
        },
        VioletVK = {
            accent = { r = 186, g = 92,  b = 255 },
            glow   = { r = 148, g = 58,  b = 224 },
            panel  = { r = 20,  g = 13,  b = 30  },
            header = { r = 30,  g = 19,  b = 44  },
            colors = {
                skeleton = { r = 206, g = 124, b = 255 },
                name     = { r = 250, g = 242, b = 255 },
                box      = { r = 232, g = 112, b = 245 },
                health   = { r = 82,  g = 232, b = 152 },
                armor    = { r = 152, g = 132, b = 255 },
                fov      = { r = 206, g = 124, b = 255 }
            }
        },
        Crimson = {
            accent = { r = 232, g = 64,  b = 92  },
            glow   = { r = 185, g = 36,  b = 64  },
            panel  = { r = 20,  g = 12,  b = 15  },
            header = { r = 30,  g = 17,  b = 22  },
            colors = {
                skeleton = { r = 255, g = 92,  b = 118 },
                name     = { r = 255, g = 242, b = 245 },
                box      = { r = 255, g = 120, b = 140 },
                health   = { r = 72,  g = 224, b = 132 },
                armor    = { r = 255, g = 155, b = 90  },
                fov      = { r = 255, g = 92,  b = 118 }
            }
        },
        Emerald = {
            accent = { r = 38,  g = 198, b = 126 },
            glow   = { r = 22,  g = 154, b = 96  },
            panel  = { r = 11,  g = 20,  b = 17  },
            header = { r = 16,  g = 30,  b = 25  },
            colors = {
                skeleton = { r = 66,  g = 235, b = 158 },
                name     = { r = 240, g = 255, b = 248 },
                box      = { r = 105, g = 242, b = 182 },
                health   = { r = 80,  g = 245, b = 145 },
                armor    = { r = 72,  g = 185, b = 255 },
                fov      = { r = 66,  g = 235, b = 158 }
            }
        },
        Cyber = {
            accent = { r = 0,   g = 212, b = 255 },
            glow   = { r = 168, g = 42,  b = 196 },
            panel  = { r = 12,  g = 15,  b = 28  },
            header = { r = 18,  g = 23,  b = 42  },
            colors = {
                skeleton = { r = 0,   g = 225, b = 255 },
                name     = { r = 245, g = 250, b = 255 },
                box      = { r = 255, g = 85,  b = 205 },
                health   = { r = 65,  g = 235, b = 140 },
                armor    = { r = 0,   g = 185, b = 255 },
                fov      = { r = 0,   g = 225, b = 255 }
            }
        },
        Amber = {
            accent = { r = 242, g = 156, b = 38  },
            glow   = { r = 194, g = 104, b = 18  },
            panel  = { r = 21,  g = 17,  b = 12  },
            header = { r = 32,  g = 25,  b = 17  },
            colors = {
                skeleton = { r = 255, g = 182, b = 66  },
                name     = { r = 255, g = 248, b = 236 },
                box      = { r = 255, g = 202, b = 98  },
                health   = { r = 72,  g = 224, b = 132 },
                armor    = { r = 245, g = 145, b = 52  },
                fov      = { r = 255, g = 182, b = 66  }
            }
        }
    },
    data = {
        colors = {}
    }
}

function Cfg.normalize_choice(val, list, fallback)
    local arr = (type(list) == "table" and #list > 0) and list or { "Classic" }
    local fb = fallback or arr[1]
    local s = tostring(val or fb):lower()
    if s == "bone_mode" or s == "bonemode" or s == "solid" then return "Classic" end
    if s == "bars" or s == "ticks" or s == "dashes" then return "Stripes" end
    for i = 1, #arr do
        if arr[i]:lower() == s then return arr[i] end
    end
    return fb
end

function Cfg.cycle_choice(cur_val, list, fallback, dir)
    local arr = (type(list) == "table" and #list > 0) and list or { "Classic" }
    local cur = Cfg.normalize_choice(cur_val, arr, fallback)
    local idx = 1
    for i = 1, #arr do
        if arr[i] == cur then idx = i; break end
    end
    local delta = (dir and dir < 0) and -1 or 1
    return arr[((idx - 1 + delta) % #arr) + 1]
end

function Cfg.skel_style(v) return Cfg.normalize_choice(v, Env.styles.skeleton, "Classic") end
function Cfg.box_style(v)  return Cfg.normalize_choice(v, Env.styles.box, "Corners") end
function Cfg.aim_bone(v)   return Cfg.normalize_choice(v, Env.styles.aim_bone, "Head") end
function Cfg.aim_prio(v)   return Cfg.normalize_choice(v, Env.styles.aim_prio, "FOV") end

function Cfg.theme_choices()
    local list = {}
    for i = 1, #Env.styles.themes do
        list[#list + 1] = Env.styles.themes[i]
    end
    local disk_files = Gen.scan_theme_files()
    for i = 1, #disk_files do
        local name = disk_files[i].name
        local exists = false
        for j = 1, #list do
            if list[j]:lower() == name:lower() then exists = true; break end
        end
        if not exists then
            list[#list + 1] = name
        end
    end
    return list
end

function Cfg.theme_file_for_name(theme_name)
    local target = tostring(theme_name or ""):lower()
    if target == "" then return nil end
    local disk_files = Gen.scan_theme_files()
    for i = 1, #disk_files do
        if disk_files[i].name:lower() == target then
            return disk_files[i]
        end
    end
    return nil
end

function Cfg.sanitize_key(key, raw)
    local spec = Cfg.schema[key]
    if not spec then return raw end
    if spec.type == "bool" then
        if type(raw) == "boolean" then return raw end
        if type(raw) == "string" then
            local low = raw:lower()
            if low == "true" or low == "1" then return true end
            if low == "false" or low == "0" then return false end
        end
        if type(raw) == "number" then return raw ~= 0 end
        return spec.default
    elseif spec.type == "number" then
        local n = tonumber(raw)
        if not n or n ~= n then return spec.default end
        local lo = spec.min or -100000
        local hi = spec.max or 100000
        local st = spec.step or 1
        n = Sys.clamp(n, lo, hi)
        if st > 0 then
            n = math.floor((n / st) + 0.5) * st
            n = Sys.clamp(n, lo, hi)
        end
        return n
    elseif spec.type == "choice" then
        local list = (key == "theme_name") and Cfg.theme_choices() or spec.choices
        return Cfg.normalize_choice(raw, list, spec.default)
    end
    return spec.default
end

function Cfg.bind_root(root_dir)
    Cfg.root = root_dir or Gen.resolve_root()
end

function Cfg.section_file(section)
    local dir = (Cfg.root and Cfg.root ~= "") and Cfg.root or Gen.resolve_root()
    return Gen.join(dir, "bubblewrap_menu_" .. tostring(section) .. ".cfg")
end

function Cfg.init_defaults()
    for key, spec in pairs(Cfg.schema) do
        Cfg.data[key] = { value = spec.default }
    end
    for part, def in pairs(Cfg.color_defaults) do
        Cfg.data.colors[part] = { r = def.r, g = def.g, b = def.b }
    end
end

function Cfg.format_key_value(key)
    local spec = Cfg.schema[key]
    local entry = Cfg.data[key]
    if not spec or not entry then return nil end
    local val = Cfg.sanitize_key(key, entry.value)
    entry.value = val
    return (spec.type == "bool") and (val and "true" or "false") or tostring(val)
end

function Cfg.format_color_value(part)
    local col = Cfg.data.colors[part]
    if not col then return nil end
    return string.format("%d,%d,%d",
        math.floor(Sys.clamp(tonumber(col.r) or 255, 0, 255) + 0.5),
        math.floor(Sys.clamp(tonumber(col.g) or 255, 0, 255) + 0.5),
        math.floor(Sys.clamp(tonumber(col.b) or 255, 0, 255) + 0.5))
end

function Cfg.read_section_map(section)
    local map = {}
    local raw = Gen.read_file(Cfg.section_file(section))
    if not raw then return map end
    for line in raw:gmatch("[^\r\n]+") do
        local trimmed = line:match("^%s*(.-)%s*$")
        if trimmed ~= "" and not trimmed:match("^#") and not trimmed:match("^;") then
            local k, v = trimmed:match("^([%w_]+)%s*=%s*(.-)$")
            if k and k ~= "" then
                map[k] = v or ""
            end
        end
    end
    return map
end

function Cfg.write_section_map(section, map)
    local lines = { "# Bubblewrap Menu [" .. tostring(section) .. "] config" }
    if section == "colors" then
        for part in pairs(Cfg.color_defaults) do
            local ckey = "col_" .. part
            if map[ckey] ~= nil then
                lines[#lines + 1] = ckey .. " = " .. tostring(map[ckey])
            end
        end
    else
        for key, spec in pairs(Cfg.schema) do
            if spec.section == section and map[key] ~= nil then
                lines[#lines + 1] = key .. " = " .. tostring(map[key])
            end
        end
    end
    local body = table.concat(lines, "\n") .. "\n"
    return Gen.write_file(Cfg.section_file(section), body, true)
end

function Cfg.save_key(key)
    local spec = Cfg.schema[key]
    if not spec then return false end
    local sec = spec.section or "settings"
    local val_str = Cfg.format_key_value(key)
    if val_str == nil then return false end
    local map = Cfg.read_section_map(sec)
    map[key] = val_str
    return Cfg.write_section_map(sec, map)
end

function Cfg.save_color(part)
    local val_str = Cfg.format_color_value(part)
    if val_str == nil then return false end
    local map = Cfg.read_section_map("colors")
    map["col_" .. part] = val_str
    return Cfg.write_section_map("colors", map)
end

function Cfg.ensure_all_section_files()
    for i = 1, #Cfg.sections do
        local sec = Cfg.sections[i]
        local map = Cfg.read_section_map(sec)
        if sec == "colors" then
            for part in pairs(Cfg.color_defaults) do
                local ckey = "col_" .. part
                if map[ckey] == nil then
                    map[ckey] = Cfg.format_color_value(part)
                end
            end
        else
            for key, spec in pairs(Cfg.schema) do
                if spec.section == sec and map[key] == nil then
                    map[key] = Cfg.format_key_value(key)
                end
            end
        end
        Cfg.write_section_map(sec, map)
    end
end

function Cfg.save_all()
    for i = 1, #Cfg.sections do
        local sec = Cfg.sections[i]
        local map = Cfg.read_section_map(sec)
        if sec == "colors" then
            for part in pairs(Cfg.color_defaults) do
                local v = Cfg.format_color_value(part)
                if v then map["col_" .. part] = v end
            end
        else
            for key, spec in pairs(Cfg.schema) do
                if spec.section == sec then
                    local v = Cfg.format_key_value(key)
                    if v then map[key] = v end
                end
            end
        end
        Cfg.write_section_map(sec, map)
    end
end

function Cfg.load_from_disk()
    for i = 1, #Cfg.sections do
        local sec = Cfg.sections[i]
        local map = Cfg.read_section_map(sec)
        if sec == "colors" then
            for part, def in pairs(Cfg.color_defaults) do
                local raw_c = map["col_" .. part]
                if type(raw_c) == "string" then
                    local r, g, b = raw_c:match("^(%-?%d+)%s*,%s*(%-?%d+)%s*,%s*(%-?%d+)$")
                    if r and g and b then
                        Cfg.data.colors[part] = {
                            r = math.floor(Sys.clamp(tonumber(r) or def.r, 0, 255) + 0.5),
                            g = math.floor(Sys.clamp(tonumber(g) or def.g, 0, 255) + 0.5),
                            b = math.floor(Sys.clamp(tonumber(b) or def.b, 0, 255) + 0.5)
                        }
                    end
                end
            end
        else
            for key, spec in pairs(Cfg.schema) do
                if spec.section == sec and map[key] ~= nil then
                    Cfg.data[key].value = Cfg.sanitize_key(key, map[key])
                end
            end
        end
    end
    if Cfg.data.theme_name and Cfg.data.theme_name.value then
        Cfg.apply_theme(Cfg.data.theme_name.value, false)
    end
end

Cfg.init_defaults()

-- ============================================================================
-- [STAGE 4] Safe Lexis `gui.load_image` + `gui.image_rounded` Theme Engine
-- ============================================================================
local ThemeImg = {
    cache = {},
    last_error = nil
}

function ThemeImg.norm_path(p)
    if type(p) ~= "string" or p == "" then return nil end
    return p:gsub("/", "\\")
end

function ThemeImg.get_texture(file_info)
    if type(file_info) ~= "table" then return nil end
    local full_path = ThemeImg.norm_path(file_info.path)
    if not full_path then return nil end

    local key = full_path:lower()
    if ThemeImg.cache[key] ~= nil then
        return ThemeImg.cache[key] or nil
    end

    local exists = false
    if type(file) == "table" and type(file.exists) == "function" then
        local ok_e, ex = pcall(file.exists, full_path)
        exists = (ok_e and ex == true)
    end
    if not exists and type(io) == "table" and type(io.open) == "function" then
        local ok_f, f = pcall(io.open, full_path, "rb")
        if ok_f and f then
            exists = true
            pcall(f.close, f)
        end
    end

    if not exists then
        ThemeImg.cache[key] = false
        ThemeImg.last_error = "File not found: " .. full_path
        return nil
    end

    if not (gui and type(gui.load_image) == "function") then
        ThemeImg.cache[key] = false
        ThemeImg.last_error = "gui.load_image unavailable"
        return nil
    end

    local ok, tex = pcall(gui.load_image, full_path)
    if ok and tex ~= nil then
        ThemeImg.cache[key] = tex
        ThemeImg.last_error = nil
        return tex
    end

    ThemeImg.cache[key] = false
    ThemeImg.last_error = "Failed load_image: " .. full_path
    return nil
end

function ThemeImg.draw_backdrop(theme_name, x, y, w, h, alpha_byte, rounding_px)
    if not (gui and type(vec2) == "function" and type(color) == "function") then
        return false
    end
    if w <= 1 or h <= 1 then return false end

    local t_file = Cfg and Cfg.theme_file_for_name and Cfg.theme_file_for_name(theme_name) or nil
    if not t_file then return false end

    local tex = ThemeImg.get_texture(t_file)
    if not tex then return false end

    local a = math.floor(Sys.clamp(tonumber(alpha_byte) or 180, 0, 255) + 0.5)
    if a <= 0 then return false end

    local pos = vec2(x, y)
    local sz  = vec2(w, h)
    local col = color(255, 255, 255, a)
    local rnd = math.max(0.0, tonumber(rounding_px) or 0.0)

    local ok = false
    if rnd > 0.0 and type(gui.image_rounded) == "function" then
        ok = pcall(gui.image_rounded, tex, pos, sz, col, rnd)
    elseif type(gui.image) == "function" then
        ok = pcall(gui.image, tex, pos, sz, col)
    end

    if not ok then
        local k = ThemeImg.norm_path(t_file.path):lower()
        ThemeImg.cache[k] = false
        ThemeImg.last_error = "Draw failed for " .. tostring(t_file.file)
        return false
    end

    return true
end

-- ============================================================================
-- [STAGE 5] Drawing Primitives, Frame Cache, ESP, AimBot & Trigger Bot
-- ============================================================================
local Draw = {
    has_rect   = (gui and type(gui.rect) == "function" and type(vec2) == "function"),
    has_circle = (gui and type(gui.circle) == "function" and type(vec2) == "function"),
    has_text   = (gui and type(gui.text) == "function" and type(vec2) == "function"),
    has_color  = (type(color) == "function")
}

function Draw.rgb(part)
    local c = Cfg.data.colors and Cfg.data.colors[part]
    if not c then return 255, 255, 255 end
    return Sys.clamp(tonumber(c.r) or 255, 0, 255),
           Sys.clamp(tonumber(c.g) or 255, 0, 255),
           Sys.clamp(tonumber(c.b) or 255, 0, 255)
end

function Draw.theme_palette()
    local tname = Cfg.data.theme_name and tostring(Cfg.data.theme_name.value or "Midnight") or "Midnight"
    local p = Cfg.presets[tname]
    if p then
        return p.accent, p.glow, p.panel, p.header
    end
    local seed = 0
    for i = 1, #tname do
        seed = (seed * 31 + string.byte(tname, i)) % 65521
    end
    local ar, ag, ab = Sys.rainbow(seed * 0.05)
    ar, ag, ab = math.max(60, ar), math.max(60, ag), math.max(60, ab)
    return { r = ar, g = ag, b = ab },
           { r = math.floor(ar * 0.78), g = math.floor(ag * 0.78), b = math.floor(ab * 0.78) },
           { r = math.floor(ar * 0.08 + 10), g = math.floor(ag * 0.08 + 11), b = math.floor(ab * 0.08 + 18) },
           { r = math.floor(ar * 0.12 + 15), g = math.floor(ag * 0.12 + 17), b = math.floor(ab * 0.12 + 26) }
end

function Cfg.apply_theme(theme_name, persist_colors)
    local choices = Cfg.theme_choices()
    local chosen = Cfg.normalize_choice(theme_name, choices, "Midnight")
    if Cfg.data.theme_name then
        Cfg.data.theme_name.value = chosen
    end

    local t_file = Cfg.theme_file_for_name(chosen)
    if t_file then
        pcall(ThemeImg.get_texture, t_file)
    end

    local preset = Cfg.presets[chosen]
    if preset and preset.colors then
        for part, col in pairs(preset.colors) do
            Cfg.data.colors[part] = { r = col.r, g = col.g, b = col.b }
            if persist_colors and Gen.provisioned then
                Cfg.save_color(part)
            end
        end
    else
        local acc = Draw.theme_palette()
        Cfg.data.colors.skeleton = { r = acc.r, g = acc.g, b = acc.b }
        Cfg.data.colors.box      = { r = acc.r, g = acc.g, b = acc.b }
        Cfg.data.colors.fov      = { r = acc.r, g = acc.g, b = acc.b }
        if persist_colors and Gen.provisioned then
            Cfg.save_color("skeleton")
            Cfg.save_color("box")
            Cfg.save_color("fov")
        end
    end

    if Gen.provisioned then
        Cfg.save_key("theme_name")
    end
    return chosen
end

function Cfg.set(key, val, persist)
    local entry = Cfg.data[key]
    if not entry then return end
    entry.value = Cfg.sanitize_key(key, val)
    if key == "theme_name" then
        Cfg.apply_theme(entry.value, false)
    end
    if persist ~= false and Gen.provisioned then
        Cfg.save_key(key)
    end
end

function Cfg.set_color_channel(part, ch, val, persist)
    local col = Cfg.data.colors[part]
    local def = Cfg.color_defaults[part]
    if not col or not def then return end
    local n = tonumber(val)
    if not n or n ~= n then n = def[ch] or 255 end
    col[ch] = math.floor(Sys.clamp(n, 0, 255) + 0.5)
    if persist ~= false and Gen.provisioned then
        Cfg.save_color(part)
    end
end

function Draw.rect_px(x, y, w, h, r, g, b, a, rounding)
    if not Draw.has_rect or w <= 0 or h <= 0 then return false end
    local ok, obj = pcall(gui.rect, vec2(x, y), vec2(w, h))
    if not ok or not obj then return false end
    if obj.filled then obj:filled() end
    if obj.color and Draw.has_color then obj:color(color(r, g, b, a)) end
    if rounding and rounding > 0 and obj.rounding then obj:rounding(rounding) end
    if obj.draw then obj:draw() end
    return true
end

function Draw.menu_backdrop(x, y, w, h, pnl, glw, acc, pa, glow_a, s)
    Draw.rect_px(x - 1.5 * s, y - 1.5 * s, w + 3.0 * s, h + 3.0 * s, acc.r, acc.g, acc.b, 195, 10.5 * s)
    Draw.rect_px(x, y, w, h, pnl.r, pnl.g, pnl.b, pa, 9.5 * s)

    local tname = Cfg.data.theme_name and tostring(Cfg.data.theme_name.value or "") or ""
    local used_img = ThemeImg.draw_backdrop(tname, x, y, w, h, pa, 9.5 * s)

    if used_img then
        Draw.rect_px(x, y, w, h, pnl.r, pnl.g, pnl.b, math.floor(pa * 0.45), 9.5 * s)
    elseif glow_a > 2 then
        local a1 = math.floor(glow_a * 0.28)
        local a2 = math.floor(glow_a * 0.16)
        Draw.rect_px(x + w * 0.46, y + h * 0.08, w * 0.50, h * 0.54, glw.r, glw.g, glw.b, a1, 46.0 * s)
        Draw.rect_px(x + w * 0.04, y + h * 0.42, w * 0.56, h * 0.52, acc.r, acc.g, acc.b, a2, 46.0 * s)
        Draw.rect_px(x + w * 0.24, y + h * 0.22, w * 0.52, h * 0.56, glw.r, glw.g, glw.b, math.floor(glow_a * 0.12), 54.0 * s)
    end
end

function Draw.text_raw(str, x, y, r, g, b, a, px)
    if not Draw.has_text or str == "" then return end
    pcall(function()
        local obj = gui.text(str)
        if not obj then return end
        if Sys.font and obj.font then obj:font(Sys.font) end
        if obj.scale then obj:scale(px) end
        if obj.color and Draw.has_color then obj:color(color(r, g, b, a)) end
        if obj.position then obj:position(vec2(x, y)) end
        if obj.draw then obj:draw() end
    end)
end

function Draw.text(txt, x, y, r, g, b, a, px, shadow)
    local str = tostring(txt or "")
    if str == "" then return end
    local size = tonumber(px) or 14.0
    local alpha = Sys.clamp(tonumber(a) or 255, 0, 255)
    if shadow then
        local off = math.max(1.0, 1.2 * Sys.ui_scale)
        Draw.text_raw(str, x + off, y + off, 8, 10, 14, math.floor(alpha * 0.65), size)
    end
    Draw.text_raw(str, x, y, r or 255, g or 255, b or 255, alpha, size)
end

function Draw.text_width(txt, px)
    local str = tostring(txt or "")
    if str == "" then return 0.0 end
    return #str * ((tonumber(px) or 14.0) * 0.47)
end

function Draw.center_y(box_y, box_h, px)
    return box_y + math.max(0.0, ((tonumber(box_h) or 0.0) - (tonumber(px) or 14.0) * 0.68) * 0.5)
end

function Draw.line_px(x0, y0, x1, y1, thick, r, g, b, a, smooth)
    local dx, dy = x1 - x0, y1 - y0
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist < 1.0 then return end
    local t = math.max(1.4 * Sys.ui_scale, thick or (1.8 * Sys.ui_scale))
    local step_px = smooth and math.max(3.0, t * 1.1) or math.max(7.0, t * 2.4)
    local max_steps = smooth and 28 or 12
    local steps = math.max(1, math.min(max_steps, math.floor(dist / step_px)))
    local round_px = smooth and (t * 0.45) or 0.0

    for i = 0, steps do
        local f = (steps == 0) and 0.0 or (i / steps)
        Draw.rect_px(x0 + dx * f - t * 0.5, y0 + dy * f - t * 0.5, t, t, r, g, b, a, round_px)
    end
end

-- Smooth FOV circle without heavy per-segment allocations
function Draw.circle_px(cx, cy, rad, r, g, b, a, thick)
    local radius = tonumber(rad) or 0
    if radius <= 2.0 then return end
    local t = math.max(1.2 * Sys.ui_scale, thick or (1.5 * Sys.ui_scale))

    if Draw.has_circle then
        local ok = pcall(function()
            local obj = gui.circle(vec2(cx, cy), radius)
            if not obj then error("no circle") end
            if obj.color and Draw.has_color then obj:color(color(r, g, b, a)) end
            if obj.thickness then obj:thickness(t) end
            if obj.draw then obj:draw() end
        end)
        if ok then return end
    end

    local segs = 72
    local step = (math.pi * 2) / segs
    local dot_r = t * 0.5
    for i = 0, segs - 1 do
        local ang = i * step
        local px = cx + math.cos(ang) * radius
        local py = cy + math.sin(ang) * radius
        Draw.rect_px(px - dot_r, py - dot_r, t, t, r, g, b, a, dot_r)
    end
end

function Draw.bone_segment(x0, y0, x1, y1, base_thick, r, g, b, style_name, outlined, smooth)
    local dx, dy = x1 - x0, y1 - y0
    local len = math.sqrt(dx * dx + dy * dy)
    if len < (2.5 * Sys.ui_scale) then return end

    local style = Cfg.skel_style(style_name)
    local t = math.max(1.5 * Sys.ui_scale, base_thick or (2.0 * Sys.ui_scale))
    local nx, ny = -dy / len, dx / len
    local tx, ty = dx / len, dy / len

    if style == "Tapered" then
        local steps = smooth and 5 or 2
        for i = 0, steps - 1 do
            local f0, f1 = i / steps, (i + 1) / steps
            local fm = (f0 + f1) * 0.5
            local sx0, sy0 = x0 + dx * f0, y0 + dy * f0
            local sx1, sy1 = x0 + dx * f1, y0 + dy * f1
            local seg_t = math.max(1.2 * Sys.ui_scale, t * (1.25 - fm * 0.65))
            if outlined then
                local cap = math.max(1.0, 1.2 * Sys.ui_scale)
                Draw.line_px(sx0 - tx * cap, sy0 - ty * cap, sx1 + tx * cap, sy1 + ty * cap,
                    seg_t + math.max(1.6, 2.0 * Sys.ui_scale), 7, 9, 14, 235, smooth)
            end
            Draw.line_px(sx0, sy0, sx1, sy1, seg_t, r, g, b, 255, smooth)
        end
    elseif style == "CoreLine" then
        if outlined then
            local cap = math.max(1.2, 1.5 * Sys.ui_scale)
            Draw.line_px(x0 - tx * cap, y0 - ty * cap, x1 + tx * cap, y1 + ty * cap,
                t + math.max(1.8, 2.2 * Sys.ui_scale), 7, 9, 14, 240, smooth)
        end
        Draw.line_px(x0, y0, x1, y1, t, r, g, b, 255, smooth)
        Draw.line_px(x0, y0, x1, y1, math.max(1.0, t * 0.42),
            math.min(255, math.floor(r * 0.45 + 140)),
            math.min(255, math.floor(g * 0.45 + 140)),
            math.min(255, math.floor(b * 0.45 + 140)), 255, smooth)
    elseif style == "DoubleRail" then
        local off = math.max(1.6 * Sys.ui_scale, t * 0.72)
        local rail_t = math.max(1.2 * Sys.ui_scale, t * 0.52)
        local cap = math.max(1.0, 1.2 * Sys.ui_scale)
        for sign = -1, 1, 2 do
            local ox, oy = nx * off * sign, ny * off * sign
            if outlined then
                Draw.line_px(x0 + ox - tx * cap, y0 + oy - ty * cap, x1 + ox + tx * cap, y1 + oy + ty * cap,
                    rail_t + math.max(1.4, 1.8 * Sys.ui_scale), 7, 9, 14, 235, smooth)
            end
            Draw.line_px(x0 + ox, y0 + oy, x1 + ox, y1 + oy, rail_t, r, g, b, 255, smooth)
        end
    else
        if outlined then
            local cap = math.max(1.2, 1.5 * Sys.ui_scale)
            Draw.line_px(x0 - tx * cap, y0 - ty * cap, x1 + tx * cap, y1 + ty * cap,
                t + math.max(1.8, 2.2 * Sys.ui_scale), 7, 9, 14, 240, smooth)
        end
        Draw.line_px(x0, y0, x1, y1, t, r, g, b, 255, smooth)
    end
end

function Draw.joint_dot(px, py, rad_px, r, g, b, a, outlined)
    local rad = math.max(1.8 * Sys.ui_scale, rad_px or (2.6 * Sys.ui_scale))
    if outlined then
        local orad = rad + math.max(1.1, 1.3 * Sys.ui_scale)
        Draw.rect_px(px - orad, py - orad, orad * 2.0, orad * 2.0, 7, 9, 14, 235, orad)
    end
    Draw.rect_px(px - rad, py - rad, rad * 2.0, rad * 2.0, r, g, b, a, rad)
end

function Draw.joint_stripe(px, py, half_len, thick, r, g, b, a, outlined, smooth)
    local hl = math.max(3.2 * Sys.ui_scale, half_len or (5.0 * Sys.ui_scale))
    local th = math.max(1.5 * Sys.ui_scale, thick or (2.0 * Sys.ui_scale))
    if outlined then
        Draw.line_px(px - hl - 1.2 * Sys.ui_scale, py, px + hl + 1.2 * Sys.ui_scale, py,
            th + math.max(1.6, 2.0 * Sys.ui_scale), 7, 9, 14, 240, smooth)
    end
    Draw.line_px(px - hl, py, px + hl, py, th, r, g, b, a, smooth)
end

function Draw.box_style(style_name, left, right, top_y, bottom_y, r, g, b, thick_px, world_mode)
    local style = Cfg.box_style(style_name)
    if style == "Off" then return end

    local s = Sys.ui_scale
    local t_px = math.max(1.6 * s, thick_px or (2.0 * s))
    local w, h = right - left, bottom_y - top_y
    if w <= 0 or h <= 0 then return end

    local function emit(rx, ry, rw, rh, cr, cg, cb, ca)
        if rw <= 0 or rh <= 0 then return end
        local alpha = Sys.clamp(math.floor((ca or 255) + 0.5), 0, 255)
        if alpha <= 0 then return end
        if world_mode then
            Sys.draw_world_rect(rx + rw * 0.5, ry + rh * 0.5, rw, rh, cr, cg, cb, alpha)
        else
            Draw.rect_px(rx, ry, rw, rh, cr, cg, cb, alpha, 0.0)
        end
    end

    local px = world_mode and (t_px / Sys.scr_w) or t_px
    local py = world_mode and (t_px / Sys.scr_h) or t_px

    if style == "Double" then
        local c = math.min(w * 0.28, h * 0.22)
        local gx = world_mode and math.min(w * 0.12, (5.0 * s) / Sys.scr_w) or math.min(w * 0.12, 5.0 * s)
        local gy = world_mode and math.min(h * 0.12, (5.0 * s) / Sys.scr_h) or math.min(h * 0.12, 5.0 * s)
        local ic = math.max(px * 2.0, c * 0.65)
        local dr, dg, db = math.max(20, math.floor(r * 0.55)), math.max(20, math.floor(g * 0.55)), math.max(20, math.floor(b * 0.55))

        emit(left, top_y, c, py, r, g, b, 255)
        emit(left, top_y, px, c, r, g, b, 255)
        emit(right - c, top_y, c, py, r, g, b, 255)
        emit(right - px, top_y, px, c, r, g, b, 255)
        emit(left, bottom_y - py, c, py, r, g, b, 255)
        emit(left, bottom_y - c, px, c, r, g, b, 255)
        emit(right - c, bottom_y - py, c, py, r, g, b, 255)
        emit(right - px, bottom_y - c, px, c, r, g, b, 255)

        local il, ir, it, ib = left + gx, right - gx, top_y + gy, bottom_y - gy
        if ir > il and ib > it then
            emit(il, it, ic, py, dr, dg, db, 225)
            emit(il, it, px, ic, dr, dg, db, 225)
            emit(ir - ic, it, ic, py, dr, dg, db, 225)
            emit(ir - px, it, px, ic, dr, dg, db, 225)
            emit(il, ib - py, ic, py, dr, dg, db, 225)
            emit(il, ib - ic, px, ic, dr, dg, db, 225)
            emit(ir - ic, ib - py, ic, py, dr, dg, db, 225)
            emit(ir - px, ib - ic, px, ic, dr, dg, db, 225)
        end
    elseif style == "Brackets" then
        local br_h = math.max(py * 3.0, h * 0.34)
        local br_w = math.min(w * 0.16, px * 4.5)
        local tw = math.max(px * 2.5, w * 0.14)
        local th = math.max(py * 2.5, h * 0.08)
        local mid_x = (left + right) * 0.5 - tw * 0.5
        local mid_y = (top_y + bottom_y) * 0.5 - br_h * 0.5

        emit(left, mid_y, px, br_h, r, g, b, 255)
        emit(left, mid_y, br_w, py, r, g, b, 255)
        emit(left, mid_y + br_h - py, br_w, py, r, g, b, 255)
        emit(right - px, mid_y, px, br_h, r, g, b, 255)
        emit(right - br_w, mid_y, br_w, py, r, g, b, 255)
        emit(right - br_w, mid_y + br_h - py, br_w, py, r, g, b, 255)

        emit(mid_x, top_y, tw, py, r, g, b, 235)
        emit((left + right) * 0.5 - px * 0.5, top_y, px, th, r, g, b, 235)
        emit(mid_x, bottom_y - py, tw, py, r, g, b, 235)
        emit((left + right) * 0.5 - px * 0.5, bottom_y - th, px, th, r, g, b, 235)
    elseif style == "Fade" then
        local c = math.min(w * 0.30, h * 0.24)
        local alphas = { 255, 175, 100, 42 }
        local sw, sh = c / 4, c / 4
        for idx = 1, 4 do
            local a = alphas[idx]
            local sx0, sx1 = left + (idx - 1) * sw, right - idx * sw
            local sy0, sy1 = top_y + (idx - 1) * sh, bottom_y - idx * sh
            emit(sx0, top_y, sw, py, r, g, b, a)
            emit(sx1, top_y, sw, py, r, g, b, a)
            emit(sx0, bottom_y - py, sw, py, r, g, b, a)
            emit(sx1, bottom_y - py, sw, py, r, g, b, a)
            emit(left, sy0, px, sh, r, g, b, a)
            emit(left, sy1, px, sh, r, g, b, a)
            emit(right - px, sy0, px, sh, r, g, b, a)
            emit(right - px, sy1, px, sh, r, g, b, a)
        end
    else
        local hw, vh = w * 0.28, h * 0.22
        emit(left, top_y, hw, py, r, g, b, 255)
        emit(left, top_y, px, vh, r, g, b, 255)
        emit(right - hw, top_y, hw, py, r, g, b, 255)
        emit(right - px, top_y, px, vh, r, g, b, 255)
        emit(left, bottom_y - py, hw, py, r, g, b, 255)
        emit(left, bottom_y - vh, px, vh, r, g, b, 255)
        emit(right - hw, bottom_y - py, hw, py, r, g, b, 255)
        emit(right - px, bottom_y - vh, px, vh, r, g, b, 255)
    end
end

-- Per-frame cache so 31 players don't trigger duplicate native calls across ESP, AimBot & TriggerBot
local FrameCache = {
    valid = false,
    my_id = nil,
    my_ped = 0,
    my_name = "Self",
    my_pos = nil,
    players = {},
    player_ped_map = {},
    skel_rgb = { 96, 178, 255 },
    name_rgb = { 244, 248, 255 },
    box_rgb  = { 120, 210, 255 },
    hp_rgb   = { 62, 224, 124 },
    arm_rgb  = { 88, 158, 255 },
    fov_rgb  = { 96, 205, 255 }
}

local Esp = {}

function Esp.bone_px(dist_m, skel_val)
    local v = Sys.clamp(tonumber(skel_val) or 25.0, 1.0, 100.0)
    local base_px = (1.6 + ((v - 1.0) / 99.0) * 2.8) * Sys.ui_scale
    local df = ((dist_m or 0.0) > 60.0) and math.max(0.6, 60.0 / dist_m) or 1.0
    return math.max(1.2 * Sys.ui_scale, base_px * df)
end

function Esp.self_info()
    if FrameCache.valid then
        return FrameCache.my_id, FrameCache.my_ped, FrameCache.my_name, FrameCache.my_pos
    end
    local id, ped, name = nil, 0, nil
    if players and type(players.me) == "function" then
        local ok, me = pcall(players.me)
        if ok and me then
            id = tonumber(Sys.field(me, "id"))
            ped = tonumber(Sys.field(me, "ped")) or 0
            name = Sys.to_string(Sys.field(me, "name"))
        end
    end
    if not id or id < 0 or id > 31 then id = Sys.int("player_id", Env.hashes.player_id) end
    if ped <= 0 then ped = Sys.int("player_ped_id", Env.hashes.player_ped) end
    if not name or name == "" then name = "Self" end
    local pos = (ped > 0 and Sys.entity_exists(ped)) and Sys.entity_coords(ped) or nil
    return id, ped, name, pos
end

function FrameCache.refresh()
    FrameCache.now = Sys.now
    FrameCache.players = {}
    FrameCache.player_ped_map = {}

    local id, ped, name = nil, 0, nil
    if players and type(players.me) == "function" then
        local ok, me = pcall(players.me)
        if ok and me then
            id = tonumber(Sys.field(me, "id"))
            ped = tonumber(Sys.field(me, "ped")) or 0
            name = Sys.to_string(Sys.field(me, "name"))
        end
    end
    if not id or id < 0 or id > 31 then id = Sys.int("player_id", Env.hashes.player_id) end
    if ped <= 0 then ped = Sys.int("player_ped_id", Env.hashes.player_ped) end
    if not name or name == "" then name = "Self" end

    local pos = (ped > 0 and Sys.entity_exists(ped)) and Sys.entity_coords(ped) or nil
    FrameCache.my_id = id
    FrameCache.my_ped = ped
    FrameCache.my_name = name
    FrameCache.my_pos = pos

    local seen_ids = {}
    local seen_peds = {}
    if id and id >= 0 then seen_ids[id] = true end
    if ped and ped > 0 then seen_peds[ped] = true end

    local function push_player(pid, pped, pname)
        if not pped or pped <= 0 then return end
        if pid == id or pped == ped then return end
        if pid and seen_ids[pid] then return end
        if seen_peds[pped] then return end
        if not Sys.entity_exists(pped) then return end
        if pid and pid >= 0 then seen_ids[pid] = true end
        seen_peds[pped] = true
        FrameCache.player_ped_map[pped] = pid or true
        FrameCache.players[#FrameCache.players + 1] = {
            id = pid,
            ped = pped,
            name = pname,
            pos = nil,
            dist = nil,
            dead = nil,
            in_veh = nil
        }
    end

    if players and type(players.list) == "function" then
        local ok, list = pcall(players.list)
        if ok and type(list) == "table" then
            for _, p in pairs(list) do
                local pid = tonumber(Sys.field(p, "id"))
                if pid and pid >= 0 and pid <= 31
                    and Sys.field(p, "connected") ~= false and Sys.field(p, "exists") ~= false then
                    local pped = tonumber(Sys.field(p, "ped")) or 0
                    if pped <= 0 then
                        pped = Sys.int("get_player_ped", Env.hashes.get_player_ped, pid)
                    end
                    local pname = Sys.to_string(Sys.field(p, "name"))
                    push_player(pid, pped, pname)
                end
            end
        end
    else
        for pid = 0, 31 do
            if pid ~= id and not seen_ids[pid] and Sys.bool("network_is_player_active", Env.hashes.player_active, pid) then
                local pped = Sys.int("get_player_ped", Env.hashes.get_player_ped, pid)
                push_player(pid, pped, nil)
            end
        end
    end

    FrameCache.skel_rgb[1], FrameCache.skel_rgb[2], FrameCache.skel_rgb[3] = Draw.rgb("skeleton")
    FrameCache.name_rgb[1], FrameCache.name_rgb[2], FrameCache.name_rgb[3] = Draw.rgb("name")
    FrameCache.box_rgb[1],  FrameCache.box_rgb[2],  FrameCache.box_rgb[3]  = Draw.rgb("box")
    FrameCache.hp_rgb[1],   FrameCache.hp_rgb[2],   FrameCache.hp_rgb[3]   = Draw.rgb("health")
    FrameCache.arm_rgb[1],  FrameCache.arm_rgb[2],  FrameCache.arm_rgb[3]  = Draw.rgb("armor")
    FrameCache.fov_rgb[1],  FrameCache.fov_rgb[2],  FrameCache.fov_rgb[3]  = Draw.rgb("fov")
    FrameCache.valid = true
end

function Esp.iter_player_peds(my_id, my_ped)
    if FrameCache.valid then
        return FrameCache.players
    end
    FrameCache.refresh()
    return FrameCache.players
end

function Esp.ped_screen_rect(ped, pos)
    if not ped or not pos then return nil end
    local hb = Sys.bone_coords(ped, Env.bones.head)
    local nb = Sys.bone_coords(ped, Env.bones.neck)
    local pb = Sys.bone_coords(ped, Env.bones.pelvis)
    local fl = Sys.bone_coords(ped, Env.bones.lfoot)
    local fr = Sys.bone_coords(ped, Env.bones.rfoot)

    local ax = (pb and pb.x) or (nb and nb.x) or pos.x
    local ay = (pb and pb.y) or (nb and nb.y) or pos.y
    local top_z = (hb and (hb.z + 0.16)) or (nb and (nb.z + 0.40)) or (pos.z + 1.15)
    local bot_z = (fl and fr and (math.min(fl.z, fr.z) - 0.04))
        or ((fl or fr) and ((fl or fr).z - 0.04))
        or (pos.z - 0.88)

    local s_top = Sys.world_to_screen({ x = ax, y = ay, z = top_z })
    local s_bot = Sys.world_to_screen({ x = ax, y = ay, z = bot_z })
    if not s_top or not s_bot then return nil end

    local ty_px = math.min(s_top.y, s_bot.y) * Sys.scr_h
    local by_px = math.max(s_top.y, s_bot.y) * Sys.scr_h
    local h_px = by_px - ty_px
    if h_px < 4.0 then return nil end

    local cx_px = ((s_top.x + s_bot.x) * 0.5) * Sys.scr_w
    local w_px = math.max(12.0, h_px * 0.46)
    return {
        left   = cx_px - w_px * 0.5,
        right  = cx_px + w_px * 0.5,
        top    = ty_px,
        bottom = by_px,
        cx     = cx_px,
        cy     = (ty_px + by_px) * 0.5
    }
end

function Esp.draw_segment(a, b, dist_m, idx, skel_val, rgb_on, style, outlined)
    if not a or not b then return end
    local sa, sb = Sys.world_to_screen(a), Sys.world_to_screen(b)
    if not sa or not sb then return end
    local cx0, cy0, cx1, cy1 = Sys.clip_segment(sa.x, sa.y, sb.x, sb.y)
    if not cx0 then return end

    local px0, py0 = cx0 * Sys.scr_w, cy0 * Sys.scr_h
    local px1, py1 = cx1 * Sys.scr_w, cy1 * Sys.scr_h
    local dx, dy = px1 - px0, py1 - py0
    if (dx * dx + dy * dy) < (3.0 * Sys.ui_scale * Sys.ui_scale) then return end

    local r, g, bl = FrameCache.skel_rgb[1], FrameCache.skel_rgb[2], FrameCache.skel_rgb[3]
    if rgb_on then r, g, bl = Sys.rainbow(Sys.now * 3.2 + (idx or 0) * 0.35) end
    Draw.bone_segment(px0, py0, px1, py1, Esp.bone_px(dist_m, skel_val), r, g, bl, style, outlined, false)
end

function Esp.draw_joint(pt, dist_m, idx, skel_val, rgb_on, outlined, stripe)
    if not pt then return end
    local sc = Sys.world_to_screen(pt)
    if not sc or sc.x < 0.0 or sc.x > 1.0 or sc.y < 0.0 or sc.y > 1.0 then return end
    local thick = Esp.bone_px(dist_m, skel_val)
    local r, g, bl = FrameCache.skel_rgb[1], FrameCache.skel_rgb[2], FrameCache.skel_rgb[3]
    if rgb_on then r, g, bl = Sys.rainbow(Sys.now * 3.2 + (idx or 0) * 0.35) end
    if stripe then
        Draw.joint_stripe(sc.x * Sys.scr_w, sc.y * Sys.scr_h, thick * 2.4, thick * 0.95, r, g, bl, 255, outlined, false)
    else
        Draw.joint_dot(sc.x * Sys.scr_w, sc.y * Sys.scr_h, thick * 1.15, r, g, bl, 255, outlined)
    end
end

function Esp.draw_bar(x, top_y, bot_y, width, frac, r, g, b, ox_px, oy_px)
    frac = Sys.clamp(frac, 0.0, 1.0)
    local dx = (tonumber(ox_px) or 0.0) / Sys.scr_w
    local dy = (tonumber(oy_px) or 0.0) / Sys.scr_h
    local min_y = math.min(top_y, bot_y) + dy
    local max_y = math.max(top_y, bot_y) + dy
    local h = max_y - min_y
    if h <= 0 then return end
    Sys.draw_world_rect(x + dx, (min_y + max_y) * 0.5, width, h, 10, 12, 16, 130)
    if frac > 0 then
        local fh = h * frac
        Sys.draw_world_rect(x + dx, max_y - fh * 0.5, width, fh, r, g, b, 255)
    end
end

function Esp.draw_caption(text_str, cx_norm, top_norm, bw_norm, size, ox, oy, is_veh)
    if not text_str or text_str == "" or not cx_norm or not top_norm then return end
    local cx_px = cx_norm * Sys.scr_w
    local top_py = top_norm * Sys.scr_h
    local bw_px = (bw_norm or 0.14) * Sys.scr_w

    local desired = math.max(14.0 * Sys.ui_scale, math.min(64.0 * Sys.ui_scale, (tonumber(size) or 24.0) * Sys.ui_scale))
    local span_mult = is_veh and 2.6 or 1.45
    local min_span = (is_veh and 130.0 or 64.0) * Sys.ui_scale
    local max_span = math.max(min_span, bw_px * span_mult)
    local char_w = 0.49
    local font_px = math.max(13.0 * Sys.ui_scale, math.min(desired, max_span / math.max(1, #text_str * char_w)))
    local est_w = #text_str * (font_px * char_w)

    local tx = Sys.clamp((cx_px - est_w * 0.5) + (tonumber(ox) or 0.0) * Sys.ui_scale,
        4.0 * Sys.ui_scale, math.max(4.0 * Sys.ui_scale, Sys.scr_w - est_w - 4.0 * Sys.ui_scale))
    local ty = Sys.clamp((top_py - font_px - 2.0 * Sys.ui_scale) + (tonumber(oy) or 0.0) * Sys.ui_scale,
        4.0 * Sys.ui_scale, math.max(4.0 * Sys.ui_scale, Sys.scr_h - font_px - 4.0 * Sys.ui_scale))

    Draw.text(text_str, tx, ty, FrameCache.name_rgb[1], FrameCache.name_rgb[2], FrameCache.name_rgb[3], 255, font_px, true)
end

function Esp.render_entity(entry, my_id, my_pos)
    local id, ped, label = entry.id, entry.ped, entry.name
    if not ped or ped <= 0 then return end

    if entry.dead == nil then
        entry.dead = Sys.bool("is_ped_dead_or_dying", Env.hashes.ped_dead, ped, true)
    end
    if entry.dead then return end

    if not entry.pos then
        entry.pos = Sys.entity_coords(ped)
    end
    local pos = entry.pos
    if not pos then return end

    if not entry.dist then
        local dx, dy, dz = pos.x - my_pos.x, pos.y - my_pos.y, pos.z - my_pos.z
        entry.dist = math.sqrt(dx * dx + dy * dy + dz * dz)
    end
    local dist_m = entry.dist

    if entry.in_veh == nil then
        entry.in_veh = Sys.bool("is_ped_in_any_vehicle", Env.hashes.ped_in_vehicle, ped, false)
    end
    local in_veh = entry.in_veh
    local pfx = in_veh and "veh_" or ""
    local d = Cfg.data

    if not d[pfx .. "enabled"].value then return end
    if id == my_id and not d[pfx .. "show_self"].value then return end
    if dist_m > (tonumber(d[pfx .. "range"].value) or 10000) then return end

    local skel_style = Cfg.skel_style(d[pfx .. "skel_style"].value)
    local box_style  = Cfg.box_style(d[pfx .. "box_style"].value)
    local want_skel  = d[pfx .. "skeleton"].value == true
    local want_box   = d[pfx .. "box"].value == true
    local want_hp    = d[pfx .. "health"].value == true
    local want_arm   = d[pfx .. "armour"].value == true
    local want_name  = d[pfx .. "names"].value == true
    local want_dist  = d[pfx .. "distance"].value == true

    if not (want_skel or want_box or want_hp or want_arm or want_name or want_dist) then return end

    local cache = {}
    local function bone(b_id)
        if cache[b_id] == nil then
            local v = Sys.bone_coords(ped, b_id)
            if not v then
                if b_id == Env.bones.head   then v = { x = pos.x, y = pos.y, z = pos.z + 0.68 }
                elseif b_id == Env.bones.neck   then v = { x = pos.x, y = pos.y, z = pos.z + 0.52 }
                elseif b_id == Env.bones.spine2 then v = { x = pos.x, y = pos.y, z = pos.z + 0.36 }
                elseif b_id == Env.bones.spine1 then v = { x = pos.x, y = pos.y, z = pos.z + 0.16 }
                elseif b_id == Env.bones.pelvis then v = { x = pos.x, y = pos.y, z = pos.z - 0.05 }
                end
            end
            cache[b_id] = v or false
        end
        return cache[b_id] or nil
    end

    local box_cx, box_top_y, box_w = nil, nil, nil
    if want_box or want_hp or want_arm or want_name or want_dist then
        local hb = Sys.bone_coords(ped, Env.bones.head)
        local nb = Sys.bone_coords(ped, Env.bones.neck)
        local pb = Sys.bone_coords(ped, Env.bones.pelvis)
        local fl = Sys.bone_coords(ped, Env.bones.lfoot)
        local fr = Sys.bone_coords(ped, Env.bones.rfoot)

        local ax = (pb and pb.x) or (nb and nb.x) or pos.x
        local ay = (pb and pb.y) or (nb and nb.y) or pos.y

        local top_z = in_veh
            and ((hb and (hb.z + 0.14)) or (nb and (nb.z + 0.36)) or (pos.z + 0.85))
            or ((hb and (hb.z + 0.16)) or (nb and (nb.z + 0.40)) or (pos.z + 1.15))

        local bot_z
        if in_veh then
            bot_z = (pb and (pb.z - 0.35)) or (pos.z - 0.45)
        elseif fl and fr then
            bot_z = math.min(fl.z, fr.z) - 0.04
        else
            bot_z = ((fl or fr) and ((fl or fr).z - 0.04)) or (pos.z - 0.88)
        end

        local s_top = Sys.world_to_screen({ x = ax, y = ay, z = top_z })
        local s_bot = Sys.world_to_screen({ x = ax, y = ay, z = bot_z })

        if s_top or s_bot then
            local approx_h = Sys.clamp(0.45 / math.max(1.0, dist_m), 0.015, 0.95)
            local ty = s_top and s_top.y or (s_bot.y - approx_h)
            local by = s_bot and s_bot.y or (s_top.y + approx_h)
            local h = math.abs(by - ty)
            if h > 0.004 and h < 1.8 then
                local w = h * 0.42 * (Sys.scr_h / Sys.scr_w)
                local cx = Sys.clamp((s_top and s_bot) and ((s_top.x + s_bot.x) * 0.5) or ((s_top or s_bot).x), 0.0, 1.0)
                local min_y = Sys.clamp(math.min(ty, by), 0.0, 1.0)
                local max_y = Sys.clamp(math.max(ty, by), 0.0, 1.0)
                box_cx, box_top_y, box_w = cx, min_y, w

                if max_y > min_y then
                    local bar_px = Sys.clamp(tonumber(d[pfx .. "bar_size"].value) or 2, 1, 10) * Sys.ui_scale
                    local bar_w = bar_px / Sys.scr_w
                    local bar_gap = math.max(4.0 / Sys.scr_w, bar_w + (2.0 / Sys.scr_w))
                    local box_ox = (tonumber(d[pfx .. "box_offset_x"].value) or 0.0) * Sys.ui_scale
                    local box_oy = (tonumber(d[pfx .. "box_offset_y"].value) or 0.0) * Sys.ui_scale

                    if want_box then
                        local dx_n, dy_n = box_ox / Sys.scr_w, box_oy / Sys.scr_h
                        Draw.box_style(box_style, cx + dx_n - w * 0.5, cx + dx_n + w * 0.5,
                            min_y + dy_n, max_y + dy_n, FrameCache.box_rgb[1], FrameCache.box_rgb[2], FrameCache.box_rgb[3],
                            2.0 * Sys.ui_scale, true)
                    end
                    if want_hp then
                        local hp = Sys.int("get_entity_health", Env.hashes.entity_health, ped)
                        local mhp = Sys.int("get_entity_max_health", Env.hashes.entity_max_health, ped)
                        if mhp <= 100 then mhp = 200 end
                        Esp.draw_bar(cx - w * 0.5 - bar_gap, min_y, max_y, bar_w,
                            (hp - 100) / math.max(1, mhp - 100), FrameCache.hp_rgb[1], FrameCache.hp_rgb[2], FrameCache.hp_rgb[3],
                            ((tonumber(d[pfx .. "hp_offset_x"].value) or 0.0) * Sys.ui_scale) + box_ox,
                            ((tonumber(d[pfx .. "hp_offset_y"].value) or 0.0) * Sys.ui_scale) + box_oy)
                    end
                    if want_arm then
                        local ap = Sys.int("get_ped_armour", Env.hashes.ped_armour, ped)
                        Esp.draw_bar(cx + w * 0.5 + bar_gap, min_y, max_y, bar_w, ap / 100.0,
                            FrameCache.arm_rgb[1], FrameCache.arm_rgb[2], FrameCache.arm_rgb[3],
                            ((tonumber(d[pfx .. "arm_offset_x"].value) or 0.0) * Sys.ui_scale) + box_ox,
                            ((tonumber(d[pfx .. "arm_offset_y"].value) or 0.0) * Sys.ui_scale) + box_oy)
                    end
                end
            end
        end
    end

    if (want_name or want_dist) and box_cx and box_top_y then
        local base_name = (label and label ~= "") and label or ((id == my_id) and "Self" or ("Player " .. tostring(id)))
        local caption = want_name and base_name or ""
        if want_dist then
            local m_str = tostring(math.floor(dist_m + 0.5)) .. " m"
            caption = (caption ~= "") and (caption .. " [" .. m_str .. "]") or m_str
        end
        Esp.draw_caption(caption, box_cx, box_top_y, box_w, d[pfx .. "size"].value,
            d[pfx .. "name_offset_x"].value, d[pfx .. "name_offset_y"].value, in_veh)
    end

    if want_skel then
        local head_pt   = bone(Env.bones.head)
        local neck_pt   = bone(Env.bones.neck)
        local spine2_pt = bone(Env.bones.spine2)
        local spine1_pt = bone(Env.bones.spine1)
        local pelvis_pt = bone(Env.bones.pelvis)
        local n_ref     = neck_pt or { x = pos.x, y = pos.y, z = pos.z + 0.52 }
        local lu_raw    = Sys.bone_coords(ped, Env.bones.luarm)
        local ru_raw    = Sys.bone_coords(ped, Env.bones.ruarm)
        local sh_z      = n_ref.z + 0.04

        local sh_l = lu_raw and {
            x = lu_raw.x + (lu_raw.x - pos.x) * 0.16,
            y = lu_raw.y + (lu_raw.y - pos.y) * 0.16,
            z = math.max(lu_raw.z + 0.07, sh_z)
        } or nil
        local sh_r = ru_raw and {
            x = ru_raw.x + (ru_raw.x - pos.x) * 0.16,
            y = ru_raw.y + (ru_raw.y - pos.y) * 0.16,
            z = math.max(ru_raw.z + 0.07, sh_z)
        } or nil

        local arm_root = neck_pt or spine2_pt or spine1_pt or pelvis_pt or n_ref
        local leg_root = pelvis_pt or spine1_pt or spine2_pt
        local skel_sz  = d[pfx .. "skel_size"].value
        local rgb_on   = d[pfx .. "rgb_skeleton"].value
        local outlined = d[pfx .. "bone_outline"].value == true
        local seg_n    = 0

        local function seg(a_pt, b_pt)
            if not a_pt or not b_pt then return end
            seg_n = seg_n + 1
            Esp.draw_segment(a_pt, b_pt, dist_m, seg_n, skel_sz, rgb_on, skel_style, outlined)
        end
        local function joint(pt, stripe)
            if not pt then return end
            seg_n = seg_n + 1
            Esp.draw_joint(pt, dist_m, seg_n, skel_sz, rgb_on, outlined, stripe)
        end

        if skel_style == "Minimal" then
            seg(pelvis_pt or spine1_pt, neck_pt or head_pt)
            seg(neck_pt, head_pt)
            joint(head_pt, false)
            joint(pelvis_pt, false)
        elseif skel_style == "Core" then
            seg(neck_pt, head_pt)
            seg(pelvis_pt, neck_pt)
            seg(arm_root, sh_l); seg(arm_root, sh_r)
            seg(leg_root, bone(Env.bones.lthigh)); seg(leg_root, bone(Env.bones.rthigh))
        else
            seg(neck_pt, head_pt); seg(spine2_pt, neck_pt); seg(spine1_pt, spine2_pt); seg(pelvis_pt, spine1_pt)
            seg(arm_root, sh_l); seg(sh_l, bone(Env.bones.llarm)); seg(bone(Env.bones.llarm), bone(Env.bones.lhand))
            seg(arm_root, sh_r); seg(sh_r, bone(Env.bones.rlarm)); seg(bone(Env.bones.rlarm), bone(Env.bones.rhand))
            seg(leg_root, bone(Env.bones.lthigh)); seg(bone(Env.bones.lthigh), bone(Env.bones.lcalf)); seg(bone(Env.bones.lcalf), bone(Env.bones.lfoot))
            seg(leg_root, bone(Env.bones.rthigh)); seg(bone(Env.bones.rthigh), bone(Env.bones.rcalf)); seg(bone(Env.bones.rcalf), bone(Env.bones.rfoot))

            if skel_style == "Joints" or skel_style == "Stripes" then
                local st = (skel_style == "Stripes")
                local pts = { head_pt, neck_pt, sh_l, sh_r, bone(Env.bones.llarm), bone(Env.bones.rlarm),
                              pelvis_pt, bone(Env.bones.lthigh), bone(Env.bones.rthigh), bone(Env.bones.lcalf), bone(Env.bones.rcalf) }
                for i = 1, #pts do joint(pts[i], st) end
            end
        end
    end
end

function Esp.frame()
    if Sys.is_paused() then return end
    local my_id, my_ped, my_name, my_pos = Esp.self_info()
    if my_ped <= 0 or not my_pos then return end

    local list = Esp.iter_player_peds(my_id, my_ped)
    for i = 1, #list do
        Esp.render_entity(list[i], my_id, my_pos)
    end

    if Cfg.data.show_self.value or Cfg.data.veh_show_self.value then
        Esp.render_entity({
            id = my_id,
            ped = my_ped,
            name = my_name,
            pos = my_pos,
            dist = 0.0,
            dead = false,
            in_veh = nil
        }, my_id, my_pos)
    end
end

-- ============================================================================
-- AimBot Module (FOV Lock + Smooth Camera Nudge, Strictly Enemy Peds Only)
-- ============================================================================
local Aim = {}

function Aim.target_bone_id(bone_choice)
    local b = Cfg.aim_bone(bone_choice)
    if b == "Neck"   then return Env.bones.neck end
    if b == "Spine"  then return Env.bones.spine2 end
    if b == "Pelvis" then return Env.bones.pelvis end
    return Env.bones.head
end

function Aim.target_world_pos(ped, pos, bone_choice)
    local v = Sys.bone_coords(ped, Aim.target_bone_id(bone_choice))
    if v then return v end
    local b = Cfg.aim_bone(bone_choice)
    if b == "Neck"   then return { x = pos.x, y = pos.y, z = pos.z + 0.52 } end
    if b == "Spine"  then return { x = pos.x, y = pos.y, z = pos.z + 0.36 } end
    if b == "Pelvis" then return { x = pos.x, y = pos.y, z = pos.z - 0.05 } end
    return { x = pos.x, y = pos.y, z = pos.z + 0.68 }
end

function Aim.has_los(my_ped, target_ped, vis_check)
    if not vis_check then return true end
    return Sys.bool("has_entity_clear_los_to_entity", Env.hashes.has_entity_clear_los, my_ped, target_ped, 17)
end

function Aim.is_key_active(aim_vk)
    local vk = tonumber(aim_vk) or 0x02
    if vk <= 0x06 then
        if input and type(input.mouse) == "function" then
            local ok, res = pcall(input.mouse, vk)
            if ok and res == true then return true end
        end
        if vk == 0x02 then
            if Sys.bool("is_control_pressed", Env.hashes.is_control_pressed, 0, 25) then return true end
            if Sys.bool("is_control_pressed", Env.hashes.is_control_pressed, 0, 68) then return true end
        end
    end
    if input and type(input.key) == "function" then
        local ok, res = pcall(input.key, vk)
        if ok and res == true then return true end
    end
    return false
end

function Aim.nudge_look(dx_px, dy_px, smooth_val)
    local sm = Sys.clamp(tonumber(smooth_val) or 6.0, 1.0, 50.0)
    local step_factor = 1.0 / math.max(1.0, sm * 0.55)
    local norm_x = dx_px / math.max(1.0, Sys.scr_w * 0.5)
    local norm_y = dy_px / math.max(1.0, Sys.scr_h * 0.5)

    local nx = Sys.clamp(norm_x * step_factor * 1.45, -0.75, 0.75)
    local ny = Sys.clamp(norm_y * step_factor * 1.45, -0.75, 0.75)

    if math.abs(nx) > 0.001 then
        pcall(Sys.native, "set_control_normal", Env.hashes.set_control_normal, 0, 1, nx)
    end
    if math.abs(ny) > 0.001 then
        pcall(Sys.native, "set_control_normal", Env.hashes.set_control_normal, 0, 2, ny)
    end
end

function Aim.tick()
    if Sys.is_paused() then return end
    local d = Cfg.data
    local fov_rad = (tonumber(d.aim_fov.value) or 220.0) * Sys.ui_scale
    local cx, cy = Sys.scr_w * 0.5, Sys.scr_h * 0.5

    if d.aim_draw_fov.value and fov_rad > 2.0 then
        Draw.circle_px(cx, cy, fov_rad, FrameCache.fov_rgb[1], FrameCache.fov_rgb[2], FrameCache.fov_rgb[3], 175, 1.4 * Sys.ui_scale)
    end

    if not d.aim_enabled.value then return end
    if not Aim.is_key_active(d.aim_key.value) then return end

    local my_id, my_ped, _, my_pos = Esp.self_info()
    if my_ped <= 0 or not my_pos then return end

    local max_dist = tonumber(d.aim_range.value) or 300.0
    local ignore_veh = d.aim_ignore_veh.value == true
    local vis_check = d.aim_vis_check.value == true
    local prio = Cfg.aim_prio(d.aim_priority.value)
    local bone_choice = d.aim_bone.value

    local best_score = math.huge
    local best_dx, best_dy = nil, nil
    local list = Esp.iter_player_peds(my_id, my_ped)

    for i = 1, #list do
        local p = list[i]
        local ped = p.ped
        if ped > 0 and ped ~= my_ped and p.id ~= my_id then
            if p.dead == nil then
                p.dead = Sys.bool("is_ped_dead_or_dying", Env.hashes.ped_dead, ped, true)
            end
            if not p.dead then
                if not p.pos then p.pos = Sys.entity_coords(ped) end
                local pos = p.pos
                if pos then
                    if not p.dist then
                        local dx, dy, dz = pos.x - my_pos.x, pos.y - my_pos.y, pos.z - my_pos.z
                        p.dist = math.sqrt(dx * dx + dy * dy + dz * dz)
                    end
                    local dist = p.dist
                    if dist > 0.5 and dist <= max_dist then
                        if p.in_veh == nil then
                            p.in_veh = Sys.bool("is_ped_in_any_vehicle", Env.hashes.ped_in_vehicle, ped, false)
                        end
                        if not (ignore_veh and p.in_veh) and Aim.has_los(my_ped, ped, vis_check) then
                            local aim_pt = Aim.target_world_pos(ped, pos, bone_choice)
                            local sc = aim_pt and Sys.world_to_screen(aim_pt) or nil
                            if sc and sc.x >= 0.0 and sc.x <= 1.0 and sc.y >= 0.0 and sc.y <= 1.0 then
                                local sx, sy = sc.x * Sys.scr_w, sc.y * Sys.scr_h
                                local odx, ody = sx - cx, sy - cy
                                local fov_dist = math.sqrt(odx * odx + ody * ody)
                                if fov_dist <= fov_rad then
                                    local score = (prio == "Distance") and dist or fov_dist
                                    if score < best_score then
                                        best_score = score
                                        best_dx, best_dy = odx, ody
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if best_dx and best_dy then
        Aim.nudge_look(best_dx, best_dy, d.aim_smooth.value)
    end
end

-- ============================================================================
-- Trigger Bot Module (Full Player Model Hitbox, No Manual Zone)
-- ============================================================================
local Trig = {
    pending_since = nil,
    last_shot_at = 0.0,
    pulse_frames = 0
}

function Trig.is_other_player_ped(ped, my_id, my_ped)
    if not ped or ped <= 0 or ped == my_ped then return false end
    local mapped = FrameCache.player_ped_map[ped]
    return mapped ~= nil and mapped ~= my_id
end

function Trig.has_player_on_model(my_id, my_ped, my_pos, max_dist, ignore_veh, vis_check)
    if Sys._aim_ent then
        local ok, res = pcall(invoker.call, Env.hashes.get_aim_entity, my_ped, Sys._aim_ent:address())
        if ok and Sys.to_bool(res) then
            local ent = tonumber(Sys._aim_ent.value) or 0
            if ent > 0 and ent ~= my_ped and Trig.is_other_player_ped(ent, my_id, my_ped) then
                if not Sys.bool("is_ped_dead_or_dying", Env.hashes.ped_dead, ent, true) then
                    if not (ignore_veh and Sys.bool("is_ped_in_any_vehicle", Env.hashes.ped_in_vehicle, ent, false)) then
                        local pos = Sys.entity_coords(ent)
                        if pos then
                            local dx, dy, dz = pos.x - my_pos.x, pos.y - my_pos.y, pos.z - my_pos.z
                            local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
                            if dist > 0.5 and dist <= max_dist then
                                if not vis_check or Sys.bool("has_entity_clear_los_to_entity", Env.hashes.has_entity_clear_los, my_ped, ent, 17) then
                                    return true
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local cx, cy = Sys.scr_w * 0.5, Sys.scr_h * 0.5
    local list = Esp.iter_player_peds(my_id, my_ped)

    for i = 1, #list do
        local p = list[i]
        local ped = p.ped
        if ped > 0 and ped ~= my_ped and p.id ~= my_id then
            if p.dead == nil then
                p.dead = Sys.bool("is_ped_dead_or_dying", Env.hashes.ped_dead, ped, true)
            end
            if not p.dead then
                if not p.pos then p.pos = Sys.entity_coords(ped) end
                local pos = p.pos
                if pos then
                    if not p.dist then
                        local dx, dy, dz = pos.x - my_pos.x, pos.y - my_pos.y, pos.z - my_pos.z
                        p.dist = math.sqrt(dx * dx + dy * dy + dz * dz)
                    end
                    if p.dist > 0.5 and p.dist <= max_dist then
                        if p.in_veh == nil then
                            p.in_veh = Sys.bool("is_ped_in_any_vehicle", Env.hashes.ped_in_vehicle, ped, false)
                        end
                        if not (ignore_veh and p.in_veh) then
                            local rect = Esp.ped_screen_rect(ped, pos)
                            if rect and cx >= rect.left and cx <= rect.right and cy >= rect.top and cy <= rect.bottom then
                                if not vis_check or Sys.bool("has_entity_clear_los_to_entity", Env.hashes.has_entity_clear_los, my_ped, ped, 17) then
                                    return true
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return false
end

function Trig.apply_attack_pulse()
    pcall(Sys.native, "set_control_normal", Env.hashes.set_control_normal, 0, 24, 1.0)
    pcall(Sys.native, "set_control_normal", Env.hashes.set_control_normal, 0, 257, 1.0)
    if Trig.pulse_frames == 2 and input and type(input.mouse_click) == "function" then
        pcall(input.mouse_click, 0x01)
    end
end

function Trig.tick()
    if Trig.pulse_frames > 0 then
        Trig.apply_attack_pulse()
        Trig.pulse_frames = Trig.pulse_frames - 1
    end

    local d = Cfg.data
    if not d.trig_enabled.value then
        Trig.pending_since = nil
        return
    end
    if Sys.is_paused() then
        Trig.pending_since = nil
        return
    end

    if d.trig_only_aiming.value then
        local rmb = Aim.is_key_active(0x02)
        if not rmb then
            Trig.pending_since = nil
            return
        end
    end

    local my_id, my_ped, _, my_pos = Esp.self_info()
    if my_ped <= 0 or not my_pos then
        Trig.pending_since = nil
        return
    end

    local max_dist = tonumber(d.trig_range.value) or 300.0
    local ignore_veh = d.trig_ignore_veh.value == true
    local vis_check = d.trig_vis_check.value == true

    local on_model = Trig.has_player_on_model(my_id, my_ped, my_pos, max_dist, ignore_veh, vis_check)
    local now = Sys.now

    if not on_model then
        Trig.pending_since = nil
        return
    end

    if not Trig.pending_since then
        Trig.pending_since = now
    end

    local delay_sec = (tonumber(d.trig_delay_ms.value) or 0.0) / 1000.0
    local interval_sec = math.max(0.02, (tonumber(d.trig_interval_ms.value) or 75.0) / 1000.0)

    if (now - Trig.pending_since) >= delay_sec and (now - Trig.last_shot_at) >= interval_sec then
        Trig.last_shot_at = now
        Trig.pulse_frames = 2
        Trig.apply_attack_pulse()
    end
end

-- ============================================================================
-- [STAGE 6] GUI Menu, Tabs, Draggable Hotkey HUD & Interactive Preview
-- ============================================================================
local VK_LBUTTON = 0x01
local VK_BACK    = 0x08
local VK_RETURN  = 0x0D

local VK_NAMES = {
    [0x01] = "LMB",  [0x02] = "RMB",  [0x04] = "MMB",  [0x05] = "M4",   [0x06] = "M5",
    [0x08] = "BKSP", [0x09] = "TAB",  [0x0D] = "ENTER",[0x10] = "SHIFT",[0x11] = "CTRL",
    [0x12] = "ALT",  [0x14] = "CAPS", [0x1B] = "ESC",  [0x20] = "SPACE",[0x21] = "PGUP",
    [0x22] = "PGDN", [0x23] = "END",  [0x24] = "HOME", [0x25] = "LEFT", [0x26] = "UP",
    [0x27] = "RIGHT",[0x28] = "DOWN", [0x2D] = "INS",  [0x2E] = "DEL",
    [0x70] = "F1",   [0x71] = "F2",   [0x72] = "F3",   [0x73] = "F4",   [0x74] = "F5",
    [0x75] = "F6",   [0x76] = "F7",   [0x77] = "F8",   [0x78] = "F9",   [0x79] = "F10",
    [0x7A] = "F11",  [0x7B] = "F12"
}

local BIND_KEYS = {
    0x02, 0x04, 0x05, 0x06,
    0x08, 0x09, 0x0D, 0x10, 0x11, 0x12, 0x14, 0x20,
    0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x2D, 0x2E,
    0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7A, 0x7B
}
for code = 0x30, 0x5A do BIND_KEYS[#BIND_KEYS + 1] = code end
for code = 0x60, 0x69 do BIND_KEYS[#BIND_KEYS + 1] = code end

local UI = {
    running = true,
    open = true,
    tab = "player",
    preview_mode = "player",
    color_target = "skeleton",

    x = 460.0, y = 66.0,
    w = 920.0, h = 770.0,
    header_h = 48.0, pad = 16.0,

    cur_mx = 0.0, cur_my = 0.0,
    last_mx = nil, last_my = nil,
    dx = 0.0, dy = 0.0,

    mode_idx = 1,
    modes = { "Windows", "Raw Input", "DirectInput" },

    dragging = false, drag_ox = 0.0, drag_oy = 0.0,
    dragging_hud = false, hud_ox = 0.0, hud_oy = 0.0,
    dragging_slider = nil,
    dragging_preview = nil, preview_ox = 0.0, preview_oy = 0.0,

    binding_target = nil,
    _prev_bind = {},

    editing_key = nil, edit_buf = "", edit_min = 0, edit_max = 10000,
    _prev_digits = {}, _prev_bksp = false, _prev_enter = false,

    _cursor_shown = false,
    _was_lmb = false,
    _was_bind = false
}

function UI.panel_alpha()
    return math.floor(Sys.clamp(tonumber(Cfg.data.ui_panel_alpha.value) or 188, 80, 255) + 0.5)
end

function UI.theme_glow_alpha()
    return math.floor(Sys.clamp(tonumber(Cfg.data.theme_glow.value) or 140, 0, 255) + 0.5)
end

function UI.short_theme_label(name)
    local s = tostring(name or "Midnight")
    if #s <= 13 then return s end
    return s:sub(1, 11) .. ".."
end

function UI.vk_label(vk)
    local v = tonumber(vk) or 0x2D
    if VK_NAMES[v] then return VK_NAMES[v] end
    if v >= 0x30 and v <= 0x39 then return string.char(v) end
    if v >= 0x41 and v <= 0x5A then return string.char(v) end
    if v >= 0x60 and v <= 0x69 then return "NUM" .. tostring(v - 0x60) end
    return string.format("0x%X", v)
end

function UI.button_down(fn, vk)
    if type(fn) ~= "function" then return false end
    local ok, res = pcall(fn, vk)
    if not ok or res == nil then return false end
    if type(res) == "boolean" then return res end
    if type(res) == "table" or type(res) == "userdata" then
        if res.pressed ~= nil then return res.pressed == true end
        if res.down ~= nil then return res.down == true end
    end
    return false
end

function UI.any_key_or_mouse_down(vk)
    if vk <= 0x06 and UI.button_down(input and input.mouse, vk) then return true end
    return UI.button_down(input and input.key, vk)
end

function UI.set_cursor_visible(visible)
    local want = (visible == true)
    if input and type(input.show_cursor) == "function" then
        pcall(input.show_cursor, want)
    end
    if gui and type(gui.show_cursor) == "function" then
        pcall(gui.show_cursor, want)
    end
    if _G.mouse and type(_G.mouse.set_visible) == "function" then
        pcall(_G.mouse.set_visible, want)
    end
end

function UI.hide_cursor()
    UI._cursor_shown = false
    UI.last_mx, UI.last_my = nil, nil
    UI.dx, UI.dy = 0.0, 0.0
    UI.set_cursor_visible(false)
end

function UI.force_unload_cleanup()
    UI.running = false
    UI.open = false
    UI.binding_target = nil
    UI.dragging = false
    UI.dragging_hud = false
    UI.dragging_slider = nil
    UI.dragging_preview = nil
    UI._was_lmb = false
    UI.hide_cursor()
    pcall(Sys.restore_game_input)
end

function UI.sync_cursor()
    if UI.running and (UI.open or UI.dragging_hud) then
        if not UI._cursor_shown then
            UI._cursor_shown = true
            UI.set_cursor_visible(true)
        end
    else
        UI.hide_cursor()
    end
end

function UI.apply_resolution(announce)
    local mode = tostring(Cfg.data.res_mode.value or "2K")
    if mode == "1080p" then Sys.scr_w, Sys.scr_h = 1920.0, 1080.0
    elseif mode == "4K" then Sys.scr_w, Sys.scr_h = 3840.0, 2160.0
    elseif mode == "2K" then Sys.scr_w, Sys.scr_h = 2560.0, 1440.0
    else Sys.scr_w, Sys.scr_h = Sys.auto_w, Sys.auto_h end

    local s = Sys.clamp(Sys.scr_h / 1440.0, 0.70, 2.0)
    Sys.ui_scale = s
    Sys.res_label = Sys.format_res(Sys.scr_w, Sys.scr_h)

    UI.w = 920.0 * s
    UI.h = 770.0 * s
    UI.header_h = 48.0 * s
    UI.pad = 16.0 * s
    UI.x = Sys.clamp(UI.x, 12.0 * s, math.max(12.0 * s, Sys.scr_w - UI.w - 12.0 * s))
    UI.y = Sys.clamp(UI.y, 12.0 * s, math.max(12.0 * s, Sys.scr_h - UI.h - 12.0 * s))

    Cfg.data.hud_x.value = Sys.clamp(tonumber(Cfg.data.hud_x.value) or 16.0, 0.0, math.max(0.0, Sys.scr_w - 230.0 * s))
    Cfg.data.hud_y.value = Sys.clamp(tonumber(Cfg.data.hud_y.value) or 16.0, 0.0, math.max(0.0, Sys.scr_h - 60.0 * s))

    Sys.ensure_font(22.0 * s)
    if announce then bubblewrap_toast("Screen: " .. Sys.res_label) end
end

function UI.commit_edit()
    if not UI.editing_key then return end
    local key = UI.editing_key
    local num = tonumber(UI.edit_buf)
    if num then
        if Cfg.schema[key] then
            Cfg.set(key, num, true)
        elseif key == "rgb_r" or key == "rgb_g" or key == "rgb_b" then
            local ch = (key == "rgb_r") and "r" or ((key == "rgb_g") and "g" or "b")
            Cfg.set_color_channel(UI.color_target, ch, num, true)
        end
    end
    UI.editing_key = nil
    UI.edit_buf = ""
end

function UI.close()
    UI.commit_edit()
    UI.binding_target = nil
    UI.open = false
    UI.dragging = false
    UI.dragging_slider = nil
    if UI.dragging_preview then
        local drag_key = UI.dragging_preview.key
        UI.dragging_preview = nil
        if drag_key and Gen.provisioned then Cfg.save_key(drag_key) end
    end
    if UI.dragging_hud then
        UI.dragging_hud = false
        if Gen.provisioned then
            Cfg.save_key("hud_x")
            Cfg.save_key("hud_y")
        end
    end
    UI._was_lmb = false
    UI.hide_cursor()
    pcall(Sys.restore_game_input)
end

function UI.update_mouse()
    local mx, my = UI.cur_mx, UI.cur_my
    if input and type(input.mouse_position) == "function" then
        local ok, a, b = pcall(input.mouse_position)
        if ok and a ~= nil then
            if type(a) == "table" or type(a) == "userdata" then
                mx = tonumber(a.x) or mx
                my = tonumber(a.y) or my
            else
                mx = tonumber(a) or mx
                my = tonumber(b) or my
            end
        end
    end

    if UI.last_mx and UI.last_my then
        UI.dx, UI.dy = mx - UI.last_mx, my - UI.last_my
    else
        UI.dx, UI.dy = 0.0, 0.0
    end
    UI.last_mx, UI.last_my = mx, my

    local mode = UI.modes[UI.mode_idx]
    if mode == "Windows" then
        UI.cur_mx, UI.cur_my = mx, my
    elseif mode == "Raw Input" then
        UI.cur_mx, UI.cur_my = UI.cur_mx + UI.dx, UI.cur_my + UI.dy
    else
        if math.abs(UI.dx) > 0.0 or math.abs(UI.dy) > 0.0 then
            UI.cur_mx, UI.cur_my = UI.cur_mx + UI.dx, UI.cur_my + UI.dy
        else
            UI.cur_mx, UI.cur_my = mx, my
        end
    end

    UI.cur_mx = Sys.clamp(UI.cur_mx, 0.0, Sys.scr_w)
    UI.cur_my = Sys.clamp(UI.cur_my, 0.0, Sys.scr_h)
    UI.sync_cursor()
end

function UI.poll_bind()
    if not UI.binding_target then return end
    for i = 1, #BIND_KEYS do
        local vk = BIND_KEYS[i]
        local down = UI.any_key_or_mouse_down(vk)
        if down and not UI._prev_bind[vk] then
            local key = UI.binding_target
            Cfg.set(key, vk, true)
            UI.binding_target = nil
            UI._was_bind = true
            UI._was_lmb = true
            bubblewrap_toast("Bind set: " .. UI.vk_label(vk))
            return
        end
        UI._prev_bind[vk] = down
    end
end

function UI.poll_number_edit()
    if not UI.editing_key then return end
    for d = 0, 9 do
        local down = UI.button_down(input and input.key, 0x30 + d) or UI.button_down(input and input.key, 0x60 + d)
        if down and not UI._prev_digits[d] and #UI.edit_buf < 6 then
            UI.edit_buf = UI.edit_buf .. tostring(d)
        end
        UI._prev_digits[d] = down
    end
    local bksp = UI.button_down(input and input.key, VK_BACK)
    if bksp and not UI._prev_bksp and #UI.edit_buf > 0 then
        UI.edit_buf = UI.edit_buf:sub(1, #UI.edit_buf - 1)
    end
    UI._prev_bksp = bksp

    local enter = UI.button_down(input and input.key, VK_RETURN)
    if enter and not UI._prev_enter then UI.commit_edit() end
    UI._prev_enter = enter
end

function UI.hit(mx, my, x, y, w, h)
    return mx >= x and mx <= (x + w) and my >= y and my <= (y + h)
end

function UI.label(txt, x, y, r, g, b, a, px, shadow)
    Draw.text(txt, x, y, r, g, b, a, (px or 15.5) * Sys.ui_scale, shadow == true)
end

function UI.centered(txt, x, y, w, h, r, g, b, a, px, align)
    local fp = (px or 14.5) * Sys.ui_scale
    local tw = Draw.text_width(txt, fp)
    local tx = x + 12.0 * Sys.ui_scale
    if align == "center" then tx = x + (w - tw) * 0.5
    elseif align == "right" then tx = x + w - tw - 12.0 * Sys.ui_scale end
    Draw.text(txt, tx, Draw.center_y(y, h, fp), r, g, b, a, fp, false)
end

function UI.section(title, x, y, w)
    local s = Sys.ui_scale
    local acc = Draw.theme_palette()
    UI.label(string.upper(title), x + 4.0 * s, y, 122, 148, 196, 255, 11.0, true)
    local lx = x + 116.0 * s
    Draw.rect_px(lx, y + 6.5 * s, math.max(10.0 * s, (x + w) - lx), 1.0 * s,
        math.floor(acc.r * 0.55), math.floor(acc.g * 0.6), math.floor(acc.b * 0.7), 210, 0.0)
end

function UI.toggle(mx, my, clicked, x, y, w, h, lbl, key, val)
    local s = Sys.ui_scale
    local pa = UI.panel_alpha()
    local acc = Draw.theme_palette()
    local hov = UI.hit(mx, my, x, y, w, h)
    Draw.rect_px(x, y, w, h, hov and 32 or 22, hov and 41 or 27, hov and 56 or 37, pa, 5.5 * s)
    Draw.rect_px(x, y + 5.0 * s, 3.0 * s, h - 10.0 * s, val and acc.r or 42, val and acc.g or 50, val and acc.b or 68, 220, 1.5 * s)
    UI.label(lbl, x + 13.0 * s, Draw.center_y(y, h, 14.5 * s), hov and 255 or 234, hov and 255 or 240, hov and 255 or 250, 255, 14.5, true)

    local pw, ph = 38.0 * s, 17.0 * s
    local px, py = x + w - pw - 10.0 * s, y + math.floor((h - ph) * 0.5)
    if val then
        Draw.rect_px(px, py, pw, ph, acc.r, acc.g, acc.b, 255, 8.5 * s)
        Draw.rect_px(px + pw - ph + 2.0 * s, py + 2.0 * s, ph - 4.0 * s, ph - 4.0 * s, 252, 254, 255, 255, 6.5 * s)
    else
        Draw.rect_px(px, py, pw, ph, 46, 53, 68, 255, 8.5 * s)
        Draw.rect_px(px + 2.0 * s, py + 2.0 * s, ph - 4.0 * s, ph - 4.0 * s, 180, 190, 208, 255, 6.5 * s)
    end

    if hov and clicked then
        local nxt = not val
        if key then Cfg.set(key, nxt, true) end
        return nxt
    end
    return val
end

function UI.selector(mx, my, clicked, x, y, w, h, lbl, key, cur, list, fallback)
    local s = Sys.ui_scale
    local pa = UI.panel_alpha()
    local acc = Draw.theme_palette()
    local current = Cfg.normalize_choice(cur, list, fallback)
    local hov_row = UI.hit(mx, my, x, y, w, h)
    Draw.rect_px(x, y, w, h, hov_row and 32 or 22, hov_row and 41 or 27, hov_row and 56 or 37, pa, 5.5 * s)
    Draw.rect_px(x, y + 5.0 * s, 3.0 * s, h - 10.0 * s, acc.r, acc.g, acc.b, 220, 1.5 * s)
    UI.label(lbl, x + 13.0 * s, Draw.center_y(y, h, 14.5 * s), hov_row and 255 or 234, hov_row and 255 or 240, hov_row and 255 or 250, 255, 14.5, true)

    local sw, bw, sh = 154.0 * s, 22.0 * s, h - 6.0 * s
    local sx, sy = x + w - sw - 8.0 * s, y + 3.0 * s
    local px, nx = sx, sx + sw - bw
    local mx_box, mw = px + bw, math.max(12.0 * s, sw - bw * 2.0)
    local h_prev, h_next = UI.hit(mx, my, px, sy, bw, sh), UI.hit(mx, my, nx, sy, bw, sh)

    Draw.rect_px(px, sy, bw, sh, h_prev and acc.r or 32, h_prev and acc.g or 40, h_prev and acc.b or 56, 245, 4.0 * s)
    Draw.rect_px(mx_box, sy, mw, sh, 18, 22, 31, 235, 3.5 * s)
    Draw.rect_px(nx, sy, bw, sh, h_next and acc.r or 32, h_next and acc.g or 40, h_next and acc.b or 56, 245, 4.0 * s)

    UI.centered("<", px, sy, bw, sh, 240, 246, 255, 255, 13.5, "center")
    UI.centered(UI.short_theme_label(current), mx_box, sy, mw, sh, 132, 204, 255, 255, 12.5, "center")
    UI.centered(">", nx, sy, bw, sh, 240, 246, 255, 255, 13.5, "center")

    if clicked and (h_prev or h_next) then
        local nxt = Cfg.cycle_choice(current, list, fallback, h_prev and -1 or 1)
        if key then Cfg.set(key, nxt, true) end
        return nxt
    end
    return current
end

function UI.key_picker(mx, my, clicked, x, y, w, h, lbl, key, cur_vk)
    local s = Sys.ui_scale
    local pa = UI.panel_alpha()
    local acc = Draw.theme_palette()
    local active_bind = (UI.binding_target == key)
    local hov = UI.hit(mx, my, x, y, w, h)
    Draw.rect_px(x, y, w, h, active_bind and 34 or (hov and 32 or 22), active_bind and 60 or (hov and 41 or 27), active_bind and 106 or (hov and 56 or 37), pa, 5.5 * s)
    Draw.rect_px(x, y + 5.0 * s, 3.0 * s, h - 10.0 * s, acc.r, acc.g, acc.b, 220, 1.5 * s)
    UI.label(lbl, x + 13.0 * s, Draw.center_y(y, h, 14.5 * s), 234, 240, 250, 255, 14.5, true)

    local bw, bh = 88.0 * s, h - 6.0 * s
    local bx, by = x + w - bw - 8.0 * s, y + 3.0 * s
    Draw.rect_px(bx, by, bw, bh, active_bind and acc.r or 32, active_bind and acc.g or 40, active_bind and acc.b or 56, 245, 4.0 * s)
    UI.centered(active_bind and "Press..." or ("[" .. UI.vk_label(cur_vk) .. "]"),
        bx, by, bw, bh, active_bind and 255 or 132, active_bind and 232 or 204, active_bind and 125 or 255, 255, 13.0, "center")

    if clicked and hov then
        UI.commit_edit()
        UI.binding_target = active_bind and nil or key
        UI._prev_bind = {}
    end
end

function UI.slider(mx, my, clicked, down, x, y, w, h, lbl, key, val, on_set, min_v, max_v, step, suf, drag_id, val_x, br, bg, bb)
    local s = Sys.ui_scale
    local pa = UI.panel_alpha()
    local acc = Draw.theme_palette()
    val = Sys.clamp(tonumber(val) or min_v, min_v, max_v)
    local hov = UI.hit(mx, my, x, y, w, h)
    Draw.rect_px(x, y, w, h, hov and 32 or 22, hov and 41 or 27, hov and 56 or 37, pa, 5.5 * s)

    local nb_w, nb_h = 68.0 * s, 19.0 * s
    local nb_x = x + (val_x or 124.0) * s - 4.0 * s
    local nb_y = y + math.floor((h - nb_h) * 0.5)
    local editing = (UI.editing_key == key)
    local h_num = UI.hit(mx, my, nb_x, nb_y, nb_w, nb_h)

    if clicked then
        if h_num then
            UI.commit_edit()
            UI.editing_key = key
            UI.edit_buf = tostring(math.floor(val + 0.5))
            UI.edit_min, UI.edit_max = min_v, max_v
            editing = true
        elseif editing then
            UI.commit_edit()
            editing = false
        end
    end

    UI.label(lbl, x + 13.0 * s, Draw.center_y(y, h, 14.5 * s), 234, 240, 250, 255, 14.5, true)
    Draw.rect_px(nb_x, nb_y, nb_w, nb_h, editing and 18 or 28, editing and 34 or 35, editing and 58 or 48, 245, 3.5 * s)
    local disp = editing and ((UI.edit_buf ~= "" and UI.edit_buf or "0") .. "_") or (tostring(math.floor(val + 0.5)) .. (suf or ""))
    UI.centered(disp, nb_x, nb_y, nb_w, nb_h, editing and 255 or 132, editing and 232 or 204, editing and 125 or 255, 255, 13.5, "center")

    local sl_x = nb_x + nb_w + 11.0 * s
    local sl_w = math.max(44.0 * s, (x + w - 10.0 * s) - sl_x)
    local th = 5.0 * s
    local ty = y + math.floor((h - th) * 0.5)

    local dragging = (UI.dragging_slider ~= nil and UI.dragging_slider.id == drag_id)
    if clicked and UI.hit(mx, my, sl_x - 5.0 * s, y, sl_w + 10.0 * s, h) then
        UI.dragging_slider = { id = drag_id, key = key }
        dragging = true
    elseif not down and dragging then
        local released_key = UI.dragging_slider.key
        UI.dragging_slider = nil
        dragging = false
        if Gen.provisioned then
            if Cfg.schema[released_key] then
                Cfg.save_key(released_key)
            elseif released_key == "rgb_r" or released_key == "rgb_g" or released_key == "rgb_b" then
                Cfg.save_color(UI.color_target)
            end
        end
    end

    if dragging then
        local ratio = Sys.clamp((mx - sl_x) / math.max(1.0, sl_w), 0.0, 1.0)
        val = Sys.clamp(math.floor(((min_v + ratio * (max_v - min_v)) / step) + 0.5) * step, min_v, max_v)
        if on_set then on_set(val) end
    end

    local ratio = (val - min_v) / math.max(1.0, max_v - min_v)
    local fw = math.max(2.0 * s, sl_w * ratio)
    Draw.rect_px(sl_x, ty, sl_w, th, 44, 51, 66, 245, 2.5 * s)
    Draw.rect_px(sl_x, ty, fw, th, br or acc.r, bg or acc.g, bb or acc.b, 255, 2.5 * s)
    Draw.rect_px(sl_x + fw - 4.0 * s, ty - 3.0 * s, 8.0 * s, th + 6.0 * s, 252, 254, 255, 255, 3.0 * s)
end

function UI.draw_preview_skeleton(cx, by, bh, skel_val, rgb_on, style_name, outlined)
    local s = Sys.ui_scale
    local t = Sys.now
    local style = Cfg.skel_style(style_name)
    local breath = math.sin(t * 2.4)
    local sway_x = math.sin(t * 1.4) * 2.4 * s
    local lift_y = breath * 1.8 * s

    local hx, hy   = cx + sway_x * 1.15 + math.sin(t * 1.9) * 1.2 * s, by + bh * 0.11 + lift_y
    local nx, ny   = cx + sway_x, by + bh * 0.21 + lift_y
    local s2x, s2y = cx + sway_x * 0.8, by + bh * 0.30 + lift_y * 0.7
    local s1x, s1y = cx + sway_x * 0.6, by + bh * 0.40 + lift_y * 0.45
    local px, py   = cx + sway_x * 0.35, by + bh * 0.52 + breath * 0.8 * s

    local asp = math.min(24.0 * s, bh * 0.13)
    local lsx, lsy = nx - asp, ny + bh * 0.02 + breath * 1.0 * s
    local lex, ley = lsx - 6.0 * s + math.sin(t * 2.1) * 1.4 * s, lsy + bh * 0.15
    local lhx, lhy = lex - 2.0 * s + math.cos(t * 2.1) * 1.5 * s, ley + bh * 0.14

    local rsx, rsy = nx + asp, ny + bh * 0.02 + breath * 1.0 * s
    local rex, rey = rsx + 6.0 * s - math.sin(t * 2.1) * 1.4 * s, rsy + bh * 0.15
    local rhx, rhy = rex + 2.0 * s + math.cos(t * 2.1) * 1.5 * s, rey + bh * 0.14

    local lsp = math.min(18.0 * s, bh * 0.095)
    local lkx, lky = px - lsp * 0.85, by + bh * 0.74
    local lfx, lfy = px - lsp, by + bh * 0.94
    local rkx, rky = px + lsp * 0.85, by + bh * 0.74
    local rfx, rfy = px + lsp, by + bh * 0.94

    local segs
    if style == "Minimal" then
        segs = { { px, py, nx, ny }, { nx, ny, hx, hy } }
    elseif style == "Core" then
        segs = { { nx, ny, hx, hy }, { px, py, nx, ny }, { nx, ny, lsx, lsy }, { nx, ny, rsx, rsy }, { px, py, lkx, lky }, { px, py, rkx, rky } }
    else
        segs = {
            { nx, ny, hx, hy }, { s2x, s2y, nx, ny }, { s1x, s1y, s2x, s2y }, { px, py, s1x, s1y },
            { nx, ny, lsx, lsy }, { lsx, lsy, lex, ley }, { lex, ley, lhx, lhy },
            { nx, ny, rsx, rsy }, { rsx, rsy, rex, rey }, { rex, rey, rhx, rhy },
            { px, py, lkx, lky }, { lkx, lky, lfx, lfy },
            { px, py, rkx, rky }, { rkx, rky, rfx, rfy }
        }
    end

    local v = Sys.clamp(tonumber(skel_val) or 25.0, 1.0, 100.0)
    local mult = 0.65 + ((v - 1.0) / 99.0) * 1.15
    local thick = math.max(1.6 * s, math.min(3.8 * s, 1.8 * mult * s))
    local sr, sg, sb = FrameCache.skel_rgb[1], FrameCache.skel_rgb[2], FrameCache.skel_rgb[3]

    for i = 1, #segs do
        local b = segs[i]
        local r, g, bl = sr, sg, sb
        if rgb_on then r, g, bl = Sys.rainbow(t * 3.2 + i * 0.35) end
        Draw.bone_segment(b[1], b[2], b[3], b[4], thick, r, g, bl, style, outlined, true)
    end

    local jr, jg, jb = sr, sg, sb
    if rgb_on then jr, jg, jb = Sys.rainbow(t * 3.2) end
    if style == "Joints" or style == "Stripes" then
        local pts = { { hx, hy }, { nx, ny }, { lsx, lsy }, { rsx, rsy }, { lex, ley }, { rex, rey }, { px, py }, { lkx, lky }, { rkx, rky } }
        for i = 1, #pts do
            if style == "Stripes" then
                Draw.joint_stripe(pts[i][1], pts[i][2], math.max(3.6 * s, 4.8 * mult * s), math.max(1.6 * s, 1.9 * mult * s), jr, jg, jb, 255, outlined, true)
            else
                Draw.joint_dot(pts[i][1], pts[i][2], math.max(2.0 * s, 2.3 * mult * s), jr, jg, jb, 255, outlined)
            end
        end
    elseif style == "Minimal" then
        local rad = math.max(2.2 * s, 2.5 * mult * s)
        Draw.joint_dot(hx, hy, rad, jr, jg, jb, 255, outlined)
        Draw.joint_dot(px, py, rad, jr, jg, jb, 255, outlined)
    end
end

-- Interactive & draggable Hotkey HUD
function UI.render_hud(clicked, down)
    if Cfg.data.hotkey_hud_enabled.value ~= true then return end
    if (not UI.open) and (Cfg.data.hotkey_hud_when_hidden.value ~= true) then return end
    if Sys.is_paused() then return end

    local s = Sys.ui_scale
    local acc = Draw.theme_palette()
    local bw, hh, lh, pad = 228.0 * s, 22.0 * s, 20.0 * s, 6.0 * s
    local bh = hh + pad * 2.0 + lh

    local hx = tonumber(Cfg.data.hud_x.value) or (16.0 * s)
    local hy = tonumber(Cfg.data.hud_y.value) or (16.0 * s)

    local mx, my = UI.cur_mx, UI.cur_my
    local hov = UI.hit(mx, my, hx, hy, bw, bh)

    local menu_busy = UI.dragging or (UI.dragging_slider ~= nil) or (UI.dragging_preview ~= nil)
    if clicked and not menu_busy and hov then
        UI.dragging_hud = true
        UI.hud_ox = mx - hx
        UI.hud_oy = my - hy
        UI.sync_cursor()
    elseif not down and UI.dragging_hud then
        UI.dragging_hud = false
        Cfg.data.hud_x.value = math.floor(hx + 0.5)
        Cfg.data.hud_y.value = math.floor(hy + 0.5)
        if Gen.provisioned then
            Cfg.save_key("hud_x")
            Cfg.save_key("hud_y")
        end
        UI.sync_cursor()
    end

    if UI.dragging_hud then
        hx = Sys.clamp(mx - UI.hud_ox, 0.0, math.max(0.0, Sys.scr_w - bw))
        hy = Sys.clamp(my - UI.hud_oy, 0.0, math.max(0.0, Sys.scr_h - bh))
        Cfg.data.hud_x.value = hx
        Cfg.data.hud_y.value = hy
    end

    local border_r = (UI.dragging_hud or hov) and acc.r or 44
    local border_g = (UI.dragging_hud or hov) and acc.g or 56
    local border_b = (UI.dragging_hud or hov) and acc.b or 82
    local bg_a = (UI.dragging_hud or hov) and 225 or 200

    Draw.rect_px(hx - 1.0 * s, hy - 1.0 * s, bw + 2.0 * s, bh + 2.0 * s, border_r, border_g, border_b, 200, 7.0 * s)
    Draw.rect_px(hx, hy, bw, bh, 14, 18, 26, bg_a, 6.5 * s)
    Draw.rect_px(hx, hy, bw, hh, hov and 28 or 20, hov and 36 or 26, hov and 52 or 38, 235, 6.5 * s)
    Draw.rect_px(hx + 8.0 * s, hy + 5.0 * s, 3.0 * s, hh - 10.0 * s, acc.r, acc.g, acc.b, 255, 1.5 * s)
    UI.label(UI.dragging_hud and "MOVING HUD..." or "HOTKEYS HUD",
        hx + 16.0 * s, Draw.center_y(hy, hh, 11.5 * s), 220, 232, 250, 255, 11.5, false)

    local ry = hy + hh + pad
    UI.label("Toggle Menu", hx + 12.0 * s, Draw.center_y(ry, lh, 12.5 * s), 210, 220, 236, 255, 12.5, false)
    UI.label("[" .. UI.vk_label(Cfg.data.menu_key.value) .. "]", hx + bw - 64.0 * s, Draw.center_y(ry, lh, 12.5 * s), 132, 204, 255, 255, 12.5, false)
end

function UI.render_entity_tab(mx, my, clicked, down, x, y, w, is_veh)
    local s = Sys.ui_scale
    local d = Cfg.data
    local pfx = is_veh and "veh_" or ""
    local r_h, r_gap = 20.5 * s, 1.6 * s

    UI.section(is_veh and "In-Vehicle ESP & Outlines" or "Player ESP & Outlines", x, y, w)
    y = y + 16.0 * s

    d[pfx .. "enabled"].value      = UI.toggle(mx, my, clicked, x, y, w, r_h, "Enable", pfx .. "enabled", d[pfx .. "enabled"].value); y = y + r_h + r_gap
    d[pfx .. "names"].value        = UI.toggle(mx, my, clicked, x, y, w, r_h, "Names", pfx .. "names", d[pfx .. "names"].value); y = y + r_h + r_gap
    d[pfx .. "skeleton"].value     = UI.toggle(mx, my, clicked, x, y, w, r_h, "Skeleton", pfx .. "skeleton", d[pfx .. "skeleton"].value); y = y + r_h + r_gap
    d[pfx .. "skel_style"].value   = UI.selector(mx, my, clicked, x, y, w, r_h, "Skeleton Style", pfx .. "skel_style", d[pfx .. "skel_style"].value, Env.styles.skeleton, "Classic"); y = y + r_h + r_gap
    d[pfx .. "bone_outline"].value = UI.toggle(mx, my, clicked, x, y, w, r_h, "Bone Outline", pfx .. "bone_outline", d[pfx .. "bone_outline"].value); y = y + r_h + r_gap
    d[pfx .. "rgb_skeleton"].value = UI.toggle(mx, my, clicked, x, y, w, r_h, "RGB Skeleton", pfx .. "rgb_skeleton", d[pfx .. "rgb_skeleton"].value); y = y + r_h + r_gap
    d[pfx .. "box"].value          = UI.toggle(mx, my, clicked, x, y, w, r_h, "Corner Box", pfx .. "box", d[pfx .. "box"].value); y = y + r_h + r_gap
    d[pfx .. "box_style"].value    = UI.selector(mx, my, clicked, x, y, w, r_h, "Box Style", pfx .. "box_style", d[pfx .. "box_style"].value, Env.styles.box, "Corners"); y = y + r_h + r_gap
    d[pfx .. "health"].value       = UI.toggle(mx, my, clicked, x, y, w, r_h, "Health", pfx .. "health", d[pfx .. "health"].value); y = y + r_h + r_gap
    d[pfx .. "armour"].value       = UI.toggle(mx, my, clicked, x, y, w, r_h, "Armor", pfx .. "armour", d[pfx .. "armour"].value); y = y + r_h + r_gap
    d[pfx .. "distance"].value     = UI.toggle(mx, my, clicked, x, y, w, r_h, "Distance", pfx .. "distance", d[pfx .. "distance"].value); y = y + r_h + r_gap
    d[pfx .. "show_self"].value    = UI.toggle(mx, my, clicked, x, y, w, r_h, "Show Self", pfx .. "show_self", d[pfx .. "show_self"].value); y = y + r_h + r_gap + 3.0 * s

    UI.section(is_veh and "In-Vehicle Scale" or "Player Scale", x, y, w)
    y = y + 16.0 * s

    UI.slider(mx, my, clicked, down, x, y, w, r_h, "Distance", pfx .. "range", d[pfx .. "range"].value,
        function(v) d[pfx .. "range"].value = v end, 10.0, 10000.0, 10.0, " m", pfx .. "rng", 124.0); y = y + r_h + r_gap
    UI.slider(mx, my, clicked, down, x, y, w, r_h, "Name Size", pfx .. "size", d[pfx .. "size"].value,
        function(v) d[pfx .. "size"].value = v end, 10.0, 100.0, 1.0, "", pfx .. "sz", 124.0); y = y + r_h + r_gap
    UI.slider(mx, my, clicked, down, x, y, w, r_h, "Skeleton Size", pfx .. "skel_size", d[pfx .. "skel_size"].value,
        function(v) d[pfx .. "skel_size"].value = v end, 1.0, 100.0, 1.0, "", pfx .. "sksz", 124.0); y = y + r_h + r_gap
    UI.slider(mx, my, clicked, down, x, y, w, r_h, "Bar Size", pfx .. "bar_size", d[pfx .. "bar_size"].value,
        function(v) d[pfx .. "bar_size"].value = v end, 1.0, 10.0, 1.0, " px", pfx .. "bsz", 124.0)
end

function UI.render_aimbot_tab(mx, my, clicked, down, x, y, w)
    local s = Sys.ui_scale
    local d = Cfg.data
    local rh, gap = 22.0 * s, 2.5 * s

    UI.section("AimBot Controls", x, y, w); y = y + 18.0 * s
    d.aim_enabled.value    = UI.toggle(mx, my, clicked, x, y, w, rh, "Enable AimBot", "aim_enabled", d.aim_enabled.value); y = y + rh + gap
    d.aim_draw_fov.value   = UI.toggle(mx, my, clicked, x, y, w, rh, "Draw FOV Circle", "aim_draw_fov", d.aim_draw_fov.value); y = y + rh + gap
    d.aim_ignore_veh.value = UI.toggle(mx, my, clicked, x, y, w, rh, "Ignore In-Vehicle", "aim_ignore_veh", d.aim_ignore_veh.value); y = y + rh + gap
    d.aim_vis_check.value  = UI.toggle(mx, my, clicked, x, y, w, rh, "Visibility Check", "aim_vis_check", d.aim_vis_check.value); y = y + rh + gap
    d.aim_bone.value       = UI.selector(mx, my, clicked, x, y, w, rh, "Target Bone", "aim_bone", d.aim_bone.value, Env.styles.aim_bone, "Head"); y = y + rh + gap
    d.aim_priority.value   = UI.selector(mx, my, clicked, x, y, w, rh, "Target Priority", "aim_priority", d.aim_priority.value, Env.styles.aim_prio, "FOV"); y = y + rh + gap
    UI.key_picker(mx, my, clicked, x, y, w, rh, "Aim Key", "aim_key", d.aim_key.value); y = y + rh + gap + 6.0 * s

    UI.section("AimBot Tuning", x, y, w); y = y + 18.0 * s
    UI.slider(mx, my, clicked, down, x, y, w, rh, "FOV Radius", "aim_fov", d.aim_fov.value,
        function(v) d.aim_fov.value = v end, 10.0, 600.0, 5.0, " px", "aim_fov", 124.0); y = y + rh + gap
    UI.slider(mx, my, clicked, down, x, y, w, rh, "Smoothness", "aim_smooth", d.aim_smooth.value,
        function(v) d.aim_smooth.value = v end, 1.0, 50.0, 1.0, "", "aim_sm", 124.0); y = y + rh + gap
    UI.slider(mx, my, clicked, down, x, y, w, rh, "Max Distance", "aim_range", d.aim_range.value,
        function(v) d.aim_range.value = v end, 10.0, 1000.0, 10.0, " m", "aim_rng", 124.0)
end

function UI.render_trigger_tab(mx, my, clicked, down, x, y, w)
    local s = Sys.ui_scale
    local d = Cfg.data
    local rh, gap = 22.0 * s, 2.5 * s

    UI.section("Trigger Bot (Full Player Model)", x, y, w); y = y + 18.0 * s
    d.trig_enabled.value     = UI.toggle(mx, my, clicked, x, y, w, rh, "Enable Trigger Bot", "trig_enabled", d.trig_enabled.value); y = y + rh + gap
    d.trig_only_aiming.value = UI.toggle(mx, my, clicked, x, y, w, rh, "Only While Aiming", "trig_only_aiming", d.trig_only_aiming.value); y = y + rh + gap
    d.trig_ignore_veh.value  = UI.toggle(mx, my, clicked, x, y, w, rh, "Ignore In-Vehicle", "trig_ignore_veh", d.trig_ignore_veh.value); y = y + rh + gap
    d.trig_vis_check.value   = UI.toggle(mx, my, clicked, x, y, w, rh, "Visibility Check", "trig_vis_check", d.trig_vis_check.value); y = y + rh + gap + 6.0 * s

    UI.section("Trigger Timing & Range", x, y, w); y = y + 18.0 * s
    UI.slider(mx, my, clicked, down, x, y, w, rh, "Shot Delay", "trig_delay_ms", d.trig_delay_ms.value,
        function(v) d.trig_delay_ms.value = v end, 0.0, 500.0, 5.0, " ms", "trig_dly", 124.0); y = y + rh + gap
    UI.slider(mx, my, clicked, down, x, y, w, rh, "Shot Cooldown", "trig_interval_ms", d.trig_interval_ms.value,
        function(v) d.trig_interval_ms.value = v end, 20.0, 1000.0, 10.0, " ms", "trig_int", 124.0); y = y + rh + gap
    UI.slider(mx, my, clicked, down, x, y, w, rh, "Max Distance", "trig_range", d.trig_range.value,
        function(v) d.trig_range.value = v end, 10.0, 1000.0, 10.0, " m", "trig_rng", 124.0)
end

function UI.render_colors_tab(mx, my, clicked, down, x, y, w)
    local s = Sys.ui_scale
    local pa = UI.panel_alpha()
    local rh, gap = 20.0 * s, 2.0 * s
    UI.section("ESP & FOV Element", x, y, w)
    y = y + 16.0 * s

    local items = {
        { id = "skeleton", lbl = "Skeleton" },
        { id = "name",     lbl = "Name & Dist" },
        { id = "box",      lbl = "Corner Box" },
        { id = "health",   lbl = "Health Bar" },
        { id = "armor",    lbl = "Armor Bar" },
        { id = "fov",      lbl = "Aim FOV Circle" }
    }
    for i = 1, #items do
        local it = items[i]
        local sel = (UI.color_target == it.id)
        local hov = UI.hit(mx, my, x, y, w, rh + 3.0 * s)
        local r, g, b = Draw.rgb(it.id)
        Draw.rect_px(x, y, w, rh + 3.0 * s, sel and 34 or (hov and 30 or 22), sel and 48 or (hov and 38 or 27), sel and 72 or (hov and 52 or 37), pa, 5.5 * s)
        if sel then Draw.rect_px(x, y + 4.0 * s, 3.0 * s, rh - 5.0 * s, 64, 142, 255, 255, 1.5 * s) end
        UI.label(it.lbl, x + 13.0 * s, Draw.center_y(y, rh + 3.0 * s, 14.0 * s), sel and 255 or 224, sel and 255 or 230, sel and 255 or 242, 255, 14.0, true)

        local sw_w, sw_h = 32.0 * s, 15.0 * s
        local sw_x, sw_y = x + w - sw_w - 12.0 * s, y + math.floor((rh + 3.0 * s - sw_h) * 0.5)
        Draw.rect_px(sw_x - 1.0 * s, sw_y - 1.0 * s, sw_w + 2.0 * s, sw_h + 2.0 * s, 90, 104, 132, 255, 3.5 * s)
        Draw.rect_px(sw_x, sw_y, sw_w, sw_h, r, g, b, 255, 3.0 * s)
        if hov and clicked then UI.commit_edit(); UI.color_target = it.id end
        y = y + rh + 3.0 * s + gap + 2.0 * s
    end

    y = y + 8.0 * s
    UI.section("RGB Channels", x, y, w)
    y = y + 16.0 * s
    local target_id = UI.color_target
    local col = Cfg.data.colors[target_id]

    UI.slider(mx, my, clicked, down, x, y, w, rh + 2.0 * s, "Red", "rgb_r", col.r,
        function(v) Cfg.set_color_channel(target_id, "r", v, false) end,
        0.0, 255.0, 1.0, "", "rgb_r", 124.0, 235, 70, 70); y = y + rh + 4.0 * s + gap
    UI.slider(mx, my, clicked, down, x, y, w, rh + 2.0 * s, "Green", "rgb_g", col.g,
        function(v) Cfg.set_color_channel(target_id, "g", v, false) end,
        0.0, 255.0, 1.0, "", "rgb_g", 124.0, 75, 220, 110); y = y + rh + 4.0 * s + gap
    UI.slider(mx, my, clicked, down, x, y, w, rh + 2.0 * s, "Blue", "rgb_b", col.b,
        function(v) Cfg.set_color_channel(target_id, "b", v, false) end,
        0.0, 255.0, 1.0, "", "rgb_b", 124.0, 75, 145, 255)
end

function UI.render_hotkeys_tab(mx, my, clicked, x, y, w)
    local s = Sys.ui_scale
    local pa = UI.panel_alpha()
    local rh, gap = 21.0 * s, 2.0 * s
    UI.section("Keybinds", x, y, w)
    y = y + 18.0 * s

    UI.key_picker(mx, my, clicked, x, y, w, rh + 4.0 * s, "Menu Toggle Key", "menu_key", Cfg.data.menu_key.value)
    y = y + rh + 4.0 * s + gap + 8.0 * s

    UI.section("Hotkey Mini HUD", x, y, w)
    y = y + 18.0 * s
    Cfg.data.hotkey_hud_enabled.value = UI.toggle(mx, my, clicked, x, y, w, rh + 3.0 * s, "Enable Hotkey HUD",
        "hotkey_hud_enabled", Cfg.data.hotkey_hud_enabled.value); y = y + rh + 5.0 * s + gap
    Cfg.data.hotkey_hud_when_hidden.value = UI.toggle(mx, my, clicked, x, y, w, rh + 3.0 * s, "Show When Menu Hidden",
        "hotkey_hud_when_hidden", Cfg.data.hotkey_hud_when_hidden.value); y = y + rh + 5.0 * s + gap + 8.0 * s

    UI.section("Active Binds List", x, y, w)
    y = y + 18.0 * s
    Draw.rect_px(x, y, w, rh + 2.0 * s, 22, 27, 37, pa, 5.5 * s)
    UI.label("Toggle Menu", x + 13.0 * s, Draw.center_y(y, rh + 2.0 * s, 14.0 * s), 220, 228, 242, 255, 14.0, true)
    UI.label("[ " .. UI.vk_label(Cfg.data.menu_key.value) .. " ]", x + w - 96.0 * s, Draw.center_y(y, rh + 2.0 * s, 14.0 * s), 132, 204, 255, 255, 14.0, true)
end

function UI.render_settings_tab(mx, my, clicked, down, x, y, w)
    local s = Sys.ui_scale
    local pa = UI.panel_alpha()
    local d = Cfg.data
    local rh, gap = 21.0 * s, 2.0 * s

    UI.section("System & Display", x, y, w); y = y + 18.0 * s
    local h_res = UI.hit(mx, my, x, y, w, rh + 2.0 * s)
    Draw.rect_px(x, y, w, rh + 2.0 * s, h_res and 36 or 24, h_res and 46 or 31, h_res and 64 or 43, pa, 5.5 * s)
    UI.label("Screen (" .. Sys.res_label .. ")", x + 13.0 * s, Draw.center_y(y, rh + 2.0 * s, 14.0 * s), 234, 240, 250, 255, 14.0, true)
    local rm = tostring(d.res_mode.value or "2K")
    UI.label((rm == "auto" and "Auto" or rm) .. " >", x + w - 92.0 * s, Draw.center_y(y, rh + 2.0 * s, 14.0 * s), 132, 204, 255, 255, 14.0, true)
    if h_res and clicked then
        local order = { "2K", "1080p", "4K", "auto" }
        local next_rm = "2K"
        for i = 1, #order do
            if order[i] == rm then next_rm = order[(i % #order) + 1]; break end
        end
        Cfg.set("res_mode", next_rm, true)
        UI.apply_resolution(true)
        return true
    end
    y = y + rh + 2.0 * s + gap

    local theme_list = Cfg.theme_choices()
    local cur_theme = Cfg.normalize_choice(d.theme_name.value, theme_list, "Midnight")
    d.theme_name.value = UI.selector(mx, my, clicked, x, y, w, rh + 2.0 * s, "Themes", "theme_name", cur_theme, theme_list, "Midnight")
    y = y + rh + 2.0 * s + gap

    local h_mode = UI.hit(mx, my, x, y, w, rh + 2.0 * s)
    Draw.rect_px(x, y, w, rh + 2.0 * s, h_mode and 36 or 24, h_mode and 46 or 31, h_mode and 64 or 43, pa, 5.5 * s)
    UI.label("Cursor Mode", x + 13.0 * s, Draw.center_y(y, rh + 2.0 * s, 14.0 * s), 234, 240, 250, 255, 14.0, true)
    UI.label(UI.modes[UI.mode_idx] .. " >", x + w - 92.0 * s, Draw.center_y(y, rh + 2.0 * s, 14.0 * s), 132, 204, 255, 255, 14.0, true)
    if h_mode and clicked then UI.mode_idx = (UI.mode_idx % #UI.modes) + 1 end
    y = y + rh + 2.0 * s + gap + 6.0 * s

    UI.section("Theme & Transparency", x, y, w); y = y + 18.0 * s
    UI.slider(mx, my, clicked, down, x, y, w, rh + 2.0 * s, "Panel Opacity", "ui_panel_alpha", d.ui_panel_alpha.value,
        function(v) d.ui_panel_alpha.value = v end, 80.0, 255.0, 1.0, "", "pnl_a", 124.0); y = y + rh + 4.0 * s + gap
    UI.slider(mx, my, clicked, down, x, y, w, rh + 2.0 * s, "Backdrop Glow", "theme_glow", d.theme_glow.value,
        function(v) d.theme_glow.value = v end, 0.0, 255.0, 1.0, "", "thm_g", 124.0)
    y = y + rh + 4.0 * s + gap + 8.0 * s

    UI.section("Storage & Provisioning", x, y, w); y = y + 18.0 * s
    Draw.rect_px(x, y, w, 54.0 * s, 18, 22, 31, pa, 5.5 * s)
    UI.label("Dir: " .. Cfg.root, x + 12.0 * s, y + 6.0 * s, 132, 204, 255, 255, 11.5, true)
    local t_file = Cfg.theme_file_for_name(d.theme_name.value)
    local t_info = t_file and ("Theme img: " .. t_file.file) or ("Theme: " .. tostring(d.theme_name.value) .. " [saved]")
    UI.label(t_info, x + 12.0 * s, y + 21.0 * s, 188, 210, 240, 255, 11.5, true)
    local st_txt = ThemeImg.last_error
        or ((Gen.written_count > 0)
            and ("Saved: " .. tostring(Gen.written_count) .. " files [" .. Gen.backend_used .. "]")
            or (Gen.last_error or "Ready"))
    UI.label(st_txt, x + 12.0 * s, y + 36.0 * s, 168, 180, 202, 255, 11.5, true)
    return false
end

function UI.render_preview(mx, my, clicked, down, px, py, pw, ph)
    local s = Sys.ui_scale
    local pa = UI.panel_alpha()
    local d = Cfg.data
    local top_h = 24.0 * s
    local is_veh = (UI.preview_mode == "vehicle")
    local pfx = is_veh and "veh_" or ""

    Draw.rect_px(px - 1.0 * s, py - 1.0 * s, pw + 2.0 * s, ph + 2.0 * s, 34, 43, 62, 200, 8.0 * s)
    Draw.rect_px(px, py, pw, ph, 12, 14, 20, math.floor(pa * 0.22), 7.5 * s)

    Draw.rect_px(px, py, pw, top_h, 22, 27, 39, math.min(255, pa + 55), 7.5 * s)
    UI.label("LIVE PREVIEW (" .. (is_veh and "VEH" or "PED") .. " / " .. Cfg.skel_style(d[pfx .. "skel_style"].value) .. ")",
        px + 10.0 * s, Draw.center_y(py, top_h, 11.5 * s), 134, 154, 190, 255, 11.5, true)

    local stage_top = py + top_h + 44.0 * s
    local bh = math.max(120.0 * s, (py + ph - 14.0 * s) - stage_top)
    local bw = Sys.clamp(bh * 0.56, 90.0 * s, pw - 96.0 * s)
    local bx = px + (pw - bw) * 0.5
    local by = stage_top

    if not d[pfx .. "enabled"].value then
        UI.label((is_veh and "Vehicle ESP" or "Player ESP") .. " Disabled", bx + 8.0 * s, by + 46.0 * s, 155, 162, 178, 255, 14.0, true)
        return
    end

    if not down and UI.dragging_preview then
        local drag_key = UI.dragging_preview.key
        UI.dragging_preview = nil
        if drag_key and Gen.provisioned then Cfg.save_key(drag_key) end
    end

    local function drag_item(id, ox_key, oy_key, ox_o, oy_o, hx, hy, hw, hh)
        if clicked and not UI.dragging_preview and UI.hit(mx, my, hx, hy, hw, hh) then
            UI.commit_edit()
            UI.dragging_preview = { id = id, ox_key = ox_key, oy_key = oy_key, key = ox_key }
            UI.preview_ox = mx - (tonumber(ox_o.value) or 0.0) * s
            UI.preview_oy = my - (tonumber(oy_o.value) or 0.0) * s
        end
        if UI.dragging_preview and UI.dragging_preview.id == id then
            ox_o.value = Sys.clamp((mx - UI.preview_ox) / math.max(0.01, s), -600.0, 600.0)
            oy_o.value = Sys.clamp((my - UI.preview_oy) / math.max(0.01, s), -400.0, 400.0)
            UI.dragging_preview.key = ox_key
        end
    end

    local box_ox_k, box_oy_k = pfx .. "box_offset_x", pfx .. "box_offset_y"
    local box_ox, box_oy = d[box_ox_k], d[box_oy_k]
    local draw_bx = bx + (tonumber(box_ox.value) or 0.0) * s
    local draw_by = by + (tonumber(box_oy.value) or 0.0) * s

    if d[pfx .. "box"].value then
        drag_item("box", box_ox_k, box_oy_k, box_ox, box_oy, draw_bx - 8.0 * s, draw_by - 8.0 * s, bw + 16.0 * s, bh + 16.0 * s)
        draw_bx = bx + (tonumber(box_ox.value) or 0.0) * s
        draw_by = by + (tonumber(box_oy.value) or 0.0) * s
        Draw.box_style(d[pfx .. "box_style"].value, draw_bx, draw_bx + bw, draw_by, draw_by + bh,
            FrameCache.box_rgb[1], FrameCache.box_rgb[2], FrameCache.box_rgb[3], 2.2 * s, false)
    end

    local bar_w = math.max(3.5 * s, math.min(11.0 * s, (tonumber(d[pfx .. "bar_size"].value) or 2.0) * 1.5 * s))
    local gap = math.max(7.0 * s, bar_w + 3.5 * s)
    local hit_w = math.max(18.0 * s, bar_w + 10.0 * s)

    if d[pfx .. "health"].value then
        local hox_k, hoy_k = pfx .. "hp_offset_x", pfx .. "hp_offset_y"
        local hox, hoy = d[hox_k], d[hoy_k]
        local hx = draw_bx - gap - bar_w + (tonumber(hox.value) or 0.0) * s
        local hy = draw_by + (tonumber(hoy.value) or 0.0) * s
        drag_item("hp", hox_k, hoy_k, hox, hoy, hx - (hit_w - bar_w) * 0.5, hy - 6.0 * s, hit_w, bh + 12.0 * s)
        hx = draw_bx - gap - bar_w + (tonumber(hox.value) or 0.0) * s
        hy = draw_by + (tonumber(hoy.value) or 0.0) * s
        Draw.rect_px(hx, hy, bar_w, bh, 10, 12, 16, 180, 0.0)
        Draw.rect_px(hx, hy + bh * 0.12, bar_w, bh * 0.88, FrameCache.hp_rgb[1], FrameCache.hp_rgb[2], FrameCache.hp_rgb[3], 255, 0.0)
    end

    if d[pfx .. "armour"].value then
        local aox_k, aoy_k = pfx .. "arm_offset_x", pfx .. "arm_offset_y"
        local aox, aoy = d[aox_k], d[aoy_k]
        local ax = draw_bx + bw + gap + (tonumber(aox.value) or 0.0) * s
        local ay = draw_by + (tonumber(aoy.value) or 0.0) * s
        drag_item("arm", aox_k, aoy_k, aox, aoy, ax - (hit_w - bar_w) * 0.5, ay - 6.0 * s, hit_w, bh + 12.0 * s)
        ax = draw_bx + bw + gap + (tonumber(aox.value) or 0.0) * s
        ay = draw_by + (tonumber(aoy.value) or 0.0) * s
        Draw.rect_px(ax, ay, bar_w, bh, 10, 12, 16, 180, 0.0)
        Draw.rect_px(ax, ay + bh * 0.25, bar_w, bh * 0.75, FrameCache.arm_rgb[1], FrameCache.arm_rgb[2], FrameCache.arm_rgb[3], 255, 0.0)
    end

    if d[pfx .. "skeleton"].value then
        UI.draw_preview_skeleton(draw_bx + bw * 0.5, draw_by, bh, d[pfx .. "skel_size"].value,
            d[pfx .. "rgb_skeleton"].value, d[pfx .. "skel_style"].value, d[pfx .. "bone_outline"].value == true)
    end

    local _, _, self_name = Esp.self_info()
    local cap = d[pfx .. "names"].value and tostring(self_name or "Self") or ""
    if d[pfx .. "distance"].value then
        cap = (cap ~= "") and (cap .. " [0 m]") or "[0 m]"
    end
    if cap ~= "" then
        local sz = tonumber(d[pfx .. "size"].value) or 24.0
        local fpx = math.max(13.0, math.min(25.0, 13.0 + ((sz - 10.0) / 90.0) * 12.0))
        local est_w = #cap * (fpx * s * 0.50)
        local min_y, max_y = py + top_h + 6.0 * s, py + ph - fpx * s - 6.0 * s
        local nox_k, noy_k = pfx .. "name_offset_x", pfx .. "name_offset_y"
        local nox, noy = d[nox_k], d[noy_k]
        local base_x = Sys.clamp(draw_bx + bw * 0.5 - est_w * 0.5, px + 8.0 * s, px + pw - est_w - 8.0 * s)
        local base_y = Sys.clamp(draw_by - fpx * s - 6.0 * s, min_y, max_y)
        local cur_x = Sys.clamp(base_x + (tonumber(nox.value) or 0.0) * s, px + 6.0 * s, px + pw - est_w - 6.0 * s)
        local cur_y = Sys.clamp(base_y + (tonumber(noy.value) or 0.0) * s, min_y, max_y)

        drag_item("name", nox_k, noy_k, nox, noy, cur_x - 8.0 * s, cur_y - 6.0 * s, est_w + 16.0 * s, fpx * s + 12.0 * s)
        local fx = Sys.clamp(base_x + (tonumber(nox.value) or 0.0) * s, px + 6.0 * s, px + pw - est_w - 6.0 * s)
        local fy = Sys.clamp(base_y + (tonumber(noy.value) or 0.0) * s, min_y, max_y)
        UI.label(cap, fx, fy, FrameCache.name_rgb[1], FrameCache.name_rgb[2], FrameCache.name_rgb[3], 255, fpx, true)
    end
end

function UI.render_menu(clicked, down)
    local s = Sys.ui_scale
    local pa = UI.panel_alpha()
    local glow_a = UI.theme_glow_alpha()
    local acc, glw, pnl, hdr = Draw.theme_palette()
    local mx, my = UI.cur_mx, UI.cur_my

    local cw, ch = 24.0 * s, 22.0 * s
    local cx, cy = UI.x + UI.w - cw - 10.0 * s, UI.y + 10.0 * s
    local h_close = UI.hit(mx, my, cx, cy, cw, ch)
    if clicked and h_close then UI.close(); return end

    local child_drag = (UI.dragging_slider ~= nil) or (UI.dragging_preview ~= nil) or UI.dragging_hud
    if clicked and not h_close and not child_drag and UI.hit(mx, my, UI.x, UI.y, UI.w, UI.header_h) then
        UI.dragging = true
        UI.drag_ox, UI.drag_oy = mx - UI.x, my - UI.y
    elseif not down then
        UI.dragging = false
    end

    if UI.dragging then
        UI.x = Sys.clamp(mx - UI.drag_ox, 0.0, math.max(0.0, Sys.scr_w - UI.w))
        UI.y = Sys.clamp(my - UI.drag_oy, 0.0, math.max(0.0, Sys.scr_h - UI.h))
        cx, cy = UI.x + UI.w - cw - 10.0 * s, UI.y + 10.0 * s
        h_close = UI.hit(mx, my, cx, cy, cw, ch)
    end

    Draw.menu_backdrop(UI.x, UI.y, UI.w, UI.h, pnl, glw, acc, pa, glow_a, s)

    Draw.rect_px(UI.x, UI.y, UI.w, UI.header_h, hdr.r, hdr.g, hdr.b, math.min(255, pa + 55), 9.5 * s)
    Draw.rect_px(UI.x, UI.y + UI.header_h - 1.0 * s, UI.w, 1.0 * s, 38, 48, 68, 255, 0.0)
    Draw.rect_px(UI.x + 12.0 * s, UI.y + 11.0 * s, 4.0 * s, 20.0 * s, acc.r, acc.g, acc.b, 255, 2.0 * s)

    UI.label("Bubblewrap Menu", UI.x + 22.0 * s, Draw.center_y(UI.y, UI.header_h, 15.5 * s), 248, 252, 255, 255, 15.5, true)
    UI.label("[" .. UI.vk_label(Cfg.data.menu_key.value) .. "]", UI.x + 162.0 * s, Draw.center_y(UI.y, UI.header_h, 12.5 * s), 126, 148, 186, 255, 12.5, true)

    local tabs = {
        { id = "player",   lbl = "Player" },
        { id = "vehicle",  lbl = "Vehicle" },
        { id = "aimbot",   lbl = "AimBot" },
        { id = "trigger",  lbl = "Trigger" },
        { id = "colors",   lbl = "Colors" },
        { id = "hotkeys",  lbl = "Hotkeys" },
        { id = "settings", lbl = "Settings" }
    }
    local tw, th = 62.0 * s, 22.0 * s
    local ty = UI.y + math.floor((UI.header_h - th) * 0.5)
    for i = 1, #tabs do
        local tb = tabs[i]
        local tx = UI.x + 204.0 * s + (i - 1) * (tw + 4.0 * s)
        local act = (UI.tab == tb.id)
        local hov = UI.hit(mx, my, tx, ty, tw, th)
        Draw.rect_px(tx, ty, tw, th, act and acc.r or (hov and 34 or 25), act and acc.g or (hov and 43 or 31), act and acc.b or (hov and 58 or 43), 245, 5.0 * s)
        UI.centered(tb.lbl, tx, ty, tw, th, act and 255 or (hov and 245 or 206), act and 255 or (hov and 248 or 214), act and 255 or (hov and 255 or 228), 255, 12.5, "center")
        if clicked and hov and not act then
            UI.commit_edit()
            UI.tab = tb.id
            if tb.id == "player" or tb.id == "vehicle" then UI.preview_mode = tb.id end
        end
    end

    Draw.rect_px(cx, cy, cw, ch, h_close and 215 or 42, h_close and 52 or 34, h_close and 64 or 44, 255, 5.0 * s)
    UI.centered("X", cx, cy, cw, ch, 255, 255, 255, 255, 14.0, "center")

    local lx = UI.x + UI.pad
    local ly = UI.y + UI.header_h + UI.pad
    local col_w = 364.0 * s

    if UI.tab == "player" then
        UI.render_entity_tab(mx, my, clicked, down, lx, ly, col_w, false)
    elseif UI.tab == "vehicle" then
        UI.render_entity_tab(mx, my, clicked, down, lx, ly, col_w, true)
    elseif UI.tab == "aimbot" then
        UI.render_aimbot_tab(mx, my, clicked, down, lx, ly, col_w)
    elseif UI.tab == "trigger" then
        UI.render_trigger_tab(mx, my, clicked, down, lx, ly, col_w)
    elseif UI.tab == "colors" then
        UI.render_colors_tab(mx, my, clicked, down, lx, ly, col_w)
    elseif UI.tab == "hotkeys" then
        UI.render_hotkeys_tab(mx, my, clicked, lx, ly, col_w)
    else
        if UI.render_settings_tab(mx, my, clicked, down, lx, ly, col_w) then return end
    end

    local px = lx + col_w + UI.pad
    local pw = UI.w - col_w - UI.pad * 3.0
    local ph = math.max(220.0 * s, (UI.y + UI.h - UI.pad) - ly)
    UI.render_preview(mx, my, clicked, down, px, ly, pw, ph)
end

-- ============================================================================
-- [STAGE 7] Runtime Loop & Safe Startup
-- ============================================================================
local Lifecycle = {
    warned = false
}

function Lifecycle.warn(prefix, err)
    if Lifecycle.warned then return end
    Lifecycle.warned = true
    bubblewrap_toast(prefix .. ": " .. tostring(err))
end

function Lifecycle.tick()
    Sys.now = Sys.clock()
    FrameCache.valid = false

    local need_players = Cfg.data.enabled.value or Cfg.data.veh_enabled.value
        or Cfg.data.aim_enabled.value or Cfg.data.trig_enabled.value
    if need_players and not Sys.is_paused() then
        pcall(FrameCache.refresh)
    end

    local e_ok, e_err = pcall(Esp.frame)
    if not e_ok then Lifecycle.warn("ESP warn", e_err) end

    local a_ok, a_err = pcall(Aim.tick)
    if not a_ok then Lifecycle.warn("Aim warn", a_err) end

    local t_ok, t_err = pcall(Trig.tick)
    if not t_ok then Lifecycle.warn("Trigger warn", t_err) end

    if UI.binding_target then
        pcall(Sys.block_game_input)
        pcall(UI.poll_bind)
    else
        local bind_vk = tonumber(Cfg.data.menu_key.value) or 0x2D
        local bind_down = UI.button_down(input and input.key, bind_vk)
        if bind_down and not UI._was_bind then
            if UI.open then
                UI.close()
            else
                UI.open = true
                UI.last_mx, UI.last_my = nil, nil
                UI.dx, UI.dy = 0.0, 0.0
                UI.sync_cursor()
                pcall(Sys.block_game_input)
            end
        end
        UI._was_bind = bind_down
    end

    local lmb = UI.button_down(input and input.mouse, VK_LBUTTON)
    local clicked = lmb and not UI._was_lmb

    if UI.open or UI.dragging_hud then
        pcall(UI.update_mouse)
    end

    pcall(UI.render_hud, clicked, lmb)

    if UI.open then
        pcall(Sys.block_game_input)
        pcall(UI.sync_cursor)
        pcall(UI.poll_number_edit)
        UI.render_menu(clicked, lmb)
    elseif UI.dragging_hud then
        pcall(Sys.block_game_input)
        pcall(UI.sync_cursor)
    else
        pcall(UI.hide_cursor)
    end

    UI._was_lmb = lmb
end

function Lifecycle.cleanup()
    UI.commit_edit()
    if Gen.provisioned then
        pcall(Cfg.save_all)
    end
    UI.force_unload_cleanup()
end

if util and type(util.on_stop) == "function" then
    pcall(util.on_stop, Lifecycle.cleanup)
end

pcall(function()
    Gen.generate_all_files(Cfg)
    Cfg.load_from_disk()
end)

UI.apply_resolution(false)

util.create_thread(function()
    while UI.running do
        local ok, err = pcall(Lifecycle.tick)
        if not ok then Lifecycle.warn("Loop warn", err) end
        util.yield(0)
    end
    Lifecycle.cleanup()
end)

bubblewrap_toast("Bubblewrap Menu loaded")