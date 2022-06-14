local KC = require 'klib/container/container'
local Table = require 'klib/utils/table'
local SelectionTool = require 'klib/gmo/selection_tool'
local TabAndContent = require 'klib/fgui/tab_and_content'

local GE = require 'klib/fgui/gui_element'

local Config = require 'scenario/mobile_factory/config'
local Team = require 'scenario/mobile_factory/player/team'
local MobileBase = require 'scenario/mobile_factory/base/mobile_base'

local SelectBaseFlow = require 'scenario/mobile_factory/base_gui/select_base_flow'

local SelectedBaseTab = KC.class(Config.PACKAGE_BASE_GUI_PREFIX .. 'SelectedBaseTab', TabAndContent, function(self, tabbed_pane)
    TabAndContent(self, tabbed_pane)
    self.components = {}
    self:add_component(SelectBaseFlow:new(self), false)
end)

SelectedBaseTab:define_player_data("selected_base_id")

function SelectedBaseTab:add_component(component, auto_update)
    Table.insert(self.components, component)
    if auto_update == nil then auto_update = true end
    component.auto_update = auto_update
end

function SelectedBaseTab:get_selected_base(player_index)
    local base_id = self:get_selected_base_id(player_index)
    return (base_id and KC.get(base_id)), base_id
end

function SelectedBaseTab:build_content(player, parent)
    for _, component in pairs(self.components) do
        component:build(player, parent)
    end
    self:update(player)
end

function SelectedBaseTab:update(player)
    for _, component in pairs(self.components) do
        if component.update then
            component:update(player)
        end
    end
end

function SelectedBaseTab:on_auto_update(player)
    for _, component in pairs(self.components) do
        if component.update and component.auto_update then
            component:update(player)
        end
    end
end

function SelectedBaseTab:on_selected(event, refs)
    self:update(GE.get_player(event))
end

SelectionTool.register_selection(Config.SELECTION_TYPE_SELECT_BASE, function(event)
    local team_id = Team.get_id_by_player_index(event.player_index)
    if team_id then
        local bases = MobileBase.find_bases_in_area(event.area, team_id)
        if next(bases) then
            KC.for_each_object(SelectedBaseTab, function(tab)
                tab:set_selected_base_id(event.player_index, bases[1]:get_id())
                tab:update(GE.get_player(event))
            end)
        end
    end
end)

SelectedBaseTab:on(Config.ON_PLAYER_ENTER_BASE, function(self, event)
    self:set_selected_base_id(event.player_index, event.base_id)
    self:update(GE.get_player(event))
end)

SelectedBaseTab:on(defines.events.on_selected_entity_changed, function(self, event)
    local base = MobileBase.get_by_vehicle(event.last_entity)
    local player = game.get_player(event.player_index)
    if base and base.force == player.force then
        self:set_selected_base_id(event.player_index, base:get_id())
        self:update(player)
    end
end)

return SelectedBaseTab