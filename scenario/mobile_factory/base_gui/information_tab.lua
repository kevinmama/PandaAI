local KC = require 'klib/container/container'
local Config = require 'scenario/mobile_factory/config'

local SelectedBaseTab = require 'scenario/mobile_factory/base_gui/selected_base_tab'
local StatusTable = require 'scenario/mobile_factory/base_gui/information_tab_status_table'

local InformationTab = KC.class(Config.PACKAGE_BASE_GUI_PREFIX .. 'InformationTab', SelectedBaseTab, function(self, tabbed_pane)
    SelectedBaseTab(self, tabbed_pane)
    self.caption = {"mobile_factory_base_gui.information_tab_caption" }
    self:add_component(StatusTable:new(self))
end)

return InformationTab