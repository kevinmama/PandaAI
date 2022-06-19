local KC = require 'klib/container/container'
local Config = require 'scenario/mobile_factory/config'

local SelectedBaseTab = require 'scenario/mobile_factory/base_gui/selected_base_tab'
local LinkedBeltTable = require 'scenario/mobile_factory/base_gui/linked_belt_table'

local LinkTab = KC.class(Config.PACKAGE_BASE_GUI_PREFIX .. 'LinkTab', SelectedBaseTab, function(self, tabbed_pane)
    SelectedBaseTab(self, tabbed_pane)
    self.caption = {"mobile_factory_base_gui.link_tab_caption" }
    self:add_component(LinkedBeltTable:new(self))
end)

return LinkTab
