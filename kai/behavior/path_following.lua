local KC = require 'klib/container/container'
local Position = require 'klib/gmo/position'
local Behavior = require 'kai/behavior/behavior'

local DEFAULT_RADIUS = 5

local PathFollowing = KC.class('kai.behavior.PathFollowing', Behavior, function(self, agent, opts)
    Behavior(self, agent)
    self:set_path(opts.path)

    self.index = 1
    self.waypoint = opts.path.waypoints[self.index]
    self.radius = opts.radius or DEFAULT_RADIUS
    self.scale = opts.scale or 1
    self.done = false
end)

PathFollowing:reference_objects("path")

function PathFollowing:get_name()
    return "path_following"
end

function PathFollowing:update()
    if not self.done then
        local path = self:get_path()
        if self:_is_reach(self.waypoint, self.radius) then
            self.index = self.index + 1
            if self.index > #path.waypoints then
                self.done = true
                return
            else
                self.waypoint = path.waypoints[self.index]
            end
        end
        self:get_agent():get_steer():seek(self.waypoint.position)
    end
end

function PathFollowing:_is_reach(waypoint, radius)
    return Position.distance(self:get_agent():get_position(), waypoint.position) < radius
end

return PathFollowing
