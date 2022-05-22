local log = require('stdlib/misc/logger')('command', __DEBUG__)
local KC = require('klib/container/container')
local Behaviors = require 'kai/behavior/behaviors'
local ColorList = require 'stdlib/utils/defines/color_list'

local Path = require('kai/concept/path')
local Command = require 'kai/command/command'
local Config = require 'kai/config'

local Move = KC.class('kai.command.Move', Command, function(self, agent, destination)
    Command(self, agent)
    self.destination = destination
end)

Move:reference_objects("path")

function Move:execute()
    self:destroy_path()
    local agent = self:get_agent()
    self.path_id = agent:get_surface().request_path({
        bounding_box = agent:get_bounding_box(),
        collision_mask = Config.CHARACTER_COLLISION_MASK,
        start = agent:get_position(),
        goal = self.destination,
        force = agent:get_force(),
        can_open_gates = true,
        --entity_to_ignore = entity
        pathfind_flags = {
            allow_paths_through_own_entities = true
        }
    })
    log(string.format("request path (path_id = %s)", self.path_id))
end

Move:on(defines.events.on_script_path_request_finished, function(self, event)
    if event.id == self.path_id then
        if event.path then
            log(string.format("request path success (path_id = %s):", self.path_id))
            local agent = self:get_agent()
            self:set_path(Path:new(agent:get_surface(), event.path))
            self:on_path_created()
        else
            log(string.format("request path failed (path_id = %s, try_again_later = %s )", self.path_id, event.try_again_later))
        end
    end
end)

function Move:on_path_created()
    local path = self:get_path()
    local agent = self:get_agent()
    if path then
        agent:remove_behavior(Behaviors.PathFollowing)
        path:display({
            color = ColorList.lightblue
        })
        agent:add_behavior(Behaviors.PathFollowing, {
            path = path,
            radius = 0.4
        })
        path:display()
    end
end

function Move:destroy_path()
    local path = self:get_path()
    if path then
        path:destroy()
    end
end

function Move:on_destroy()
    self:destroy_path()
end

return Move
