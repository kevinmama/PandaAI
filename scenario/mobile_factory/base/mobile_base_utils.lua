local KC = require 'klib/container/container'
local Table = require 'klib/utils/table'
local Chunk = require 'klib/gmo/chunk'
local Position = require 'klib/gmo/position'
local Area = require 'klib/gmo/area'
local Dimension = require 'klib/gmo/dimension'
local Entity = require 'klib/gmo/entity'
local Inventory = require 'klib/gmo/inventory'
local Config = require 'scenario/mobile_factory/config'
local ColorList = require 'stdlib/utils/defines/color_list'
local Player = require 'scenario/mobile_factory/player/player'
local Team = require 'scenario/mobile_factory/player/team'

local U = {}

function U.get_base_by_vehicle(vehicle)
    local data = vehicle and Entity.get_data(vehicle)
    return data and data.base_id and KC.get(data.base_id)
end

--- 获取玩家遥控或驾驶的基地
function U.get_controlling_base_by_player(player)
    local vehicle = player.cursor_stack and player.cursor_stack.connected_entity or player.vehicle
    return U.get_base_by_vehicle(vehicle)
end

function U.get_visiting_base_by_player(player)
    return Player.get(player.index).visiting_base
end

local function find_bases(team_id, handler)
    local force
    if team_id then
        local team = KC.get(team_id)
        force = team and team.force
    end
    local vehicles = handler(force)
    local bases = {}
    for _, vehicle in pairs(vehicles) do
        local base = U.get_base_by_vehicle(vehicle)
        Table.insert(bases, base)
    end
    return bases
end

function U.find_bases_in_area(area, team_id)
    return find_bases(team_id, function(force)
        return game.surfaces[Config.GAME_SURFACE_NAME].find_entities_filtered({
            name = Config.BASE_VEHICLE_NAME,
            area = area,
            force = force
        })
    end)
end

function U.find_bases_in_radius(position, radius, team_id)
    return find_bases(team_id, function(force)
        return game.surfaces[Config.GAME_SURFACE_NAME].find_entities_filtered({
            name = Config.BASE_VEHICLE_NAME,
            position = position,
            radius = radius,
            force = force
        })
    end)
end

function U.give_base_initial_items(base)
    local should_give = false
    local team = base.team
    if team:is_main_team() then
        should_give = true
    else
        should_give = team.captain.never_reset
    end

    if should_give then
        Entity.give_unit_armoury(base.vehicle, Table.dictionary_combine(
            Config.SPIDER_INIT_AMMO,
            Config.SPIDER_INIT_GRID_ITEMS,
            Config.SPIDER_INIT_ITEMS
        ))
    end
end

function U.is_position_inside(base, position)
    return Position.inside(position, U.get_base_area(base, true))
end

function U.get_deploy_position(base)
    return base.deploy_position or Position.round(base.vehicle.position)
end

function U.get_base_area(base, inside)
    return Area.from_dimensions(base.dimensions, base.center, inside)
end

function U.get_deploy_area(base, inside)
    return Area.from_dimensions(base.dimensions, U.get_deploy_position(base), inside)
end

function U.get_valid_area(base, inside)
    return base:is_deployed() and U.get_deploy_area(base, inside) or U.get_base_area(base, inside)
end

function U.get_io_area(base, inside)
    return Area.from_dimensions(Dimension.CHUNK_UNIT, U.get_deploy_position(base), inside)
end

function U.find_chunk_of_base(base, func)
    return Chunk.find_from_dimensions(base.dimensions, base.center, true, func)
end

function U.each_chunk_of_base(base, func)
    Chunk.each_from_dimensions(base.dimensions, base.center, true, func)
end

function U.each_chunk_of_deploy_area(base, func)
    Chunk.each_from_dimensions(base.dimensions, U.get_deploy_position(base), true, func)
end

function U.find_entities_in_base(base, filter)
    return base.surface.find_entities_filtered(Table.merge({
        area = U.get_base_area(base)
    },filter))
end

function U.find_entities_in_deploy_area(base, filter)
    return base.surface.find_entities_filtered(Table.merge({
        area = Area.from_dimensions(base.dimensions, U.get_deploy_position(base), true)
    }, filter))
end

function U.set_player_bonus(player)
    player.character_running_speed_modifier = Config.BASE_RUNNING_SPEED_MODIFIER
    player.character_reach_distance_bonus = Config.BASE_REACH_DISTANCE_BONUS
    player.character_build_distance_bonus = Config.BASE_BUILD_DISTANCE_BONUS
end

function U.reset_player_bonus(player)
    player.character_running_speed_modifier = 0
    player.character_reach_distance_bonus = 0
    player.character_build_distance_bonus = 0
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
    if entity then
        Entity.set_indestructible(entity, true)
        return entity
    else
        return nil
    end
end

function U.transfer_chest_inventory(from_entity, to_entity)
    local inv1 = from_entity.get_inventory(defines.inventory.chest)
    local inv2 = to_entity.get_inventory(defines.inventory.chest)
    Inventory.transfer_inventory(inv1, inv2)
end

function U.set_player_visiting_base(player, base)
    -- 有可能传进 character 类，这里过滤掉
    if player and player.object_name == 'LuaPlayer' then
        Player.get(player.index):set_visiting_base(base)
    end
end

function U.get_alt_surface()
    return game.surfaces[Config.ALT_SURFACE_NAME]
end

return U