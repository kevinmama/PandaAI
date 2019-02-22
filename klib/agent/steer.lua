local dlog = require('klib/utils/dlog')
local KC = require('klib/container/container')
local TypeUtils = require('klib/utils/type_utils')
local Vector = require('klib/math/vector')
local CollisionAvoidance = require('klib/agent/collision_avoidance')

local is_table, is_function = TypeUtils.is_table, TypeUtils.is_function

local Steer = KC.class('klib.agent.Steer', function(self, agent)
    self.agent = agent
    self._force = Vector.zero
end)

function Steer:get_force()
    return self._force
end

function Steer:clear_force()
    self._force = Vector.zero
end

function Steer:force(force, opts)
    if is_table(opts) then
        local normalize = opts.normalize
        local multiplier = opts.multiplier
        if opts.weight then
            normalize = true
            multiplier = opts.weight
        end
        if normalize then
            force = force:normalized()
        end
        if multiplier then
            force = force * multiplier
        end
    elseif is_function(opts) then
        force = opts(force)
    end
    self._force = self._force + force
end

function Steer:stop(opts)
    opts = opts or {}
    local weight = opts.weight or 10
    if self._force:len() < weight then
        self._force = Vector.zero
    end
end

function Steer:seek(position, opts)
    --dlog("agent position: ", self.agent:position())
    --dlog("seek to position ", position)
    local force = Vector(self.agent:position(), position)
    --dlog("force: ", force)
    self:force(force, opts)
    --dlog("result force: ", self._force)
end

function Steer:flee(position, opts)
    local force = Vector(position, self.agent:position())
    self:force(force, opts)
end

function Steer:wander(min, max, opts)
    local force = Vector.random_direction(min, max)
    self:force(force, opts)
end

function Steer:arrival(position, opts)
    opts = opts or {}
    local max_weight = opts.max_weight or 100
    local slowdown_distance = opts.slowdown_distance or 10
    local stop_distance = opts.stop_distance or 0
    self:seek(position, function(force)
        local len = force:len()
        force:normalize_inplace()
        if len >= slowdown_distance then
            force = force * max_weight
        elseif len >= stop_distance then
            force = force * max_weight * (len / (slowdown_distance - stop_distance))
        else
            force = Vector.zero
        end
        return force
    end)
end

function Steer:avoid_close_neighbors(neighbors, opts)
    opts = opts or {}
    local weight = opts.weight or 25
    local distance = opts.distance or 1

    local position = self.agent:position()
    local flee_force = Vector.zero
    for _, neighbor in pairs(neighbors) do
        if neighbor ~= self.agent.entity then
            local force = Vector(neighbor.position, position)
            local len = force:len()
            if len >= distance then
                force = Vector.zero
            elseif len > 0 then
                -- 与距离的反比成线性关系
                force = force * weight / (len * len)
            else
                force = Vector(1, 0) * weight * 1000000
            end
            flee_force = flee_force + force
        end
    end
    --dlog("flee_force of avoid_close_neighbors: ", flee_force)
    self:force(flee_force)
end

function Steer:avoid_collision(opts)
    local force = CollisionAvoidance:new(self.agent):get_avoidance_force()
    self:force(force, opts)
end

return Steer
