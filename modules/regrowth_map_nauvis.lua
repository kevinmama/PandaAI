local KC = require('klib/container/container')
local RegrowthMap = require('modules/regrowth_map')

local RegrowthMapNauvis = KC.singleton('modules.RegrowthMapNauvis', RegrowthMap, function(self)
    RegrowthMap(self, "nauvis")
end)

return RegrowthMapNauvis