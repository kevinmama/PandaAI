local KContainer = require('klib/kcontainer')
require 'stdlib/area/position'

local Follow = KContainer.define_class('klib.agent.command.Follow', {

}, function(self, agent, target)
    self.agent = agent
    self.target = target
end)

function Follow:execute()
    self.agent:arrival(self.target.position, {
        max_weight = 100,
        slowdown_distance = 20,
        stop_distance = 2
    })

    local near_area = Position.new(self.agent:position()):expand_to_area(1)
    local near_solders = self.target.surface.find_entities_filtered({
        area = near_area,
        name = 'player',
        force = 'player'
    })
    self.agent:avoid_close_neighbors(near_solders, {
        distance = 1
    })

    self.agent:stop({ weight = 20 })
end

return Follow