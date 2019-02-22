local TypeUtils = require('klib/utils/type_utils')
local Event = require('klib/event/proxy')
local Repeat = {}

function Repeat.execute_when(event_id, condition, handler)
    TypeUtils.assert_is_function(condition)
    TypeUtils.assert_is_function(handler)
    Event.register(event_id, function(event)
        if condition(event) then
            handler(event)
        end
    end)
end

return Repeat
