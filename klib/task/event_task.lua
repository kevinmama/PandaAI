local KC = require 'klib/container/container'
local Event = require 'klib/event/event'

local EventTask = KC.class('klib.task.EventTask', {
    registry = {}
}, function(self, event_id)
    if event_id then
        local registry = self:get_registry()
        local event_mapping = registry[event_id]
        if not event_mapping then
            event_mapping = {}
            registry[event_id] = event_mapping
        end
        table.insert(event_mapping, self)
    end
end)

local active_events = {}

function EventTask.hook_event(event_id)
    if not active_events[event_id] then
        active_events[event_id] = true
        Event.register(event_id, function(event)
            local registry = EventTask:get_registry()
            local task_list = registry[event_id]
            if task_list then
                for i = #task_list, 1, -1 do
                    local task = task_list[i]
                    task:run(event)
                    if task.destroyed then
                        table.remove(task_list, i)
                    end
                end
            end
        end)
    end
end

Event.on_init_and_load(function()
    active_events = nil
end)

return EventTask