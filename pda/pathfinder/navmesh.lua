-- 网格表示类，同时向寻路器提供寻路数据
local PriorityQueue = require 'klib/ds/priority_queue'

local KC = require 'klib/container/container'
local Config = require 'pda/pathfinder/config'
local Bump = require 'klib/ds/bump'
local Seeder = require 'pda/pathfinder/pasfv/seeder'
local Grower = require 'pda/pathfinder/pasfv/grower'
local Display = require 'pda/pathfinder/display'

local NavMesh = KC.class('pda.pathfinder.NavMesh', function(self, surface, collision_mask)
    self.surface = surface
    self.collision_mask = collision_mask

    -- negative 可扩展区域
    -- position 已扩展区域
    self.regions = {}

    -- space world
    self.world = Bump:new(Config.SPACE_CELL_SIZE)
    -- chunk world for bounding detecting, can merge later to improve performance
    self.chunk_world = Bump:new(Config.CHUNK_CELL_SIZE)

    self.display = Display:new(self)
    self.seeder = Seeder:new(self)
    self.grower = Grower:new(self)

end)

function NavMesh:on_destroy()
    self.world:destroy()
    self.chunk_world:destroy()
    self.seeder:destroy()
    self.grower:destroy()
    self.display:destroy()
    for _, region in pairs(regions) do
        region:destroy()
    end
end

NavMesh:on(defines.events.on_chunk_generated, function(self, event)
    if event.surface == self.surface then
        self.grower:add_chunk(event.area)
    end
end)

NavMesh:on(defines.events.on_chunk_deleted, function(self, event)
    -- TODO
end)

-- entity put/delete
NavMesh:on(defines.events.on_tick, function(self, event)
    -- 从优先队列中获取待处理的对象
    -- 块: 给 seeder 处理
    -- 种子、区间、次给区间

    -- TODO: 1. 当块扩展时，允许合并边界区域
    self.grower:grow()

    --local area = self.negative_chunk_areas()
    --if area then
    --    self.chunk_world:add_area({}, area)
    --    local seeds = self.seeder:seed_chunk(area)
    --
    --    self.display:display_world(area)
    --    self.display:display_seeds(seeds)
    --
    --    self.grower:add_seeds(seeds)
    --    return
    --end
    --
    --local updated_regions = self.grower:grow()
    --if updated_regions then
    --    self.display:display_regions(updated_regions)
    --    return
    --end
end)

return NavMesh
