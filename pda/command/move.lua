local log = require('__stdlib__/stdlib/misc/logger').new('command', DEBUG)
local table = require('__stdlib__/stdlib/utils/table')
local KC = require('klib/container/container')
local Behaviors = require 'pda/behavior/behaviors'
local Path = require('pda/path/path')
local ColorList = require '__stdlib__/stdlib/utils/defines/color_list'

local Move = KC.class('pda.command.Move', function(self, agent, position)
    self.agent = agent
    self.position = position
    self.path_id = nil
    self.path = nil
end)

function Move:execute()
    local entity = self.agent.entity
    self.path_id = entity.surface.request_path({
        bounding_box = entity.bounding_box,
        collision_mask = {"player-layer"},
        start = entity.position,
        goal = self.position,
        force = entity.force,
    })
end

Move:on(defines.events.on_script_path_request_finished, function(event, self)
    if event.id == self.path_id then
        if event.path then
            log(string.format("request path success (path_id = %s):", self.path_id))
            log(event.path)

            local positions = table.map(event.path, function(item)
                return item.position
            end)
            self.path = Path:new(self.agent.entity.surface, positions)
            self:on_path_created()
        else
            log(string.format("request path failed (path_id = %s, try_again_later = %s ):", self.path_id, event.try_again_later))
        end
    end
end)

function Move:on_path_created()
    if self.path then
        self.agent:remove_behavior(Behaviors.PathFollowing)
        self.path:display({
            color = ColorList.lightblue
        })
        self.agent:add_behavior(Behaviors.PathFollowing, {
            path = self.path,
            radius = 2
        })
    end
end

function Move:on_destroy()
    if self.path then
        self.path:destroy()
    end
end

return Move
