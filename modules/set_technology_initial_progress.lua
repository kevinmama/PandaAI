local Event = require 'klib/event/event'

local initial_progress = 0.9

Event.on_force_created(function(event)
    for _, tech in pairs(event.force.technologies) do
        if not tech.researched then
            local progress = event.force.get_saved_technology_progress(tech)
            if not progress or progress < initial_progress then
                event.force.set_saved_technology_progress(tech, initial_progress)
            end
        end
    end
end)

return function(progress)
    initial_progress = progress
end