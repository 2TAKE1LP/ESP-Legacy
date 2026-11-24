local HASH = {
    player_id = 0x4F8644AF03D0E0D6,
    player_ped = 0xD80958FC74E988A6,
    player_active = 0xB8DFD30D6973E135,
    get_player_ped = 0x43A66C31C68491C0,
    get_player_name = 0x6D0DE6A7B5DA71F8,
    entity_exists = 0x7239B21A38F536BA,
    entity_coords = 0x3FEF770D40960D5A,
    bone_coords = 0x17C07FC640E86B4E,
    ped_dead = 0x3317DEDB88C95038,
    ped_in_vehicle = 0x997ABD671D25CA0B,
    entity_health = 0xEEF059FAD016D209,
    entity_max_health = 0x15D757606D170C3C,
    ped_armour = 0x9483AF821605B1D8,
    screen_coords = 0x34E82F05DF2974F5,
    draw_rect = 0x3A618A217E5154F0,
    disable_control_action = 0xFE99B66D079CF6BC,
    is_pause_menu_active = 0x535DB43E6352AD21,
    get_active_screen_resolution = 0x873C9F3104101DD3
}

local BONES = {
    head = 31086,
    neck = 39317,
    spine2 = 24817,
    pelvis = 11816,
    luarm = 45509, llarm = 61163, lhand = 18905,
    ruarm = 40269, rlarm = 28252, rhand = 57005,
    lthigh = 58271, lcalf = 63931, lfoot = 14201,
    rthigh = 51826, rcalf = 36864, rfoot = 52301
}

local BONE_GROUPS = {
    spine = {
        {BONES.neck, BONES.head},
        {BONES.neck, BONES.spine2},
        {BONES.spine2, BONES.pelvis}
    },
    arms = {
        {BONES.neck, BONES.luarm},
        {BONES.luarm, BONES.llarm},
        {BONES.llarm, BONES.lhand},
        {BONES.neck, BONES.ruarm},
        {BONES.ruarm, BONES.rlarm},
        {BONES.rlarm, BONES.rhand}
    },
    legs = {
        {BONES.pelvis, BONES.lthigh},
        {BONES.lthigh, BONES.lcalf},
        {BONES.lcalf, BONES.lfoot},
        {BONES.pelvis, BONES.rthigh},
        {BONES.rthigh, BONES.rcalf},
        {BONES.rcalf, BONES.rfoot}
    }
}

local BONE_GROUPS_VEH = {
    spine = {
        {BONES.neck, BONES.head},
        {BONES.neck, BONES.spine2},
        {BONES.spine2, BONES.pelvis}
    },
    arms = {
        {BONES.neck, BONES.luarm},
        {BONES.luarm, BONES.llarm},
        {BONES.neck, BONES.ruarm},
        {BONES.ruarm, BONES.rlarm}
    },
    legs = {
        {BONES.pelvis, BONES.lthigh},
        {BONES.lthigh, BONES.lcalf},
        {BONES.pelvis, BONES.rthigh},
        {BONES.rthigh, BONES.rcalf}
    }
}

local function toast(message)
    if notify and type(notify.push) == 'function' then
        pcall(notify.push, 'Player ESP', tostring(message), {time = 5000})
    elseif type(print) == 'function' then
        pcall(print, tostring(message))
    end
end

if not (invoker and type(invoker.call) == 'function' and util and type(util.create_thread) == 'function') then
    toast('Lexis API unavailable')
    return
end

if game and type(game.build) == 'function' then
    local ok, build = pcall(game.build)
    if ok and type(build) == 'string' and build:lower() == 'enhanced' then
        toast('This script is for GTA V Legacy')
        return
    end
end

