local KC = require('klib/container/container')
local Team = require('scenario/mobile_factory/team')
local Config = require('scenario/mobile_factory/config')

local MainTeam = KC.singleton(Config.CLASS_NAME_MAIN_TEAM, Team, function(self)
    self.force = game.forces['player']
    Team(self)
    self.allow_join = true
    self.allow_auto_join = true
end)

function MainTeam:get_name()
    return {"mobile_factory.main_team_name"}
end

function MainTeam:is_main_team()
    return true
end

return MainTeam
