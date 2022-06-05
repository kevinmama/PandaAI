local Registry = require 'klib/utils/registry'
local TeamRegistry = require('scenario/mobile_factory/player/team_registry')

local TeamCenterRegistry = {}

function TeamCenterRegistry.get_by_team_id(team_id)
    return TeamCenterRegistry[team_id]
end

function TeamCenterRegistry.get_by_force_index(force_index)
    local team = TeamRegistry[force_index]
    return team and TeamCenterRegistry.get_by_team_id(team:get_id())
end

function TeamCenterRegistry.get_first_base_by_team_id(team_id)
    local team_center = TeamCenterRegistry[team_id]
    return team_center and team_center.bases[1]
end

function TeamCenterRegistry.get_bases_by_team_id(team_id)
    local team_center = TeamCenterRegistry[team_id]
    return team_center and team_center.bases
end

function TeamCenterRegistry.get_by_player_index(player_index)
    local team = TeamRegistry.get_by_player_index(player_index)
    return team and TeamCenterRegistry[team:get_id()]
end

function TeamCenterRegistry.get_first_base_by_player_index(player_index)
    local team = TeamRegistry.get_by_player_index(player_index)
    return team and TeamCenterRegistry.get_first_base_by_team_id(team:get_id())
end

function TeamCenterRegistry.get_bases_by_player_index(player_index)
    local team = TeamRegistry.get_by_player_index(player_index)
    return team and TeamCenterRegistry.get_bases_by_team_id(team:get_id())
end

Registry.new_local(TeamCenterRegistry)

return TeamCenterRegistry