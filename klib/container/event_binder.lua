local dlog = require 'klib/container/dlog'
local Event = require 'klib/event/event'
local ObjectRegistry = require('klib/container/object_registry')

local EventBinder = {}

function EventBinder.bind_class_event(class, event_id, handler)
    dlog("register event (" .. serpent.line(event_id) .. ") for " .. class["_class_"])
    Event.register(event_id, function(event)
        ObjectRegistry.for_each_object(class, function(object)
            -- dlog("fire event (" .. event_id .. ") for " .. object["_class_"] .. "@" .. object["_id_"])
            handler(object, event)
        end)
    end)
end

function EventBinder.bind_singleton_event(singleton_getter, event_id, handler)
    Event.register(event_id, function(event)
        local object = singleton_getter()
        handler(object, event)
    end)
end

return EventBinder
