local KC = require 'klib/container/container'
local ModGuiFrame = require 'klib/fgui/mod_gui_frame'
local MobileBase = require 'scenario/mobile_factory/mobile_base'
local Config = require 'scenario/mobile_factory/config'
local gui = require 'flib/gui'

local MobileBaseGui = KC.singleton('scenario.MobileFactory.MobileBaseGui', ModGuiFrame, function(self)
    ModGuiFrame(self)
    self.mod_gui_sprite = "item/spidertron"
    self.mod_gui_tooltip = {"mobile_factory.mod_gui_mobile_base_tooltip"}
    self.mod_gui_frame_caption = {"mobile_factory.mod_gui_mobile_base_caption"}
    self.mod_gui_frame_minimal_width = 0
end)

function MobileBaseGui:build_main_frame_structure(refs)
    return {}
end


function MobileBaseGui:post_build_mod_gui_frame(refs, player)
    gui.update(refs.mod_gui_button, {
        elem_mods = {visible = false, mouse_button_filter = {"left", "right"}},
    })
end

function MobileBaseGui:toggle_mod_gui_frame(event, refs)
    if event.button == defines.mouse_button_type.left then
        ModGuiFrame.toggle_mod_gui_frame(self, event, refs)
    elseif event.button == defines.mouse_button_type.right then
        MobileBase.get_by_player_index(event.player_index):toggle_working_state()
    end
end

function MobileBaseGui:update_mod_gui_button(event)
    local base = MobileBase.get_by_player_index(event.player_index)
    local refs = self.refs[event.player_index]
    refs.mod_gui_button.visible = base ~= nil
end

MobileBaseGui:on(Config.ON_PLAYER_JOINED_TEAM, function(self, event)
    self:update_mod_gui_button(event)
end)

MobileBaseGui:on(Config.ON_PLAYER_LEFT_TEAM, function(self, event)
    self:update_mod_gui_button(event)
end)

MobileBaseGui:on(Config.ON_MOBILE_BASE_CREATED, function(self, event)
    local team = KC.get(event.team_id)
    if team and team.captain then
        self:update_mod_gui_button({
            player_index = team.captain
        })
    end
end)

return MobileBaseGui
