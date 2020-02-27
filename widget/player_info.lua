local table = require('__stdlib__/stdlib/utils/table')
local Event = require 'klib/event/event'
local ScriptHelper = require 'klib/helper/script_helper'
local gui = require 'klib/gui/gui'

local PlayerInfoModifierUpdater = {}
table.merge(PlayerInfoModifierUpdater, {
    components = {},
    add = function(key, component)
        PlayerInfoModifierUpdater.components[key] = component
    end,
    update = function()
        ScriptHelper.each_alive_player(function(player)
            local components = PlayerInfoModifierUpdater.components
            for key, component in pairs(components) do
                local value = player.character[key]
                component:get_element(player.index).caption = value
            end
        end)
    end
})

Event.every_n_tick(30, function()
    PlayerInfoModifierUpdater.update()
end)

return gui.button('player_info_menu', 'info'):toggle_component(function()

    local info_table = gui.table('player_info_table', 2, gui.left):visible(false)
                          :label_item('player_info_position', 'position', function(value)
        value:on(defines.events.on_player_changed_position, function(self, event)
            local pos = game.players[event.player_index].position
            self:get_element(event.player_index).caption = pos.x .. ', ' .. pos.y
        end)
    end)
                          :label_item('player_info_pollution', 'pollution', function(value)
        value:on(defines.events.on_player_changed_position, function(self, event)
            local player = game.players[event.player_index]
            self:get_element(event.player_index).caption = player.surface.get_pollution(player.position)
        end)
             :on(defines.events.on_tick, function(self, event)
            if event.tick % 60 == 0 then
                for _, player in pairs(game.connected_players) do
                    self:get_element(player.index).caption = player.surface.get_pollution(player.position)
                end
            end
        end)
    end)

    for _, modifier_name in ipairs({
        'crafting_speed_modifier',
        'mining_speed_modifier',
        'running_speed_modifier',
        'build_distance_bonus',
        'item_drop_distance_bonus',
        'reach_distance_bonus',
        'resource_reach_distance_bonus',
        'item_pickup_distance_bonus',
        'loot_pickup_distance_bonus',
        'inventory_slots_bonus',
        'logistic_slot_count_bonus',
        'trash_slot_count_bonus',
        'maximum_following_robot_count_bonus',
        'health_bonus'
    }) do
        local component_name = 'player_info_' .. modifier_name
        local label = modifier_name
        local prop_key = 'character_' .. modifier_name
        info_table:label_item(component_name, label, function(value)
            PlayerInfoModifierUpdater.add(prop_key, value)
        end)
    end

    return info_table
end)


