local KC = require 'klib/container/container'
local LazyFunction = require 'klib/utils/lazy_function'
local Event = require 'klib/event/event'
local Steer = require 'kai/agent/Steer'
local BehaviorController = require 'kai/agent/behavior_controller'
local CommandController = require 'kai/agent/command_controller'

local Group = KC.class('kai.agent.Group', function(self, surface, position, force)
    self.surface = surface
    self.position = position
    self.force = force
    self.member_ids = {}
end)

function Group:get_position()
    return self.position
end

function Group:add_member(agent)

end

function Group:remove_member(agent)

end

function Group:set_command(command)

end

function Group:update()

end

return Group