-- 当玩家进入游戏时，给予玩家初始物品

local Event = require 'klib/event/event'
require 'modules/k_panel/k_panel'
require 'scenario/mobile_factory/team_gui'
require 'scenario/mobile_factory/minimap_gui'

require 'scenario/mobile_factory/mobile_base'
require 'scenario/mobile_factory/main_team'
require 'scenario/mobile_factory/misc'

Event.on_init(function()
    -- 用作 mod 时，跳过 freeplay 的场景和设置
    if remote.interfaces['freeplay'] then
        remote.call("freeplay", "")
        remote.call("freeplay", "set_disable_crashsite", true)
        remote.call("freeplay", "set_skip_intro", true)
        remote.call("freeplay", "set_created_items", {})
    end
end)
