local dlog = require 'klib/utils/dlog'
local KC = require 'klib/container/container'
local Vector = require 'klib/math/vector'
local CollisionAvoidance = require 'ai/agent/collision_avoidance'
local Table = require 'stdlib/utils/table'
local ColorList = require 'stdlib/utils/defines/color_list'
local Rendering = require 'klib/gmo/rendering'

local Steer = KC.class('kai.agent.Steer', function(self, agent)
    self:set_agent(agent)
    self._force = Vector.zero
end)

Steer:reference_objects("agent")

function Steer:on_load()
    Vector.load(self._force)
    if self._original_force then
        Vector.load(self._original_force)
    end
    if self._avoid_force then
        Vector.load(self._avoid_force)
    end
end

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
    --dlog("agent position: ", self.agent:get_position())
    --dlog("seek to position ", position)
    local force = Vector(self:get_agent():get_position(), position)
    --dlog("force: ", force)
    self:force(force, modifier)
    --dlog("result force: ", self._force)
end

function Steer:flee(position, modifier)
    local force = Vector(position, self.get_agent():get_position())
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

    local agent = self:get_agent()
    local position = agent:get_position()
    local flee_force = Vector.zero
    for _, neighbor in pairs(neighbors) do
        if neighbor ~= agent.entity then
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

--- 防止碰撞
function Steer:avoid_collision(opts)
    local opts = opts or {}
    local modifier = opts.modifier
    local force = CollisionAvoidance.get_avoidance_force(self:get_agent(), opts)
    self._original_force = self._force
    self._avoid_force = force
    self:force(force, modifier)
end

--- 防止伤害，也可以用防止碰撞的方法实现
function Steer:avoid_damage(opts)

end

function Steer:_render_force(force, opts)
    if force == nil then
        return
    end

    local entity = self:get_agent().entity
    local from = entity.position
    local to = force:end_point(from)
    local args = Table.dictionary_merge(opts or {}, {
        color = ColorList.green,
        width = 2,
        from = from,
        to = to,
        surface = entity.surface
    })
    return rendering.draw_line(args)
end

function Steer:display()
    Rendering.destroy_all(self._render_ids)
    self._render_ids = {}
    Table.insert(self._render_ids, self:_render_force(self._original_force, {
        color = ColorList.lightblue
    }))
    Table.insert(self._render_ids, self:_render_force(self._avoid_force, {
        color = ColorList.red
    }))
    Table.insert(self._render_ids, self:_render_force(self._force))
end

function Steer:on_destroy()
    Rendering.destroy_all(self._render_ids)
end

return Steer