local KC = require 'klib/container/container'
local Table = require 'klib/utils/table'
local BaseComponent = require 'klib/fgui/base_component'
local gui = require 'flib/gui'

local GE = require 'klib/gmo/gui_element'

local Config = require 'scenario/mobile_factory/config'
local Team = require 'scenario/mobile_factory/player/team'
local MobileBase = require 'scenario/mobile_factory/base/mobile_base'

local SelectBaseFlow = require 'scenario/mobile_factory/base_gui/information_tab_select_base_flow'
local StatusTable = require 'scenario/mobile_factory/base_gui/information_tab_status_table'
local ResourceTable = require 'scenario/mobile_factory/base_gui/information_tab_resource_table'

local InformationTab = KC.singleton(Config.PACKAGE_BASE_GUI_PREFIX .. 'InformationTab', BaseComponent, function(self)
    BaseComponent(self)
end)

InformationTab:define_player_data("selected_base_id")

local Components = { SelectBaseFlow, StatusTable, ResourceTable}
for _, component in pairs(Components) do Table.merge(InformationTab, component.actions) end

function InformationTab:get_selected_base(player_index)
    local base_id = self:get_selected_base_id(player_index)
    return (base_id and KC.get(base_id)), base_id
end

function InformationTab:create_tab_and_content_structure()
    return {
        tab = { type = "tab", caption = {"mobile_factory_base_gui.information_tab_caption" }},
        content = { type = "frame", direction = 'vertical' }
    }
end

function InformationTab:build_content(parent, player, refs)
    for _, component in pairs(Components) do
        Table.merge(refs, gui.build(parent, component.create_structures()))
        if component.post_build then
            component.post_build(self, player, refs)
        end
    end
end
function InformationTab:on_auto_update(player)
    local refs = self.refs[player.index]
    self:update_contents(player, refs)
end

function InformationTab:update_contents(player, refs)
    StatusTable.update(self, player, refs)
    ResourceTable.update(self, refs, self:get_selected_base_id(player.index))
end

function InformationTab:is_selected(player_index)
    return self.refs[player_index].tabbed_pane.selected_tab_index == self.tab_index
end

function InformationTab:on_selected(player_index)
    self:refresh(player_index)
end

function InformationTab:on_open_frame(event)
    self:refresh(event.player_index)
end

function InformationTab:refresh(player_index)
    local refs = self.refs[player_index]
    local player = game.get_player(player_index)
    SelectBaseFlow.update(self, player, refs)
    self:update_contents(player, refs)
end


--InformationTab:on({Config.ON_BASE_CREATED, Config.ON_PRE_BASE_DESTROYED}, function(self, event)
--    local team = KC.get(event.base_id).team
--    local players = team:get_members()
--    for _, player in pairs(players) do
--        local selected_base_id = self:get_selected_base_id(player)
--        if selected_base_id == event.base_id then
--            self:set_selected_base_id(player, nil)
--        end
--        self:update_select_base_drop_down(player, self.refs[player.index])
--    end
--end)

return InformationTab