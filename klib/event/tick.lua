local Event = require('klib/event/proxy')
local Tick = {}

function Tick.every_second(handler)
    Event.on_nth_tick(60, handler)
end

function Tick.every_minute(handler)
    Event.on_nth_tick(3600, handler)
end

function Tick.every_hour(handler)
    Event.on_nth_tick(216000, handler)
end

return Tick

