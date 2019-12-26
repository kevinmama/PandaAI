local KC = require 'klib/container/container'
local Helper = require 'pda/behavior/helper'
local Position = require '__stdlib__/stdlib/area/position'

local DEFAULT_RADIUS = 5

local PathFollowing = KC.class('pda.behavior.PathFollowing', function(self, agent, opts)
    self.agent = agent
    self.path = opts.path

    self.index = 1
    self.node = opts.path.nodes[self.index]
    self.radius = opts.radius or DEFAULT_RADIUS
    self.scale = opts.scale or 1
    self.done = false
end)

Helper.define_name(PathFollowing, "path_following")

function PathFollowing:update()
    if not self.done then
        if self:_is_reach(self.node, self.radius) then
            self.index = self.index + 1
            if self.index > #self.path.nodes then
                self.done = true
                return
            else
                self.node = self.path.nodes[self.index]
            end
        end
        self.agent.steer:seek(self.node)
    end
end

function PathFollowing:_is_reach(node, radius)
    return Position.distance(self.agent:position(), node) < radius
end

return PathFollowing
