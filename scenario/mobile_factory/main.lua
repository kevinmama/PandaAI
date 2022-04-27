-- 当玩家进入游戏时，给予玩家初始物品

local Event = require 'klib/event/event'
require 'scenario/mobile_factory/mobile_base_manager'

local GAME_SURFACE_NAME = 'nauvis'

Event.on_init(function()
    if remote.interfaces['freeplay'] then
        remote.call("freeplay", "set_disable_crashsite", true)
        remote.call("freeplay", "set_created_items", {})
    end
end)

local PLAYER_INIT_ITEMS= {
     ["tank"] = 1,
     ["submachine-gun"] = 1 ,
     ["firearm-magazine"] = 100,
     ["small-electric-pole"] = 50,
     --["solar-panel"] = 50,
     --["accumulator"] = 50,
     --["rocket-launcher"] = 1,
     --["rocket"] = 100,
     --["atomic-bomb"] = 1,
     ["nuclear-fuel"] = 2
}

local function givePlayerInitItems(player)
    for name,count in pairs(PLAYER_INIT_ITEMS) do
        player.insert({name=name, count=count})
        if DEBUG then
            player.character_running_speed_modifier = 5
        end
    end
end

local function givePlayerInitItemsOnEvent(event)
    givePlayerInitItems(game.players[event.player_index])
end

Event.on_event(defines.events.on_player_created, givePlayerInitItemsOnEvent)
