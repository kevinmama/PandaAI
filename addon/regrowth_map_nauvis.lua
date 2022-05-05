local KC = require('klib/container/container')
local RegrowthMap = require('addon/regrowth_map')

local RegrowthMapNauvis = KC.singleton('addon.RegrowthMapNauvis', RegrowthMap, function(self)
    RegrowthMap(self, "nauvis")
end)

return RegrowthMapNauvis