-- 加强 bump，且使它在读档后可用
local KC = require 'klib/container/container'
local Bump = require '__stdlib__/stdlib/vendor/bump'
local LazyFunction = require 'klib/utils/lazy_function'
local Is = require '__stdlib__/stdlib/utils/is'

local SMALL = 10e-8

local KBump = KC.class('klib.classes.Bump', function(self, cellSize)
    self.world = Bump.newWorld(cellSize)
end)

function KBump:on_load()
    local world = Bump.newWorld(self.world.cellSize)
    world.rects = self.world.rects
    world.rows = self.world.rows
    world.nonEmptyCells = self.world.nonEmptyCells
    self.world = world
end

local function area_to_unpack_rect(area)
    local x, y = area.left_top.x, area.left_top.y
    local w, h = area.right_bottom.x - area.left_top.x, area.right_bottom.y - area.left_top.y
    return x, y, w, h
end

function KBump:addArea(item, area)
    local x, y, w, h = area_to_unpack_rect(area)
    self.world:add(item, x, y, w, h)
end
KBump.add_area = KBump.addArea

function KBump:addRect(item, rect)
    self.world:add(item, rect.x, rect.y, rect.w, rect.h)
end
KBump.add_rect = KBump.addRect

function KBump:updateArea(item, area)
    local x, y, w, h = area_to_unpack_rect(area)
    self.world:update(item, x, y, w, h)
end
KBump.update_area = KBump.updateArea

function KBump:updateRect(item, rect)
    self.world:update(item, rect.x, rect.y, rect.w, rect.h)
end
KBump.update_rect = KBump.updateRect

function KBump:queryRect(x, y, w, h, filter)
    if Is.table(x) then
        local rect = x
        x, y, w, h = rect.x, rect.y, rect.w, rect.h
    end
    return self.world:queryRect(x + SMALL, y + SMALL, w - 2 * SMALL, h - 2 * SMALL, filter)
end
KBump.query_rect = KBump.queryRect

function KBump:queryArea(area, filter)
    return self.world:queryRect(
            area.left_top.x + SMALL,
            area.left_top.y + SMALL,
            area.right_bottom.x - area.left_top.x - 2 * SMALL,
            area.right_bottom.y - area.left_top.y - 2 * SMALL,
            filter
    )
end
KBump.query_area = KBump.queryArea

LazyFunction.delegate_instance_methods(KBump, "world", {
    "add", "remove", "update", "move",
    "getRect", "getItems",
    "queryPoint", "querySegment", "querySegmentWithCoords"
})
KBump.get_rect = KBump.getRect
KBump.get_items = KBump.getItems
KBump.query_point = KBump.queryPoint
KBump.query_segment = KBump.querySegment
KBump.query_segment_with_coords = KBump.querySegmentWithCoords

return KBump
