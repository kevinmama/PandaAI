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

Area.from_dimensions = function(...)
    return Area(FArea.from_dimensions(...))
end

Area.center_on = function(...)
    return Area(FArea.center_on(...))
end

Area.unit = Area.new({ left_top = { x = -0.5, y = -0.5 }, right_bottom = { 0.5, 0.5 } })

setmetatable(Area, {
    __call = function(_, area) return Area.new(area) end,
    __tostring = Area.to_string
})

return Area
