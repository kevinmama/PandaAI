local KC = require('klib/container/container')
local Table = require 'klib/utils/table'

local Team = require('scenario/mobile_factory/team')
local Player = require('scenario/mobile_factory/player')
local Config = require('scenario/mobile_factory/config')
local RegrowthMap = require 'scenario/mobile_factory/regrowth_map_nauvis'

local MainTeam = KC.singleton(Config.CLASS_NAME_MAIN_TEAM, Team, function(self)
    self.force = game.forces['player']
    Team(self)
    self.allow_join = true
    self.allow_auto_join = true
    KC.get(RegrowthMap):add_vehicle(self:get_base().vehicle)
end)

function MainTeam:get_name()
    return {"mobile_factory.main_team_name"}
end

function MainTeam:is_main_team()
    return true
end

function MainTeam:is_online()
    local main_team_id = self:get_id()
    return #Table.filter(self.force.connected_players, function(player)
        return Player.get(player.index).team_id == main_team_id
    end) > 0
end

function MainTeam:get_members()
    local main_team_id = self:get_id()
    return Table.filter(self.force.players, function(player)
        return Player.get(player.index).team_id == main_team_id
    end)
end

return MainTeam
