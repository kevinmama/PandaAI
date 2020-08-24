local ColorList = require '__stdlib__/stdlib/utils/defines/color_list'
local KC = require 'klib/container/container'
local Rendering = require 'klib/rendering/rendering'
local C = require 'pda/pathfinder/config'
local Edge = require 'pda/pathfinder/edge'

local Display = KC.class('pda.pathfinder.Display', function(self, mesh)
    self.mesh = mesh
    self.world = mesh.world
end)

function Display:display_world(area)
    local items, len = self.world:queryArea(area)
    for i = 1, len do
        local item = items[i]
        local color
        if item.type == C.OBJECT_TYPES.REGION then
            color = ColorList.lightgreen
            self:_renderItem(item, { color = color })
        elseif item.type == C.OBJECT_TYPES.ENTITY then
            color = ColorList.red
            self:_renderItem(item, { color = color })
        else
            --item.type == C.OBJECT_TYPES.TILE
            self:_renderItem(item, { color = ColorList.red })
        end
    end
end

function Display:display_seeds(seeds)
    for _, seed in pairs(seeds) do
        self:display_seed(seed)
    end
end

function Display:display_seed(seed)
    self:_renderRect({
        color = ColorList.yellow,
        x = seed.x, y = seed.y, w = seed.w, h = seed.h,
    })
end

function Display:display_regions(regions)
    if regions then
        for _, region in pairs(regions) do
            self:display_region(region)
        end
    end
end

function Display:display_region(region)
    if not region then
        return
    end
    Rendering.clear(region.render_ids)
    local render_ids = {}
    table.insert(render_ids, self:_renderRect({
        color = ColorList.lightgreen,
        x = region.x,
        y = region.y,
        w = region.w,
        h = region.h
    }))
    for _, neighbour in ipairs(region.neighbours) do
        local edge_midpoint = Edge.midpoint(region:get_edge(neighbour))
        table.insert(render_ids, rendering.draw_line({
            from = region:center(),
            to = edge_midpoint,
            width = 2,
            color = ColorList.purple,
            surface = self.mesh.surface,
            time_to_live = C.DISPLAY_TTL
        }))
        table.insert(render_ids, rendering.draw_line({
            from = edge_midpoint,
            to = neighbour.region:center(),
            width = 2,
            color = ColorList.purple,
            surface = self.mesh.surface,
            time_to_live = C.DISPLAY_TTL
        }))
    end
    region.render_ids = render_ids
end

function Display:_renderItem(item, opts)
    local opts = opts or {}
    local x, y, w, h = self.world:getRect(item)
    return rendering.draw_rectangle({
        color = opts.color or ColorList.red,
        left_top = { x + 0.02, y + 0.02 },
        right_bottom = { x + w - 0.02, y + h - 0.02 },
        surface = self.mesh.surface,
        filled = false,
        time_to_live = opts.time_to_live or C.DISPLAY_TTL
    })
end

function Display:_renderRect(args)
    local x = args.x
    local y = args.y
    local w = args.w
    local h = args.h
    return rendering.draw_rectangle({
        color = args.color or ColorList.red,
        left_top = { x, y },
        right_bottom = { x + w, y + h },
        surface = self.mesh.surface,
        filled = false,
        time_to_live = args.time_to_live or C.DISPLAY_TTL
    })
end

return Display
