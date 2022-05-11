local StdPosition = require 'stdlib/area/position'

local Position = {}

Position.new = StdPosition.new
Position.add = StdPosition.add
Position.to_chunk_position = StdPosition.to_chunk_position
Position.from_chunk_position = StdPosition.from_chunk_position

setmetatable(Position, {
    __call = function(_, area) return Position.new(area) end
})
return Position