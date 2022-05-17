local KC = require 'klib/container/container'
local Behavior = require 'ai/behavior/behavior'
local Position = require 'klib/gmo/position'

local Separation = KC.class('ai.behavior.Separation', Behavior, function(self, agent, distance)
    Behavior(self,  agent)
    self.distance = distance or 1
end)

function Separation:get_name()
    return "separation"
end

function Separation:update()
    local agent = self:get_agent()
    local near_area = Position.new(agent:get_position()):expand_to_area(self.distance)
    local near_entities = agent.entity.surface.find_entities_filtered({
            area = near_area,
            name = agent.entity.name,
            force = agent.entity.force
        })
    agent:get_steer():separation(near_entities, {
        distance = self.distance
    })
end

return Separation
