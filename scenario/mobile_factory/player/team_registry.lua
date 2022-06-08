local Registry = require 'klib/utils/registry'
local PlayerRegistry = require 'scenario/mobile_factory/player/player_registry'

local TeamRegistry = {}

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

Registry.new_local(TeamRegistry)
--Registry.new_global("team", TeamRegistry)

return TeamRegistry
