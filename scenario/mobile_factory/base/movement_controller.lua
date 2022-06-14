local KC = require 'klib/container/container'
local Area = require 'klib/gmo/area'
local Position = require 'klib/gmo/position'

local Config = require 'scenario/mobile_factory/config'
local WorkingState = require 'scenario/mobile_factory/base/working_state'

local MovementController = KC.class(Config.PACKAGE_BASE_PREFIX .. 'MovementController', function(self, base)
    self.base = base
end)

function MovementController:move_to_position(position)
    if Area.is_area(position) then
        position = position.left_top
    end
    if self.base.vehicle.valid then
        self.base.vehicle.autopilot_destination = position
    end
end

function MovementController:follow_target(target, offset)
    local vehicle = self.base.vehicle
    if vehicle.valid then
        vehicle.follow_target = target
        if offset then
            vehicle.follow_offset = offset
        end
    end
end

--function MovementController:update()
--end

--- 更新非移动模式下基地的速度
function MovementController:update_movement()
    local base = self.base
    if base.online and base.vehicle and base.working_state.current ~= WorkingState.MOVING then
        base.vehicle.autopilot_destination = base.station_position
        local driver = base.vehicle.get_driver()
        if driver then
            driver.walking_state = { walking = false }
        end
    end

    -- 利用 teleport 实现速度控制
    --if self.online and self.vehicle and self.working_state == Config.BASE_WORKING_STATE_MOVING then
    --    local speed = self.vehicle.speed
    --    if self.vehicle.speed > 0 then
    --        local driver = self.vehicle.get_driver()
    --        local walking_state = driver and driver.walking_state
    --        if walking_state.walking then
    --            local pos = Position(self.vehicle.position) + Direction.to_vector(walking_state.direction, -0.5*self.vehicle.speed)
    --            self.vehicle.teleport(pos)
    --        else
    --            -- 自动驾驶调速
    --        end
    --    end
    --end
end

return MovementController

