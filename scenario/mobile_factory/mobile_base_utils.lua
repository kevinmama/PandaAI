local Table = require 'klib/utils/table'
local Chunk = require 'klib/gmo/chunk'
local Area = require 'klib/gmo/area'
local Dimension = require 'klib/gmo/dimension'
local Config = require 'scenario/mobile_factory/config'
local ColorList = require 'stdlib/utils/defines/color_list'

local BASE_SIZE , CHUNK_SIZE = Config.BASE_SIZE, Config.CHUNK_SIZE

local U = {}

function U.for_each_chunk_of_base(base, func)
    Chunk.find_from_dimensions(Dimension.expand(BASE_SIZE, CHUNK_SIZE), base.center, func)
end

function U.find_entities_in_base(base, filter)
    return base.surface.find_entities_filtered(Table.merge({
        {area = Area.from_dimensions(Dimension.expand(BASE_SIZE, CHUNK_SIZE), base.center)}
    },filter))
end

function U.draw_state_text(base, options)
    return rendering.draw_text(Table.merge({
        text = "",
        surface = base.vehicle.surface,
        target = base.vehicle,
        target_offset = {0, -6},
        color = ColorList.green,
        scale = 1,
        font = 'default-game',
        alignment = 'center',
        scale_with_zoom = false,
        visible = false
    }, options or {}))
end

function U.update_state_text(state_text_id, list)
    local text = {""}
    for _, state_and_string in ipairs(list) do
        if state_and_string[1] then
            table.insert(text, '[')
            table.insert(text, state_and_string[2])
            table.insert(text, ']')
        end
    end
    if next(text) then
        rendering.set_text(state_text_id, text)
        rendering.set_visible(state_text_id, true)
    else
        rendering.set_visible(state_text_id, false)
    end
end

return U