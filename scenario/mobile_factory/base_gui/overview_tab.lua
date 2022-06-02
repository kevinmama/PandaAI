local KC = require 'klib/container/container'
local BaseComponent = require 'klib/fgui/base_component'
local gui = require 'flib/gui'

local Config = require 'scenario/mobile_factory/config'
local Team = require 'scenario/mobile_factory/player/team'
local MobileBase = require 'scenario/mobile_factory/base/mobile_base'

local OverviewTab = KC.singleton(Config.PACKAGE_BASE_GUI_PREFIX .. 'OverviewTab', BaseComponent, function(self)
    BaseComponent(self)
end)

function OverviewTab:create_tab_and_content_structure()
    return {
        tab = {
            type = "tab",
            caption = { "mobile_factory_base_gui.overview_tab_caption" },
        },
        content = {
            type = "label",
            caption = "Overview Tab"
        }
    }
end

function OverviewTab:on_selected(player_index)
    log("on click overview tab")
end

function OverviewTab:build_content(parent, player, refs)

end


return OverviewTab