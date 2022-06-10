local KC = require('klib/container/container')
local Config = require 'scenario/mobile_factory/config'
local ChunkKeeper = require('modules/chunk_keeper')

local MFChunkKeeper = KC.singleton('scenario.MobileFactory.ChunkKeeper', ChunkKeeper, function(self)
    ChunkKeeper(self, game.surfaces[Config.GAME_SURFACE_NAME])
    self.keep_pollution = false
    self.keep_resources = true
end)

return MFChunkKeeper