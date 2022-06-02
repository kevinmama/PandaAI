local Event = require 'klib/event/event'

require 'modules/k_panel/k_panel'
require 'scenario/mobile_factory/player/team_gui'
require 'scenario/mobile_factory/base_gui/mobile_base_gui'
require 'scenario/mobile_factory/base_gui/minimap_gui'
require 'scenario/mobile_factory/player/recharge_gui'
require 'scenario/mobile_factory/player/spectator_gui'

require 'modules/distribute_button'
require 'modules/collect_output_button'
require 'modules/clear_corpse_button'

require 'scenario/mobile_factory/base/team_center'

--require 'scenario/mobile_factory/enemy_controller'
require 'scenario/mobile_factory/enemy_group'

require 'scenario/mobile_factory/misc'
require 'scenario/mobile_factory/debug'

Event.on_init(function()
    -- 用作 mod 时，跳过 freeplay 的场景和设置
    if remote.interfaces['freeplay'] then
        remote.call("freeplay", "set_disable_crashsite", true)
        remote.call("freeplay", "set_skip_intro", true)
        remote.call("freeplay", "set_created_items", {})
    end

    --game.map_settings.enemy_expansion.enabled = false
end)


