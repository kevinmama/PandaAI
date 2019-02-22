local dlog = require 'klib/container/dlog'
local Event = require 'klib/event/event'
local ObjectRegistry = require('klib/container/object_registry')

local EventBinder = {}

function EventBinder.init_container(Container)
    Event.register(Event.core_events.load, function()
        dlog("before KContainer.load(global): ", global)
        Container.load(global)
    end)

    Event.on_game_ready(function()
        Container.persist(global)
        dlog("after KContainer.persist(global): ",global)
    end)
end

function EventBinder.bind_class_event(class, event_id, handler)
    Event.register(event_id, function(event)
        ObjectRegistry.for_each_object(class, function(object)
            handler(event, object)
        end)
    end)
end

function EventBinder.bind_singleton_event(singleton_getter, event_id, handler)
    Event.register(event_id, function(event)
        local object = singleton_getter()
        handler(event, object)
    end)
end

return EventBinder
