local log = require('stdlib/misc/logger')('command', __DEBUG__)
local KC = require('klib/container/container')
local Table = require('klib/utils/table')
local Behaviors = require 'ai/behavior/behaviors'
local Path = require('ai/concept/path')
local ColorList = require 'stdlib/utils/defines/color_list'
local Command = require 'ai/command/command'
local Config = require 'ai/config'

local Move = KC.class('ai.command.Move', Command, function(self, agent, destination)
    Command(self, agent)
    self.destination = destination
end)

Move:reference_objects("path")

function Move:execute()
    local entity = self:get_agent().entity

    --entity.set_command({
    --    type = defines.command.go_to_location,
    --    destination = self.position
    --})

    self:destroy_path()
    self.path_id = entity.surface.request_path({
        bounding_box = entity.bounding_box,
        collision_mask = Config.CHARACTER_COLLISION_MASK,
        start = entity.position,
        goal = self.destination,
        force = entity.force,
        can_open_gates = true,
        entity_to_ignore = entity
    })

    log(string.format("request path (path_id = %s)", self.path_id))

    --self.path = pathfinding({
    --    surface = entity.surface,
    --    bounding_box = entity.prototype.collision_box,
    --    collision_mask = { "player-layer"},
    --    start = entity.position,
    --    goal = self.position,
    --    force = entity.force,
    --    can_open_gates = true
    --})
    --self:on_path_created()
end

Move:on(defines.events.on_script_path_request_finished, function(self, event)
    if event.id == self.path_id then
        if event.path then
            log(string.format("request path success (path_id = %s):", self.path_id))
            local agent = self:get_agent()
            self:set_path(Path:new(agent.entity.surface, event.path))
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
