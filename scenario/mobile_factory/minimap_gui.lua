local KC = require 'klib/container/container'
local ModGuiFrame = require 'klib/fgui/mod_gui_frame'
local MobileBase = require 'scenario/mobile_factory/mobile_base'
local Team = require 'scenario/mobile_factory/team'
local Config = require 'scenario/mobile_factory/config'

local MinimapGui = KC.singleton('scenario.MobileFactory.MinimapGui', ModGuiFrame, function(self)
    ModGuiFrame(self)
    self.mod_gui_sprite = "virtual-signal/signal-M"
    self.mod_gui_tooltip = {"mobile_factory.mod_gui_minimap_tooltip"}
    self.mod_gui_frame_caption = {"mobile_factory.mod_gui_minimap_caption"}
    self.mod_gui_frame_minimal_width = 0
end)

function MinimapGui:build_main_frame_structure()
    return {
        type = "minimap",
        ref = {"minimap"},
        elem_mods = {visible = false}
    }
end


function MinimapGui:post_build_mod_gui_frame(data, player)
    data.refs.mod_gui_button.visible = false
end

function MinimapGui:update_minimap(event)
    local base = MobileBase.get_by_player_index(event.player_index)
    local data = self.data[event.player_index]
    data.refs.mod_gui_button.visible = base ~= nil
    local minimap = data.refs.minimap
    minimap.visible = base ~= nil
    if base then
        minimap.entity = base.vehicle
    end
end

MinimapGui:on(Config.ON_PLAYER_JOINED_TEAM_EVENT, function(self, event)
    self:update_minimap(event)
end)

MinimapGui:on(Config.ON_PLAYER_LEFT_TEAM_EVENT, function(self, event)
    self:update_minimap(event)
end)

MinimapGui:on(Config.ON_MOBILE_BASE_CREATED_EVENT, function(self, event)
    local team = KC.get(event.team_id)
    if team and team.captain then
        self:update_minimap({
            player_index = team.captain
        })
    end
end)


return MinimapGui