require 'stdlib/event/event'

local Proxy = {
    register = Event.register,
    remove = Event.remove,
    core_events = Event.core_events
}

return Proxy

