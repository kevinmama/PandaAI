local mod_gui = require '__core__/lualib/mod-gui'
local gui = require 'flib/gui'
local KC = require 'klib/container/container'
local GE = require 'klib/fgui/gui_element'

local BaseGui = require 'klib/fgui/base_gui'

local ModGuiButton = KC.class('klib.fgui.ModGuiButton', BaseGui, function(self)
    BaseGui(self)
    self.mod_gui_sprite = "utility/notification"
    self.mod_gui_tooltip = {"missing_text"}
end)

ModGuiButton.MOD_GUI_BUTTON = "mod_gui_button"

function ModGuiButton:build(player)
    self.refs[player.index] = {
        [ModGuiButton.MOD_GUI_BUTTON] = self:build_mod_gui_button(player)
    }
end

function ModGuiButton:build_mod_gui_button(player)
    --mouse_button_filter = {"left", "right"},
    return gui.add(mod_gui.get_button_flow(player), GE.sprite_button(
            self, self.mod_gui_sprite, mod_gui.button_style,
            self.mod_gui_tooltip,"on_click"
    ))
end

function ModGuiButton:on_click(event, refs)
end

return ModGuiButton
