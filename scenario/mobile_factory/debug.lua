if not __DEBUG__ then return end

local KC = require('klib/container/container')
local Tasks = require 'klib/task/tasks'
local Team = require 'scenario/mobile_factory/player/team'
local Player = require 'scenario/mobile_factory/player/player'

Tasks.submit_init_task("scenario.mobile_factory.Main$DebugTask", 1, function(self)
    local main_team = KC.find_object(Team, function(team)
        return team:is_main_team()
    end)
    for _, player in pairs(game.connected_players) do
        main_team:request_join(player.index)
    end
    game.speed = 8
end)


