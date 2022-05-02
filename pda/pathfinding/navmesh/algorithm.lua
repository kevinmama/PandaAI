local log = (require 'stdlib/misc/logger')('navmesh', DEBUG)
local Position = require 'stdlib/area/position'
local NavMeshConfig = require 'pda/pathfinding/pasfv/config'
local OpenList = require 'pda/pathfinding/navmesh/open_list'
local Path = require 'pda/path/path'
local PathTunning = require 'pda/pathfinding/navmesh/path_tunning'

local Algorithm = {}

-- node:
--   region 对应的区域
--   key 结点权重，由 h + g 表示
--   g 从起点到当前结点的距离
--   h 估算当前结点到目标的距离
--   parent 路径的父区域
--   open 表示结点是否在开列表中

function Algorithm.new(args)
    return setmetatable({
        navmesh = args.navmesh,
        bounding_box = args.bounding_box,
        start = args.start,
        goal = args.goal,
        radius = args.radius or 1,

        finish = false
    }, {
        __index = Algorithm
    })
end

local NEXT_PATH_ID = 1
local function next_path_id()
    local id = NEXT_PATH_ID
    NEXT_PATH_ID = NEXT_PATH_ID + 1
    return id
end

function Algorithm:run()
    self.path_id = next_path_id()
    self:init_start_and_goal_region()
    self:check_trivial()
    if self.finish then
        return self.path
    end
    -- perform A* on mesh
    return self:perform_path_finding()
end

function Algorithm:init_start_and_goal_region()
    self.start_region = self:find_unique_region(self.start)
    self.goal_region = self:find_unique_region(self.goal)
end

function Algorithm:check_trivial()
    if self.start_region == nil or self.goal_region == nil then
        self.finish = true
    elseif self.start_region == self.goal_region then
        self.finish = true
        self.path = Path:new(self.navmesh.surface, {
            {position = self.start},
            {position = self.goal}
        })
    end
end

function Algorithm:find_unique_region(point)
    local items, len = self.navmesh.world:queryPoint(point.x, point.y, function (item)
        return item.type == NavMeshConfig.OBJECT_TYPES.REGION
    end)
    return len ~= 1 and nil or items[1]
end

function Algorithm:perform_path_finding()
    self:init_open_list()
    local cur = self.open_list:pop()
    while cur ~= nil do
        log("current node is " .. serpent.line(cur.region:debug_info()))
        for _, neighbour in pairs(cur.region.neighbours) do
            if self:is_reach(neighbour) then
                return self:generate_path(cur, neighbour)
            end

            if neighbour.region.seen ~= self.path_id then
                self:create_new_node(cur, neighbour)
            else
                self:update_seen_node(cur, neighbour)
            end
        end
        cur.open = false
        cur = self.open_list:pop()
    end
    return nil
end

function Algorithm:is_reach(neighbour)
    return neighbour.region == self.goal_region
end

function Algorithm:generate_path(cur, neighbour)
    local goal_node = self:init_goal_node(cur, neighbour)
    local path_tunning = PathTunning.new(self, goal_node)
    return path_tunning:generate_path()
end

function Algorithm:init_open_list()
    self.open_list = OpenList.new(self)
    local start_node = {
        region = self.start_region,
        open = true,
        g = 0,
        parent = nil,
        parent_point = self.start
    }
    start_node.h = Position.distance(self.start, self.goal)
    start_node.key = start_node.g + start_node.h
    self.open_list:push(start_node)
end

function Algorithm:init_goal_node(parent_node, neighbour)
    return {
        region = neighbour.region,
        direction_from_parent = neighbour.direction,
        parent = parent_node,
        parent_point = parent_node.region:get_edge_midpoint(neighbour)
    }
end

function Algorithm:create_new_node(cur, neighbour)
    local node = {
        region = neighbour.region,
        direction_from_parent = neighbour.direction,
        open = true,
        parent = cur,
        parent_point = cur.region:get_edge_midpoint(neighbour)
    }
    node.g = cur.g + Position.distance(cur.parent_point, node.parent_point)
    node.h = Position.distance(node.parent_point, self.goal)
    node.key = node.g + node.h
    self.open_list:push(node)
    neighbour.region:see_node(self.path_id, node)
end

function Algorithm:update_seen_node(cur, neighbour)
    local prev = neighbour.region.seen_node
    local node = {
        region = neighbour.region,
        direction_from_parent = neighbour.direction,
        parent = cur,
        parent_point = cur.region:get_edge_midpoint(neighbour),
        h = prev.h,
        open = true
    }
    node.g = cur.g + Position.distance(cur.parent_point, node.parent_point)
    node.key = node.g + node.h

    if node.key < prev.key then
        if prev.open then
            self.open_list:replace(prev, node)
        else
            self.open_list:push(node)
        end
        neighbour.region:see_node(self.path_id, node)
    end
end


return Algorithm
