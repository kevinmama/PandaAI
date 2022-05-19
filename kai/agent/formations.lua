local Position = require 'klib/gmo/position'
local Formations = {}

Formations.Spiral = {
    id = "Spiral",
    get_offset = function(index)
        local pos = Position.from_spiral_index(index)
        return {x=pos.x*2, y=pos.y*2}
    end
}

return Formations