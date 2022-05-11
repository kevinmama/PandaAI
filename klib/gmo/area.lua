local StdArea = require 'stdlib/area/area'
local FArea = require 'flib/area'

local Area = {}

Area.new = StdArea.new
Area.load = StdArea.load
Area.iterate = StdArea.iterate
Area.expand = StdArea.expand

Area.from_dimensions = function(...)
    return Area(FArea.from_dimensions(...))
end

Area.center_on = function(...)
    return Area(FArea.center_on(...))
end

setmetatable(Area, {
    __call = function(_, area) return Area.new(area) end
})

return Area
