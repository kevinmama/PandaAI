local log = (require '__stdlib__/stdlib/misc/logger')("pasfv", DEBUG)
local Bump = require '__stdlib__/stdlib/vendor/bump'
local Position = require '__stdlib__/stdlib/area/position'
local ColorList = require '__stdlib__/stdlib/utils/defines/color_list'
local Queue = require '__stdlib__/stdlib/misc/queue'

local C = require 'pda/pathfinding/pasfv/config'
local Seed = require 'pda/pathfinding/pasfv/seed'
local Grow = require 'pda/pathfinding/pasfv/grow'

local Algorithm = {}

function Algorithm.new(args)
    local algorithm = setmetatable({
        surface = args.surface,
        position = args.position,
        radius = args.radius or 32,
        collision_mask = args.collision_mask or {"player-layer"},
        -- 待扩展的种子区域列表
        seed_queue = Queue(),
        regions = {},
    }, {__index = Algorithm })
    algorithm:init()
    return algorithm
end


-- 实现 seeding 算法

function Algorithm:init()
    self:init_world()
    self:init_obstruction()
    self.seed = Seed.new(self)
    self.seed:seed()
    self.grow = Grow.new(self)
    self.grow:grow()
end

function Algorithm:init_world()
    self.world = Bump.newWorld(C.CELL_SIZE)
    self.bounding = {
        left_top = { x = self.position.x - self.radius, y = self.position.y - self.radius},
        right_bottom = { x = self.position.x + self.radius, y = self.position.y + self.radius}
    }
end

function Algorithm:init_obstruction()
    local entities = self.surface.find_entities_filtered({
        area = self.bounding,
        collision_mask = self.collision_mask
    })

    for _, entity in pairs(entities) do
        if entity.name ~= 'character' then
            self:_add_entity(entity)
        end
    end

    local tiles = self.surface.find_tiles_filtered({
        area = self.bounding,
        collision_mask = self.collision_mask
    })

    for _, tile in pairs(tiles) do
        self:_add_tile(tile)
    end
end

function Algorithm:_add_entity(entity)
    local item = {
        name = entity.name,
        type = C.OBJECT_TYPES.OBSTRUCTION
    }
    self.world:add(
            item,
            entity.bounding_box.left_top.x,
            entity.bounding_box.left_top.y,
            entity.bounding_box.right_bottom.x - entity.bounding_box.left_top.x,
            entity.bounding_box.right_bottom.y - entity.bounding_box.left_top.y
    )
end

function Algorithm:_add_tile(tile)
    local item = {
        name = tile.name,
        type = C.OBJECT_TYPES.OBSTRUCTION
    }
    self.world:add(item, tile.position.x - 0.5, tile.position.y - 0.5, 1,1)
end


function Algorithm:display()
    self:display_boundary()
    self:display_world()
    self:display_regions()
    self:display_seeds()
end

function Algorithm:display_boundary()
    rendering.draw_rectangle({
        color = ColorList.orange,
        left_top = self.bounding.left_top,
        right_bottom = self.bounding.right_bottom,
        surface = self.surface,
        filled = false,
        time_to_live = C.DISPLAY_TTL
    })
end

function Algorithm:display_world()
    local items, len = self.world:getItems()
    for i=1, len do
        local item = items[i]
        local color
        if item.type == C.OBJECT_TYPES.REGION then
            color = ColorList.lightgreen
        else
            color = ColorList.red
        end
        self:_renderItem(item, {color = color})
    end
end

function Algorithm:display_regions()
    for _, region in ipairs(self.regions) do
        for _, neighbour in ipairs(region.neighbours) do
            local edge_midpoint = region:edge_midpoint(region:get_edge(neighbour))
            rendering.draw_line({
                from = region:center(),
                to = edge_midpoint,
                width = 2,
                color = ColorList.purple,
                surface = self.surface,
                time_to_live = C.DISPLAY_TTL
            })
            rendering.draw_line({
                from = edge_midpoint,
                to = neighbour.region:center(),
                width = 2,
                color = ColorList.purple,
                surface = self.surface,
                time_to_live = C.DISPLAY_TTL
            })
        end
    end
end

function Algorithm:display_seeds()
    for _, seed in pairs(self.seed_queue) do
        self:_renderRect({
            color = ColorList.yellow,
            x = seed.x, y = seed.y, w = seed.w, h =seed.h,
        })
    end
end

function Algorithm:_renderItem(item, opts)
    local opts = opts or {}
    local x,y,w,h = self.world:getRect(item)
    rendering.draw_rectangle({
        color = opts.color or ColorList.red,
        left_top = {x+0.02, y+0.02},
        right_bottom = {x+w-0.02,y+h-0.02},
        surface = self.surface,
        filled = false,
        time_to_live = opts.time_to_live or C.DISPLAY_TTL
    })
end

function Algorithm:_renderRect(args)
    local x = args.x
    local y = args.y
    local w = args.w
    local h = args.h
    rendering.draw_rectangle({
        color = args.color or ColorList.red,
        left_top = {x,y},
        right_bottom = {x+w,y+h},
        surface = self.surface,
        filled = false,
        time_to_live = args.time_to_live or C.DISPLAY_TTL
    })
end

return Algorithm
