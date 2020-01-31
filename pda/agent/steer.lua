local dlog = require 'klib/utils/dlog'
local table = require '__stdlib__/stdlib/utils/table'
local KC = require 'klib/container/container'
local Vector = require 'klib/math/vector'
local CollisionAvoidance = require 'pda/agent/collision_avoidance'
local ColorList = require '__stdlib__/stdlib/utils/defines/color_list'
local RenderingGroup = require 'klib/rendering/rendering_group'

local Steer = KC.class('pda.agent.Steer', function(self, agent)
    self.agent = agent
    self._force = Vector.zero
    self._display = RenderingGroup:new()
end)

function Steer:reset()
    self:clear_force()
end

function Steer:get_force()
    return self._force
end

function Steer:clear_force()
    self._force = Vector.zero
end

function Steer:force(force, modifier)
    if modifier then
        force = modifier(force)
    end
    self._force = self._force + force
end

function Steer:stop(threshold)
    local threshold = threshold or 10
    if self._force:len() < threshold then
        self._force = Vector.zero
    end
end

function Steer:seek(position, modifier)
    --dlog("agent position: ", self.agent:position())
    --dlog("seek to position ", position)
    local force = Vector(self.agent:position(), position)
    --dlog("force: ", force)
    self:force(force, modifier)
    --dlog("result force: ", self._force)
end

function Steer:flee(position, modifier)
    local force = Vector(position, self.agent:position())
    self:force(force, modifier)
end

function Steer:wander(min_dist, max_dist, modifier)
    local force = Vector.random_direction(min_dist, max_dist)
    self:force(force, modifier)
end

function Steer:arrival(position, opts)
    local opts = opts or {}
    local scale = opts.scale or 1
    local slowdown_distance = opts.slowdown_distance or 10
    local stop_distance = opts.stop_distance or 0
    local modifier = opts.modifier
    self:seek(position, function(force)
        local len = force:len()
        force:normalize_inplace()
        if len >= slowdown_distance then
            force = force * scale
        elseif len >= stop_distance then
            force = force * scale * (len / (slowdown_distance - stop_distance))
        else
            force = Vector.zero
        end
        if modifier then
            force = modifier(force)
        end
        return force
    end)
end

function Steer:separation(neighbors, opts)
    local opts = opts or {}
    local scale = opts.scale or 1
    local distance = opts.distance or 1
    local modifier = opts.modifier

    local position = self.agent:position()
    local flee_force = Vector.zero
    for _, neighbor in pairs(neighbors) do
        if neighbor ~= self.agent.entity then
            local force = Vector(neighbor.position, position)
            local len = force:len()
            if len >= distance then
                force = Vector.zero
            elseif len > 0 then
                -- 与距离的反比的平方成线性关系
                -- 参照万有引力
                force = force * scale / (len * len)
            else
                force = Vector(1, 0) * scale * 1000000
            end
            flee_force = flee_force + force
        end
    end
    --dlog("flee_force of separation: ", flee_force)
    self:force(flee_force, modifier)
end

function Steer:avoid_collision(opts)
    local opts = opts or {}
    local modifier = opts.modifier
    local force = CollisionAvoidance:new(self.agent, opts):get_avoidance_force()
    self._original_force = self._force
    self._avoid_force = force
    self:force(force, modifier)
end

function Steer:_render_force(force, opts)
    if force == nil then
        return
    end
    self._display:render(function()
        local entity = self.agent.entity
        local from = entity.position
        local to = force:end_point(from)
        local args = table.dictionary_merge(opts or {}, {
            color = ColorList.green,
            width = 2,
            from = from,
            to = to,
            surface = entity.surface
        })
        return rendering.draw_line(args)
    end)
end

function Steer:display()
    self._display:reset()
    self:_render_force(self._original_force, {
        color = ColorList.lightblue
    })
    self:_render_force(self._avoid_force, {
        color = ColorList.red
    })
    self:_render_force(self._force)
end


return Steer
