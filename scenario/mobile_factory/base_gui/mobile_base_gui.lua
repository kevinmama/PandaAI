local KC = require 'klib/container/container'
local GE = require 'klib/fgui/gui_element'
local ModGuiFrameButton = require 'klib/fgui/mod_gui_frame_button'
local TabbedPane = require 'klib/fgui/tabbed_pane'

local Config = require 'scenario/mobile_factory/config'
local Team = require 'scenario/mobile_factory/player/team'
local MobileBase = require 'scenario/mobile_factory/base/mobile_base'

--local OverviewTab = require 'scenario/mobile_factory/base_gui/overview_tab'
local InformationTab = require 'scenario/mobile_factory/base_gui/information_tab'
local ResourcesTab = require 'scenario/mobile_factory/base_gui/resources_tab'
local LinkTab = require 'scenario/mobile_factory/base_gui/link_tab'

local MobileBaseTabbedPane = KC.class(Config.PACKAGE_BASE_GUI_PREFIX .. 'MobileBaseTabbedPane', TabbedPane, function(self)
    TabbedPane(self)
    self:add_tab(InformationTab:new(self))
    self:add_tab(ResourcesTab:new(self))
    self:add_tab(LinkTab:new(self))
end)

function MobileBaseTabbedPane:update(player)
    self:get_selected_tab(player.index):update(player)
end

function MobileBaseTabbedPane:on_auto_update(player)
    self:get_selected_tab(player.index):on_auto_update(player)
end

local MobileBaseGui = KC.singleton(Config.PACKAGE_BASE_GUI_PREFIX .. 'MobileBaseGui', ModGuiFrameButton, function(self)
    ModGuiFrameButton(self)
    self.mod_gui_sprite = "item/spidertron"
    self.mod_gui_tooltip = {"mobile_factory_base_gui.tooltip"}
    self.mod_gui_frame_caption = {"mobile_factory_base_gui.caption"}
    self:set_auto_update(true)

    self.tabbed_pane = MobileBaseTabbedPane:new()
end)

function MobileBaseGui:build_frame_content(player, parent)
    local refs = self.tabbed_pane:build(player, parent)
    self:update(player)
    return refs
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

function MobileBaseGui:update(player)
    local refs = self.refs[player.index]
    refs.mod_gui_button.visible = nil ~= Team.get_by_player_index(player.index)
    if not refs.mod_gui_button.visible then
        self:close_mod_gui_frame({player_index = player.index}, refs)
    else
        self.tabbed_pane:update(player)
    end
end

function MobileBaseGui:on_auto_update(player)
    self.tabbed_pane:on_auto_update(player)
end

function MobileBaseGui:on_open_frame(event, refs)
    self:update(GE.get_player(event))
end

MobileBaseGui:on({Config.ON_PLAYER_JOINED_TEAM, Config.ON_PLAYER_LEFT_TEAM}, function(self, event)
    self:update(GE.get_player(event))
end)

MobileBaseGui:on(Config.ON_BASE_CREATED, function(self, event)
    local team = KC.get(event.team_id)
    if team and team.captain then
        self:update(team.captain.player)
    end
end)

return MobileBaseGui
