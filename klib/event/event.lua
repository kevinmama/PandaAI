local Proxy = require('klib/event/proxy')
local Removable = require('klib/event/removable')
local Repeat = require('klib/event/repeat')
local Tick = require('klib/event/tick')


local Event = {
    register = Proxy.register,
    on_event = Proxy.on_event,
    remove = Proxy.remove,
    core_events = Proxy.core_events,
    on_init = Proxy.on_init,
    on_load = Proxy.on_load,
    on_configuration_changed = Proxy.on_configuration_changed,

    CHECK_POINT = Removable.CHECK_POINT,
    register_removable = Removable.register_removable,
    execute_once = Removable.execute_once,
    execute_while = Removable.execute_while,
    execute_until = Removable.execute_until,

    execute_when = Repeat.execute_when,

    every_n_tick = Tick.every_n_tick,
    every_second = Tick.every_second,
    every_minute = Tick.every_minute,
    every_hour = Tick.every_hour
}

function Event.on_game_ready(handler)
    return Event.execute_once(defines.events.on_tick, handler)
end

return Event

