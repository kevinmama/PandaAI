local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local ScheduledTask = require 'klib/task/scheduled_task'
local EventTask = require 'klib/task/event_task'

local Tasks = {}

function Tasks.register_scheduled_task(name, delay, interval, run)
    if run == nil then
        if interval == nil then
            run = delay
            delay = nil
            interval = nil
        else
            run = interval
            interval = nil
        end
    end
    local NT = KC.class(name, ScheduledTask, function(self, p_delay, p_interval)
        ScheduledTask(self, p_delay or delay or 0, p_interval or interval)
    end)
    NT.run = function(self)
        run(self)
        ScheduledTask.run(self)
    end
    return NT
end

function Tasks.submit_init_task(name, delay, interval, run)
    local NT = Tasks.register_scheduled_task(name, delay, interval, run)
    Event.on_init(function()
        NT:new_local()
    end)
end

function Tasks.register_event_task(name, event_id, run)
    local NT = KC.class(name, EventTask, function(self)
        EventTask(self, event_id)
    end)
    NT.run = run
    EventTask.hook_event(event_id, NT)
    return NT
end

return Tasks