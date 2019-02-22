local KC = require 'klib/container/container'
local SolderSpawner = require 'scenario/tow/solder_spawner'

local SolderSpawnerManager = KC.singleton('SolderSpawnerManager', function(self)
    self.spawners = {}
end)

SolderSpawnerManager:on(defines.events.on_player_created, function(event, self)
    local spawner = SolderSpawner:new(game.players[event.player_index])
    self.spawners[event.player_index] = spawner
end)

return SolderSpawnerManager
