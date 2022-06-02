local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local PriorityQueue = require 'klib/classes/priority_queue'

local ScheduledTask = KC.class("klib.task.ScheduledTask", {
    "task_queue", function()
        return {
            task_queue = PriorityQueue:new_local()
        }
    end
}, function(self, delay, interval)
    local q = self:get_task_queue()
    q:push(game.tick + delay, self)
    self.interval = interval
end)

function ScheduledTask:run()
    -- IMPROVE 还可以支持控制在 N Tick 后再执行
    if not self.destroyed then
        if self.interval then
            self:get_task_queue():push(game.tick + self.interval, self)
        else
            self:destroy()
        end
    end
end

Event.on_tick(function()
    while true do
        local q = ScheduledTask:get_task_queue()
        local task, tick = q:peek()
        if tick and game.tick >= tick then
            q:pop()
            if not task.destroyed then
                task:run()
            end
        else
            break
        end
    end
end)

return ScheduledTask
