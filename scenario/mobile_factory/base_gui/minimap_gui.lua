local KC = require 'klib/container/container'
local ModGuiFrameButton = require 'klib/fgui/mod_gui_frame_button'
local Config = require 'scenario/mobile_factory/config'
local MobileBase = require 'scenario/mobile_factory/base/mobile_base'

local MinimapGui = KC.singleton(Config.PACKAGE_BASE_GUI_PREFIX .. 'MinimapGui', ModGuiFrameButton, function(self)
    ModGuiFrameButton(self)
    self.mod_gui_sprite = "virtual-signal/signal-M"
    self.mod_gui_tooltip = {"mobile_factory.mod_gui_minimap_tooltip"}
    self.mod_gui_frame_caption = {"mobile_factory.mod_gui_minimap_caption"}
    self.mod_gui_frame_minimal_width = 0
    self.close_others_on_open = false
    self.ignore_close_others_on_open = true
end)

function MinimapGui:create_frame_structure()
    return {
        type = "minimap",
        ref = {"minimap"},
        elem_mods = {visible = false},
        actions = {
            on_click = "open_map"
        }
    }
end


function MinimapGui:post_build(refs, player)
    refs.mod_gui_button.visible = false
end

function MinimapGui:update_minimap(event)
    local player = game.get_player(event.player_index)
    local base = MobileBase.get_by_visitor(player)
    local refs = self.refs[event.player_index]
    refs.mod_gui_button.visible = base ~= nil
    local minimap = refs.minimap
    minimap.visible = base ~= nil
    if base and base.vehicle and base.vehicle.valid then
        minimap.entity = base.vehicle
        self:open_mod_gui_frame(event, refs)
    else
        self:close_mod_gui_frame(event, refs)
    end
end

function MinimapGui:is_open_map(event, refs)
    return event.element == refs.minimap
end

function MinimapGui:open_map(event)
    game.get_player(event.player_index).open_map(event.element.entity.position, 1)
end

MinimapGui:on({ Config.ON_PLAYER_ENTER_BASE, Config.ON_PLAYER_LEFT_BASE }, function(self, event)
    self:update_minimap(event)
end)

return MinimapGui