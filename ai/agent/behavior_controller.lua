local KC = require('klib/container/container')

local BehaviorController = KC.class('ai.agent.BehaviorController', function(self, agent)
    self:set_agent(agent)
    self.behavior_ids = {}
end)

BehaviorController:reference_objects("agent")

function BehaviorController:on_destroy()
    self:clear()
end

function BehaviorController:clear()
    for _, behavior_id in pairs(self.behavior_ids) do
        KC.get(behavior_id):destroy()
    end
    self.behavior_ids = {}
end

function BehaviorController:update()
    for _, behavior_id in pairs(self.behavior_ids) do
        KC.get(behavior_id):update()
    end
end

--- example:
--- 1. pass a behavior class and construct argument except agent
---   agent.add_behavior(Follow, me)
--- 2. pass a behavior instance
---   agent.add_behavior(follow_me_behavior)
function BehaviorController:add(behavior, ...)
    -- if pass a behavior class and arguments, create its instance first
    if KC.is_class(behavior) then
        local Behavior = behavior
        behavior = Behavior:new(self:get_agent(), ...)
    elseif KC.is_object(behavior) then
    else
        error('command must be a subclass of Behavior or its instance')
    end

    local prev_behavior_id = self.behavior_ids[behavior:get_name()]
    if prev_behavior_id ~= behavior:get_id() then
        if prev_behavior_id ~= nil then
            KC.get(prev_behavior_id):destroy()
        end
        self.behavior_ids[behavior:get_name()] = behavior:get_id()
    end
end

--- behavior is class or instance
function BehaviorController:remove(behavior)
    local name = behavior:get_name()
    local prev_behavior_id = self.behavior_ids[name]
    if nil ~= prev_behavior_id then
        KC.get(prev_behavior_id):destroy()
    end
    self.behavior_ids[name] = nil
end

return BehaviorController
