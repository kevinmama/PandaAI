local Event = require('klib/event/proxy')
local Tick = {}

function Tick.every_n_tick(tick, handler)
    Event.register(defines.events.on_tick, function(e)
        if e.tick % tick == 0 then
            handler(e)
        end
    end)
end

function Tick.every_second(handler)
    Tick.every_n_tick(60, handler)
end

function Tick.every_minute(handler)
    Tick.every_n_tick(3600, handler)
end

function Tick.every_hour(handler)
    Tick.every_n_tick(216000, handler)
end

return Tick

