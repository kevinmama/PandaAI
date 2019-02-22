local KL  = require 'klib/klib'
local KC = KL.Container
local Agent = KL.Agent

local SolderSpawner = KC.class('SolderSpawner', function(self, player)
    game.print('init spawner for player: ' .. player.name)
    self.player = player
    self.agents = {}
end)

function SolderSpawner:on_agent_destroy(agent)
    self.agents[agent:id()] = nil
end

function SolderSpawner:spawn(surface, position)
    local pos = surface.find_non_colliding_position("player", position, 50, 2)
    local entity = surface.create_entity({
        name = "player",
        position = pos,
        force = "player"
    })
    local agent = Agent:new(entity)
    agent:join_group(self)
    self.agents[agent:id()] = agent
    return entity
end

function SolderSpawner:add_command(command, ...)
    for _, agent in pairs(self.agents) do
        agent:add_command(command, ...)
    end
end

function SolderSpawner:spawn_around_player()
    local surface = self.player.surface
    local position = self.player.position
    return self:spawn(surface, position)
end

return SolderSpawner