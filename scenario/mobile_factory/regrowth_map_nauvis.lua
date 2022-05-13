local KC = require('klib/container/container')
local Config = require 'scenario/mobile_factory/config'
local RegrowthMap = require('modules/regrowth_map')

local RegrowthMapNauvis = KC.singleton('scenario.MobileFactory.RegrowthMapNauvis', RegrowthMap, function(self)
    RegrowthMap(self, Config.GAME_SURFACE_NAME)
    self.check_pollution = false
end)

return RegrowthMapNauvis