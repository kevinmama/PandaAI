-- 通行区域

local KC = require 'klib/container/container'
local Direction = require 'stdlib/area/direction'
local Edge = require 'pda/pathfinder/edge'
local C = require 'pda/pathfinder/config'

local Region = KC.class('pda.pathfinder.Region', function(self, seed)
    self.x = seed.x
    self.y = seed.y
    self.w = seed.w
    self.h = seed.h

    self.type = C.OBJECT_TYPES.REGION
    self.high_priority = true
    self.next_grow_direction_index = 1
    self.grow_directions = {
        defines.direction.east,
        defines.direction.south,
        defines.direction.west,
        defines.direction.north,
    }
    self.neighbours = {}
end)

function Region:east_axis()
    return self.x + self.w
end

function Region:west_axis()
    return self.x
end

function Region:north_axis()
    return self.y
end

function Region:south_axis()
    return self.y + self.h
end

function Region:axis_by_direction(direction)
    if direction == defines.direction.east then
        return self:east_axis()
    elseif direction == defines.direction.west then
        return self:west_axis()
    elseif direction == defines.direction.north then
        return self:north_axis()
    elseif direction == defines.direction.south then
        return self:south_axis()
    else
        return nil
    end
end

function Region:next_grow_direction()
    local l = #self.grow_directions
    if l == 0 then
        return nil
    end

    local direction = self.grow_directions[self.next_grow_direction_index]
    self.next_grow_direction_index = self.next_grow_direction_index + 1
    if self.next_grow_direction_index > l then
        self.next_grow_direction_index = 1
    end
    return direction
end

function Region:stop_grow(direction)
    local length = #self.grow_directions
    for i = 1, length do
        if self.grow_directions[i] == direction then
            table.remove(self.grow_directions, i)
            if self.next_grow_direction_index >= i then
                self.next_grow_direction_index = self.next_grow_direction_index - 1
            end
            -- 如果被分割成两个不连续的方向，则设置为低优先级
            length = length - 1
            if length == 1 then
                self.high_priority = false
            elseif length == 2 then
                if Direction.opposite_direction(self.grow_directions[1]) == self.grow_directions[2] then
                    self.high_priority = false
                end
            end
            return
        end
    end
end

function Region:generate_region_to_claim(direction, step)
    local claim_region
    if direction == defines.direction.east then
        claim_region = { x = self.x + self.w, y = self.y, w = step, h = self.h }
    elseif direction == defines.direction.west then
        claim_region = { x = self.x - step, y = self.y, w = step, h = self.h }
    elseif direction == defines.direction.south then
        claim_region = { x = self.x, y = self.y + self.h, w = self.w, h = step }
    else
        claim_region = { x = self.x, y = self.y - step, w = self.w, h = step }
    end
    claim_region.step = step
    return claim_region
end

function Region:expand(direction, step)
    if direction == defines.direction.east then
        self.w = self.w + step
    elseif direction == defines.direction.west then
        self.x = self.x - step
        self.w = self.w + step
    elseif direction == defines.direction.south then
        self.h = self.h + step
    else
        -- north
        self.y = self.y - step
        self.h = self.h + step
    end
end

function Region:expand_to(direction, to)
    if direction == defines.direction.east then
        self.w = to - self.x
    elseif direction == defines.direction.west then
        self.w = self.w + (self.x - to)
        self.x = to
    elseif direction == defines.direction.south then
        self.h = to - self.y
    else
        -- north
        self.h = self.h + (self.y - to)
        self.y = to
    end
end

function Region:add_neighbour(region, direction)
    -- 不知道会不会有重复，是否需要遍历检查？
    table.insert(self.neighbours, {
        region = region,
        direction = direction
    })
    table.insert(region.neighbours, {
        region = self,
        direction = Direction.opposite_direction(direction)
    })
end

function Region:get_edge(neighbour)
    local edge
    local region, direction = neighbour.region, neighbour.direction
    if direction == defines.direction.east then
        local x = self.x + self.w
        edge = {
            { x = x, y = math.max(self.y, region.y) },
            { x = x, y = math.min(self.y + self.h, region.y + region.h) }
        }
    elseif direction == defines.direction.west then
        edge = {
            { x = self.x, y = math.max(self.y, region.y) },
            { x = self.x, y = math.min(self.y + self.h, region.y + region.h) }
        }
    elseif direction == defines.direction.south then
        local y = self.y + self.h
        edge = {
            { x = math.max(self.x, region.x), y = y },
            { x = math.min(self.x + self.w, region.x + region.w), y = y }
        }
    else
        edge = {
            { x = math.max(self.x, region.x), y = self.y },
            { x = math.min(self.x + self.w, region.x + region.w), y = self.y }
        }
    end
    return edge
end

function Region:get_edge_midpoint(neighbour)
    local edge = self:get_edge(neighbour)
    return Edge.midpoint(edge)
end

function Region:center()
    return {
        x = self.x + self.w / 2,
        y = self.y + self.h / 2
    }
end

function Region:get_corners()
    local x1, x2, y1, y2 = self.x, self.x + self.w, self.y, self.y + self.h
    return {
        {x = x1, y = y1},
        {x = x2, y = y1},
        {x = x2, y = y2},
        {x = x1, y = y2}
    }
end

function Region:debug_info()
    return { self.x, self.y, self.w, self.h }
end

function Region:see_node(path_id, node)
    self.seen = path_id
    self.seen_node = node
end

return Region
