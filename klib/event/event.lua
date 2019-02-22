local Proxy = require('klib/event/proxy')
local Removable = require('klib/event/removable')
local Repeat = require('klib/event/repeat')


local Event = {
    register = Proxy.register,
    remove = Proxy.remove,
    core_events = Proxy.core_events,

    CHECK_POINT = Removable.CHECK_POINT,
    register_removable = Removable.register_removable,
    execute_once = Removable.execute_once,
    execute_while = Removable.execute_while,
    execute_until = Removable.execute_until,

    execute_when = Repeat.execute_when
}

function Event.on_game_ready(handler)
    return Event.execute_once(defines.events.on_tick, handler)
end

return Event
