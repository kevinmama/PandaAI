local KC = require 'klib/container/container'

local WG = KC.singleton('scenario.invasion.WorldGenerator', function(self, surface)

end)

function WG:dispatch(self, event)
    
end

WG:on(defines.events.on_chunk_generated, function(self, event)
    local surface = event.surface
    local lt = event.area.left_top
    local ltx  = lt.x
    local lty = lt.y
    self.dispatch(event)
end)

return WG