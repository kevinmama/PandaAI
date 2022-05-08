local Config = require 'scenario.mobile_factory.config'
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
        player.insert{name="construction-robot", count = 50}
    end
end

function H.give_player_init_items(player)
    for name,count in pairs(Config.PLAYER_INIT_ITEMS) do
        player.insert({name=name, count=count})
    end
    H.give_quick_start_modular_armor(player)
end

return H