local Position = require 'klib/gmo/position'

local RichText = {}

function RichText.gps(position)
    return '[gps=' .. position.x .. ',' .. position.y .. ']'
end

return RichText