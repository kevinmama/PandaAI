local StdPosition = require 'stdlib/area/position'

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

setmetatable(Position, {
    __call = function(_, area) return Position.new(area) end
})
return Position