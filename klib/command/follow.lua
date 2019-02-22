local KC = require('klib/container/container')
require 'stdlib/area/position'
local CommandHelper = require('klib/command/command_helper')

local Follow = KC.class('klib.agent.command.Follow', function(self, agent, target)
    self.agent = agent
    self.target = target
    self.steer = agent.steer
end)

CommandHelper.define_name(Follow, 'follow')

function Follow:execute()
    self.steer:arrival(self.target.position, {
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
    self.steer:avoid_close_neighbors(near_solders, {
        distance = 2
    })

    self.steer:stop({ weight = 20 })

    self.steer:avoid_collision()
end

return Follow