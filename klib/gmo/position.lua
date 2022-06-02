local StdPosition = require 'stdlib/area/position'
local math = require 'stdlib/utils/math'
local Table = require 'klib/utils/table'

local Position = {}

Position.new = StdPosition.new
Position.add = StdPosition.add
Position.to_chunk_position = StdPosition.to_chunk_position
Position.from_chunk_position = StdPosition.from_chunk_position
Position.expand_to_area = StdPosition.expand_to_area
Position.equals = StdPosition.equals
Position.distance_squared = StdPosition.distance_squared
Position.distance = StdPosition.distance
Position.manhattan_distance = StdPosition.manhattan_distance
Position.normalize = StdPosition.normalize
Position.normalized = StdPosition.normalized
Position.to_area = StdPosition.to_area
Position.to_chunk_area = StdPosition.to_chunk_area
Position.to_tile_area = StdPosition.to_tile_area
Position.chunk_position_to_chunk_area = StdPosition.chunk_position_to_chunk_area
Position.is_position = StdPosition.is_position
Position.is_simple_position = StdPosition.is_simple_position
Position.is_complex_position = StdPosition.is_complex_position

local function get_array(...)
    local array = select(2, ...)
    if array then
        table.insert(array, (...))
    else
        array = (...)
    end
    return array
end

function Position.average(...)
    local positions = get_array(...)
    local x,y = 0,0
    for _, pos in ipairs(positions) do
        x = x + pos.x or pos[1]
        y = y + pos.y or pos[2]
    end
    local count = #positions
    if count > 0 then
        return Position.new({x=x/count, y=y/count})
    else
        return Position.new({x=x,y=y})
    end
end

--- 在第一象限，x=y 时, f(x,y) = 4x^2 - 2x
--- -x+1 <= y <= x , f(x,y) = f(x,x) - x + y
--- y >= |x| , f(x,y) = f(y,y) - x + y
--- x <= y <= -x , f(x,y) = f(-x,-x) - 3x - y
--- y <= x && y <= -x+1 , f(x,y) = f(-y+1,-y+1) + x + 3y - 2
function Position.to_spiral_index(position)
    local x,y = math.round(position.x), math.round(position.y)
    if -x+1 <= y and y <= x then
        return 4*x*x - 3*x + y
    elseif y >= math.abs(x) then
        return 4*y*y - x - y
    elseif x <= y and y <= -x then
        return 4*x*x - x - y
    else
        return 4*y*y - 3*y + x
    end
end

--- 找到最大的 x 使 4x^2 - 2x <= n，令此时 x = x0, y0 = n - x0
--- x0 = math.floor( (1+(1+4n)^0.5)/4 )
--- y0 <= 2x0 , x = x0 - y0, y = x0
--- 2x0 <= y0 <= 4x0 , x = -x0, y = x0 - ( y0 - 2x0 )
--- 4x0 <= y0 <= 6x0 + 1 , x = -x0 + y0 - 4x0, y = -x0
--- 6x0+1 <= y0 <= 8x0 + 2 , x = x0 + 1, y = -(x0+1 - 1) + y0 - (6x0+1)
function Position._from_spiral_index(index)
    local x0 = math.floor((1+(1+4*index)^0.5)/4)
    local y0 = index - (4*x0*x0 - 2*x0)
    if y0 <= 2*x0 then
        return {x=x0-y0, y=x0}
    elseif y0 <= 4*x0 then
        return {x=-x0, y=3*x0-y0}
    elseif y0 <= 6*x0 + 1 then
        return {x=-5*x0 + y0, y= -x0}
    else
        return {x=x0+1, y= -7*x0 + y0 -1}
    end
end

local FROM_SPIRAL_MAP = {}
FROM_SPIRAL_MAP[0] = {x=0,y=0}
for i = 1, 256 do
    FROM_SPIRAL_MAP[i] = Position._from_spiral_index(i)
end

function Position.from_spiral_index(index)
    if index <= 256 then
        return FROM_SPIRAL_MAP[index]
    else
        return Position._from_spiral_index(index)
    end
end

setmetatable(Position, {
    __call = function(_, area) return Position.new(area) end
})
return Position