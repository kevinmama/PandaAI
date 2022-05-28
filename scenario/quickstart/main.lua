local Event = require 'klib/event/event'
local ChunkKeeper = require 'modules/chunk_keeper'
if __DEBUG__ then
   local QS = require('stdlib/scripts/quickstart')
   QS.register_events()
end

Event.on_init(function()
   ChunkKeeper:new(game.surfaces[1])
end)
