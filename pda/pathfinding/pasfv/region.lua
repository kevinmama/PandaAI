local Direction = require '__stdlib__/stdlib/area/direction'
local Is = require '__stdlib__/stdlib/utils/is'
local C = require 'pda/pathfinding/pasfv/config'
local Region = {}

function Region.new(seed)
    return setmetatable({
        x = seed.x,
        y = seed.y,
        w = seed.w,
        h = seed.h,

        type = C.OBJECT_TYPES.REGION,
        highPriority = true,
        next_grow_direction_index = 1,
        grow_directions = {
            defines.direction.east,
            defines.direction.south,
            defines.direction.west,
            defines.direction.north,
        },
        neighbours = {}
    }, { __index = Region })
end

function Region:next_grow_direction()
    local l = #self.grow_directions
    if l == 0 then
        return nil
    else
        local direction = self.grow_directions[self.next_grow_direction_index]
        self.next_grow_direction_index = self.next_grow_direction_index + 1
        if self.next_grow_direction_index > l then
            self.next_grow_direction_index = 1
        end
        return direction
    end
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
            if length <= 3 then
                if length <= 2 then
                    self.highPriority = false
                else
                    if (self.grow_directions[1] == defines.direction.east
                            and self.grow_directions[2] == defines.direction.west)
                            or (self.grow_directions[1] == defines.direction.south
                            and self.grow_directions[2] == defines.direction.north) then
                        self.highPriority = false
                    end
                end
            end
            return
        end
    end
end

function Region:generate_region_to_claim(direction, step, bounding)
    local claimRegion, stop
    if direction == defines.direction.east then
        if self.x + self.w + step > bounding.right_bottom.x + C.EPS then
            step = bounding.right_bottom.x - self.x - self.w
            stop = true
        end
        claimRegion = { x = self.x + self.w, y = self.y, w = step, h = self.h }
    elseif direction == defines.direction.west then
        if self.x - step < bounding.left_top.x - C.EPS then
            step = self.x - bounding.left_top.x
            stop = true
        end
        claimRegion = { x = self.x - step, y = self.y, w = step, h = self.h }
    elseif direction == defines.direction.south then
        if self.y + self.h + step > bounding.right_bottom.y + C.EPS then
            step = bounding.right_bottom.y - self.y - self.h
            stop = true
        end
        claimRegion = { x = self.x, y = self.y + self.h, w = self.w, h = step }
    else
        -- north
        if self.y - step < bounding.left_top.y - C.EPS then
            step = self.y - bounding.left_top.y
            stop = true
        end
        claimRegion = { x = self.x, y = self.y - step, w = self.w, h = step }
    end
    claimRegion.stop = stop
    claimRegion.step = step
    return claimRegion
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
    -- 不知道会不会有重复，是否需要遍历检查？jk
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
            { x = math.max(self.x, region.x) , y = y},
            { x = math.min(self.x + self.w, region.x + region.w) , y = y}
        }
    else
        edge = {
            { x = math.max(self.x, region.x) , y = self.y},
            { x = math.min(self.x + self.w, region.x + region.w) , y = self.y}
        }
    end
    return edge
end

function Region:get_edge_midpoint(neighbour)
    local edge = self:get_edge(neighbour)
    return self:edge_midpoint(edge)
end

function Region:center()
    return {
        x = self.x + self.w / 2,
        y = self.y + self.h / 2
    }
end

function Region:edge_midpoint(edge)
    return {
        x = (edge[1].x + edge[2].x)/2,
        y = (edge[1].y + edge[2].y)/2
    }
end

function Region:debug_info()
    return {self.x, self.y, self.w, self.h}
end

function Region:see_node(path_id, node)
    self.seen = path_id
    self.seen_node = node
end

return Region
