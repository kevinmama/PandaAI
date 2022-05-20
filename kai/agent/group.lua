local KC = require 'klib/container/container'
local Type = require 'klib/utils/type'
local Table = require 'klib/utils/table'
local Position = require 'klib/gmo/position'
local Direction = require 'klib/gmo/direction'
local Area = require 'klib/gmo/area'

local Agent = require 'kai/agent/agent'
local Unit = require 'kai/agent/unit'

local Group = KC.class('kai.agent.Group', Agent, function(self, props)
    Agent(self)
    self.valid = true

    props = props or {}
    self.surface = props.surface
    self.position = props.position
    self.direction_position = self.position
    self.direction = defines.direction.north
    self.force = props.force
    self.bounding_box = props.bounding_box or Area.unit
    self.member_ids = {}

    self.maximum_radius = props.maximum_radius or 16
    self.neighbours = {}
    self.neighbours_tick = game.tick
end)

Group:reference_objects("leader", "formation")

function Group:on_destroy()
    local formation = self:get_formation()
    if formation then formation:destroy() end
    Agent:on_destroy()
end

function Group:equals(agent)
    return KC.is_object(agent, Group) and self:get_id() == agent:get_id()
end

function Group:is_valid()
    return true
end

function Group:is_unit()
    return false
end

function Group:is_group()
    return true
end

function Group:get_surface()
    return self.surface
end

function Group:get_position()
    return self.position
end

function Group:get_direction()
    return self.direction
end

function Group:get_force()
    return self.force
end

function Group:get_bounding_box()
    return self.bounding_box
end

function Group:get_neighbours()
    if self.neighbours_tick ~= game.tick then
        local near_area = Position(self.position):expand_to_area(self.maximum_radius)
        self.neighbours = self.surface.find_entities_filtered({
            type = {'character', 'car'},
            area = near_area,
            force = self.force
        })
        self.neighbours_tick = game.tick
    end
    return self.neighbours
end

function Group:get_members()
    return Table.map(self.member_ids, function(member_id)
        return KC.get(member_id)
    end)
end

function Group:for_each_member(func)
    Table.each(self.member_ids, function(member_id, index)
        func(KC.get(member_id), index)
    end)
end

function Group:for_each_member_recursive(func)
    Table.each(self.member_ids, function(member_id, index)
        local agent = KC.get(member_id)
        func(agent, index)
        if KC.is_object(agent, Group) then
            agent:for_each_member_recursive(func)
        end
    end)
end

function Group:add_member(agent)
    -- 用 linked list 更好
    Table.insert(self.member_ids, agent:get_id())
    agent:set_group(self)
end

function Group:remove_member(agent)
    Table.array_remove_first_value(self.member_ids, agent:get_id())
    agent:set_group(nil)
end


function Group:set_leader(leader)
    if not KC.is_object(leader, Agent) then
        leader = Unit:new(leader, false)
    end
    self.leader_id = leader:get_id()
end

function Group:set_formation(formation, props)
    local prev_formation = self:get_formation()
    if prev_formation then prev_formation:destroy() end
    if KC.is_class(formation) then
        formation = formation:new(self, props)
    end
    self.formation_id = formation:get_id()
end

function Group:update_agent()
    self:update_position()
    local steer = self:get_steer()
    steer:reset()
    self:update_formation()
    self:get_behavior_controller():update()
    --steer:avoid_collision()
    if __DISPLAY_STEER__ then
        steer:display()
    end
end

function Group:update_formation()
    local formation = self:get_formation()
    if formation then formation:update() end

    local group = self:get_group()
    if group then
        local steer = self:get_steer()
        steer:force(group:get_steer():get_force())
        if self.formation_force then
            steer:force(self.formation_force)
        end
    end
end

--- 如果有领导者，中心是领导者，否则是成员的平均位置（去掉太偏离的成员）
function Group:update_position()
    local leader = self:get_leader()
    if leader then
        self.position = leader:get_position()
        if not self.hold_direction then
            self.direction = leader:get_direction()
        end
    else
        self:update_position_by_members()
    end
end

function Group:update_position_by_members()
    if Table.is_empty(self.member_ids) then return end

    local positions = Table.map(self.member_ids, function(member_id)
        return KC.get(member_id):get_position()
    end)

    local maximum_radius_square = self.maximum_radius * self.maximum_radius
    local avg = self.position
    local next_loop = true
    while next_loop do
        avg = Position.average(positions)
        local max_dist, max_i = 0, 0
        for i, position in ipairs(positions) do
            local dist = Position.distance_squared(position, avg)
            if dist > max_dist then
                max_dist, max_i = dist, i
            end
        end
        -- 每次去掉一个超出小队半径的成员并重计算
        if max_dist > maximum_radius_square then
            Table.remove(positions, max_i)
        else
            next_loop = false
        end
    end
    if not self.hold_direction and Position.manhattan_distance(self.direction_position, avg) > 5 then
        self.direction = Direction.from_positions(self.direction_position, avg, true)
        self.direction_position = avg
        --game.print(self:get_id() .. ' ' .. Direction.get_name(self.direction))
    end
    self.position = avg
end

return Group