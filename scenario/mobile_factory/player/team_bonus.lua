local KC = require 'klib/container/container'
local Event = require 'klib/event/event'

local Config = require 'scenario/mobile_factory/config'
local TeamRegistry = require('scenario/mobile_factory/player/team_registry')

local TeamBonus = KC.class(Config.PACKAGE_PLAYER_PREFIX .. "TeamBonus", function(self, team)
    self.team = team
    self.resource_warp_rate = 1
    team.force.research_queue_enabled = true
    team.force.worker_robots_speed_modifier = Config.WORKER_ROBOTS_SPEED_MODIFIER
end)

function TeamBonus:on_research_finished(research)
    local level = string.match(research.name, "mining%-productivity%-(%d+)")
    if level then
        level = tonumber(level)
        if not research.research_unit_count_formula then
            self.team.resource_warp_rate = Config.RESOURCE_WARP_RATE_TABLE[level]
        else
            level = research.level
            self.team.resource_warp_rate = Config.RESOURCE_WARP_RATE_TABLE[3] + (level-3) * Config.RESOURCE_WARP_RATE_MULTIPLIER
        end
    end
end

Event.register(defines.events.on_research_finished, function(event)
    local team = TeamRegistry[event.research.force.index]
    team.bonus:on_research_finished(event.research)
end)

return TeamBonus