local Config = require 'scenario.mobile_factory.config'
local KC = require 'klib/container/container'
local Table = require 'klib/utils/table'
local Entity = require 'klib/gmo/entity'

local H = {}

function H.give_quick_start_modular_armor(player)
    player.insert{name=Config.PLAYER_INIT_ARMOR, count = 1}
    if player and player.get_inventory(defines.inventory.character_armor) ~= nil and player.get_inventory(defines.inventory.character_armor)[1] ~= nil then
        local grid = player.get_inventory(defines.inventory.character_armor)[1].grid
        for item, count in pairs(Config.Player_INIT_GRID_ITEMS) do
            for _ = 1,count do
                grid.put({name = item})
            end
        end
    end
end

function H.give_player_init_items(player)
    for name,count in pairs(Config.PLAYER_INIT_ITEMS) do
        player.insert({name=name, count=count})
    end
    H.give_quick_start_modular_armor(player)
end

function H.find_near_base(player)
    local entities = player.character.surface.find_entities_filtered({
        name = Config.BASE_VEHICLE_NAME,
        force = player.force,
        position = player.position,
        radius = Config.PLAYER_RECHARGE_DISTANCE
    })
    for _, entity in pairs(entities) do
        local base_id = Entity.get_data(entity, "base_id")
        if base_id then
            return KC.get(base_id)
        end
    end
end

return H