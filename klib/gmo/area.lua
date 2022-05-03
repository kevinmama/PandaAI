local Area = require 'flib/area'

--- Create an area from dimensions and a centerpoint.
--- @param dimensions DisplayResolution
--- @param center? MapPosition
--- @return BoundingBox
function Area.from_dimensions(dimensions, center)
    center = center or { x = 0, y = 0 }
    local self = {
        left_top = {
            x = center.x - (dimensions.width / 2),
            y = center.y - (dimensions.height / 2),
        },
        right_bottom = {
            x = center.x + (dimensions.width / 2),
            y = center.y + (dimensions.height / 2),
        },
    }
    Area.load(self)
    return self
end

return Area
