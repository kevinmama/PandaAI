local KC = require('klib/container/container')
require 'stdlib/area/position'
local Helper = require('pda/behavior/helper')

local Follow = KC.class('pda.behavior.Follow', function(self, agent, target)
    self.agent = agent
    self.target = target
    self.steer = agent.steer
end)

Helper.define_name(Follow, 'follow')

function Follow:update()
    self.steer:arrival(self.target.position, {
        slowdown_distance = 10,
        stop_distance = 2
    })
end

return Follow