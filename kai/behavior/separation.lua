local KC = require 'klib/container/container'
local Position = require 'klib/gmo/position'
local Behavior = require 'kai/behavior/behavior'

local Separation = KC.class('kai.behavior.Separation', Behavior, function(self, agent, distance)
    Behavior(self, agent)
    self.distance = distance or 5

    self.tick = game.tick
    self.force = nil
end)

function Separation:get_name()
    return "separation"
end

function Separation:update()
    if game.tick >= self.tick + 60 then
        self.tick = game.tick
    else
        if self.force then
            local delta = self.tick + 60 - game.tick
            local scale = (delta * delta / 3600)
            self:get_agent():get_steer():force(self.force * scale)
        end
        return
    end

    local agent = self:get_agent()
    local group = agent:get_group()
    local near_agents
    if group then
        near_agents = group:get_neighbours()
    else
        local near_area = Position.new(agent:get_position()):expand_to_area(self.distance)
        near_agents = agent:get_surface().find_entities_filtered({
            area = near_area,
            force = agent:get_force()
        })
    end
    self.force = agent:get_steer():separation(near_agents, {
        distance = self.distance
    })
end

return Separation
