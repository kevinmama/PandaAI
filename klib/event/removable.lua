local Vargs = require 'klib/utils/vargs'
local TypeUtils = require 'klib/utils/type'
local Event = require 'klib/event/proxy'

local CHECK_POINT = {
    BEFORE = 1,
    AFTER = 2,
    MEET = 3 --- execute when condition meets
}

--- remove handler if condition meets
--- arguments: table[event_id, condition, on_remove, handler, check_point]
--- check_point: CHECK_POINT_BEFORE, CHECK_POINT_AFTER, CHECK_POINT_MEET
local function _register_removable(options)
    TypeUtils.assert_not_nil(options.event_id, 'event_id')
    TypeUtils.assert_is_function(options.condition, 'condition')
    TypeUtils.assert_nil_or_function(options.on_remove, 'on_remove')
    TypeUtils.assert_nil_or_function(options.handler, 'handler')
    TypeUtils.assert_is_int(options.check_point, 'check_point')

    local function check_and_remove(event, removable_handler)
        if options.condition(event) then
            if options.check_point == CHECK_POINT.MEET then
                if options.handler then
                    options.handler(event)
                end
            end
            Event.remove(options.event_id, removable_handler)
            if options.on_remove then
                options.on_remove(event)
            end
            return true
        else
            return false
        end
    end

    local function removable_handler(event)
        if options.check_point == CHECK_POINT.MEET then
            check_and_remove(event, removable_handler)
        else
            if options.check_point == CHECK_POINT.BEFORE then
                if check_and_remove(event, removable_handler) then
                    return
                end
            end
            if options.handler then
                options.handler(event)
            end
            if options.check_point == CHECK_POINT.AFTER then
                check_and_remove(event, removable_handler)
            end
        end
    end
    Event.register(options.event_id, removable_handler)
end

local DEFAULT_CONDITION = function()
    return true
end

local DEFAULT_CHECK_POINT = CHECK_POINT.AFTER

local Removable = {
    CHECK_POINT = CHECK_POINT
}

function Removable.register_removable(event_id, ...)
    local vargs = Vargs(...)
    vargs.next_if(TypeUtils.is_table, function(options)
        _register_removable({
            event_id = event_id,
            condition = options.condition,
            on_remove = options.on_remove,
            handler = options.handler,
            check_point = options.check_point
        })
    end)
    vargs.on_length(1, function(handler)
        _register_removable({
            event_id = event_id,
            condition = DEFAULT_CONDITION,
            handler = handler,
            check_point = DEFAULT_CHECK_POINT
        })
    end)
    vargs.on_length(2, function(condition, handler)
        _register_removable({
            event_id = event_id,
            condition = condition,
            handler = handler,
            check_point = DEFAULT_CHECK_POINT
        })
    end)
end

function Removable.execute_while(event_id, condition, on_remove, handler)
    TypeUtils.assert_is_function(condition)
    if handler == nil then
        handler = on_remove
        on_remove = nil
    end
    local function condition_not_meet(event)
        return not condition(event)
    end
    _register_removable({
        event_id = event_id,
        condition = condition_not_meet,
        on_remove = on_remove,
        handler = handler,
        check_point = CHECK_POINT.BEFORE
    })
end

function Removable.execute_until(event_id, condition, on_remove, handler)
    if handler == nil then
        handler = on_remove
        on_remove = nil
    end
    _register_removable({
        event_id = event_id,
        condition = condition,
        on_remove = on_remove,
        handler = handler,
        check_point = CHECK_POINT.BEFORE
    })
end

--- execute once when condition meet
function Removable.execute_once(event_id, condition, handler)
    if handler == nil then
        handler = condition
        condition = nil
    end
    if nil ~= condition then
        _register_removable({
            event_id = event_id,
            condition = condition,
            handler = handler,
            check_point = CHECK_POINT.MEET
        })
    else
        _register_removable({
            event_id = event_id,
            condition = DEFAULT_CONDITION,
            handler = handler,
            check_point = CHECK_POINT.AFTER
        })
    end
end

return Removable
