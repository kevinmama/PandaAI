local table = require '__stdlib__/stdlib/utils/table'
local KC = require 'klib/container/container'
local gui = require 'klib/gui/gui'

local SolderSpawnerManager = require 'scenario/tow/solder_spawner_manager'
local AutoSupply = require 'scenario/tow/auto_supply'
local EnemySpawner = require 'scenario/tow/enemy_spawner'


--local Event = require 'klib/event/event'
--Event.execute_once(defines.events.tick, function()
--    game.player.gui.top.add {
--        type = "label",
--        name = "greeting",
--        caption = "Hi!"
--    }
--end)


gui.button_tab('main_menu_tab', gui.top)
        :with(function(main_menu_tab)

    require('widget/debug_panel'):attach(main_menu_tab)
    require('widget/player_info'):attach(main_menu_tab)


    gui.button('spawn_solder_btn', 'spawn', main_menu_tab):on_click(function(event)
        SolderSpawnerManager:get_spawner_by_event(event):spawn_around_player()
    end)

    gui.button('solder_command_menu', 'behavior', main_menu_tab):toggle_component(function(self)
        return gui.flow('solder_command_list', gui.left)
                  :visible(false)
                  :with(function(parent)
            gui.button('cmd_follow_btn', 'Follow', parent):on_click(function(event)
                SolderSpawnerManager:get_spawner_by_event(event):add_default_behavior()
            end)
            gui.button('cmd_follow_path', 'Path', parent):on_click(function(event)
                SolderSpawnerManager:get_spawner_by_event(event):toggle_follow_path()
            end)
            gui.button('cmd_stop_btn', 'Stop', parent):on_click(function(event)
                SolderSpawnerManager:get_spawner_by_event(event):stop_following()
            end)
        end)
    end)

    gui.button('supply_btn', 'Supply', main_menu_tab):on_click(function(event)
        local agents = SolderSpawnerManager:get_spawner_by_event(event).agents
        local characters = table.map(agents, function(agent)
            return agent.entity
        end)
        table.insert(characters, game.players[event.player_index])
        KC.get(AutoSupply):supply_weapon_and_ammo(characters)
    end)

    gui.button('enemy_spawner_btn', 'Enemy', main_menu_tab):on_click(function(event)
        KC.get(EnemySpawner):spawn_around_target(game.players[event.player_index])
    end)

    gui.button('path_menu_btn', 'Path', main_menu_tab):toggle_component(function(self)
        return gui.flow('path_menu_flow', gui.left):visible(false):with(function(parent)
            gui.button('new_path_btn', 'New Path', parent):on_click(function(event)
                SolderSpawnerManager:get_spawner_by_event(event):new_path()
            end)
            gui.button('add_node_btn', 'New Node', parent):on_click(function(event)
                SolderSpawnerManager:get_spawner_by_event(event):add_path_node()
            end)
        end)
    end)

    gui.button('pollute_btn', 'Pollute', main_menu_tab):on_click(function(event)
        local player = game.players[event.player_index]
        player.surface.pollute(player.position, 10000)
    end)
end)

