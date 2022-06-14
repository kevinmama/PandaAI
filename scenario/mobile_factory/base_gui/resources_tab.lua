local KC = require 'klib/container/container'
local Config = require 'scenario/mobile_factory/config'

local SelectedBaseTab = require 'scenario/mobile_factory/base_gui/selected_base_tab'
local PowerStatusFlow = require 'scenario/mobile_factory/base_gui/resources_tab_power_status_flow'
local ResourceTable = require 'scenario/mobile_factory/base_gui/resources_tab_resource_table'

local ResourcesTab = KC.class(Config.PACKAGE_BASE_GUI_PREFIX .. 'ResourcesTab', SelectedBaseTab, function(self, tabbed_pane)
    SelectedBaseTab(self, tabbed_pane)
    self.caption = {"mobile_factory_base_gui.resources_tab_caption" }
    self:add_component(PowerStatusFlow:new(self))
    self:add_component(ResourceTable:new(self))
end)

return ResourcesTab
