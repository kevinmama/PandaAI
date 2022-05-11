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
    generate_event_name = Proxy.generate_event_name,
    raise_event = Proxy.raise_event,

    CHECK_POINT = Removable.CHECK_POINT,
    register_removable = Removable.register_removable,
    execute_once = Removable.execute_once,
    execute_while = Removable.execute_while,
    execute_until = Removable.execute_until,
    on_first_tick = Removable.execute_on_first_tick,

    execute_when = Repeat.execute_when,

    on_nth_tick = Proxy.on_nth_tick,
    every_second = Tick.every_second,
    every_minute = Tick.every_minute,
    every_hour = Tick.every_hour
}

--- 不能使用条件注册的事件，因为加载时无法重注册事件

function Event.on_game_ready(handler)
    return Event.execute_once(defines.events.on_tick, handler)
end

function Event.on_first_tick(handler)
    return Event.execute_once(defines.events.on_tick, function(event)
        return event.tick == 1
    end, handler)
end

return Event

