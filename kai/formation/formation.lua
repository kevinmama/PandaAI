local KC = require('klib/container/container')

local Formation = KC.class('kai.formation.Formation', function(self, group)
    self:set_group(group)
end)

Formation:reference_objects("group")

function Formation:update()
end

return Formation