local log = (require '__stdlib__/stdlib/misc/logger')('pathfinder_tiles', DEBUG)
local Table = require '__stdlib__/stdlib/utils/table'
local Queue = require '__stdlib__/stdlib/misc/queue'
local Direction = require '__stdlib__/stdlib/area/direction'
local Tiles = {}

local TileMerger = {}

local function get_index(position)
    return position.x .. "_" .. position.y
end

function TileMerger.new(tiles)
    local indexes = {}
    for _, tile in pairs(tiles) do
        indexes[get_index(tile.position)] = {
            name= tile.name,
            position = tile.position
        }
    end

    return setmetatable({
        tiles = indexes,
        size = #tiles
    }, {__index = TileMerger})
end

function TileMerger:get_tile(pos)
    return self.tiles[get_index(pos)]
end

function TileMerger:remove_tile(pos)
    self.tiles[get_index(pos)] = nil
    self.size = self.size - 1
end

function TileMerger:merge()
    local result = {}
    -- index tiles
    -- greedy merge tile

    -- select a tile
    -- check each direction, extend if it can
    while self.size > 0 do
        local tile = self:pick()
        --log('  pick a tile: ' .. serpent.line(tile))
        self:hq_try_merge_neighbours(tile)
        self:correct_bounding(tile)
        --log('  hq expand to: ' .. serpent.line(tile))
        table.insert(result, tile)
    end
    return result
    end

function TileMerger:pick()
    for _, tile in pairs(self.tiles) do
        local pos = tile.position
        tile.left_top = {
            x = pos.x,
            y = pos.y
        }
        tile.right_bottom = {
            x = pos.x,
            y = pos.y
        }
        tile.high_priority = true
        tile.next_direction_index = 1
        tile.available_directions = {
            defines.direction.east,
            defines.direction.south,
            defines.direction.west,
            defines.direction.north
        }
        self:remove_tile(pos)
        return tile
    end
end

function TileMerger:correct_bounding(tile)
    tile.left_top.x = tile.left_top.x - 0.5
    tile.left_top.y = tile.left_top.y - 0.5
    tile.right_bottom.x = tile.right_bottom.x + 0.5
    tile.right_bottom.y = tile.right_bottom.y + 0.5
end


function TileMerger:hq_try_merge_neighbours(tile)
    while tile.high_priority == true do
        self:try_merge_neighbour(tile)
    end
end

function TileMerger:lq_try_merge_neighbours(tile)
    while #tile.available_directions > 0 do
        self:try_merge_neighbour((tile))
    end
end

function TileMerger:try_merge_neighbour(tile)
    local direction = tile.available_directions[tile.next_direction_index]
    if direction == defines.direction.east then
        local x = tile.right_bottom.x + 1
        self:merge_direction(tile, tile.left_top.y, tile.right_bottom.y, function(y)
            return {x = x, y = y}
        end, function()
            tile.right_bottom.x = x
        end)
    elseif direction == defines.direction.west then
        local x = tile.left_top.x - 1
        self:merge_direction(tile, tile.left_top.y, tile.right_bottom.y, function (y)
            return {x = x, y = y}
        end, function()
            tile.left_top.x = x
        end)
    elseif direction == defines.direction.south then
        local y = tile.right_bottom.y + 1
        self:merge_direction(tile, tile.left_top.x, tile.right_bottom.x, function (x)
            return {x = x, y = y}
        end, function()
            tile.right_bottom.y = y
        end)
    else
        local y = tile.left_top.y - 1
        self:merge_direction(tile, tile.left_top.x, tile.right_bottom.x, function (x)
            return {x = x, y = y}
        end, function()
            tile.left_top.y = y
        end)
    end
end

local function checker_loop(lower, upper, assert)
    for i = lower, upper do
        if not assert(i) then
            return false
        end
    end
    return true
end

local function update_priority(tile)
    if #tile.available_directions == 1 then
        tile.high_priority = false
    elseif #tile.available_directions == 2 then
        if tile.available_directions[1] == Direction.opposite_direction(tile.available_directions[2]) then
            tile.high_priority = false
        end
    end
end

function TileMerger:merge_direction(tile, lower, upper, get_pos, on_merge)
    local positions = {}
    local can_merge = checker_loop(lower, upper, function(cur)
        local pos = get_pos(cur)
        local neighbor = self:get_tile(pos)
        if neighbor then
            table.insert(positions, pos)
            return true
        else
            return false
        end
    end)
    if can_merge then
        on_merge(tile)
        for _, pos in pairs(positions) do
            self:remove_tile(pos)
        end
        tile.next_direction_index = tile.next_direction_index == #tile.available_directions and 1 or tile.next_direction_index + 1
    else
        table.remove(tile.available_directions, tile.next_direction_index)
        if tile.next_direction_index > #tile.available_directions then
            tile.next_direction_index = 1
        end
        update_priority(tile)
    end
end

function Tiles.merge_tiles(tiles)
    return TileMerger.new(tiles):merge()
end

return Tiles
