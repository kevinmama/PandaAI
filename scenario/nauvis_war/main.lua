local KC = require 'klib/container/container'
local KPanel = require 'modules/k_panel/k_panel'

require 'scenario/nauvis_war/buy_gui'

local Event = require 'klib/event/event'
local Entity = require 'klib/gmo/entity'
local Agent = require 'ai/agent/agent'
local Table = require 'klib/utils/table'
local Commands = require 'ai/command/commands'
local Behaviors = require 'ai/behavior/behaviors'

Event.on_init(function()
    local kp = KC.get(KPanel)
    kp.map_info_main_caption = "异星战场"
    kp.map_info_sub_caption = "打虫子，买士兵"
    kp.map_info_text = "如果你身上的金币没增加，检查你的士兵物品栏。By Kevinma Q群:780980177"

    --local surface = game.surfaces["nauvis"]
    --local player_force = game.forces["player"]
    --for i = 1, 15 do
    --    local unit = Entity.create_unit(surface, {
    --        name = 'character', position = {0,0}, force = player_force
    --    }, {['submachine-gun'] = 1, ['firearm-magazine'] = 200})
    --    --group.add_member(unit)
    --    local agent = Agent:new(unit)
    --    Table.insert(agents, agent)
    --end
end)

Event.register(defines.events.on_player_created, function(event)
    local player = game.get_player(event.player_index)
    Entity.give_unit_armoury(player.character, {
        ["submachine-gun"] = 1,
        ["firearm-magazine"] = 200,
        ["shotgun"] = 1,
        ["shotgun-shell"] = 100,
        ["heavy-armor"] = 1,
    })
    Entity.give_entity_items(player.character, {
        coin = 1000
    })
end)

Event.register(defines.events.on_player_respawned, function(event)
    local player = game.get_player(event.player_index)
    Entity.give_unit_armoury(player.character, {
        ["submachine-gun"] = 1,
        ["firearm-magazine"] = 50
    })
    Entity.give_entity_items(player.character, {
        coin = 200
    })
end)

Event.register(defines.events.on_entity_died, function(event)
    if event.entity.type == 'unit-spawner' then
        if event.cause then
            Entity.give_entity_items(event.cause, {
                coin = 50
            })
        end
    end
end)

Event.on_nth_tick(60, function()
    Table.each(game.connected_players, function(player)
        Entity.give_entity_items(player.character, {
            coin = 1
        })
    end)
end)

--Event.on_game_ready(function()
    --Entity.set_indestructible(game.get_player(1).character)
    --Table.each(agents, function(agent)
    --    --agent:execute_command(Commands.Move, {x=32,y=0})
    --    agent:add_behavior(Behaviors.Alert)
    --    agent:add_behavior(Behaviors.Separation, 1)
    --    agent:set_command(Commands.Follow, game.players[1])
    --end)
--end)
