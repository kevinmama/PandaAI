local Table = require '__stdlib__/stdlib/utils/table'
local Region = {}

function Region.new(seed)
    return setmetatable({
        x = seed.x,
        y = seed.y,
        w = seed.w,
        h = seed.h,

        next_grow_direction_index = 1,
        grow_directions = {
            defines.direction.east,
            defines.direction.south,
            defines.direction.west,
            defines.direction.north,
        }
    }, {__index = Region})
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
    for i = 1, #self.grow_directions do
        if self.grow_directions[i] == direction then
            table.remove(self.grow_directions, i)
            if self.next_grow_direction_index >= i then
                self.next_grow_direction_index = self.next_grow_direction_index - 1
            end
        end
    end
end

function Region:generate_region_to_claim(direction, step, bounding)
    local claimRegion, stop
    if direction == defines.direction.east then
        if self.x + self.w + step > bounding.right_bottom.x then
            step = bounding.right_bottom.x - self.x - self.w
            stop = true
        end
        claimRegion = { x = self.x + self.w, y = self.y, w = step, h = self.h }
    elseif direction == defines.direction.west then
        if self.x - step < bounding.left_top.x then
            step = self.x - bounding.left_top.x
            stop = true
        end
        claimRegion = { x = self.x - step, y = self.y, w = step, h = self.h }
    elseif direction == defines.direction.south then
        if self.y + self.h + step > bounding.right_bottom.y then
            step = bounding.right_bottom.y - self.y - self.h
            stop = true
        end
        claimRegion = { x = self.x, y = self.y + self.h, w = self.w, h = step}
    else -- north
        if self.y - step < bounding.left_top.y then
            step = self.y - bounding.left_top.y
            stop = true
        end
        claimRegion = { x = self.x, y = self.y - step, w = self.w , h = step }
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
    else -- north
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
    else -- north
        self.h = self.h + (self.y - to)
        self.y = to
    end
end

return Region
