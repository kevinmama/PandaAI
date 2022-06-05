local Event = require 'klib/event/event'

-- Map loaders to logistics tech for unlocks.
local loaders_technology_map = {
    ['logistics'] = 'loader',
    ['logistics-2'] = 'fast-loader',
    ['logistics-3'] = 'express-loader'
}

local function enable_loaders(event)
    local research = event.research
    local recipe = loaders_technology_map[research.name]
    if recipe then research.force.recipes[recipe].enabled = true end
end

----------------------------------------
-- On Research Finished
-- This is where you can permanently remove researched techs
----------------------------------------
Event.register(defines.events.on_research_finished, function(event)
    enable_loaders(event)
end)