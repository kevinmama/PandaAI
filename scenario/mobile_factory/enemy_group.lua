local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local Table = require 'klib/utils/table'
local Entity = require 'klib/gmo/entity'
local Config = require 'scenario/mobile_factory/config'
local Time = require 'stdlib/utils/defines/time'
local Area = require 'klib/gmo/area'
local Position = require 'klib/gmo/position'
local Chunk = require 'klib/gmo/chunk'

local MobileBase = require 'scenario/mobile_factory/base/mobile_base'

local CHUNK_SIZE = Config.CHUNK_SIZE
local MAX_GROUP_SIZE = 200
local MIN_GATHERING_TIME = 2 * Time.minute
local MAX_GATHERING_TIME = 10 * Time.minute
local TTL_AFTER_GATHERED = 3 * Time.minute

local SEARCH_RADIUS = 8 * CHUNK_SIZE
local ATTACK_AREA_RADIUS = CHUNK_SIZE

local EnemyGroup = {}
EnemyGroup = KC.class('scenario.MobileFactory.EnemyGroup', {
    -- 用 linked_list 实现更好
    group_map = {},
    "next_group_number",
}, function(self, group)
    self.group = group
    self.group_number = group.group_number
    self.tick = game.tick
    self.idle = true
    self.gathering_time = math.random(MIN_GATHERING_TIME, MAX_GATHERING_TIME)
    self.ttl = self.gathering_time + TTL_AFTER_GATHERED
    self.attacking_base = nil
    EnemyGroup:get_group_map()[self.group_number] = self
end)

Event.on_init(function()
    local s = game.map_settings.unit_group
    s.min_group_gathering_time = MAX_GATHERING_TIME + Time.minute
    s.max_group_gathering_time = MAX_GATHERING_TIME + Time.minute
    s.max_gathering_unit_groups = 30
    s.max_wait_time_for_late_members = Time.minute
    s.max_unit_group_size = MAX_GROUP_SIZE + 50
end)

--- 仅仅销毁包装类，其成员可能加入别的组
function EnemyGroup:on_destroy()
    EnemyGroup:get_group_map()[self.group_number] = nil
end

--- 当组生命周期结束时调用，删除组及其成员
function EnemyGroup:destroy_all()
    if self.group and self.group.valid then
        --game.print(string.format("group%s destroyed", Position.to_gps(self.group.position)))
        for _, member in pairs(self.group.members) do
            if member.valid then
                member.destroy()
            end
        end
        self.group.destroy()
    end
    self:destroy()
end

function EnemyGroup:is_valid()
    return self.group.valid
end

