local KC = require 'klib/container/container'
local Registry = require 'klib/utils/registry'
local PlayerRegistry = require 'scenario/mobile_factory/player/player_registry'

local TeamRegistry = {}
TeamRegistry.MAIN_TEAM = -1
local main_team = nil

function TeamRegistry.get_by_player_index(player_index)
    local player = PlayerRegistry[player_index]
    return player and player.team
end

function TeamRegistry.get_id_by_player_index(player_index)
    local player = PlayerRegistry[player_index]
    return player and player.team:get_id()
end

function TeamRegistry.get_by_force(force)
    return TeamRegistry[force.index]
end

function TeamRegistry.get_main_team()
    if KC.is_valid(main_team) then
        return main_team
    else
        for i = 1, #game.forces do
            local team = TeamRegistry[game.forces[i].index]
            if team and team:is_main_team() then
                main_team = team
                return main_team
            end
        end
        return nil
    end
end

Registry.new_local(TeamRegistry)
--Registry.new_global("team", TeamRegistry)

return TeamRegistry
