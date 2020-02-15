local C = require 'pda/pathfinding/pasfv/config'

local Seed = {}

function Seed.new(algorithm)
    return setmetatable({
        algorithm = algorithm,
        world = algorithm.world
    }, {__index = Seed})
end

function Seed:seed()
    local items, len = self.world:getItems()
    for i=1, len do
        local item = items[i]
        local x,y,w,h = self.world:getRect(item)
        -- 对每条边缘添加种子，如果边缘被隔开，每个分开的部分都添加一个种子

        -- 用 x,y,w,h 来表示矩形
        -- e-l: x-(w+u)/2, y, u, h
        -- e-r: x+(w+u)/2, y, u, h
        -- e-t: x, y-(h+u)/2, w, u
        -- e-b: x, y+(h+u)/2, w, u
        self:_seed_edge(x - C.UNIT_SIZE, y, C.UNIT_SIZE, h)
        self:_seed_edge(x + w, y, C.UNIT_SIZE, h)
        self:_seed_edge(x, y - C.UNIT_SIZE, w, C.UNIT_SIZE)
        self:_seed_edge(x, y + h, w, C.UNIT_SIZE)
    end
end

function Seed:_seed_edge(x, y, w, h)
    --self:_renderRect({x = x, y = y, w = w, h = h, color = ColorList.lightblue})
    local items, len = self.world:queryRect(x + C.EPS, y + C.EPS, w - 2*C.EPS, h - 2*C.EPS)
    if len == 0 then
        self:_new_seed(x, y)
    else
        -- 边上有障碍物，故需要添加多个
        if w > h then -- 横向的
            -- 以 x 排序，计算出每一段负向区域
            self:_x_add_region_if_gap_greater_than_unit(x, y, w, h, items, len)
        else    -- 竖向的
            self:_y_add_region_if_gap_greater_than_unit(x, y, w, h, items, len)
        end
    end
end

function Seed:_new_seed(x,y)
    local region = { type = C.OBJECT_TYPES.REGION }
    --self.world:add(region, x, y, C.UNIT_SIZE, C.UNIT_SIZE)
    self.algorithm.seed_queue({
        x = x,
        y = y,
        w = C.UNIT_SIZE,
        h = C.UNIT_SIZE
    })
end

function Seed:_x_add_region_if_gap_greater_than_unit(x, y, w, h, items, len)
    local segments = {}
    for i = 1, len do
        local x,y,w,h = self.world:getRect(items[i])
        table.insert(segments, {point=x, len=w})
    end
    self:_add_region_if_gap_greater_than_unit(x, x+w, segments, len, function(point)
        self:_new_seed(point, y)
    end)
end

function Seed:_y_add_region_if_gap_greater_than_unit(x,y,w,h,items, len)
    local segments = {}
    for i = 1, len do
        local x,y,w,h = self.world:getRect(items[i])
        table.insert(segments, {point=y, len=h})
    end
    self:_add_region_if_gap_greater_than_unit(y, y+h, segments, len, function(point)
        self:_new_seed(x, point)
    end)
end

function Seed:_add_region_if_gap_greater_than_unit(start_point, end_point, segments, len, callback)
    table.sort(segments, function(a,b)
        return a.point < b.point
    end)
    local cur = start_point
    for i = 1, len do
        local seg = segments[i]
        if seg.point - cur >= C.UNIT_SIZE then
            callback(cur)
        end
        cur = seg.point + seg.len
    end
    if end_point - cur >= C.UNIT_SIZE then
        callback(cur)
    end
end

return Seed

