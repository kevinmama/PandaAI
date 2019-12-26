local KL  = require 'klib/klib'
local KC = KL.Container
local Agent = KL.Agent
local Behaviors = require 'pda/behavior/behaviors'
local Path = require 'pda/path/path'
local Position = require '__stdlib__/stdlib/area/position'

local SolderSpawner = KC.class('SolderSpawner', function(self, player)
    game.print('init spawner for player: ' .. player.name)
    self.player = player
    self.agents = {}
end)

function SolderSpawner:on_agent_destroy(agent)
    self.agents[agent:id()] = nil
end

function SolderSpawner:spawn(surface, position)
    local pos = surface.find_non_colliding_position("character", position, 50, 2)
    local entity = surface.create_entity({
        name = "character",
        position = pos,
        force = "player"
    })
    local agent = Agent:new(entity)
    agent:join_group(self)
    self.agents[agent:id()] = agent
    return entity
end

function SolderSpawner:add_behavior(command, ...)
    for _, agent in pairs(self.agents) do
        agent:add_behavior(command, ...)
    end
end

function SolderSpawner:add_default_behavior()
    for _, agent in pairs(self.agents) do
        agent:add_behavior(Behaviors.Follow, self.player)
        agent:add_behavior(Behaviors.Alert)
        agent:add_behavior(Behaviors.Separation)
    end
end

function SolderSpawner:stop_following()
    for _, agent in pairs(self.agents) do
        agent:remove_behavior(Behaviors.Follow)
    end
end

function SolderSpawner:toggle_follow_path()
    self._following_path = not self._following_path
    for _, agent in pairs(self.agents) do
        if self._following_path then
            agent:remove_behavior(Behaviors.Follow)
            agent:add_behavior(Behaviors.PathFollowing, {
                path = self.path
            })
        else
            agent:remove_behavior(Behaviors.PathFollowing)
        end
    end
end

function SolderSpawner:spawn_around_player()
    local surface = self.player.surface
    local position = self.player.position
    return self:spawn(surface, position)
end

function SolderSpawner:new_path()
    if self.path then
        self.path:destroy()
    end
    self.path = Path:new()
    self.player.print('create new path')
    self:add_path_node(self.player.position)
end

function SolderSpawner:add_path_node()
    local position = self.player.position
    self.path:add_node(position)
    self.player.print('add position ' .. Position.to_string(position) .. ' to path')
end

return SolderSpawner
