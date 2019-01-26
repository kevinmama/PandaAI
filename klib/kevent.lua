require 'stdlib/event/event'
local KEvent = {
    register = Event.register,
    remove = Event.remove,
    core_events = Event.core_events
}

local function parse_removable_handler_arguments(...)
    local args = { ... }
    local condition, on_remove, handler, check_after
    if #args == 1 then
        args = args[1]
        condition = args.condition
        on_remove = args.on_remove
        handler = args.handler
        check_after = args.check_after or false
    elseif #args == 2 then
        condition = args[1]
        handler = args[2]
    else
        condition = args[1]
        on_remove = args[2]
        handler = args[3]
    end
    return {
        condition = condition,
        on_remove = on_remove,
        handler = handler,
        check_after = check_after
    }
end

function KEvent.register_removable(event_id, ...)
    local args = parse_removable_handler_arguments(...)

    args.try_remove = function(event)
        if args.condition(event) then
            Event.remove(event_id, args.removable_handler)
            if args.on_remove then
                args.on_remove(event)
            end
            return true
        else
            return false
        end
    end

    args.removable_handler = function(event)
        if not args.check_after then
            if not args.try_remove(event) then
                args.handler(event)
            end
        else
            args.handler(event)
            args.try_remove(event)
        end

    end

    Event.register(event_id, args.removable_handler)
end

function KEvent.on_game_ready(handler)
    KEvent.register_removable(defines.events.on_tick, {
        condition = function()
            return true
        end,
        handler = handler,
        check_after = true
    })
end

return KEvent
