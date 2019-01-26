local KAgent = require('klib/agent/agent')
local Vector = require('klib/math/kvector')

function KAgent:force(vector, opts)
    if type(opts) == 'table' then
        local normalize = opts.normalize
        local multiplier = opts.multiplier
        if opts.weight then
            normalize = true
            multiplier = weight
        end
        if normalize then
            vector = vector:normalize()
        end
        if multiplier then
            vector = vector * multiplier
        end
    elseif type(opts) == 'function' then
        vector = opts(vector)
    end
    self.vector = self.vector + vector
end

function KAgent:stop(opts)
    opts = opts or {}
    local weight = opts.weight or 10
    if self.vector:len() < weight then
        self.vector = Vector.zero
    end
end

function KAgent:seek(position, opts)
    local v = Vector(self:position(), position)
    self:force(v, opts)
end

function KAgent:flee(position, opts)
    local v = Vector(position, self:position())
    self:force(v, opts)
end

function KAgent:wander(min, max, opts)
    local v = Vector.random_direction(min, max)
    self:force(v, opts)
end

function KAgent:arrival(position, opts)
    opts = opts or {}
    local max_weight = opts.max_weight or 100
    local slowdown_distance = opts.slowdown_distance or 10
    local stop_distance = opts.stop_distance or 0
    self:seek(position, function(vector)
        local len = vector:len()
        vector:normalize_inplace()
        if len >= slowdown_distance then
            vector = vector * max_weight
        elseif len >= stop_distance then
            vector = vector * max_weight * (len / (slowdown_distance - stop_distance))
        else
            vector = Vector.zero
        end
        return vector
    end)
end

function KAgent:avoid_close_neighbors(neighbors, opts)
    opts = opts or {}
    local weight = opts.weight or 25
    local distance = opts.distance or 1

    local position = self:position()
    local flee_vector = Vector.zero
    for _, neighbor in pairs(neighbors) do
        if neighbor ~= self.control then
            local v = Vector(neighbor.position, position)
            local len = v:len()
            if len >= distance then
                v = Vector.zero
            elseif len > 0 then
                -- 与距离的反比成线性关系
                v = v * weight / (len * len)
            else
                v = Vector(1, 0) * weight * 1000000
            end
            flee_vector = flee_vector + v
        end
    end
    self:force(flee_vector)
end