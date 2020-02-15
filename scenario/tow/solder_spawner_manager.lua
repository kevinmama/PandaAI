local Position = require('__stdlib__/stdlib/area/position')
local Area = require('__stdlib__/stdlib/area/area')
local KC = require 'klib/container/container'
local SolderSpawner = require 'scenario/tow/solder_spawner'

local SolderSpawnerManager = KC.singleton('SolderSpawnerManager', function(self)
    self.spawners = {}
end)

SolderSpawnerManager:on(defines.events.on_player_created, function(event, self)
    local spawner = SolderSpawner:new(game.players[event.player_index])
    self.spawners[event.player_index] = spawner
end)

function SolderSpawnerManager:get_spawner_by_event(event)
    return KC.get(self).spawners[event.player_index]
end

--SolderSpawnerManager:on(defines.events.on_put_item, function(event, self)
--    local player = game.players[event.player_index]
--    local stack = player.cursor_stack
--    game.print("putting something on position" .. Position.to_string(event.position))
--    if stack.valid_for_read and stack.name == 'stone-furnace' then
--        game.print("putting stone-furnace to position" .. Position.to_string(event.position))
--        self.spawners[event.player_index]:move_to_position(event.position)
--    end
--end)

SolderSpawnerManager:on(defines.events.on_player_deconstructed_area, function(event, self)
    --game.print(event.item)
    local position = Area.center(event.area)
    --game.print("move to position " .. serpent.line({position.x, position.y}))
    self.spawners[event.player_index]:move_to_position(position)
end)

return SolderSpawnerManager
