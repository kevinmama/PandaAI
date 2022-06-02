local KC = require 'klib/container/container'
local Table = require 'klib/utils/table'
local ModGuiFrameButton = require 'klib/fgui/mod_gui_frame_button'
local gui = require 'flib/gui'

local Config = require 'scenario/mobile_factory/config'
local Team = require 'scenario/mobile_factory/player/team'
local MobileBase = require 'scenario/mobile_factory/base/mobile_base'

local OverviewTab = require 'scenario/mobile_factory/base_gui/overview_tab'
local InformationTab = require 'scenario/mobile_factory/base_gui/information_tab'

local MobileBaseGui = KC.singleton(Config.PACKAGE_BASE_GUI_PREFIX .. 'MobileBaseGui', ModGuiFrameButton, function(self)
    ModGuiFrameButton(self)
    self.mod_gui_sprite = "item/spidertron"
    self.mod_gui_tooltip = {"mobile_factory_base_gui.tooltip"}
    self.mod_gui_frame_caption = {"mobile_factory_base_gui.caption"}
    --self.mod_gui_frame_minimal_width = 0
    self:set_auto_update(true)
end)

--local Tabs = { OverviewTab, InformationTab }
local Tabs = { InformationTab }
function MobileBaseGui:for_each_tabs(func)
    for index, component in pairs(Tabs) do
        func(KC.get(component), index)
    end
end

function MobileBaseGui:build_frame_content(parent, player)
    local tabbed_pane = {
        type = "tabbed-pane",
        style = "tabbed_pane",
        ref = { "tabbed_pane" },
        style_mods = { horizontally_stretchable = true },
        actions = {
           on_selected_tab_changed = "on_selected_tab_changed"
        },
        tabs = {}
    }

    self:for_each_tabs(function(component, i)
        local tab = KC.get(component)
        tab.tab_index = i
        local structure = tab:create_tab_and_content_structure()
        structure.tab.ref = { "tabs", i }
        structure.content.ref = { "contents", i }
        table.insert(tabbed_pane.tabs, structure)
    end)
    local refs = gui.build(parent, { tabbed_pane })
    self:for_each_tabs(function(tab, i)
        local tab_refs = tab.refs[player.index]
        if not tab_refs then
            tab_refs = {}
            tab.refs[player.index] = tab_refs
        end
        tab_refs.tabbed_pane = refs.tabbed_pane
        tab_refs.tab = refs.tabs[i]
        tab_refs.content = refs.contents[i]
        tab:build_content(tab_refs.content, player, tab_refs)
    end)
    refs.tabbed_pane.selected_tab_index = 1
    return refs
end

function MobileBaseGui:is_on_selected_tab_changed(event, refs)
    return event.element == refs.tabbed_pane
end

function MobileBaseGui:on_selected_tab_changed(event, refs)
    local tab = KC.get(Tabs[refs.tabbed_pane.selected_tab_index])
    if tab.on_selected then
        tab:on_selected(event.player_index)
    end
end

function MobileBaseGui:post_build(refs, player)
    gui.update(refs.mod_gui_button, {
        elem_mods = {visible = false, mouse_button_filter = {"left", "right"}},
    })
end

function MobileBaseGui:on_click(event, refs)
    if event.button == defines.mouse_button_type.left then
        ModGuiFrameButton.on_click(self, event, refs)
    elseif event.button == defines.mouse_button_type.right then
        local player = game.get_player(event.player_index)
        local base = MobileBase.get_by_controller(player) or MobileBase.get_by_visitor(player)
        if base then
            base:toggle_working_state()
        else
            player.print({"mobile_factory.require_driving_or_remote"})
        end
    end
end

function MobileBaseGui:update(event)
    local refs = self.refs[event.player_index]
    refs.mod_gui_button.visible = nil ~= Team.get_by_player_index(event.player_index)
end

function MobileBaseGui:on_auto_update(player)
    local selected_tab = KC.get(Tabs[self.refs[player.index].tabbed_pane.selected_tab_index])
    if selected_tab.on_auto_update then
        selected_tab:on_auto_update(player)
    end
end

function MobileBaseGui:on_open_frame(event, refs)
    local selected_tab = KC.get(Tabs[self.refs[event.player_index].tabbed_pane.selected_tab_index])
    if selected_tab.on_open_frame then
        selected_tab:on_open_frame(event)
    end
end

MobileBaseGui:on(Config.ON_PLAYER_JOINED_TEAM, function(self, event)
    self:update(event)
end)

MobileBaseGui:on(Config.ON_PLAYER_LEFT_TEAM, function(self, event)
    self:update(event)
end)

MobileBaseGui:on(Config.ON_BASE_CREATED, function(self, event)
    local team = KC.get(event.team_id)
    if team and team.captain then
        self:update({
            player_index = team.captain.index
        })
    end
end)

return MobileBaseGui
