local Event = require 'klib/event/event'
local Chunk = require 'klib/gmo/chunk'
local Surface = require 'klib/gmo/surface'
local Config = require 'scenario/mobile_factory/config'

local function init_alt_surface()
    local surface = game.create_surface(Config.ALT_SURFACE_NAME)
    surface.generate_with_lab_tiles = true
    surface.always_day = true

    local surface = game.surfaces[Config.CHARACTER_PRESERVING_SURFACE_NAME]
    local area = Config.CHARACTER_PRESERVING_AREA
    Chunk.request_to_generate_chunks(surface, area)
    surface.force_generate_chunk_requests()
    Surface.clear_entities_in_area(surface, Config.CHARACTER_PRESERVING_AREA)
    Surface.set_tiles(surface, "concrete", Config.CHARACTER_PRESERVING_AREA)
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
    --game.map_settings.enemy_expansion.enabled = false
end)