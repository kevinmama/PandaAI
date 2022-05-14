local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local Entity = require 'klib/gmo/entity'
local Config = require 'scenario/mobile_factory/config'
local MobileBase = require 'scenario/mobile_factory/mobile_base'
local Time = require 'stdlib/utils/defines/time'
local Area = require 'klib/gmo/area'
local Position = require 'klib/gmo/position'
local Chunk = require 'klib/gmo/chunk'
local RichText = require 'klib/gmo/rich_text'

local CHUNK_SIZE = Config.CHUNK_SIZE
local GROUP_SIZE = 50
local MAXIMAL_GATHERING_TIME = 2 * Time.minute

local SEARCH_RADIUS = 8 * CHUNK_SIZE
local ATTACK_AREA_RADIUS = CHUNK_SIZE / 2

local EnemyGroup = {}
EnemyGroup = KC.class('scenario.MobileFactory.EnemyGroup', {
    -- 用 linked_list 实现更好
    group_list = {},
    group_map = {},
    next_slot = 1
}, function(self, group)
    self.group = group
    self.group_number = group.group_number
    self.tick = game.tick
    self.idle = true
    EnemyGroup:get_group_map()[self.group_number] = self:get_id()
end)

function EnemyGroup:on_destroy()
    EnemyGroup:get_group_map()[self.group_number] = nil
end

function EnemyGroup:is_valid()
    return self.group.valid
end

function EnemyGroup:update()
    if not self.idle then return end
    if game.tick > self.tick + MAXIMAL_GATHERING_TIME then
        self:find_base_to_attack(self.group)
        if self.idle then
            self:attack_most_polluted_chunk()
        end
    end
end

function EnemyGroup:find_base_to_attack()
    local group = self.group
    -- 寻找附近的蜘蛛，如果没有，就有污染最重的地方建基地
    local vehicles = group.surface.find_entities_filtered({
        name = Config.BASE_VEHICLE_NAME,
        position = group.position,
        radius = SEARCH_RADIUS,
    })
    -- 如果是基地
    for _, vehicle in pairs(vehicles) do
        local base = MobileBase.get_by_vehicle(vehicle)
        if base and base:is_online() then
            group.set_command({
                type = defines.command.attack_area,
                destination = vehicle.position,
                radius = ATTACK_AREA_RADIUS
            })
            if group.valid then
                group.start_moving()
                --base.force.print("一波虫子正在靠近")
                --game.print("attacking vehicle from: " .. RichText.gps(group.position))
            end
            self.idle = false
        end
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

    if Position.manhattan_distance(dest, group.position) > CHUNK_SIZE then
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
        --game.print("build base: " .. RichText.gps(dest))
    end
    if group.valid then
        group.start_moving()
    end
    self.idle = false
end

Event.register(defines.events.on_unit_group_created, function(event)
    --game.print("group created: " .. RichText.gps(event.group.position))
    local list = EnemyGroup:get_group_list()
    local enemy_group = EnemyGroup:new(event.group)
    table.insert(list, enemy_group:get_id())
end)

Event.register(defines.events.on_ai_command_completed, function(event)
    local enemy_group_id = EnemyGroup:get_group_map()[event.unit_number]
    local enemy_group = enemy_group_id and KC.get(enemy_group_id)
    if enemy_group and enemy_group:is_valid() then
        local position = enemy_group.group.position
        --if not event.was_distracted then
        --    enemy_group.idle = true
        --    --enemy_group:update()
        --end
        enemy_group.idle = true

        --game.print("group command completed: " .. RichText.gps(position) .. (enemy_group.idle and "idle" or ""))
    end
end)

EnemyGroup:on_nth_tick(5 * Time.second, function()
    local list = EnemyGroup:get_group_list()
    local next_slot = EnemyGroup:get_next_slot()
    local group_id = list[next_slot]
    if group_id then
        local enemy_group = KC.get(group_id)
        if enemy_group:is_valid() then
            enemy_group:update()
        else
            enemy_group:destroy()
            table.remove(list, next_slot)
        end
    end
    next_slot = next_slot + 1
    if next_slot > #list then
        next_slot = 1
    end
    EnemyGroup:set_next_slot(next_slot)
end)

return EnemyGroup