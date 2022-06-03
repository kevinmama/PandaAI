local PlayerRegistry = require 'scenario/mobile_factory/player/player_registry'

local TeamRegistry = require ('klib/utils/local_registry')()

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

return TeamRegistry