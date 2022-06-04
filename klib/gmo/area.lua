local StdArea = require 'stdlib/area/area'
local FArea = require 'flib/area'

local Area = {}

Area.new = StdArea.new
Area.load = StdArea.load
Area.iterate = StdArea.iterate
Area.expand = StdArea.expand
Area.width = StdArea.width
Area.height = StdArea.height
Area.to_string = StdArea.to_string
Area.to_string_xy = StdArea.to_string_xy
Area.offset = StdArea.offset
Area.size = StdArea.size
Area.is_area = StdArea.is_area
Area.is_simple_area = StdArea.is_simple_area
Area.is_complex_area = StdArea.is_complex_area
Area.contains_positions = StdArea.contains_positions
Area.contains_areas = StdArea.contains_areas
Area.corners = StdArea.corners


function Area.from_dimensions(dimensions, center, inside)
    center = center or { x = 0, y = 0 }
    local epsilon = inside and 0.001 or 0
    local area = {
        left_top = {
            x = center.x - (dimensions.width / 2),
            y = center.y - (dimensions.height / 2),
        },
        right_bottom = {
            x = center.x + (dimensions.width / 2) - epsilon,
            y = center.y + (dimensions.height / 2) - epsilon,
        },
    }
    return Area(area)
end

Area.center_on = function(...)
    return Area(FArea.center_on(...))
end

function Area.collides(area1, area2)
    local ltx1, lty1 = area1.left_top.x, area1.left_top.y
    local ltx2, lty2 = area2.left_top.x, area2.left_top.y
    local rbx1, rby1 = area1.right_bottom.x, area1.right_bottom.y
    local rbx2, rby2 = area2.right_bottom.x, area2.right_bottom.y
    return not (ltx1 > rbx2 or ltx2 > rbx1 or lty1 > rby2 or lty2 > rby1)
end

function Area.collides_areas(area, areas)
    for _, inner in pairs(areas) do if not Area.collides(area, inner) then return false end end
    return true
end

function Area.intersect(area1, area2)
    local ltx1, lty1 = area1.left_top.x, area1.left_top.y
    local ltx2, lty2 = area2.left_top.x, area2.left_top.y
    local rbx1, rby1 = area1.right_bottom.x, area1.right_bottom.y
    local rbx2, rby2 = area2.right_bottom.x, area2.right_bottom.y
    if not (ltx1 > rbx2 or ltx2 > rbx1 or lty1 > rby2 or lty2 > rby1) then
        local ltx, lty = math.max(ltx1, ltx2), math.max(lty1, lty2)
        local rbx, rby = math.min(rbx1, rbx2), math.min(rby1, rby2)
        return Area({left_top = {ltx, lty}, right_bottom = {rbx, rby}})
    else
        return nil
    end
end

Area.unit = Area.new({ left_top = { x = -0.5, y = -0.5 }, right_bottom = { 0.5, 0.5 } })

setmetatable(Area, {
    __call = function(_, area) return Area.new(area) end,
    __tostring = Area.to_string
})

return Area
