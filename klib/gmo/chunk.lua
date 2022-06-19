local Position = require 'klib/gmo/position'
local Chunk = {}

local CHUNK_SIZE = 32
local EPS = 0.001

local function get_epsilon_from_dimensions(dimensions, center, inside)
    if inside then
        return (((center.x + dimensions.width / 2) % CHUNK_SIZE) == 0 and EPS or 0),
        (((center.y + dimensions.height / 2) % CHUNK_SIZE) == 0 and EPS or 0)
    else
        return 0, 0
    end
end

local function get_epsilon_from_area(area, inside)
    if inside then
        return (area.right_bottom.x % CHUNK_SIZE == 0 and EPS or 0),
        (area.right_bottom.y % CHUNK_SIZE == 0 and EPS or 0)
    else
        return 0, 0
    end
end

--- find chunk that func(c_pos, ...) is not nil
function Chunk.find_from_dimensions(dimensions, center, inside, func)
    if func == nil then inside, func = nil, inside end
    local ex, ey = get_epsilon_from_dimensions(dimensions, center, inside)
    for offset_x = -dimensions.width/2, dimensions.width/2 - ex, CHUNK_SIZE do
        for offset_y = -dimensions.height/2, dimensions.height/2 - ey, CHUNK_SIZE do
            local c_pos = Position.to_chunk_position( {
                x = center.x + offset_x,
                y = center.y + offset_y
            })
            if func(c_pos) then return true end
        end
    end
    return false
end

function Chunk.each_from_dimensions(dimensions, center, inside, func)
    if func == nil then inside, func = nil, inside end
    local ex, ey = get_epsilon_from_dimensions(dimensions, center, inside)
    for offset_x = -dimensions.width/2, dimensions.width/2 - ex, CHUNK_SIZE do
        for offset_y = -dimensions.height/2, dimensions.height/2 - ey, CHUNK_SIZE do
            local c_pos = Position.to_chunk_position( {
                x = center.x + offset_x,
                y = center.y + offset_y
            })
            func(c_pos)
        end
    end
end

function Chunk.each_from_area(area, inside, func)
    if func == nil then inside, func = nil, inside end
    local ex, ey = get_epsilon_from_area(area, inside)
    for x = area.left_top.x, area.right_bottom.x - ex, CHUNK_SIZE do
        for y = area.left_top.y, area.right_bottom.y - ey, CHUNK_SIZE do
            local c_pos = Position.to_chunk_position({x=x,y=y})
            func(c_pos)
        end
    end
end

function Chunk.request_to_generate_chunks(surface, area)
    for x = area.left_top.x, area.right_bottom.x, CHUNK_SIZE do
        for y = area.left_top.y, area.right_bottom.y, CHUNK_SIZE do
            surface.request_to_generate_chunks({x=x,y=y},1)
        end
    end
end

function Chunk.get_chunk_area_at_position(position)
    local pos = Position.to_chunk_position(position)
    return {
        left_top = {x=pos.x*32, y=pos.y*32},
        right_bottom = {x=pos.x*32+32, y=pos.y*32+32}
    }
end

return Chunk