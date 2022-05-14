local Table = require 'klib/utils/table'
local Chunk = require 'klib/gmo/chunk'
local Area = require 'klib/gmo/area'
local Dimension = require 'klib/gmo/dimension'
local Entity = require 'klib/gmo/entity'
local Inventory = require 'klib/gmo/inventory'
local Config = require 'scenario/mobile_factory/config'
local ColorList = require 'stdlib/utils/defines/color_list'
local Player = require 'scenario/mobile_factory/player'

local BASE_SIZE , CHUNK_SIZE = Config.BASE_SIZE, Config.CHUNK_SIZE

local U = {}

function U.give_base_initial_items(base)
    local should_give = false
    local team = base:get_team()
    if team:is_main_team() then
        should_give = true
    else
        local captain_player_index = base:get_team().captain
        should_give = Player.get(captain_player_index).never_reset
    end

    if should_give then
        U.give_spider_init_ammo(base.vehicle)
        U.give_spider_init_items(base.vehicle)
        U.give_spider_init_equipment(base.vehicle)
    end
end

function U.give_spider_init_ammo(spider)
    local inventory = spider.get_inventory(defines.inventory.spider_ammo)
    for name,count in pairs(Config.SPIDER_INIT_AMMO) do
        inventory.insert({name=name, count=count})
    end
end

function U.give_spider_init_items(spider)
    local inventory = spider.get_inventory(defines.inventory.spider_trunk)
    for name,count in pairs(Config.SPIDER_INIT_ITEMS) do
        inventory.insert({name=name, count=count})
    end
end

function U.give_spider_init_equipment(spider)
    local grid = spider.grid
    for item, count in pairs(Config.SPIDER_INIT_GRID_ITEMS) do
        for _ = 1,count do
            grid.put({name = item})
        end
    end
end


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

function U.create_system_entity(base, name, position, options)
    local entity = base.surface.create_entity(Table.merge({
        name = name,
        position = position,
        force = base.force
    }, options or {}))
    Entity.set_indestructible(entity, true)
    return entity
end

function U.transfer_chest_inventory(from_entity, to_entity)
    local inv1 = from_entity.get_inventory(defines.inventory.chest)
    local inv2 = to_entity.get_inventory(defines.inventory.chest)
    Inventory.transfer_inventory(inv1, inv2)
end


return U