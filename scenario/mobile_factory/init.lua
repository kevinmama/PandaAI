local Event = require 'klib/event/event'
local Chunk = require 'klib/gmo/chunk'
local Surface = require 'klib/gmo/surface'
local Area = require 'klib/gmo/area'
local Config = require 'scenario/mobile_factory/config'

local function init_alt_surface()
    local map_gen_settings = game.default_map_gen_settings
    map_gen_settings.peaceful_mode = true
    map_gen_settings.property_expression_names["enemy-base-frequency"] = 0
    local surface = game.create_surface(Config.ALT_SURFACE_NAME, map_gen_settings)
    surface.generate_with_lab_tiles = true
    surface.always_day = true
    surface.clear()
end

local function init_preserving_area()
    local surface = game.surfaces[Config.CHARACTER_PRESERVING_SURFACE_NAME]
    local area = Area.from_dimensions({
        width=Config.CHARACTER_PRESERVING_RADIUS,
        height=Config.CHARACTER_PRESERVING_RADIUS
    }, Config.CHARACTER_PRESERVING_POSITION, true)
    Chunk.request_to_generate_chunks(surface, Area.expand(area, 4*32))
end

--- 用作 mod 时，跳过 freeplay 的场景和设置
local function ignore_freeplay_settings()
    if remote.interfaces['freeplay'] then
        remote.call("freeplay", "set_disable_crashsite", true)
        remote.call("freeplay", "set_skip_intro", true)
        remote.call("freeplay", "set_created_items", {})
    end
end

Event.on_init(function()
    ignore_freeplay_settings()
    init_alt_surface()
    init_preserving_area()
    --game.map_settings.enemy_expansion.enabled = false
end)