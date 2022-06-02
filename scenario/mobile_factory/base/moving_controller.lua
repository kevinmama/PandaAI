local KC = require 'klib/container/container'
local Position = require 'klib/gmo/position'

local Config = require 'scenario/mobile_factory/config'
local WorkingState = require 'scenario/mobile_factory/base/working_state'

local MovingController = KC.class(Config.PACKAGE_BASE_PREFIX .. 'MovingController', function(self, base)
    self.base = base
end)

function MovingController:update()
    local base = self.base
    local vehicle_position = base.vehicle.position
    local moving = not Position.equals(vehicle_position, base.last_vehicle_position)
    if moving then
        base.last_vehicle_position = vehicle_position
    end
    if moving ~= base.moving then
        base.moving = moving
        base.moving_tick = game.tick
    end
end

--- 更新非移动模式下基地的速度
function MovingController:update_movement()
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

return MovingController

