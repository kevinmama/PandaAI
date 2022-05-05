-- 当玩家进入游戏时，给予玩家初始物品

local Event = require 'klib/event/event'
require 'scenario/mobile_factory/mobile_base_manager'

Event.on_init(function()
    if remote.interfaces['freeplay'] then
        remote.call("freeplay", "set_disable_crashsite", true)
        remote.call("freeplay", "set_created_items", {})
    end
end)

local PLAYER_INIT_ITEMS= {
     --["tank"] = 1,
     ["spidertron"] = 1,
     ["spidertron-remote"] = 1,
     ["submachine-gun"] = 1 ,
     ["firearm-magazine"] = 100,
     ["small-electric-pole"] = 50,
     ["iron-plate"] = 100,
     ["copper-plate"] = 100,
     ["coal"] = 100,
     ["stone"] = 100,
     --["solar-panel"] = 50,
     --["accumulator"] = 50,
     --["rocket-launcher"] = 1,
     --["rocket"] = 100,
     --["atomic-bomb"] = 2,
     --["nuclear-fuel"] = 2
}

local function give_quick_start_modular_armor(player)
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

local function givePlayerInitItems(player)
    for name,count in pairs(PLAYER_INIT_ITEMS) do
        player.insert({name=name, count=count})
    end
    give_quick_start_modular_armor(player)
end

local function givePlayerInitItemsOnEvent(event)
    givePlayerInitItems(game.players[event.player_index])
end

Event.on_event(defines.events.on_player_created, givePlayerInitItemsOnEvent)
