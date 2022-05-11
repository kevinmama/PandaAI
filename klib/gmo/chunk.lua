local Position = require 'klib/gmo/position'
local Chunk = {}

local CHUNK_SIZE = 32

--- find chunk that func(c_pos, ...) is not nil
function Chunk.find_from_dimensions(dimensions, center, func, ...)
    for offset_x = -dimensions.width/2, dimensions.width/2, CHUNK_SIZE do
        for offset_y = -dimensions.height/2, dimensions.height/2, CHUNK_SIZE do
            local c_pos = Position.to_chunk_position( {
                x = center.x + offset_x,
                y = center.y + offset_y
            })
            if func(c_pos, ...) then return true end
        end
    end
    return false
end

function Chunk.each_from_dimensions(dimensions, center, func, ...)
    for offset_x = -dimensions.width/2, dimensions.width/2, CHUNK_SIZE do
        for offset_y = -dimensions.height/2, dimensions.height/2, CHUNK_SIZE do
            local c_pos = Position.to_chunk_position( {
                x = center.x + offset_x,
                y = center.y + offset_y
            })
            func(c_pos, ...)
        end
    end
end

return Chunk