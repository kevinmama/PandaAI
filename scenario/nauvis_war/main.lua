local KC = require 'klib/container/container'
local KPanel = require 'modules/k_panel/k_panel'

require 'scenario/nauvis_war/buy_gui'

local Event = require 'klib/event/event'
local Table = require 'klib/utils/table'
local Entity = require 'klib/gmo/entity'
local Player = require 'klib/gmo/player'

local Group = require 'kai/agent/group'
local Commands = require 'kai/command/commands'

Event.on_init(function()
    local kp = KC.get(KPanel)
    kp.map_info_main_caption = "异星战场"
    kp.map_info_sub_caption = "打虫子，买士兵"
    kp.map_info_text = "如果你身上的金币没增加，检查你的士兵物品栏。By Kevinma Q群:780980177"
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

    local group = Group:new({
        surface = player.surface,
        position = player.position,
        force = player.force,
        bounding_box = player.character.bounding_box
    })
    Player.set_data(player.index, "group_id", group:get_id())
    group:set_command(Commands.Follow, player)
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
