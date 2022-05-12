local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local Entity = require 'klib/gmo/entity'
local Config = require 'scenario/mobile_factory/config'
local MobileBase = require 'scenario/mobile_factory/mobile_base'
local Time = require 'stdlib/utils/defines/time'

local CHUNK_SIZE = Config.CHUNK_SIZE
local GROUP_SIZE = 50
local MAXIMAL_GATHERING_TIME = 2 * Time.minute

local EnemyGroup = KC.singleton('scenario.MobileFactory.EnemyGroup', {
    -- 用 linked_list 实现更好
    group_list = {},
    next_slot = 1
},function(self, group)
    self.group = group
    self.tick = game.tick
    self.idle = true
end)

function EnemyGroup:is_valid()
    return self.group.valid
end

function EnemyGroup:update()
    if not self.idle then return end
    if game.tick > self.tick + MAXIMAL_GATHERING_TIME or #self.group.members >= GROUP_SIZE then
        self:find_base_to_attack(self.group)
    end
end

function EnemyGroup:find_base_to_attack(group)
    -- 寻找附近的蜘蛛，如果没有，就有污染最重的地方建基地
    local vehicles = group.surface.find_entities_filtered({
        name = Config.BASE_VEHICLE_NAME,
        position = group.position,
        radius = 16 * CHUNK_SIZE
    })
    -- 如果是基地
    for _, vehicle in pairs(vehicles) do
        local base = MobileBase.get_by_vehicle(vehicle)
        if base and base:is_online() then
            group.set_command({
                type = defines.command.attack_area,
                destination = vehicle.position,
                radius = CHUNK_SIZE
            })
            group.start_moving()
            base.force.print("一波虫子正在靠近")
            self.idle = false
            return true
        end
    end
    return false
end

Event.register(defines.events.on_unit_group_created, function(event)
    game.print("group created: [gps=" .. event.group.position.x .. ',' .. event.group.position.y .. ']')
    local list = EnemyGroup:get_group_list()
    local enemy_group = EnemyGroup:new(event.group)
    table.insert(list, enemy_group:get_id())
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