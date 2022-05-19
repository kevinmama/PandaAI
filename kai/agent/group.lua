local KC = require 'klib/container/container'
local Table = require 'klib/utils/table'
local Position = require 'klib/gmo/position'
local Area = require 'klib/gmo/area'
local Math = require 'stdlib/utils/math'

local Agent = require 'kai/agent/agent'
local Unit = require 'kai/agent/unit'
local Formations = require 'kai/agent/formations'

local Group = KC.class('kai.agent.Group', Agent, function(self, props)
    Agent(self)
    self.valid = true

    props = props or {}
    self.surface = props.surface
    self.position = props.position
    self.force = props.force
    self.bounding_box = props.bounding_box or Area.unit
    self.member_ids = {}

    self.maximum_radius = props.maximum_radius or 16
    self.neighbours = {}
    self.neighbours_tick = game.tick
end)

Group:reference_objects("leader")

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

function Group:update_agent()
    self:update_position()
    local steer = self:get_steer()
    steer:reset()
    self:get_behavior_controller():update()
    --steer:avoid_collision()
    steer:display()
end

function Group:set_formation(formation_id)
    self.formation_id = formation_id
end

function Group:get_formation()
    return self.formation_id and Formations[self.formation_id]
end

function Group:next_formation_position()
    self.formation_position = self.formation_position + 1
    return self.formation_position
end

--- 如果有领导者，中心是领导者，否则是成员的平均位置（去掉太偏离的成员）
function Group:update_position()
    local leader = self:get_leader()
    if leader then
        self.position = leader:get_position()
        return
    end

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
    self.position = avg
end

return Group