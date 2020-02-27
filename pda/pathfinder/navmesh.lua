local KC = require 'klib/container/container'

local C = {
       CELL_SIZE = 32,
       UNIT_SIZE = 0.2,
       OBJECT_TYPES = {
              OBSTRUCTION = "obstruction",
              REGION = "region"
       },
       DISPLAY_TTL = 9000,
       SMALL = 10e-7
}

local NavMesh = KC.class('pda.pathfinder', function(self, surface, collision_mask)
       self.surface = surface
       self.collision_mask = collision_mask

       self.world = Bump.newWorld(C.CELL_SIZE)
       self:init()
end)

table.merge(NavMesh, C)

function NavMesh:init()

end

NavMesh:on(defines.events.on_chunk_generated, function(self, event)

end)


return NavMesh
