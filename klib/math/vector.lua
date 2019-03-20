-------------------------------------------------------------------------------
--- enhance vector, based hump's vector
-------------------------------------------------------------------------------

local HVector = require('klib/vendor/hump/vector')

local Vector = HVector.Vector
Vector.normalize_inplace = Vector.normalizeInplace

local function _from_pos(position)
    if #position == 2 then
        return { x = position[1] or 0, y = position[2] or 0 }
    else
        return { x = position.x or 0, y = position.y or 0 }
    end
end

local function from_position(position)
    local vector = _from_pos(position)
    return setmetatable(vector, Vector)
end

local function from_position2(x, y)
    return setmetatable({ x = x, y = y }, Vector)
end

local function from_distance(from, to)
    local f = _from_pos(from)
    local t = _from_pos(to)
    local v = { x = t.x - f.x, y = t.y - f.y }
    return setmetatable(v, Vector)
end

local function new(...)
    local args = { ... }
    if #args == 1 then
        return from_position(args[1])
    elseif #args == 2 then
        if type(args[1]) == 'table' and type(args[2]) == 'table' then
            return from_distance(args[1], args[2])
        else
            return from_position2(args[1], args[2])
        end
    end
end

function Vector:direction()
    local x = self.x
    local y = self.y
    local absx = math.abs(x)
    local absy = math.abs(y)
    if x == 0 and y == 0 then
        return nil
    end
    if x > 0 then
        if absx >= 2 * absy then
            return defines.direction.east
        elseif absx >= absy / 2 then
            if y > 0 then
                return defines.direction.southeast
            else
                return defines.direction.northeast
            end
        else
            if y > 0 then
                return defines.direction.south
            else
                return defines.direction.north
            end
        end
    else
        if absx >= 2 * absy then
            return defines.direction.west
        elseif absx >= absy / 2 then
            if y > 0 then
                return defines.direction.southwest
            else
                return defines.direction.northwest
            end
        else
            if y > 0 then
                return defines.direction.south
            else
                return defines.direction.north
            end
        end
    end
end

function Vector:orthogonal()
    -- x1x2 + y1y2 = 0
    return new(-self.y, self.x)
end

return setmetatable({
    from_polar = HVector.fromPolar,
    from_position = from_position,
    from_position2 = from_position2,
    from_distance = from_distance,
    random_direction = HVector.randomDirection,
    isvector = HVector.isvector,
    zero = HVector.zero,
}, {
    __call = function(_, ...)
        return new(...)
    end
})

