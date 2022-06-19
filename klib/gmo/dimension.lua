local Dimension = {}
setmetatable(Dimension, Dimension)

local metatable
--- Constructor Methods
-- @section Constructors

local CHUNK_SIZE = 32

Dimension.__call = function(_, ...)
    local type = type((...))
    if type == 'table' then
        local t = (...)
        if t.width and t.height then
            return Dimension.load(...)
        else
            return Dimension.new(...)
        end
    elseif type == 'string' then
        return Dimension.from_string(...)
    else
        return Dimension.construct(...)
    end
end

local function new(width, height)
    return setmetatable({ width = width, height = height }, metatable)
end

function Dimension.new(pos)
    return new(pos.x or pos[1] or 0, pos.y or pos[2] or 0)
end

function Dimension.load(pos)
    return setmetatable(pos, metatable)
end

function Dimension.construct(...)
    -- was self was passed as first argument?
    local args = type((...)) == 'table' and {select(2, ...)} or {select(1, ...)}
    return new(args[1] or 0, args[2] or args[1] or 0)
end

function Dimension.from_string(pos_string)
    return Dimension(load('return ' .. pos_string)())
end

function Dimension.add(dim1, ...)
    dim1 = Dimension(dim1)
    local dim2 = Dimension(...)
    return new(dim1.width + dim2.width, dim1.height + dim2.height)
end

function Dimension.subtract(dim1, ...)
    dim1 = Dimension(dim1)
    local dim2 = Dimension(...)
    return new(dim1.width - dim2.width, dim1.height - dim2.height)
end

function Dimension.divide(dim1, ...)
    dim1 = Dimension(dim1)
    local dim2 = Dimension(...)
    return new(dim1.width / dim2.width, dim1.height / dim2.height)
end

function Dimension.expand(dim, value)
    return new(dim.width + value, dim.height + value)
end

metatable = {
    __call = Dimension.new, -- copy the position.
    __index = Dimension,
    __add = Dimension.add, -- Adds two dimensions together. Returns a new dimension.
    __sub = Dimension.subtract,
    __div = Dimension.divide,
}

Dimension.CHUNK_UNIT = new(CHUNK_SIZE, CHUNK_SIZE)

return Dimension