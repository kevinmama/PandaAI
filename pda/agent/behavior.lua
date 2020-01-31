local KC = require('klib/container/container')

local Behavior = KC.class('pda.agent.Behavior', function(self, agent)
    self.agent = agent
    self.behaviors = {}
end)

function Behavior:on_destroy()
    self:clear()
end

function Behavior:clear()
    for _, behavior in pairs(self.behaviors) do
        behavior:destroy()
    end
    self.behaviors = {}
end

function Behavior:update()
    for _, behavior in pairs(self.behaviors) do
        behavior:update()
    end
end

--- example:
--- 1. pass a behavior class and construct argument except agent
---   agent.add_behavior(Follow, me)
--- 2. pass a behavior instance
---   agent.add_behavior(follow_me_behavior)
function Behavior:add(behavior, ...)
    -- if pass a behavior class and arguments, create its instance first
    if KC.is_class(behavior) then
        local Behavior = behavior
        behavior = Behavior:new(self.agent, ...)
    elseif KC.is_object(behavior) then
    else
        error('command must be a subclass of Behavior or its instance')
    end

    local prev_behavior = self.behaviors[behavior:get_name()]
    if prev_behavior ~= behavior then
        if prev_behavior ~= nil then
            prev_behavior:destroy()
        end
        self.behaviors[behavior:get_name()] = behavior
    end
end

--- behavior is class or instance
function Behavior:remove(behavior)
    local name = behavior:get_name()
    local prev_behavior = self.behaviors[name]
    if nil ~= prev_behavior then
        prev_behavior:destroy()
    end
    self.behaviors[name] = nil
end

function Behavior:clear()
    for name, behavior in pairs(self.behaviors) do
        behavior:destroy()
        self.behaviors[name] = nil
    end
end

return Behavior
