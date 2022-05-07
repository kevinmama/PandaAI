-- 当玩家进入游戏时，给予玩家初始物品

local Event = require 'klib/event/event'
require 'modules/k_panel/k_panel'

require 'scenario/mobile_factory/mobile_base_manager'
require 'scenario/mobile_factory/team_gui'

Event.on_init(function()
    if remote.interfaces['freeplay'] then
        remote.call("freeplay", "set_disable_crashsite", true)
        remote.call("freeplay", "set_created_items", {})
    end
end)
