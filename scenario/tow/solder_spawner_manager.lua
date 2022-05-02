local Position = require('stdlib/area/position')
local Area = require('stdlib/area/area')
local KC = require 'klib/container/container'
local SolderSpawner = require 'scenario/tow/solder_spawner'

local SolderSpawnerManager = KC.singleton('SolderSpawnerManager', function(self)
    self.spawners = {}
end)

SolderSpawnerManager:on(defines.events.on_player_created, function(self, event)
    local spawner = SolderSpawner:new(game.players[event.player_index])
    self.spawners[event.player_index] = spawner
end)

function SolderSpawnerManager:get_spawner_by_event(event)
    return KC.get(self).spawners[event.player_index]
end

--SolderSpawnerManager:on(defines.events.on_put_item, function(self, event)
--    local player = game.players[event.player_index]
--    local stack = player.cursor_stack
--    game.print("putting something on position" .. Position.to_string(event.position))
--    if stack.valid_for_read and stack.name == 'stone-furnace' then
--        game.print("putting stone-furnace to position" .. Position.to_string(event.position))
--        self.spawners[event.player_index]:move_to_position(event.position)
--    end
--end)

SolderSpawnerManager:on(defines.events.on_player_deconstructed_area, function(self, event)
    --game.print(event.item)
    local position = Area.center(event.area)
    --game.print("move to position " .. serpent.line({position.x, position.y}))
    self.spawners[event.player_index]:move_to_position(position)
end)

return SolderSpawnerManager
