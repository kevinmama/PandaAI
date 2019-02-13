local KC = require 'container'
local kui = require 'klib/kui'
local KCommand = require 'command'
local SolderSpawnerManager = require 'tow/solder_spawner_manager'

kui.button({
   name = "spawn_solder_btn",
   caption = "S"
}):on_click(function(event)
    KC.get(SolderSpawnerManager).spawners[event.player_index]:spawn_around_player()
end):attach(kui.top)

kui.button({
    name = "solder_command_menu",
    caption = "C"
}):on_toggle(function(toggle_event)
    return kui.flow("solder_command_list"):items(function(parent, player_index)

        kui.button({
            name = "cmd_follow_btn",
            caption = "F"
        }):on_click(function(event)
            KC.get(SolderSpawnerManager).spawners[event.player_index]:command(KCommand.Follow, game.players[event.player_index])
        end):attach(parent, player_index)

        kui.button({
            name = "cmd_stop_btn",
            caption = "S"
        }):on_click(function(event)
            KC.get(SolderSpawnerManager).spawners[event.player_index]:command(KCommand.Standby)
        end):attach(parent, player_index)

    end):attach(kui.left, toggle_event.player_index)
end):attach(kui.top)

