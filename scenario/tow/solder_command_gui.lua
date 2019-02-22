local KC = require 'klib/container/container'
local gui = require 'klib/gui/gui'
local KCommand = require 'klib/command/command'

local SolderSpawnerManager = require 'scenario/tow/solder_spawner_manager'
local AutoSupply = require 'scenario/tow/auto_supply'
local EnemySpawner = require 'scenario/tow/enemy_spawner'

gui.button({
    name = 'spawn_solder_btn',
    caption = 'S'
}):on_click(function(event)
    KC.get(SolderSpawnerManager).spawners[event.player_index]:spawn_around_player()
end):attach(gui.top)

local SolderCommmandList = gui.flow({
    name = "solder_command_list"
})
:visible(false)
:attach(gui.left)
:with(function(parent)
    gui.button({
        name = "cmd_follow_btn",
        caption = "F"
    }):on_click(function(event)
        local squad = KC.get(SolderSpawnerManager).spawners[event.player_index]
        squad:add_command(KCommand.Follow, game.players[event.player_index])
        squad:add_command(KCommand.Alert)
    end):attach(parent)

    gui.button({
        name = "cmd_stop_btn",
        caption = "S"
    }):on_click(function(event)
        KC.get(SolderSpawnerManager).spawners[event.player_index]:add_command(KCommand.Standby)
    end):attach(parent)
end)

gui.button({
    name = 'solder_command_menu',
    caption = 'C'
}):on_click(function(event)
    SolderCommmandList:toggle_visibility(event.player_index)
end):attach(gui.top)


gui.button({
    name = 'ammo_supply_btn',
    caption = 'A'
}):on_click(function(event)
    local agents = KC.get(SolderSpawnerManager).spawners[event.player_index].agents
    local characters = table.map(agents, function(agent)
        return agent.entity
    end)
    table.insert(characters, game.players[event.player_index])
    KC.get(AutoSupply):supply_weapon_and_ammo(characters)
end):attach(gui.top)

gui.button({
    name = 'enemy_spawner_btn',
    caption = 'E'
}):on_click(function(event)
    KC.get(EnemySpawner):spawn_around_target(game.players[event.player_index])
end):attach(gui.top)



