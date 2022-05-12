local KC = require 'klib/container/container'
local Entity = require 'klib/gmo/entity'
local Config = require 'scenario/mobile_factory/config'
local MobileBase = require 'scenario/mobile_factory/mobile_base'

local CHUNK_SIZE = Config.CHUNK_SIZE

local EnemyController = KC.singleton('scenario.MobileFactory.EnemyController', function(self)

end)

function EnemyController:on_unit_group_finished_gathering(group)
    local found = self:find_base_to_attack(group)
    if not found then
        game.print("虫子正在建新基地")
    end
end

function EnemyController:find_base_to_attack(group)
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
                type = defines.command.attack,
                target = vehicle
            })
            group.start_moving()
            base.force.print("一波虫子正在靠近")
            return true
        end
    end
    return false
end

EnemyController:on(defines.events.on_unit_group_created, function(self, event)
    game.print("group created: [gps=" .. event.group.position.x .. ',' .. event.group.position.y .. ']')
end)

EnemyController:on(defines.events.on_unit_group_finished_gathering, function(self, event)
    game.print("group finished gathering: [gps=" .. event.group.position.x .. ',' .. event.group.position.y .. ']')
    self:on_unit_group_finished_gathering(event.group)
end)

return EnemyController

