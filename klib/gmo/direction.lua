local FDirection = require 'flib/direction'
local StdDirection = require 'stdlib/area/direction'
local Table = require 'klib/utils/table'
local math = require 'stdlib/utils/math'

local Direction = {}

--- defines.direction.north
Direction.north = defines.direction.north
--- defines.direction.east
Direction.east = defines.direction.east
--- defines.direction.west
Direction.west = defines.direction.west
--- defines.direction.south
Direction.south = defines.direction.south
--- defines.direction.northeast
Direction.northeast = defines.direction.northeast
--- defines.direction.northwest
Direction.northwest = defines.direction.northwest
--- defines.direction.southeast
Direction.southeast = defines.direction.southeast
--- defines.direction.southwest
Direction.southwest = defines.direction.southwest

local DIRECTION_NAMES = Table.invert(defines.direction)

function Direction.get_name(direction)
    return DIRECTION_NAMES[direction]
end

Direction.from_positions = FDirection.from_positions
Direction.next = StdDirection.next

local SQRT_2 = 2^0.5/2

--- Returns a vector from a direction.
-- @tparam defines.direction direction
-- @tparam[opt = 1] number distance
-- @treturn Position
function Direction.to_vector(direction, distance)
    distance = distance or 1
    local x, y = 0, 0
    if direction == Direction.north then
        y = y - distance
    elseif direction == Direction.northeast then
        x, y = x + SQRT_2 * distance, y - SQRT_2 * distance
    elseif direction == Direction.east then
        x = x + distance
    elseif direction == Direction.southeast then
        x, y = x + SQRT_2 * distance, y + SQRT_2 * distance
    elseif direction == Direction.south then
        y = y + distance
    elseif direction == Direction.southwest then
        x, y = x - SQRT_2 * distance, y + SQRT_2 * distance
    elseif direction == Direction.west then
        x = x - distance
    elseif direction == Direction.northwest then
        x, y = x - SQRT_2 * distance, y - SQRT_2 * distance
    end
    return {x = x, y = y}
end

--- Calculate the direction of travel from the source to the target.
--- @param source MapPosition
--- @param target MapPosition
--- @param round? boolean If true, round to the nearest `defines.direction`.
--- @return defines.direction
function Direction.from_positions(source, target, round)
    local deg = math.deg(math.atan2(target.y - source.y, target.x - source.x))
    local direction = (deg + 90) / 45
    if round then
        direction = math.round(direction)
    end
    if direction < 0 then
        direction = direction + 8
    end
    return direction
end

return Direction