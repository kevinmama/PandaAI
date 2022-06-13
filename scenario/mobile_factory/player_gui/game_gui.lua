local KC = require 'klib/container/container'
local ModGuiFrameButton = require 'klib/fgui/mod_gui_frame_button'
local TabbedPane = require 'klib/fgui/tabbed_pane'
local Config = require 'scenario/mobile_factory/config'
local MapInfoTab = require 'modules/gui/map_info_tab'

local TeamOverviewTab = require 'scenario/mobile_factory/player_gui/team_overview_tab'
local TeamOperationTab = require 'scenario/mobile_factory/player_gui/team_operation_tab'

local GameTabbedPane = KC.class(Config.PACKAGE_PLAYER_GUI_PREFIX .. 'GameTabbedPane', TabbedPane, function(self)
    TabbedPane(self)

    local map_info_tab = MapInfoTab:new(self)
    map_info_tab.map_info_main_caption = {"mobile_factory_player_gui.map_info_main_caption"}
    map_info_tab.map_info_sub_caption = {"mobile_factory_player_gui.map_info_sub_caption"}
    map_info_tab.map_info_text = {"mobile_factory_player_gui.map_info_text"}
    self:add_tab(map_info_tab)
    self:add_tab(TeamOverviewTab:new(self))
    self:add_tab(TeamOperationTab:new(self))
end)


local GameGui = KC.singleton(Config.PACKAGE_PLAYER_GUI_PREFIX .. 'GameGui', ModGuiFrameButton, function(self)
    ModGuiFrameButton(self)
    self.mod_gui_sprite = "virtual-signal/signal-G"
    self.mod_gui_tooltip = {"mobile_factory_player_gui.game_gui_button_tooltip"}
    self.mod_gui_frame_caption = {"mobile_factory_player_gui.game_gui_frame_caption"}
    self.tabbed_pane = GameTabbedPane:new()
end)

function GameGui:build_frame_content(player, parent)
    return self.tabbed_pane:build(player, parent)
end

function GameGui:post_build(player, refs)
    self:open_mod_gui_frame({player_index = player.index}, refs)
end

return GameGui