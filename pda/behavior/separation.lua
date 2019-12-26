local KC = require 'klib/container/container'
local Position = require '__stdlib__/stdlib/area/position'
local Helper = require 'pda/behavior/helper'

local Separation = KC.class('pda.behavior.Separation', function(self, agent, distance, entity_filter)
    self.agent = agent
    self.steer = agent.steer
    self.distance = distance or 1
    self.entity_filter = entity_filter
end)

Helper.define_name(Separation, "separation")

function Separation:update()
    local near_area = Position.new(self.agent:position()):expand_to_area(self.distance)
    local near_entities
    if self.entity_filter then
        near_entities = self.entity_filter.filter(near_area)
    else
        near_entities = self.agent.entity.surface.find_entities_filtered({
            area = near_area,
            name = 'player',
            force = 'player'
        })
    end
    self.steer:separation(near_entities, {
        distance = self.distance
    })
end

return Separation
