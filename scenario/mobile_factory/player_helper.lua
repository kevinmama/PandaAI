local Config = require 'scenario.mobile_factory.config'
local KC = require 'klib/container/container'
local Table = require 'klib/utils/table'
local Entity = require 'klib/gmo/entity'

local H = {}

function H.give_quick_start_modular_armor(player)
    player.insert{name="modular-armor", count = 1}
    if player and player.get_inventory(defines.inventory.character_armor) ~= nil and player.get_inventory(defines.inventory.character_armor)[1] ~= nil then
        local p_armor = player.get_inventory(defines.inventory.character_armor)[1].grid
        if p_armor ~= nil then
            p_armor.put({name = "personal-roboport-equipment"})
            p_armor.put({name = "battery-mk2-equipment"})
            p_armor.put({name = "personal-roboport-equipment"})
            for _ =1,15 do
                p_armor.put({name = "solar-panel-equipment"})
            end
        end
        player.insert{name="construction-robot", count = 40}
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