function EnemyGroup:can_set_off()
    return (game.tick >= self.tick + self.gathering_time or #self.group.members >= MAX_GROUP_SIZE)
        or (game.tick >= self.tick + MAX_GATHERING_TIME)
end

function EnemyGroup:update()
    if game.tick > self.tick + self.ttl then
        self:destroy_all()
        return
    end
    if self.idle and self:can_set_off() then
        self:update_command()
    end
end

function EnemyGroup:update_command()
    -- 寻找附近的蜘蛛，如果没有，就有污染最重的地方建基地
    -- 另外可以令虫子优先在有资源的地方建基地
    if self:attack_mobile_base()
    or self:attack_most_polluted_chunk() then
        --game.print("group command updated " .. RichText.gps(self.group.position))
    end
end

function EnemyGroup:attack_mobile_base()
    if KC.is_valid(self.attacking_base) and self.attacking_base:is_active()
            and not self.attacking_base:is_heavy_damaged() then
        self:set_attack_base_command(self.attacking_base)
        return true
    else
        local group = self.group
        local bases = Table.filter(MobileBase.find_bases_in_radius(group.position, SEARCH_RADIUS), function(base)
            return base:is_active() and not base:is_heavy_damaged()
        end)
        if next(bases) then
            local selected = math.random(#bases)
            local base = bases[selected]
            self.attacking_base = base
            self:set_attack_base_command(base)
            return true
        end
    end
end

function EnemyGroup:set_attack_base_command(base)
    local group = self.group
    local vehicle = base.vehicle
    group.set_command({
        type = defines.command.attack_area,
        destination = vehicle.position,
        radius = ATTACK_AREA_RADIUS
    })
    if group.valid then
        group.start_moving()
        self.idle = false
        --base.force.print("一波虫子正在靠近")
        --game.print(string.format("attacking vehicle %s from: %s",
        --        Position.to_gps(vehicle.position), RichText.gps(group.position)))
    end
end

function EnemyGroup:attack_most_polluted_chunk()
    local group = self.group
    local dest = group.position
    local max_pollution = 0
    Chunk.each_from_dimensions({width=SEARCH_RADIUS*2, height=SEARCH_RADIUS*2}, group.position, function(c_pos)
        local pos = Position.from_chunk_position(c_pos)
        local pollution = group.surface.get_pollution(pos)
        if pollution > max_pollution then
            max_pollution = pollution
            dest = pos
        end
    end)

    -- 如果目标地点已经有巢穴，就自毁以减少单位数
    local spawners = group.surface.find_entities_filtered({
        type = 'unit-spawner',
        area = Chunk.get_chunk_area_at_position(dest),
        force = 'enemy',
    })
    if next(spawners) then
        --game.print(string.format("destroy biters %s going to %s for saving ups", Position.to_gps(self.group.position), Position.to_gps(dest)))
        self:destroy_all()
        return
    end

    if Position.manhattan_distance(dest, group.position) > 2 * CHUNK_SIZE then
        group.set_command({
            type = defines.command.attack_area,
            destination = dest,
            radius = ATTACK_AREA_RADIUS
        })
        --game.print("attack area: " .. RichText.gps(dest))
    else
        group.set_command({
            type = defines.command.build_base,
            destination = dest,
        })
        --game.print(string.format("group %s build base at %s", self:get_id(), Position.to_gps(dest)))
    end
    if group.valid then -- set_command 之后有可能会失效
        group.start_moving()
    end
    self.idle = false
end

Event.register(defines.events.on_unit_group_created, function(event)
    --game.print("group created: " .. RichText.gps(event.group.position))
    EnemyGroup:new(event.group)
end)

Event.register(defines.events.on_ai_command_completed, function(event)
    local enemy_group = EnemyGroup:get_group_map()[event.unit_number]
    if enemy_group and enemy_group:is_valid() then
        --local position = enemy_group.group.position
        --if event.was_distracted then
            --enemy_group.group.set_autonomous()
            --enemy_group.idle = true
            --enemy_group:update()
        --end
        enemy_group.idle = true

        --game.print("group command completed: " .. RichText.gps(enemy_group.group.position) .. (enemy_group.idle and "idle" or ""))
    end
end)

EnemyGroup:on_nth_tick(5 * Time.second, function()
    local map = EnemyGroup:get_group_map()
    local next_group_number = EnemyGroup:get_next_group_number()
    local group_number, enemy_group

    if not next_group_number then
        group_number, enemy_group = next(map, next_group_number)
    else
        group_number, enemy_group = next_group_number, map[next_group_number]
    end

    -- 跳过所有被删除的组
    while group_number and not enemy_group do
        --game.print("handling group: " .. group_number .. " idle: " .. ((enemy_group and enemy_group.idle) and "true" or "false"))
        group_number, enemy_group = next(map, group_number)
    end

    if enemy_group then
        --game.print("handling group: " .. group_number .. " idle: " .. ((enemy_group and enemy_group.idle) and "true" or "false"))
        if enemy_group:is_valid() then
            enemy_group:update()
        else
            enemy_group:destroy()
        end
        group_number = next(map, group_number)
    end

    EnemyGroup:set_next_group_number(group_number)
end)

return EnemyGroup