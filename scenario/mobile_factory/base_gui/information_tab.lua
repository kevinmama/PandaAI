local KC = require 'klib/container/container'
local Table = require 'klib/utils/table'
local SelectionTool = require 'klib/gmo/selection_tool'
local TabAndContent = require 'klib/fgui/tab_and_content'
local gui = require 'flib/gui'

local GE = require 'klib/fgui/gui_element'

local Config = require 'scenario/mobile_factory/config'
local Team = require 'scenario/mobile_factory/player/team'
local MobileBase = require 'scenario/mobile_factory/base/mobile_base'

local SelectBaseFlow = require 'scenario/mobile_factory/base_gui/information_tab_select_base_flow'
local StatusTable = require 'scenario/mobile_factory/base_gui/information_tab_status_table'
local IOBelts = require 'scenario/mobile_factory/base_gui/information_tab_io_belts'
local ResourceTable = require 'scenario/mobile_factory/base_gui/information_tab_resource_table'

local InformationTab = KC.class(Config.PACKAGE_BASE_GUI_PREFIX .. 'InformationTab', TabAndContent, function(self, tabbed_pane)
    TabAndContent(self, tabbed_pane)
    self.caption = {"mobile_factory_base_gui.information_tab_caption" }
    self.components = {}
    self:add_component(SelectBaseFlow:new(self), false)
    self:add_component(StatusTable:new(self))
    self:add_component(IOBelts:new(self))
    self:add_component(ResourceTable:new(self))
end)

InformationTab:define_player_data("selected_base_id")

function InformationTab:add_component(component, auto_update)
    Table.insert(self.components, component)
    if auto_update == nil then auto_update = true end
    component.auto_update = auto_update
end

function InformationTab:get_selected_base(player_index)
    local base_id = self:get_selected_base_id(player_index)
    return (base_id and KC.get(base_id)), base_id
end

function InformationTab:build_content(player, parent)
    for _, component in pairs(self.components) do
        component:build(player, parent)
    end
    self:update(player)
end

function InformationTab:update(player)
    for _, component in pairs(self.components) do
        if component.update then
            component:update(player)
        end
    end
end

function InformationTab:on_auto_update(player)
    for _, component in pairs(self.components) do
        if component.update and component.auto_update then
            component:update(player)
        end
    end
end

function InformationTab:on_selected(event, refs)
    self:update(GE.get_player(event))
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

SelectionTool.register_selection(Config.SELECTION_TYPE_SELECT_BASE, function(event)
    local team_id = Team.get_id_by_player_index(event.player_index)
    if team_id then
        local bases = MobileBase.find_bases_in_area(event.area, team_id)
        if next(bases) then
            local information_tab = KC.find_object(InformationTab, function() return true end)
            if information_tab then
                information_tab:set_selected_base_id(event.player_index, bases[1]:get_id())
                information_tab:update(GE.get_player(event))
            end
        end
    end
end)

InformationTab:on(Config.ON_PLAYER_ENTER_BASE, function(self, event)
    self:set_selected_base_id(event.player_index, event.base_id)
    self:update(GE.get_player(event))
end)

return InformationTab