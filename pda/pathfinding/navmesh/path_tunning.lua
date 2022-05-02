local log = (require 'stdlib/misc/logger')('navmesh-tunning', DEBUG)
local Path = require 'pda/path/path'
local geometry2d = require 'geometry2d'
local C = require 'pda/pathfinding/pasfv/config'

local PathTunning = {}

function PathTunning.new(algorithm, goal_node)
    return setmetatable({
        algorithm = algorithm,
        goal_node = goal_node,
    }, {__index = PathTunning})
end

function PathTunning:generate_path()
    --return self:generate_midpoint_path()
    return self:generate_edge_path()
end

function PathTunning:generate_edge_path()
    local r_edges = self:_collect_reverse_edges()
    local points = self:_collect_way_points(r_edges)
    local path_nodes = {}
    for _, point in ipairs(points) do
        table.insert(path_nodes, {position = point})
    end
    return Path:new(self.algorithm.navmesh.surface, path_nodes)
end

function PathTunning:_collect_reverse_edges()
    local edges = {}
    local cur = self.goal_node
    while cur.parent ~= nil do
        local edge = cur.parent.region:get_edge({
            region = cur.region,
            direction = cur.direction_from_parent
        })

        -- 显示要通过的边
        --rendering.draw_line({
        --    width = 10,
        --    color = {r=0,g=0,b=1},
        --    surface = self.algorithm.navmesh.surface,
        --    from = edge[1],
        --    to = edge[2]
        --})

        table.insert(edges, edge)
        cur = cur.parent
    end
    return edges
end

function PathTunning:_collect_way_points(r_edges)
    local points = {}
    table.insert(points, self.algorithm.start)

    -- edge to edge
    --for i = #r_edges, 2, -1 do
    --    local edge = r_edges[i]
    --    local next_edge = r_edges[i-1]
    --    local d, ax, ay, bx, by = geometry2d.segment_to_segment(nil,
    --            edge[1].x, edge[1].y,
    --            edge[2].x, edge[2].y,
    --            next_edge[1].x, next_edge[1].y,
    --            next_edge[2].x, next_edge[2].y
    --    )
    --    table.insert(points, {x = ax, y = ay})
    --    table.insert(points, {x = bx, y = by})
    --end

    -- point to edge
    -- 从起点走向边，并通过视线算法来平滑
    local light_point = self.algorithm.start
    local last_point = self.algorithm.start
    local cur_point = self.algorithm.start
    for i = #r_edges, 1, -1 do
        local edge = r_edges[i]
        local d, x, y = geometry2d.point_to_segment(nil, cur_point.x, cur_point.y, edge[1].x, edge[1].y, edge[2].x, edge[2].y)
        last_point = cur_point
        cur_point = {x = x, y = y}
        if not self:light_of_sight(light_point, cur_point) then
            light_point = last_point
            table.insert(points, light_point)
        end
    end

    if not self:light_of_sight(light_point, self.algorithm.goal) then
        light_point = cur_point
        table.insert(points, cur_point)
    end

    table.insert(points, self.algorithm.goal)
    return points
end

function PathTunning:light_of_sight(light_point, point)
    local items, len = self.algorithm.navmesh.world:querySegment(light_point.x, light_point.y, point.x, point.y, function(item)
        return item.type ~= C.OBJECT_TYPES.REGION
    end)
    return len == 0
end

function PathTunning:generate_midpoint_path()
    local reverse_points = {}
    table.insert(reverse_points, self.algorithm.goal)
    local cur = self.goal_node
    while cur.parent ~= nil do
        table.insert(reverse_points, cur.parent_point)
        cur = cur.parent
    end
    table.insert(reverse_points, self.algorithm.start)

    local path = {}
    for i = #reverse_points, 1, -1 do
        table.insert(path, {
            position = reverse_points[i]
        })
    end
    return Path:new(self.algorithm.navmesh.surface, path)
end

return PathTunning
