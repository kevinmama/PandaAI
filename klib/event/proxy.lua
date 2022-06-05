local Event = require('stdlib/event/event')

local Proxy = {
    on_init = Event.on_init,
    on_configuration_changed = Event.on_configuration_changed,
    on_load = Event.on_load,
    on_event = Event.on_event,
    on_nth_tick = Event.on_nth_tick,
    register = Event.register,
    remove = Event.remove,
    core_events = Event.core_events,
    custom_events = Event.custom_events,
    generate_event_name = Event.generate_event_name,
    raise_event = Event.raise_event
}

Proxy.generate_event_name = function(event_name)
    local id = Event.generate_event_name(event_name)
    log(string.format("generated custom event: %s -> %d", event_name, id))
    return id
end


return Proxy

