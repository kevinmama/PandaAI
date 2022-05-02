local log = (require 'stdlib/misc/logger').new('pathfinding', DEBUG)
local Position = require 'stdlib/area/position'
local table = require 'stdlib/utils/table'
local pkey = require 'pda/pathfinding/grid/pkey'
local OpenList = require 'pda/pathfinding/grid/open_list'
local SuccessorGenerator = require 'pda/pathfinding/grid/successor_generator'
local Path = require 'pda/path/path'
local ColorList = require 'stdlib/utils/defines/color_list'

-- node
-- {
-- key: f, 起点到目标的估算代价
-- g: 从起点到当前点的实际代价
-- h: 从当前点到目标的估算代价，如果不可通行，设置为 -1
-- position: 位置
-- parent: 路径父结点在 ptable 中的键
-- open: 是否待搜索(标记是否在open_list)
-- }

local render_ids = {}

local function init_rendering(self)
    rendering.clear()
end

local function render_node(self, node)
    if node.render_id and rendering.is_valid(node.render_id) then
        --log("render id is " .. node.render_id)
        --rendering.destory(node.render_id)
    end
    local text, color
    if node.open then color = ColorList.yellow else color = ColorList.red end
    if node.h == -1 then text = 'X' else text= 'O' end

    local id = rendering.draw_text({
        text = text,
        surface = self.surface,
        target = node.position,
        color = color
    })
    node.render_id = id
    table.insert(render_ids, id)
end

local function init_open_list(self)
    self.open_list = OpenList.new(self)
    -- normalize start position
    local start_node = {
        g = 0,
        position= self.start,
        open=true
    }
    start_node.h = Position.distance(self.start, self.goal)
    start_node.key = start_node.g + start_node.h
    self.open_list:push(start_node)
end

local function update_from_ptable(self, node)
    local pkey = pkey(node)
    local last = self.ptable[pkey]
    if last then
        node.h = last.h
        return true
    else
        return false
    end
end

local function expand_to_collision_area(self, position)
    return {
        left_top = {
            x = position.x + self.bounding_box.left_top.x,
            y = position.y + self.bounding_box.left_top.y
        },
        right_bottom= {
            x = position.x + self.bounding_box.right_bottom.x,
            y = position.y + self.bounding_box.right_bottom.y
        }
    }
end

local function check_passable(self, node)
    if node.h == -1 then
        --log("    {%s, %s} seen before and is not passable", node.position.x, node.position.y)
        return false
    elseif node.h ~= nil then
        --log("    {%s, %s} seen before and is passable", node.position.x, node.position.y)
        return true
    else
        local area = expand_to_collision_area(self, node.position)
        local entities = self.surface.find_entities_filtered({
            area = area,
            collision_mask = self.collision_mask,
            limit = 2
        })
        --if not table.is_empty(entities) then

        for _, entity in pairs(entities) do
            if entity ~= self.entity then
                node.h = -1
                --log(string.format("    {%s, %s} collide with entity (%s) {%s, %s}. ",
                --        node.position.x, node.position.y,
                --        entities[1].name, entities[1].position.x, entities[1].position.y))
                --log(string.format("    {%s, %s} has entity collision", node.position.x, node.position.y))
                return false
            end
        end

        --local tiles_count = self.surface.count_tiles_filtered({
        --    area = area,
        --    collision_mask = self.collision_mask,
        --    limit = 1
        --})
        ----if not table.is_empty(tiles) then
        --if tiles_count > 0 then
        --    node.h = -1
        --    --log(string.format("    {%s, %s} collide with tile (%s) {%s, %s}. ",
        --    --        node.position.x, node.position.y,
        --    --        tiles[1].name, tiles[1].position.x, tiles[1].position.y))
        --    log(string.format("    {%s, %s} has tile collision", node.position.x, node.position.y))
        --    return false
        --end
        local tile = self.surface.get_tile(node.position.x, node.position.y)
        if tile.collides_with("player-layer") then
            node.h = -1
            --log(string.format("    {%s, %s} has tile collision", node.position.x, node.position.y))
            return false
        end

        return true
    end
end

local function is_reach(self, node)
    return Position.distance_squared(self.goal, node.position) < self.radius ^ 2
end

local function generate_path(self, node)
    local nodes = {}
    repeat
        table.insert(nodes, node)
        node = self.ptable[node.parent]
    until(node.parent == nil)

    local path_nodes = {}
    for i = #nodes, 1, -1 do
        table.insert(path_nodes, {
            position = nodes[i].position
        })
    end
    --log("generate path: " .. serpent.block(path_nodes))
    return Path:new(self.surface, path_nodes)
end

local function compute_cost(self, node)
    node.h = Position.distance(self.goal, node.position)
    node.key = node.g + node.h
end

local function handle_open_close(self, node)
    local k = pkey(node)
    local last = self.ptable[k]
    if last == nil then
        self.open_list:push(node)
    elseif node.key < last.key then
        if not last.open then
            self.open_list:push(node)
        else
            self.open_list:replace(last, node)
        end
    end
end

local _M = {}

function _M.run(self)
    local MAX_NODES = 20000
    local process_count = 0

    --log(string.format("running grid pathfinding algorithm from (%s, %s) to (%s, %s).", self.start.x, self.start.y, self.goal.x, self.goal.y))
    init_rendering(self)
    init_open_list(self)
    local cur = self.open_list:pop()
    while cur ~= nil do
        process_count = process_count + 1
        if process_count > MAX_NODES then
            log("process exceed " .. MAX_NODES .. " nodes, pathfinding failed.")
            return nil
        end
        log(string.format("current node(NO.%s) is: (%s, %s)).", process_count, cur.position.x, cur.position.y))
        for _, successor in pairs(SuccessorGenerator.generate(self, cur)) do
            --log(string.format("  processing successor (%s, %s)", successor.position.x, successor.position.y))
            local seen = update_from_ptable(self, successor)
            if not check_passable(self, successor) then
                goto continue
            end

            if (not seen) and is_reach(self, successor) then
                return generate_path(self, successor)
            end

            compute_cost(self, successor)
            handle_open_close(self, successor)
            ::continue::
            render_node(self, successor)
        end
        cur.open = false
        render_node(self, cur)
        cur = self.open_list:pop()
    end
    return nil
end

local mt = {
    __index = _M,
    __call = _M.run
}

local Engine = {}
function Engine.new(args)
    return setmetatable({
        surface = args.surface,
        bounding_box = args.bounding_box,
        collision_mask = args.collision_mask,
        start = args.start,
        goal = args.goal,
        radius = args.radius or 1,
        ptable = {}
    }, mt)
end

return Engine