local function load_natives()
    if type(_G.native) == 'table' then return _G.native end
    if type(_G.natives) == 'table' then return _G.natives end
    if type(require) == 'function' then
        local ok, result = pcall(require, 'natives')
        if ok and type(result) == 'table' then
            _G.native = result
            return result
        end
    end
    if type(dofile) == 'function' then
        local candidates = {}
        if type(paths) == 'table' and type(paths.script) == 'string' then
            local dir = paths.script
            if dir:sub(-1) ~= '\\' and dir:sub(-1) ~= '/' then dir = dir .. '\\' end
            candidates[#candidates + 1] = dir .. 'natives.lua'
        end
        if type(paths) == 'table' and type(paths.game) == 'string' then
            candidates[#candidates + 1] = paths.game .. '\\scripts\\natives.lua'
        end
        candidates[#candidates + 1] = 'natives.lua'
        candidates[#candidates + 1] = '.\\natives.lua'
        candidates[#candidates + 1] = './natives.lua'
        candidates[#candidates + 1] = 'scripts\\natives.lua'
        candidates[#candidates + 1] = 'scripts/natives.lua'
        for i = 1, #candidates do
            local ok, result = pcall(dofile, candidates[i])
            if ok and type(result) == 'table' then
                _G.native = result
                return result
            end
            if type(_G.native) == 'table' then return _G.native end
            if type(_G.natives) == 'table' then return _G.natives end
        end
    end
    return nil
end

local N = load_natives()

local function field(object, key)
    if object == nil then return nil end
    local ok, result = pcall(function() return object[key] end)
    if ok then return result end
    return nil
end

local function first_field(object, keys)
    for i = 1, #keys do
        local result = field(object, keys[i])
        if result ~= nil then return result end
    end
    return nil
end

local function call_native(name, hash, ...)
    local fn = N and N[name] or nil
    if type(fn) == 'function' then
        local ok, a, b, c = pcall(fn, ...)
        if ok then return a, b, c, true end
    end
    local ok, a, b, c = pcall(invoker.call, hash, ...)
    if ok then return a, b, c, true end
    return nil, nil, nil, false
end

local function as_bool(value)
    if type(value) == 'boolean' then return value end
    if type(value) == 'number' then return value ~= 0 end
    local v = first_field(value, {'bool', 'value', 'result'})
    if type(v) == 'boolean' then return v end
    if type(v) == 'number' then return v ~= 0 end
    return false
end

local function as_number(value, keys)
    if type(value) == 'number' then return value end
    return tonumber(first_field(value, keys or {'int', 'float', 'int64', 'value', 'result'}))
end

local function as_string(value)
    if type(value) == 'string' then return value end
    local v = first_field(value, {'str', 'string', 'value', 'text'})
    if type(v) == 'string' then return v end
    return nil
end

local function as_vec3(a, b, c)
    if type(a) == 'number' and type(b) == 'number' and type(c) == 'number' then
        return {x = a, y = b, z = c}
    end
    if a == nil then return nil end
    local nested = first_field(a, {'scr_vec3', 'vector3', 'vector', 'vec3', 'value'})
    local v = nested or a
    local x = tonumber(field(v, 'x') or field(v, 'X') or field(v, 1))
    local y = tonumber(field(v, 'y') or field(v, 'Y') or field(v, 2))
    local z = tonumber(field(v, 'z') or field(v, 'Z') or field(v, 3))
    if x and y and z and x == x and y == y and z == z then
        return {x = x, y = y, z = z}
    end
    return nil
end

local function get_int(name, hash, ...)
    local result = call_native(name, hash, ...)
    return as_number(result, {'int', 'int64', 'integer', 'value', 'result'}) or 0
end

local function get_bool(name, hash, ...)
    return as_bool(call_native(name, hash, ...))
end

local function get_vec3(name, hash, ...)
    local a, b, c = call_native(name, hash, ...)
    return as_vec3(a, b, c)
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function detect_game_resolution()
    if type(pointer_int) == 'function' then
        local px = pointer_int()
        local py = pointer_int()
        if px and py then
            local fn = N and N.get_active_screen_resolution or nil
            local ok, res
            if type(fn) == 'function' then
                ok, res = pcall(fn, px, py)
            else
                ok, res = pcall(invoker.call, HASH.get_active_screen_resolution, px:address(), py:address())
            end
            if ok then
                local w = tonumber(px.value) or as_number(res)
                local h = tonumber(py.value)
                if w and h and w >= 800 and h >= 600 and w <= 7680 and h <= 4320 then
                    return w, h
                end
            end
        end
    end

    local res_sources = { _G.screen, _G.display, _G.graphics, _G.render, gui }
    for i = 1, #res_sources do
        local src = res_sources[i]
        if src then
            local w = tonumber(first_field(src, {'width', 'screen_width', 'res_x', 'w'}))
            local h = tonumber(first_field(src, {'height', 'screen_height', 'res_y', 'h'}))
            if w and h and w >= 800 and h >= 600 and w <= 7680 and h <= 4320 then
                return w, h
            end
        end
    end

    return 2560.0, 1440.0
end

local AUTO_W, AUTO_H = detect_game_resolution()
local SCR_W, SCR_H = AUTO_W, AUTO_H
local UI_SCALE = 1.0
local ACTIVE_RES_LABEL = "2K"

local function format_res_label(w, h)
    local iw, ih = math.floor(w + 0.5), math.floor(h + 0.5)
    if iw == 1920 and ih == 1080 then return "1920x1080 [1080p]" end
    if iw == 2560 and ih == 1440 then return "2560x1440 [2K]" end
    if iw == 3840 and ih == 2160 then return "3840x2160 [4K]" end
    return tostring(iw) .. "x" .. tostring(ih)
end

local CUSTOM_FONT = nil
local loaded_font_px = 0.0

local function ensure_font(target_px)
    local px = clamp(tonumber(target_px) or 20.0, 12.0, 48.0)
    if CUSTOM_FONT and math.abs(px - loaded_font_px) < 1.5 then
        return CUSTOM_FONT
    end
    if gui and type(gui.load_font) == 'function' then
        local font_paths = {
            'C:\\Windows\\Fonts\\seguisb.ttf',
            'C:\\Windows\\Fonts\\bahnschrift.ttf',
            'C:\\Windows\\Fonts\\arialbd.ttf',
            'C:\\Windows\\Fonts\\segoeui.ttf'
        }
        for i = 1, #font_paths do
            local ok, f = pcall(gui.load_font, font_paths[i], px)
            if ok and f then
                CUSTOM_FONT = f
                loaded_font_px = px
                if type(gui.rebuild) == 'function' then
                    pcall(gui.rebuild)
                end
                break
            end
        end
    end
    return CUSTOM_FONT
end

local function is_pause_menu_active()
    return get_bool('is_pause_menu_active', HASH.is_pause_menu_active)
end

local BLOCKED_CONTROLS = {
    0, 1, 2, 3, 4, 5, 6,
    21, 22, 23, 24, 25, 37, 44, 45,
    68, 69, 70, 75, 91, 92, 106, 114, 122, 135, 140, 141, 142, 143, 257, 263, 264
}

local function block_camera_and_game_input()
    for i = 1, #BLOCKED_CONTROLS do
        call_native('disable_control_action', HASH.disable_control_action, 0, BLOCKED_CONTROLS[i], true)
        call_native('disable_control_action', HASH.disable_control_action, 2, BLOCKED_CONTROLS[i], true)
    end
end

local function entity_exists(ped)
    if type(ped) ~= 'number' or ped <= 0 then return false end
    return get_bool('does_entity_exist', HASH.entity_exists, ped)
end

local function entity_coords(ped)
    return get_vec3('get_entity_coords', HASH.entity_coords, ped, true)
end

local function bone_coords(ped, bone_id)
    local v = get_vec3('get_ped_bone_coords', HASH.bone_coords, ped, bone_id, 0.0, 0.0, 0.0)
    if not v then return nil end
    if math.abs(v.x) < 0.001 and math.abs(v.y) < 0.001 and math.abs(v.z) < 0.001 then
        return nil
    end
    return v
end

local screen_x = type(pointer_float) == 'function' and pointer_float() or nil
local screen_y = type(pointer_float) == 'function' and pointer_float() or nil

local function world_to_screen(pos)
    if not pos then return nil end
    if screen_x and screen_y then
        local fn = N and N.get_screen_coord_from_world_coord or nil
        local ok, result
        if type(fn) == 'function' then
            ok, result = pcall(fn, pos.x, pos.y, pos.z, screen_x, screen_y)
        else
            ok, result = pcall(invoker.call, HASH.screen_coords,
                pos.x, pos.y, pos.z, screen_x:address(), screen_y:address())
        end
        if ok and as_bool(result) then
            local x, y = tonumber(screen_x.value), tonumber(screen_y.value)
            if x and y and x == x and y == y and x >= -5.0 and y >= -5.0 and x <= 6.0 and y <= 6.0 then
                return {x = x, y = y}
            end
        end
    end
    return nil
end

local function draw_esp_rect(x, y, w, h, r, g, b, a)
    if w <= 0 or h <= 0 then return end
    call_native('draw_rect', HASH.draw_rect, x, y, w, h, r, g, b, a, false)
end

local function clip_segment_2d(x0, y0, x1, y1)
    local t0, t1 = 0.0, 1.0
    local dx, dy = x1 - x0, y1 - y0
    local checks = {
        {-dx, x0},
        {dx, 1.0 - x0},
        {-dy, y0},
        {dy, 1.0 - y0}
    }
    for i = 1, 4 do
        local p, q = checks[i][1], checks[i][2]
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

local function rgb_color(phase)
    local p = phase or 0.0
    local r = math.floor(math.sin(p) * 127.5 + 127.5)
    local g = math.floor(math.sin(p + 2.0943951) * 127.5 + 127.5)
    local b = math.floor(math.sin(p + 4.1887902) * 127.5 + 127.5)
    return r, g, b
end

local settings = {
    enabled = {value = true},
    hide_skel_veh = {value = false},
    names = {value = true},
    skeleton = {value = true},
    rgb_skeleton = {value = false},
    box = {value = true},
    health = {value = true},
    armour = {value = true},
    distance = {value = true},
    show_self = {value = true},
    range = {value = 10000},
    size = {value = 22},
    skel_size = {value = 25},
    bar_size = {value = 2},
    menu_key = {value = 0x2D},
    res_mode = {value = "auto"},
    skel_parts = {
        spine = true,
        arms = true,
        legs = true
    },
    colors = {
        skeleton = {r = 244, g = 248, b = 255},
        name     = {r = 248, g = 252, b = 255},
        box      = {r = 225, g = 238, b = 248},
        health   = {r = 75,  g = 220, b = 120},
        armor    = {r = 90,  g = 165, b = 255}
    }
}

local UI = {
    open = true,
    tab = "esp",
    color_target = "skeleton",

    binding_key = false,
    _prev_bind_scan = {},

    dragging = false,
    drag_ox = 0.0,
    drag_oy = 0.0,
    dragging_range = false,
    dragging_size = false,
    dragging_skel_size = false,
    dragging_bar_size = false,
    dragging_rgb = nil,
    x = 90.0,
    y = 70.0,
    w = 780.0,
    h = 716.0,
    header_h = 44.0,
    pad = 16.0,

    mode_idx = 1,
    modes = { "Windows", "Raw Input", "DirectInput" },

    cur_mx = 0.0,
    cur_my = 0.0,
    last_mx = nil,
    last_my = nil,
    dx = 0.0,
    dy = 0.0,

    editing_key = nil,
    edit_buf = "",
    edit_min = 0,
    edit_max = 10000,
    _prev_digit_states = {},
    _prev_bksp = false,
    _prev_enter = false,

    _cursor_shown = false,
    _was_lmb_down = false,
    _was_bind_down = false,
    _running = true
}

local function apply_resolution_mode(notify_change)
    local mode = tostring(settings.res_mode.value or "auto")
    if mode == "1080p" then
        SCR_W, SCR_H = 1920.0, 1080.0
    elseif mode == "2K" then
        SCR_W, SCR_H = 2560.0, 1440.0
    elseif mode == "4K" then
        SCR_W, SCR_H = 3840.0, 2160.0
    else
        SCR_W, SCR_H = AUTO_W, AUTO_H
    end

    UI_SCALE = clamp(SCR_H / 1440.0, 0.70, 2.0)
    ACTIVE_RES_LABEL = format_res_label(SCR_W, SCR_H)

    UI.w = 780.0 * UI_SCALE
    UI.h = 716.0 * UI_SCALE
    UI.header_h = 44.0 * UI_SCALE
    UI.pad = 16.0 * UI_SCALE
    UI.x = clamp(UI.x, 12.0 * UI_SCALE, math.max(12.0 * UI_SCALE, SCR_W - UI.w - 12.0 * UI_SCALE))
    UI.y = clamp(UI.y, 12.0 * UI_SCALE, math.max(12.0 * UI_SCALE, SCR_H - UI.h - 12.0 * UI_SCALE))

    ensure_font(20.0 * UI_SCALE)
    if notify_change then
        toast("Screen: " .. ACTIVE_RES_LABEL)
    end
end

local CONFIG_PATH = nil
do
    if type(paths) == 'table' and type(paths.script) == 'string' then
        local dir = paths.script
        if dir:sub(-1) ~= '\\' and dir:sub(-1) ~= '/' then dir = dir .. '\\' end
        CONFIG_PATH = dir .. 'player_esp_config.cfg'
    else
        CONFIG_PATH = 'player_esp_config.cfg'
    end
end

local function serialize_value(v)
    if type(v) == 'boolean' then return v and 'true' or 'false' end
    if type(v) == 'number' then return tostring(v) end
    if type(v) == 'string' then return v end
    return '0'
end

local function save_config()
    if type(io) ~= 'table' or type(io.open) ~= 'function' then return end
    local ok, f = pcall(io.open, CONFIG_PATH, 'w')
    if not ok or not f then return end
    pcall(function()
        f:write('enabled=' .. serialize_value(settings.enabled.value) .. '\n')
        f:write('hide_skel_veh=' .. serialize_value(settings.hide_skel_veh.value) .. '\n')
        f:write('names=' .. serialize_value(settings.names.value) .. '\n')
        f:write('skeleton=' .. serialize_value(settings.skeleton.value) .. '\n')
        f:write('rgb_skeleton=' .. serialize_value(settings.rgb_skeleton.value) .. '\n')
        f:write('box=' .. serialize_value(settings.box.value) .. '\n')
        f:write('health=' .. serialize_value(settings.health.value) .. '\n')
        f:write('armour=' .. serialize_value(settings.armour.value) .. '\n')
        f:write('distance=' .. serialize_value(settings.distance.value) .. '\n')
        f:write('show_self=' .. serialize_value(settings.show_self.value) .. '\n')
        f:write('range=' .. serialize_value(settings.range.value) .. '\n')
        f:write('size=' .. serialize_value(settings.size.value) .. '\n')
        f:write('skel_size=' .. serialize_value(settings.skel_size.value) .. '\n')
        f:write('bar_size=' .. serialize_value(settings.bar_size.value) .. '\n')
        f:write('menu_key=' .. serialize_value(settings.menu_key.value) .. '\n')
        f:write('res_mode=' .. serialize_value(settings.res_mode.value) .. '\n')
        f:write('part_spine=' .. serialize_value(settings.skel_parts.spine ~= false) .. '\n')
        f:write('part_arms=' .. serialize_value(settings.skel_parts.arms ~= false) .. '\n')
        f:write('part_legs=' .. serialize_value(settings.skel_parts.legs ~= false) .. '\n')
        for part, col in pairs(settings.colors) do
            f:write(string.format('col_%s=%d,%d,%d\n', part,
                tonumber(col.r) or 255, tonumber(col.g) or 255, tonumber(col.b) or 255))
        end
        f:close()
    end)
end

local function load_config()
    if type(io) ~= 'table' or type(io.open) ~= 'function' then return end
    local ok, f = pcall(io.open, CONFIG_PATH, 'r')
    if not ok or not f then return end
    pcall(function()
        local content = f:read('*a')
        f:close()
        if type(content) ~= 'string' or content == '' then return end
        for line in content:gmatch('[^\r\n]+') do
            local k, v = line:match('^([%w_]+)%s*=%s*(.+)$')
            if k and v then
                if k == 'part_spine' then
                    settings.skel_parts.spine = (v == 'true')
                elseif k == 'part_arms' then
                    settings.skel_parts.arms = (v == 'true')
                elseif k == 'part_legs' then
                    settings.skel_parts.legs = (v == 'true')
                elseif k == 'res_mode' then
                    if v == 'auto' or v == '1080p' or v == '2K' or v == '4K' then
                        settings.res_mode.value = v
                    end
                elseif k:match('^col_') then
                    local part = k:sub(5)
                    local r, g, b = v:match('^(%d+)%s*,%s*(%d+)%s*,%s*(%d+)$')
                    if settings.colors[part] and r and g and b then
                        settings.colors[part].r = clamp(tonumber(r) or 255, 0, 255)
                        settings.colors[part].g = clamp(tonumber(g) or 255, 0, 255)
                        settings.colors[part].b = clamp(tonumber(b) or 255, 0, 255)
                    end
                elseif settings[k] then
                    if v == 'true' then
                        settings[k].value = true
                    elseif v == 'false' then
                        settings[k].value = false
                    else
                        local n = tonumber(v)
                        if n then settings[k].value = n end
                    end
                end
            end
        end
    end)
end

load_config()
apply_resolution_mode(false)

local function get_part_rgb(part)
    local c = settings.colors and settings.colors[part]
    if not c then return 255, 255, 255 end
    return clamp(tonumber(c.r) or 255, 0, 255),
           clamp(tonumber(c.g) or 255, 0, 255),
           clamp(tonumber(c.b) or 255, 0, 255)
end

local function get_bar_width_norm()
    local px = clamp(tonumber(settings.bar_size.value) or 2, 1, 10) * UI_SCALE
    return px / SCR_W
end

local function get_esp_bone_px(distance_m)
    local v = math.max(1.0, math.min(100.0, tonumber(settings.skel_size.value) or 25.0))
    local norm = (v - 1.0) / 99.0
    local base_px = (1.5 + norm * 2.5) * UI_SCALE

    local dist_factor = 1.0
    if (distance_m or 0.0) > 60.0 then
        dist_factor = math.max(0.6, 60.0 / distance_m)
    end

    return math.max(1.2 * UI_SCALE, base_px * dist_factor)
end

local function get_preview_bone_mult()
    local v = math.max(1.0, math.min(100.0, tonumber(settings.skel_size.value) or 25.0))
    return 0.65 + ((v - 1.0) / 99.0) * 1.15
end

local function get_self_info()
    local id, ped, name = nil, 0, nil
    if players and type(players.me) == 'function' then
        local ok, me = pcall(players.me)
        if ok and me then
            id = tonumber(field(me, 'id'))
            ped = tonumber(field(me, 'ped')) or 0
            name = as_string(field(me, 'name'))
        end
    end
    if id == nil or id < 0 or id > 31 then id = get_int('player_id', HASH.player_id) end
    if ped <= 0 then ped = get_int('player_ped_id', HASH.player_ped) end
    if (not name or name == '') and id and id >= 0 and id <= 31 then
        name = as_string(call_native('get_player_name', HASH.get_player_name, id))
    end
    if not name or name == '' then
        name = 'Self'
    end

    local pos = nil
    if ped > 0 and entity_exists(ped) then
        pos = entity_coords(ped)
    end
    return id, ped, name, pos
end

local function draw_ui_rect_raw(x, y, w, h, r, g, b, a, rounding)
    if not (gui and type(gui.rect) == 'function' and type(vec2) == 'function') then return false end
    local ok, obj = pcall(gui.rect, vec2(x, y), vec2(w, h))
    if not ok or not obj then return false end
    if obj.filled then pcall(obj.filled, obj) end
    if obj.color and type(color) == 'function' then pcall(obj.color, obj, color(r, g, b, a)) end
    if rounding and obj.rounding then pcall(obj.rounding, obj, rounding) end
    if obj.draw then pcall(obj.draw, obj) end
    return true
end

local function draw_thin_line_px(x0, y0, x1, y1, thick, r, g, b, a)
    local dx = x1 - x0
    local dy = y1 - y0
    local adx = math.abs(dx)
    local ady = math.abs(dy)
    local step_px = math.max(1.5, 2.0 * UI_SCALE)
    local steps = math.max(1, math.min(90, math.floor(math.max(adx, ady) / step_px)))
    local t = math.max(1.2 * UI_SCALE, thick or (1.8 * UI_SCALE))

    for i = 0, steps do
        local f = (steps == 0) and 0.0 or (i / steps)
        local px = x0 + dx * f
        local py = y0 + dy * f
        draw_ui_rect_raw(px - t * 0.5, py - t * 0.5, t, t, r, g, b, a, 0.0)
    end
end

local function draw_line_segment_2d(x0, y0, x1, y1, distance_m, seg_idx)
    local cx0, cy0, cx1, cy1 = clip_segment_2d(x0, y0, x1, y1)
    if not cx0 then return end

    local px0, py0 = cx0 * SCR_W, cy0 * SCR_H
    local px1, py1 = cx1 * SCR_W, cy1 * SCR_H
    local dx, dy = px1 - px0, py1 - py0
    if (dx * dx + dy * dy) < (2.25 * UI_SCALE * UI_SCALE) then return end

    local thick = get_esp_bone_px(distance_m)
    local sr, sg, sb_col = get_part_rgb('skeleton')
    if settings.rgb_skeleton.value then
        local t = (type(os) == 'table' and type(os.clock) == 'function') and os.clock() or 0.0
        sr, sg, sb_col = rgb_color(t * 3.2 + (seg_idx or 0) * 0.35)
    end

    draw_thin_line_px(px0, py0, px1, py1, thick, sr, sg, sb_col, 250)
end

local function draw_strip_segment(a, b, distance_m, seg_idx)
    if not a or not b then return end
    local sa, sb = world_to_screen(a), world_to_screen(b)
    if not sa or not sb then return end
    draw_line_segment_2d(sa.x, sa.y, sb.x, sb.y, distance_m, seg_idx)
end

local function draw_label(txt, x, y, r, g, b, a, font_px)
    if not (gui and type(gui.text) == 'function' and type(vec2) == 'function') then return end
    local str = tostring(txt or '')
    if str == '' then return end

    pcall(function()
        local obj = gui.text(str)
        if not obj then return end
        if CUSTOM_FONT and type(obj.font) == 'function' then
            obj:font(CUSTOM_FONT)
        end
        if font_px and type(obj.scale) == 'function' then
            obj:scale(font_px)
        end
        if type(obj.color) == 'function' and type(color) == 'function' then
            obj:color(color(r or 255, g or 255, b or 255, a or 255))
        end
        if type(obj.position) == 'function' then
            obj:position(vec2(x, y))
        end
        if type(obj.draw) == 'function' then
            obj:draw()
        end
    end)
end

local function draw_text_on_box(value, box_cx, box_top_y, size)
    if not value or value == '' or not box_cx or not box_top_y then return end
    local text_str = tostring(value)
    local cx_px = (box_cx <= 1.0) and (box_cx * SCR_W) or box_cx
    local top_py = (box_top_y <= 1.0) and (box_top_y * SCR_H) or box_top_y

    local font_px = math.max(10.0 * UI_SCALE, math.min(100.0 * UI_SCALE, (tonumber(size) or 22.0) * UI_SCALE))
    local est_w = #text_str * (font_px * 0.48)
    local tx = cx_px - (est_w * 0.5)
    local ty = math.max(6.0 * UI_SCALE, top_py - font_px - (8.0 * UI_SCALE))

    local nr, ng, nb = get_part_rgb('name')
    draw_label(text_str, tx, ty, nr, ng, nb, 255, font_px)
end

local function corner_box(top, bottom, width)
    local left, right = top.x - width * 0.5, top.x + width * 0.5
    local top_y, bottom_y = math.min(top.y, bottom.y), math.max(top.y, bottom.y)
    local horizontal = width * 0.28
    local vertical = (bottom_y - top_y) * 0.22
    local px = (2.0 * UI_SCALE) / SCR_W
    local py = (2.0 * UI_SCALE) / SCR_H
    local segments = {
        {left + horizontal * 0.5, top_y, horizontal, py},
        {left, top_y + vertical * 0.5, px, vertical},
        {right - horizontal * 0.5, top_y, horizontal, py},
        {right, top_y + vertical * 0.5, px, vertical},
        {left + horizontal * 0.5, bottom_y, horizontal, py},
        {left, bottom_y - vertical * 0.5, px, vertical},
        {right - horizontal * 0.5, bottom_y, horizontal, py},
        {right, bottom_y - vertical * 0.5, px, vertical}
    }
    local br, bg, bb = get_part_rgb('box')
    for i = 1, #segments do
        local s = segments[i]
        draw_esp_rect(s[1], s[2], s[3], s[4], br, bg, bb, 255)
    end
end

local function draw_bar(x, top_y, bottom_y, width, fraction, r, g, b)
    fraction = math.max(0.0, math.min(1.0, fraction))
    local min_y, max_y = math.min(top_y, bottom_y), math.max(top_y, bottom_y)
    local height = max_y - min_y
    if height <= 0 then return end
    draw_esp_rect(x, (min_y + max_y) * 0.5, width, height, 10, 12, 16, 130)
    if fraction > 0 then
        local fill_h = height * fraction
        draw_esp_rect(x, max_y - fill_h * 0.5, width, fill_h, r, g, b, 255)
    end
end

local function render_player(id, ped, label, my_id, my_pos, max_distance)
    if id == my_id and not settings.show_self.value then return end
    if not entity_exists(ped) then return end
    if get_bool('is_ped_dead_or_dying', HASH.ped_dead, ped, true) then return end

    local ped_pos = entity_coords(ped)
    if not ped_pos then return end

    local dx, dy, dz = ped_pos.x - my_pos.x, ped_pos.y - my_pos.y, ped_pos.z - my_pos.z
    local distance_m = math.sqrt(dx * dx + dy * dy + dz * dz)
    if distance_m > max_distance then return end

    local in_vehicle = get_bool('is_ped_in_any_vehicle', HASH.ped_in_vehicle, ped, false)

    local bone_cache = {}
    local function get_bone(bone_id)
        local cache_key = tostring(bone_id)
        if bone_cache[cache_key] == nil then
            local raw = bone_coords(ped, bone_id)
            if not raw then
                if bone_id == BONES.head then
                    raw = {x = ped_pos.x, y = ped_pos.y, z = ped_pos.z + 0.68}
                elseif bone_id == BONES.pelvis then
                    raw = {x = ped_pos.x, y = ped_pos.y, z = ped_pos.z - 0.10}
                elseif bone_id == BONES.spine2 then
                    raw = {x = ped_pos.x, y = ped_pos.y, z = ped_pos.z + 0.35}
                end
            end
            bone_cache[cache_key] = raw or false
        end
        return bone_cache[cache_key] or nil
    end

    local head_b = get_bone(BONES.head)
    local neck_b = get_bone(BONES.neck)
    local pelvis_b = get_bone(BONES.pelvis)
    local feet_l = get_bone(BONES.lfoot)
    local feet_r = get_bone(BONES.rfoot)

    local ax = (pelvis_b and pelvis_b.x) or (neck_b and neck_b.x) or ped_pos.x
    local ay = (pelvis_b and pelvis_b.y) or (neck_b and neck_b.y) or ped_pos.y

    local head_pos
    local feet_pos
    if in_vehicle then
        local top_z = (head_b and (head_b.z + 0.14)) or (neck_b and (neck_b.z + 0.36)) or (ped_pos.z + 0.85)
        local bot_z = (pelvis_b and (pelvis_b.z - 0.35)) or (ped_pos.z - 0.45)
        head_pos = {x = ax, y = ay, z = top_z}
        feet_pos = {x = ax, y = ay, z = bot_z}
    else
        local top_z = (head_b and (head_b.z + 0.16)) or (neck_b and (neck_b.z + 0.40)) or (ped_pos.z + 1.15)
        local bot_z
        if feet_l and feet_r then
            bot_z = math.min(feet_l.z, feet_r.z) - 0.04
        elseif feet_l then
            bot_z = feet_l.z - 0.04
        elseif feet_r then
            bot_z = feet_r.z - 0.04
        else
            bot_z = ped_pos.z - 0.88
        end
        head_pos = {x = ax, y = ay, z = top_z}
        feet_pos = {x = ax, y = ay, z = bot_z}
    end

    local top_screen, bottom_screen = world_to_screen(head_pos), world_to_screen(feet_pos)
    local box_cx, box_top_y = nil, nil

    if top_screen or bottom_screen then
        local approx_h = clamp(0.45 / math.max(1.0, distance_m), 0.015, 0.95)
        local ty = top_screen and top_screen.y or (bottom_screen.y - approx_h)
        local by = bottom_screen and bottom_screen.y or (top_screen.y + approx_h)
        local h = math.abs(by - ty)

        if h > 0.004 and h < 1.8 then
            local width = h * 0.42 * (SCR_H / SCR_W)
            local ref_x = top_screen and top_screen.x or bottom_screen.x
            if top_screen and bottom_screen then
                ref_x = (top_screen.x + bottom_screen.x) * 0.5
            end
            box_cx = clamp(ref_x, 0.0, 1.0)
            local min_y = clamp(math.min(ty, by), 0.0, 1.0)
            local max_y = clamp(math.max(ty, by), 0.0, 1.0)
            box_top_y = min_y

            if max_y > min_y then
                local bar_w = get_bar_width_norm()
                local bar_gap = math.max(4.0 / SCR_W, bar_w + (2.0 / SCR_W))

                if settings.box.value then
                    corner_box({x = box_cx, y = min_y}, {x = box_cx, y = max_y}, width)
                end
                if settings.health.value then
                    local hp = get_int('get_entity_health', HASH.entity_health, ped)
                    local max_hp = get_int('get_entity_max_health', HASH.entity_max_health, ped)
                    if max_hp <= 100 then max_hp = 200 end
                    local hr, hg, hb = get_part_rgb('health')
                    draw_bar(box_cx - width * 0.5 - bar_gap, min_y, max_y,
                        bar_w, (hp - 100) / math.max(1, max_hp - 100), hr, hg, hb)
                end
                if settings.armour.value then
                    local ap = get_int('get_ped_armour', HASH.ped_armour, ped)
                    local ar, ag, ab = get_part_rgb('armor')
                    draw_bar(box_cx + width * 0.5 + bar_gap, min_y, max_y,
                        bar_w, ap / 100.0, ar, ag, ab)
                end
            end
        end
    end

    if settings.names.value or settings.distance.value then
        local base_name = label
        if not base_name or base_name == '' then
            base_name = (id == my_id) and 'Self' or ('Player ' .. tostring(id))
        end
        local caption = settings.names.value and base_name or ''
        if settings.distance.value then
            local metres = tostring(math.floor(distance_m + 0.5)) .. ' m'
            caption = caption ~= '' and (caption .. '  [' .. metres .. ']') or metres
        end
        if box_cx and box_top_y and caption ~= '' then
            draw_text_on_box(caption, box_cx, box_top_y, settings.size.value)
        end
    end

    local skip_skeleton = in_vehicle and settings.hide_skel_veh.value
    if settings.skeleton.value and not skip_skeleton then
        local groups = in_vehicle and BONE_GROUPS_VEH or BONE_GROUPS
        local seg_counter = 0
        for part_key, links in pairs(groups) do
            if settings.skel_parts[part_key] ~= false then
                for i = 1, #links do
                    seg_counter = seg_counter + 1
                    local link = links[i]
                    draw_strip_segment(get_bone(link[1]), get_bone(link[2]), distance_m, seg_counter)
                end
            end
        end
    end
end

local function esp_frame()
    if not settings.enabled.value then return end
    if is_pause_menu_active() then return end

    local my_id, my_ped, _, my_pos = get_self_info()
    if my_ped <= 0 or not entity_exists(my_ped) or not my_pos then return end

    local max_distance = tonumber(settings.range.value) or 10000
    local processed = {}

    if players and type(players.list) == 'function' then
        local ok, list = pcall(players.list)
        if ok and type(list) == 'table' then
            for _, player in pairs(list) do
                local id = tonumber(field(player, 'id'))
                if id and id >= 0 and id <= 31 and not processed[id] then
                    local connected = field(player, 'connected')
                    local exists = field(player, 'exists')
                    if connected ~= false and exists ~= false then
                        processed[id] = true
                        local ped = tonumber(field(player, 'ped')) or 0
                        if ped <= 0 or not entity_exists(ped) then
                            ped = get_int('get_player_ped', HASH.get_player_ped, id)
                        end
                        local name = as_string(field(player, 'name'))
                        if not name or name == '' then
                            name = as_string(call_native('get_player_name', HASH.get_player_name, id))
                        end
                        render_player(id, ped, name, my_id, my_pos, max_distance)
                    end
                end
            end
        end
    end

    for id = 0, 31 do
        if not processed[id] and get_bool('network_is_player_active', HASH.player_active, id) then
            processed[id] = true
            local ped = get_int('get_player_ped', HASH.get_player_ped, id)
            local name = as_string(call_native('get_player_name', HASH.get_player_name, id))
            render_player(id, ped, name, my_id, my_pos, max_distance)
        end
    end
end

local VK_NAMES = {
    [0x08] = "BKSP", [0x09] = "TAB", [0x0D] = "ENTER", [0x10] = "SHIFT",
    [0x11] = "CTRL", [0x12] = "ALT", [0x14] = "CAPS", [0x1B] = "ESC",
    [0x20] = "SPACE", [0x21] = "PGUP", [0x22] = "PGDN", [0x23] = "END",
    [0x24] = "HOME", [0x25] = "LEFT", [0x26] = "UP", [0x27] = "RIGHT",
    [0x28] = "DOWN", [0x2D] = "INS", [0x2E] = "DEL",
    [0x70] = "F1", [0x71] = "F2", [0x72] = "F3", [0x73] = "F4",
    [0x74] = "F5", [0x75] = "F6", [0x76] = "F7", [0x77] = "F8",
    [0x78] = "F9", [0x79] = "F10", [0x7A] = "F11", [0x7B] = "F12"
}

local function vk_to_label(vk)
    local v = tonumber(vk) or 0x2D
    if VK_NAMES[v] then return VK_NAMES[v] end
    if v >= 0x30 and v <= 0x39 then return string.char(v) end
    if v >= 0x41 and v <= 0x5A then return string.char(v) end
    if v >= 0x60 and v <= 0x69 then return "NUM" .. tostring(v - 0x60) end
    return string.format("0x%X", v)
end

local VK_LBUTTON = 0x01
local VK_BACK    = 0x08
local VK_RETURN  = 0x0D

local function force_hide_cursor()
    UI._cursor_shown = false
    if input and type(input.show_cursor) == "function" then
        for _ = 1, 3 do
            pcall(input.show_cursor, false)
        end
    end
end

local function sync_cursor()
    if UI._running and UI.open then
        if not UI._cursor_shown then
            UI._cursor_shown = true
            if input and type(input.show_cursor) == "function" then
                pcall(input.show_cursor, true)
            end
        end
    else
        force_hide_cursor()
    end
end

local function apply_edited_value(key, num)
    if key == "range" or key == "size" or key == "skel_size" or key == "bar_size" then
        if settings[key] then
            settings[key].value = num
            save_config()
        end
    elseif key == "rgb_r" or key == "rgb_g" or key == "rgb_b" then
        local c = settings.colors and settings.colors[UI.color_target]
        if c then
            if key == "rgb_r" then c.r = num end
            if key == "rgb_g" then c.g = num end
            if key == "rgb_b" then c.b = num end
            save_config()
        end
    end
end

local function commit_number_edit()
    if not UI.editing_key then return end
    local key = UI.editing_key
    local num = tonumber(UI.edit_buf)
    if num then
        num = math.floor(num + 0.5)
        num = math.max(UI.edit_min, math.min(UI.edit_max, num))
        apply_edited_value(key, num)
    end
    UI.editing_key = nil
    UI.edit_buf = ""
end

local function close_menu()
    commit_number_edit()
    UI.binding_key = false
    UI.open = false
    UI.dragging = false
    UI.dragging_range = false
    UI.dragging_size = false
    UI.dragging_skel_size = false
    UI.dragging_bar_size = false
    UI.dragging_rgb = nil
    UI._was_lmb_down = false
    force_hide_cursor()
end

local function cleanup()
    save_config()
    UI._running = false
    close_menu()
end

if util and type(util.on_stop) == "function" then
    pcall(util.on_stop, cleanup)
end

local function read_raw_mouse_xy()
    if not (input and type(input.mouse_position) == "function") then
        return UI.cur_mx, UI.cur_my
    end
    local ok, a, b = pcall(input.mouse_position)
    if not ok or a == nil then
        return UI.cur_mx, UI.cur_my
    end
    if type(a) == "table" or type(a) == "userdata" then
        return tonumber(a.x) or UI.cur_mx, tonumber(a.y) or UI.cur_my
    end
    return tonumber(a) or UI.cur_mx, tonumber(b) or UI.cur_my
end

local function is_button_down(fn, vk)
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

local function poll_key_bind()
    if not UI.binding_key then return end
    local candidates = {
        0x08, 0x09, 0x0D, 0x10, 0x11, 0x12, 0x14, 0x20,
        0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x2D, 0x2E,
        0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7A, 0x7B
    }
    for code = 0x30, 0x5A do
        candidates[#candidates + 1] = code
    end
    for code = 0x60, 0x69 do
        candidates[#candidates + 1] = code
    end

    for i = 1, #candidates do
        local vk = candidates[i]
        local down = is_button_down(input and input.key, vk)
        local prev = UI._prev_bind_scan[vk] == true
        if down and not prev then
            settings.menu_key.value = vk
            UI.binding_key = false
            UI._was_bind_down = true
            save_config()
            toast("Menu bind: " .. vk_to_label(vk))
            return
        end
        UI._prev_bind_scan[vk] = down
    end
end

local function process_number_input()
    if not UI.editing_key then return end

    for d = 0, 9 do
        local vk_main = 0x30 + d
        local vk_num  = 0x60 + d
        local down = is_button_down(input and input.key, vk_main) or is_button_down(input and input.key, vk_num)
        local prev = UI._prev_digit_states[d] == true
        if down and not prev and #UI.edit_buf < 6 then
            UI.edit_buf = UI.edit_buf .. tostring(d)
        end
        UI._prev_digit_states[d] = down
    end

    local bksp_down = is_button_down(input and input.key, VK_BACK)
    if bksp_down and not UI._prev_bksp and #UI.edit_buf > 0 then
        UI.edit_buf = UI.edit_buf:sub(1, #UI.edit_buf - 1)
    end
    UI._prev_bksp = bksp_down

    local enter_down = is_button_down(input and input.key, VK_RETURN)
    if enter_down and not UI._prev_enter then
        commit_number_edit()
    end
    UI._prev_enter = enter_down
end

local function in_box(mx, my, rx, ry, rw, rh)
    return mx >= rx and mx <= (rx + rw) and my >= ry and my <= (ry + rh)
end

local function draw_ui_rect(x, y, w, h, r, g, b, a, rounding)
    draw_ui_rect_raw(x, y, w, h, r, g, b, a, rounding)
end

local function draw_ui_text(txt, x, y, r, g, b, a, px_size)
    draw_label(txt, x, y, r, g, b, a, (px_size or 16.5) * UI_SCALE)
end

local function draw_preview_bone(x0, y0, x1, y1, r, g, b, base_thick)
    local mult = get_preview_bone_mult()
    local thick = math.max(1.2 * UI_SCALE, math.min(3.5 * UI_SCALE, (base_thick or 1.8) * mult * UI_SCALE))
    draw_thin_line_px(x0, y0, x1, y1, thick, r, g, b, 255)
end

local function draw_preview_skeleton(cx, by, bh)
    local s = UI_SCALE
    local head_pt  = by + bh * 0.11
    local neck_pt  = by + bh * 0.21
    local spine_pt = by + bh * 0.36
    local hip_pt   = by + bh * 0.52

    local l_sh_x, l_sh_y = cx - 22.0 * s, by + bh * 0.24
    local l_el_x, l_el_y = cx - 32.0 * s, by + bh * 0.39
    local l_hd_x, l_hd_y = cx - 35.0 * s, by + bh * 0.53

    local r_sh_x, r_sh_y = cx + 22.0 * s, by + bh * 0.24
    local r_el_x, r_el_y = cx + 32.0 * s, by + bh * 0.39
    local r_hd_x, r_hd_y = cx + 35.0 * s, by + bh * 0.53

    local l_kn_x, l_kn_y = cx - 16.0 * s, by + bh * 0.74
    local l_ft_x, l_ft_y = cx - 18.0 * s, by + bh * 0.94

    local r_kn_x, r_kn_y = cx + 16.0 * s, by + bh * 0.74
    local r_ft_x, r_ft_y = cx + 18.0 * s, by + bh * 0.94

    local bones = {}
    if settings.skel_parts.spine ~= false then
        bones[#bones + 1] = {cx, neck_pt,  cx, head_pt,  1.8}
        bones[#bones + 1] = {cx, neck_pt,  cx, spine_pt, 1.8}
        bones[#bones + 1] = {cx, spine_pt, cx, hip_pt,   1.8}
    end
    if settings.skel_parts.arms ~= false then
        bones[#bones + 1] = {cx, neck_pt, l_sh_x, l_sh_y, 1.8}
        bones[#bones + 1] = {l_sh_x, l_sh_y, l_el_x, l_el_y, 1.8}
        bones[#bones + 1] = {l_el_x, l_el_y, l_hd_x, l_hd_y, 1.8}

        bones[#bones + 1] = {cx, neck_pt, r_sh_x, r_sh_y, 1.8}
        bones[#bones + 1] = {r_sh_x, r_sh_y, r_el_x, r_el_y, 1.8}
        bones[#bones + 1] = {r_el_x, r_el_y, r_hd_x, r_hd_y, 1.8}
    end
    if settings.skel_parts.legs ~= false then
        bones[#bones + 1] = {cx, hip_pt, l_kn_x, l_kn_y, 1.8}
        bones[#bones + 1] = {l_kn_x, l_kn_y, l_ft_x, l_ft_y, 1.8}

        bones[#bones + 1] = {cx, hip_pt, r_kn_x, r_kn_y, 1.8}
        bones[#bones + 1] = {r_kn_x, r_kn_y, r_ft_x, r_ft_y, 1.8}
    end

    local sk_r, sk_g, sk_b = get_part_rgb('skeleton')
    local t_now = (type(os) == 'table' and type(os.clock) == 'function') and os.clock() or 0.0
    for i = 1, #bones do
        local b = bones[i]
        local r, g, bl = sk_r, sk_g, sk_b
        if settings.rgb_skeleton.value then
            r, g, bl = rgb_color(t_now * 3.2 + i * 0.35)
        end
        draw_preview_bone(b[1], b[2], b[3], b[4], r, g, bl, b[5])
    end
end

local function draw_preview_checkbox(mx, my, just_clicked, x, y, title, key)
    local s = UI_SCALE
    local box_s = 16.0 * s
    local row_w = 104.0 * s
    local row_h = 22.0 * s
    local checked = settings.skel_parts[key] ~= false
    local hovered = in_box(mx, my, x, y, row_w, row_h)

    draw_ui_rect(x, y + 3.0 * s, box_s, box_s,
        checked and 54 or 28,
        checked and 128 or 33,
        checked and 246 or 44, 255, 3.0 * s)

    if checked then
        draw_thin_line_px(x + 3.5 * s, y + 11.0 * s, x + 7.0 * s, y + 14.5 * s, 2.0 * s, 255, 255, 255, 255)
        draw_thin_line_px(x + 7.0 * s, y + 14.5 * s, x + 13.0 * s, y + 7.5 * s, 2.0 * s, 255, 255, 255, 255)
    end

    draw_ui_text(title, x + box_s + 7.0 * s, y + 2.0 * s, hovered and 255 or 218, hovered and 255 or 226, hovered and 255 or 240, 255, 14.5)

    if hovered and just_clicked then
        settings.skel_parts[key] = not checked
        save_config()
    end
end

local function update_cursor_by_mode()
    local mode = UI.modes[UI.mode_idx]
    local mx, my = read_raw_mouse_xy()

    if UI.last_mx ~= nil and UI.last_my ~= nil then
        UI.dx = mx - UI.last_mx
        UI.dy = my - UI.last_my
    else
        UI.dx, UI.dy = 0.0, 0.0
    end
    UI.last_mx, UI.last_my = mx, my

    if mode == "Windows" then
        UI.cur_mx, UI.cur_my = mx, my
    elseif mode == "Raw Input" then
        UI.cur_mx = UI.cur_mx + UI.dx
        UI.cur_my = UI.cur_my + UI.dy
    elseif mode == "DirectInput" then
        if math.abs(UI.dx) > 0.0 or math.abs(UI.dy) > 0.0 then
            UI.cur_mx = UI.cur_mx + UI.dx
            UI.cur_my = UI.cur_my + UI.dy
        else
            UI.cur_mx, UI.cur_my = mx, my
        end
    end

    if UI.cur_mx < 0.0 then UI.cur_mx = 0.0 end
    if UI.cur_my < 0.0 then UI.cur_my = 0.0 end
    if UI.cur_mx > SCR_W then UI.cur_mx = SCR_W end
    if UI.cur_my > SCR_H then UI.cur_my = SCR_H end

    sync_cursor()
end

local function draw_toggle_row(mx, my, just_clicked, x, y, w, h, label, value)
    local s = UI_SCALE
    local hovered = in_box(mx, my, x, y, w, h)
    draw_ui_rect(x, y, w, h, hovered and 38 or 24, hovered and 46 or 30, hovered and 62 or 40, 248, 6.0 * s)
    draw_ui_text(label, x + 14.0 * s, y + 6.5 * s, 234, 240, 250, 255, 16.5)

    local pill_w = 44.0 * s
    local pill_h = 20.0 * s
    local px = x + w - pill_w - 12.0 * s
    local py = y + math.floor((h - pill_h) * 0.5)

    if value then
        draw_ui_rect(px, py, pill_w, pill_h, 58, 134, 248, 255, 10.0 * s)
        draw_ui_rect(px + pill_w - pill_h + 2.0 * s, py + 2.0 * s, pill_h - 4.0 * s, pill_h - 4.0 * s, 252, 254, 255, 255, 8.0 * s)
    else
        draw_ui_rect(px, py, pill_w, pill_h, 56, 62, 78, 255, 10.0 * s)
        draw_ui_rect(px + 2.0 * s, py + 2.0 * s, pill_h - 4.0 * s, pill_h - 4.0 * s, 198, 205, 220, 255, 8.0 * s)
    end

    if hovered and just_clicked then
        local next_val = not value
        save_config()
        return next_val
    end
    return value
end

local function draw_slider_row(mx, my, just_clicked, lmb_down, x, y, w, h, label, opt_key, cur_val, on_change, min_val, max_val, step, suffix, drag_flag, on_drag_start, on_drag_end, val_x, bar_r, bar_g, bar_b)
    local s = UI_SCALE
    cur_val = math.max(min_val, math.min(max_val, tonumber(cur_val) or min_val))

    local hovered_row = in_box(mx, my, x, y, w, h)
    draw_ui_rect(x, y, w, h, hovered_row and 38 or 24, hovered_row and 46 or 30, hovered_row and 62 or 40, 248, 6.0 * s)

    local vx = (val_x or 142.0) * s
    local num_box_w = 78.0 * s
    local num_box_h = 22.0 * s
    local num_box_x = x + vx - 4.0 * s
    local num_box_y = y + math.floor((h - num_box_h) * 0.5)

    local is_editing = (UI.editing_key == opt_key)
    local hover_num = in_box(mx, my, num_box_x, num_box_y, num_box_w, num_box_h)

    if just_clicked then
        if hover_num then
            commit_number_edit()
            UI.editing_key = opt_key
            UI.edit_buf = tostring(math.floor(cur_val + 0.5))
            UI.edit_min = min_val
            UI.edit_max = max_val
            is_editing = true
        elseif is_editing then
            commit_number_edit()
            is_editing = false
        end
    end

    draw_ui_text(label, x + 14.0 * s, y + 6.5 * s, 234, 240, 250, 255, 16.5)

    draw_ui_rect(num_box_x, num_box_y, num_box_w, num_box_h,
        is_editing and 20 or 32,
        is_editing and 36 or 39,
        is_editing and 60 or 52, 255, 4.0 * s)

    local display_num = is_editing
        and ((UI.edit_buf ~= "" and UI.edit_buf or "0") .. "_")
        or (tostring(math.floor(cur_val + 0.5)) .. (suffix or ""))

    draw_ui_text(display_num, num_box_x + 6.0 * s, num_box_y + 2.0 * s,
        is_editing and 255 or 126,
        is_editing and 230 or 198,
        is_editing and 120 or 255, 255, 15.0)

    local slider_x = num_box_x + num_box_w + 14.0 * s
    local slider_w = math.max(50.0 * s, (x + w - 12.0 * s) - slider_x)
    local track_h = 6.0 * s
    local track_y = y + math.floor((h - track_h) * 0.5)

    local hovered_track = in_box(mx, my, slider_x - 5.0 * s, y, slider_w + 10.0 * s, h)
    if just_clicked and hovered_track then
        if on_drag_start then on_drag_start() end
    elseif not lmb_down then
        if drag_flag then save_config() end
        if on_drag_end then on_drag_end() end
    end

    if drag_flag then
        local ratio = (mx - slider_x) / math.max(1.0, slider_w)
        ratio = math.max(0.0, math.min(1.0, ratio))
        local raw_val = min_val + ratio * (max_val - min_val)
        cur_val = math.floor((raw_val / step) + 0.5) * step
        cur_val = math.max(min_val, math.min(max_val, cur_val))
        if on_change then on_change(cur_val) end
    end

    local ratio = (cur_val - min_val) / math.max(1.0, (max_val - min_val))
    local fill_w = math.max(2.0 * s, slider_w * ratio)
    local knob_x = slider_x + fill_w - 4.0 * s

    draw_ui_rect(slider_x, track_y, slider_w, track_h, 52, 58, 76, 255, 3.0 * s)
    draw_ui_rect(slider_x, track_y, fill_w, track_h, bar_r or 58, bar_g or 134, bar_b or 248, 255, 3.0 * s)
    draw_ui_rect(knob_x, track_y - 3.0 * s, 8.0 * s, track_h + 6.0 * s, 252, 254, 255, 255, 3.0 * s)
end

local function render_colors_tab(mx, my, just_clicked, lmb_down, lx, ly, col_w, row_h, gap)
    local s = UI_SCALE
    draw_ui_text("ESP ELEMENT", lx + 4.0 * s, ly - 2.0 * s, 136, 150, 178, 255, 13.0)
    ly = ly + 20.0 * s

    local targets = {
        { id = "skeleton", label = "Skeleton" },
        { id = "name",     label = "Name & Dist" },
        { id = "box",      label = "Corner Box" },
        { id = "health",   label = "Health Bar" },
        { id = "armor",    label = "Armor Bar" }
    }

    for i = 1, #targets do
        local t = targets[i]
        local selected = (UI.color_target == t.id)
        local hovered = in_box(mx, my, lx, ly, col_w, row_h)
        local tr, tg, tb = get_part_rgb(t.id)

        draw_ui_rect(lx, ly, col_w, row_h,
            selected and 38 or (hovered and 34 or 24),
            selected and 52 or (hovered and 42 or 30),
            selected and 76 or (hovered and 56 or 40), 250, 6.0 * s)

        if selected then
            draw_ui_rect(lx, ly + 4.0 * s, 4.0 * s, row_h - 8.0 * s, 58, 134, 248, 255, 2.0 * s)
        end

        draw_ui_text(t.label, lx + 14.0 * s, ly + 6.5 * s, selected and 255 or 224, selected and 255 or 230, selected and 255 or 242, 255, 16.5)

        local sw_w = 34.0 * s
        local sw_h = 18.0 * s
        local sw_x = lx + col_w - sw_w - 14.0 * s
        local sw_y = ly + math.floor((row_h - sw_h) * 0.5)
        draw_ui_rect(sw_x - 1.0 * s, sw_y - 1.0 * s, sw_w + 2.0 * s, sw_h + 2.0 * s, 90, 102, 128, 255, 4.0 * s)
        draw_ui_rect(sw_x, sw_y, sw_w, sw_h, tr, tg, tb, 255, 3.0 * s)

        if hovered and just_clicked then
            commit_number_edit()
            UI.color_target = t.id
        end

        ly = ly + row_h + gap
    end

    ly = ly + 10.0 * s
    draw_ui_text("RGB CHANNEL", lx + 4.0 * s, ly - 2.0 * s, 136, 150, 178, 255, 13.0)
    ly = ly + 20.0 * s

    local cur_c = settings.colors[UI.color_target]

    draw_slider_row(mx, my, just_clicked, lmb_down, lx, ly, col_w, row_h + 4.0 * s,
        "R (Red)", "rgb_r", cur_c.r, function(v) cur_c.r = v end,
        0.0, 255.0, 1.0, "", UI.dragging_rgb == "r",
        function() UI.dragging_rgb = "r" end,
        function() if UI.dragging_rgb == "r" then UI.dragging_rgb = nil end end,
        142.0, 235, 70, 70)
    ly = ly + row_h + 4.0 * s + gap + 2.0 * s

    draw_slider_row(mx, my, just_clicked, lmb_down, lx, ly, col_w, row_h + 4.0 * s,
        "G (Green)", "rgb_g", cur_c.g, function(v) cur_c.g = v end,
        0.0, 255.0, 1.0, "", UI.dragging_rgb == "g",
        function() UI.dragging_rgb = "g" end,
        function() if UI.dragging_rgb == "g" then UI.dragging_rgb = nil end end,
        142.0, 75, 220, 110)
    ly = ly + row_h + 4.0 * s + gap + 2.0 * s

    draw_slider_row(mx, my, just_clicked, lmb_down, lx, ly, col_w, row_h + 4.0 * s,
        "B (Blue)", "rgb_b", cur_c.b, function(v) cur_c.b = v end,
        0.0, 255.0, 1.0, "", UI.dragging_rgb == "b",
        function() UI.dragging_rgb = "b" end,
        function() if UI.dragging_rgb == "b" then UI.dragging_rgb = nil end end,
        142.0, 75, 145, 255)
end

local function render_gui(just_clicked, lmb_down)
    local s = UI_SCALE
    local mx, my = UI.cur_mx, UI.cur_my

    local close_w = 28.0 * s
    local close_h = 24.0 * s
    local close_x = UI.x + UI.w - close_w - 12.0 * s
    local close_y = UI.y + 10.0 * s
    local hover_close = in_box(mx, my, close_x, close_y, close_w, close_h)

    if just_clicked and hover_close then
        close_menu()
        return
    end

    local any_slider_drag = UI.dragging_range or UI.dragging_size or UI.dragging_skel_size or UI.dragging_bar_size or (UI.dragging_rgb ~= nil)
    if just_clicked and not hover_close and not any_slider_drag and in_box(mx, my, UI.x, UI.y, UI.w, UI.header_h) then
        UI.dragging = true
        UI.drag_ox = mx - UI.x
        UI.drag_oy = my - UI.y
    elseif not lmb_down then
        UI.dragging = false
    end

    if UI.dragging then
        UI.x = clamp(mx - UI.drag_ox, 0.0, math.max(0.0, SCR_W - UI.w))
        UI.y = clamp(my - UI.drag_oy, 0.0, math.max(0.0, SCR_H - UI.h))
        close_x = UI.x + UI.w - close_w - 12.0 * s
        close_y = UI.y + 10.0 * s
        hover_close = in_box(mx, my, close_x, close_y, close_w, close_h)
    end

    draw_ui_rect(UI.x, UI.y, UI.w, UI.h, 14, 17, 24, 252, 9.0 * s)
    draw_ui_rect(UI.x, UI.y, UI.w, UI.header_h, 22, 27, 38, 255, 9.0 * s)
    draw_ui_rect(UI.x, UI.y + UI.header_h - 1.0 * s, UI.w, 1.0 * s, 42, 50, 68, 255, 0.0)
    draw_ui_text("PLAYER ESP  [" .. vk_to_label(settings.menu_key.value) .. "]", UI.x + 18.0 * s, UI.y + 12.0 * s, 248, 252, 255, 255, 18.0)

    local tab_w = 76.0 * s
    local tab_h = 24.0 * s
    local tab_esp_x = UI.x + 220.0 * s
    local tab_col_x = tab_esp_x + tab_w + 8.0 * s
    local tab_y = UI.y + 10.0 * s

    local h_tab_esp = in_box(mx, my, tab_esp_x, tab_y, tab_w, tab_h)
    local h_tab_col = in_box(mx, my, tab_col_x, tab_y, tab_w, tab_h)

    draw_ui_rect(tab_esp_x, tab_y, tab_w, tab_h,
        (UI.tab == "esp") and 58 or (h_tab_esp and 38 or 28),
        (UI.tab == "esp") and 134 or (h_tab_esp and 46 or 34),
        (UI.tab == "esp") and 248 or (h_tab_esp and 62 or 46), 255, 5.0 * s)
    draw_ui_text("ESP", tab_esp_x + 24.0 * s, tab_y + 4.0 * s, 255, 255, 255, 255, 15.0)

    draw_ui_rect(tab_col_x, tab_y, tab_w, tab_h,
        (UI.tab == "colors") and 58 or (h_tab_col and 38 or 28),
        (UI.tab == "colors") and 134 or (h_tab_col and 46 or 34),
        (UI.tab == "colors") and 248 or (h_tab_col and 62 or 46), 255, 5.0 * s)
    draw_ui_text("Colors", tab_col_x + 16.0 * s, tab_y + 4.0 * s, 255, 255, 255, 255, 15.0)

    if just_clicked then
        if h_tab_esp and UI.tab ~= "esp" then
            commit_number_edit()
            UI.tab = "esp"
        elseif h_tab_col and UI.tab ~= "colors" then
            commit_number_edit()
            UI.tab = "colors"
        end
    end

    draw_ui_rect(close_x, close_y, close_w, close_h, hover_close and 210 or 54, 38, 48, 255, 5.0 * s)
    draw_ui_text("X", close_x + 9.0 * s, close_y + 4.0 * s, 255, 255, 255, 255, 15.5)

    local col_w = 432.0 * s
    local lx = UI.x + UI.pad
    local ly = UI.y + UI.header_h + UI.pad
    local row_h = 30.0 * s
    local gap = 3.0 * s

    if UI.tab == "esp" then
        local h_res = in_box(mx, my, lx, ly, col_w, row_h)
        draw_ui_rect(lx, ly, col_w, row_h, h_res and 42 or 27, h_res and 52 or 36, h_res and 72 or 52, 248, 6.0 * s)
        draw_ui_text("Screen (" .. ACTIVE_RES_LABEL .. ")", lx + 14.0 * s, ly + 6.5 * s, 234, 240, 250, 255, 16.0)
        local rm = tostring(settings.res_mode.value or "auto")
        local rm_txt = (rm == "auto") and "Auto >" or (rm .. " >")
        draw_ui_text(rm_txt, lx + col_w - 128.0 * s, ly + 6.5 * s, 126, 198, 255, 255, 16.0)
        if h_res and just_clicked then
            local order = { "auto", "1080p", "2K", "4K" }
            local next_m = "auto"
            for idx = 1, #order do
                if order[idx] == rm then
                    next_m = order[(idx % #order) + 1]
                    break
                end
            end
            settings.res_mode.value = next_m
            apply_resolution_mode(true)
            save_config()
            return
        end
        ly = ly + row_h + gap

        local h_bind = in_box(mx, my, lx, ly, col_w, row_h)
        draw_ui_rect(lx, ly, col_w, row_h,
            UI.binding_key and 36 or (h_bind and 40 or 27),
            UI.binding_key and 64 or (h_bind and 50 or 36),
            UI.binding_key and 112 or (h_bind and 70 or 52), 248, 6.0 * s)
        draw_ui_text("Menu Bind", lx + 14.0 * s, ly + 6.5 * s, 234, 240, 250, 255, 16.5)
        local bind_txt = UI.binding_key and "Press key..." or ("[ " .. vk_to_label(settings.menu_key.value) .. " ]")
        draw_ui_text(bind_txt, lx + col_w - 128.0 * s, ly + 6.5 * s,
            UI.binding_key and 255 or 126,
            UI.binding_key and 230 or 198,
            UI.binding_key and 120 or 255, 255, 16.0)
        if h_bind and just_clicked then
            commit_number_edit()
            UI.binding_key = not UI.binding_key
            UI._prev_bind_scan = {}
        end
        ly = ly + row_h + gap

        local h_mode = in_box(mx, my, lx, ly, col_w, row_h)
        draw_ui_rect(lx, ly, col_w, row_h, h_mode and 42 or 27, h_mode and 52 or 36, h_mode and 72 or 52, 248, 6.0 * s)
        draw_ui_text("Cursor Mode", lx + 14.0 * s, ly + 6.5 * s, 234, 240, 250, 255, 16.5)
        draw_ui_text(UI.modes[UI.mode_idx] .. " >", lx + col_w - 128.0 * s, ly + 6.5 * s, 126, 198, 255, 255, 16.5)
        if h_mode and just_clicked then
            UI.mode_idx = (UI.mode_idx % #UI.modes) + 1
        end
        ly = ly + row_h + gap + 2.0 * s

        local toggles = {
            { "Enable", settings.enabled },
            { "Hide Skeleton in Vehicle", settings.hide_skel_veh },
            { "Names", settings.names },
            { "Skeleton", settings.skeleton },
            { "RGB Skeleton", settings.rgb_skeleton },
            { "Corner Box", settings.box },
            { "Health", settings.health },
            { "Armor", settings.armour },
            { "Distance", settings.distance },
            { "Show Self", settings.show_self }
        }

        for i = 1, #toggles do
            local label, opt = toggles[i][1], toggles[i][2]
            opt.value = draw_toggle_row(mx, my, just_clicked, lx, ly, col_w, row_h, label, opt.value)
            ly = ly + row_h + gap
        end

        draw_slider_row(mx, my, just_clicked, lmb_down, lx, ly, col_w, row_h,
            "Distance", "range", settings.range.value, function(v) settings.range.value = v end,
            10.0, 10000.0, 10.0, " m", UI.dragging_range,
            function() UI.dragging_range = true end,
            function() UI.dragging_range = false end, 142.0)
        ly = ly + row_h + gap

        draw_slider_row(mx, my, just_clicked, lmb_down, lx, ly, col_w, row_h,
            "Name Size", "size", settings.size.value, function(v) settings.size.value = v end,
            10.0, 100.0, 1.0, "", UI.dragging_size,
            function() UI.dragging_size = true end,
            function() UI.dragging_size = false end, 142.0)
        ly = ly + row_h + gap

        draw_slider_row(mx, my, just_clicked, lmb_down, lx, ly, col_w, row_h,
            "Skeleton Size", "skel_size", settings.skel_size.value, function(v) settings.skel_size.value = v end,
            1.0, 100.0, 1.0, "", UI.dragging_skel_size,
            function() UI.dragging_skel_size = true end,
            function() UI.dragging_skel_size = false end, 156.0)
        ly = ly + row_h + gap

        draw_slider_row(mx, my, just_clicked, lmb_down, lx, ly, col_w, row_h,
            "Bar Size", "bar_size", settings.bar_size.value, function(v) settings.bar_size.value = v end,
            1.0, 10.0, 1.0, " px", UI.dragging_bar_size,
            function() UI.dragging_bar_size = true end,
            function() UI.dragging_bar_size = false end, 142.0)
    else
        render_colors_tab(mx, my, just_clicked, lmb_down, lx, ly, col_w, row_h, gap)
    end

    local px = lx + col_w + UI.pad
    local py = UI.y + UI.header_h + UI.pad
    local pw = UI.w - col_w - (UI.pad * 3.0)
    local ph = UI.h - UI.header_h - (UI.pad * 2.0)

    draw_ui_rect(px, py, pw, ph, 19, 23, 33, 252, 7.0 * s)
    draw_ui_text("PREVIEW", px + 14.0 * s, py + 10.0 * s, 136, 150, 178, 255, 13.5)

    local _, _, self_name = get_self_info()

    local chk_x = px + 14.0 * s
    local chk_y = py + 115.0 * s
    draw_preview_checkbox(mx, my, just_clicked, chk_x, chk_y, "Spine", "spine")
    draw_preview_checkbox(mx, my, just_clicked, chk_x, chk_y + 28.0 * s, "Arms", "arms")
    draw_preview_checkbox(mx, my, just_clicked, chk_x, chk_y + 56.0 * s, "Legs", "legs")

    local bx = px + 132.0 * s
    local by = py + 82.0 * s
    local bw = pw - 166.0 * s
    local bh = ph - 122.0 * s

    if settings.enabled.value then
        local model_cx = bx + bw * 0.5
        local top_cap = tostring(self_name or "Self")
        if settings.distance.value then
            top_cap = top_cap .. " [0 m]"
        end

        local prev_font = math.max(12.0, math.min(24.0, tonumber(settings.size.value) or 22.0))
        local est_w = #top_cap * (prev_font * s * 0.48)
        local max_cap_w = math.max(40.0 * s, pw - 24.0 * s)
        if est_w > max_cap_w then
            prev_font = math.max(11.0, prev_font * (max_cap_w / est_w))
            est_w = #top_cap * (prev_font * s * 0.48)
        end

        local cap_x = clamp(model_cx - est_w * 0.5, px + 12.0 * s, px + pw - est_w - 12.0 * s)
        local cap_y = math.max(py + 28.0 * s, by - prev_font * s - 8.0 * s)
        local nr, ng, nb = get_part_rgb('name')
        draw_ui_text(top_cap, cap_x, cap_y, nr, ng, nb, 255, prev_font)

        if settings.box.value then
            local c = 16.0 * s
            local br, bg, bb = get_part_rgb('box')
            draw_ui_rect(bx, by, c, 2.0 * s, br, bg, bb, 255)
            draw_ui_rect(bx, by, 2.0 * s, c, br, bg, bb, 255)
            draw_ui_rect(bx + bw - c, by, c, 2.0 * s, br, bg, bb, 255)
            draw_ui_rect(bx + bw - 2.0 * s, by, 2.0 * s, c, br, bg, bb, 255)
            draw_ui_rect(bx, by + bh - 2.0 * s, c, 2.0 * s, br, bg, bb, 255)
            draw_ui_rect(bx, by + bh - c, 2.0 * s, c, br, bg, bb, 255)
            draw_ui_rect(bx + bw - c, by + bh - 2.0 * s, c, 2.0 * s, br, bg, bb, 255)
            draw_ui_rect(bx + bw - 2.0 * s, by + bh - c, 2.0 * s, c, br, bg, bb, 255)
        end

        local prev_bar_w = math.max(1.0 * s, math.min(10.0 * s, (tonumber(settings.bar_size.value) or 2.0) * s))
        local prev_gap = math.max(5.0 * s, prev_bar_w + 4.0 * s)

        if settings.health.value then
            local hr, hg, hb = get_part_rgb('health')
            draw_ui_rect(bx - prev_gap - prev_bar_w, by, prev_bar_w, bh, 10, 12, 16, 150)
            draw_ui_rect(bx - prev_gap - prev_bar_w, by + 6.0 * s, prev_bar_w, bh - 6.0 * s, hr, hg, hb, 255)
        end

        if settings.armour.value then
            local ar, ag, ab = get_part_rgb('armor')
            draw_ui_rect(bx + bw + prev_gap, by, prev_bar_w, bh, 10, 12, 16, 150)
            draw_ui_rect(bx + bw + prev_gap, by + 18.0 * s, prev_bar_w, bh - 18.0 * s, ar, ag, ab, 255)
        end

        if settings.skeleton.value then
            local cx = bx + math.floor(bw * 0.5)
            draw_preview_skeleton(cx, by, bh)
        end
    else
        draw_ui_text("ESP Disabled", bx + 18.0 * s, by + 60.0 * s, 155, 162, 178, 255, 16.0)
    end
end

local esp_error_reported = false
util.create_thread(function()
    local ok, err = pcall(function()
        while UI._running do
            local e_ok, e_err = pcall(esp_frame)
            if not e_ok and not esp_error_reported then
                esp_error_reported = true
                toast("ESP error: " .. tostring(e_err))
            end

            if UI.binding_key then
                block_camera_and_game_input()
                poll_key_bind()
            else
                local bind_vk = tonumber(settings.menu_key.value) or 0x2D
                local bind_down = is_button_down(input and input.key, bind_vk)
                if bind_down and not UI._was_bind_down then
                    if UI.open then
                        close_menu()
                    else
                        UI.open = true
                        sync_cursor()
                    end
                end
                UI._was_bind_down = bind_down
            end

            if UI.open then
                block_camera_and_game_input()
                sync_cursor()
                update_cursor_by_mode()
                process_number_input()
                local lmb_down = is_button_down(input and input.mouse, VK_LBUTTON)
                local just_clicked = lmb_down and not UI._was_lmb_down
                render_gui(just_clicked, lmb_down)
                UI._was_lmb_down = lmb_down
            else
                UI._was_lmb_down = false
                force_hide_cursor()
            end

            util.yield(0)
        end
    end)

    cleanup()
    if not ok then
        toast("Script error: " .. tostring(err))
    end
end)

toast("Player ESP + GUI loaded (" .. ACTIVE_RES_LABEL .. ")")