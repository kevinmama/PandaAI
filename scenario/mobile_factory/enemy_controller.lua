local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local Entity = require 'klib/gmo/entity'
local Position = require 'klib/gmo/position'
local Config = require 'scenario/mobile_factory/config'

local MobileBase = require 'scenario/mobile_factory/base/mobile_base'

local CHUNK_SIZE = Config.CHUNK_SIZE

local EnemyController = KC.singleton('scenario.MobileFactory.EnemyController', function(self)

end)

EnemyController:on(defines.events.on_unit_group_created, function(self, event)
    game.print("group created: " .. Position.to_gps(event.group.position))
end)

EnemyController:on(defines.events.on_unit_group_finished_gathering, function(self, event)
    game.print("group finished gathering: " .. Position.to_gps(event.group.position).. " #members=" .. #event.group.members)
end)

--Event.register({ defines.events.on_unit_added_to_group, defines.events.on_unit_removed_from_group} , function(event)
--    local unit, group = event.unit, event.group
--    game.print(string.format("unit %s add to group %s", Position.to_gps(unit.position), Position.to_gps(group.position)))
--end)

Event.on_ai_command_completed(function(event)
    game.print(string.format("unit %s command completed: %s", Position.unit_number, event.result))
end)

Event.on_init(function()
    local s = game.map_settings.unit_group
    --s.min_group_gathering_time = 3600
    --s.max_group_gathering_time = 5 * 3600
    --s.max_gathering_unit_groups = 30
    --s.max_wait_time_for_late_members = 1800
end)

return EnemyController

