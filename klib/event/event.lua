local Proxy = require('klib/event/proxy')
local Tick = require('klib/event/tick')

local Event = {
    register = Proxy.register,
    on_event = Proxy.on_event,
    remove = Proxy.remove,
    core_events = Proxy.core_events,
    on_init = Proxy.on_init,
    on_load = Proxy.on_load,
    on_configuration_changed = Proxy.on_configuration_changed,
    generate_event_name = Proxy.generate_event_name,
    raise_event = Proxy.raise_event,
    on_nth_tick = Proxy.on_nth_tick,

    every_second = Tick.every_second,
    every_minute = Tick.every_minute,
    every_hour = Tick.every_hour
}

function Event.on_init_and_load(...)
    Event.register(Event.core_events.init_and_load, ...)
end

for event_name, event_id in pairs(defines.events) do
    if not Event[event_name] then
        Event[event_name] = function(...)
            Event.register(event_id, ...)
        end
    end
end

return Event

