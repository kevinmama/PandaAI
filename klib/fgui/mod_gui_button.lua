local mod_gui = require '__core__/lualib/mod-gui'
local gui = require 'flib/gui'
local KC = require 'klib/container/container'

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
    return gui.add(mod_gui.get_button_flow(player), {
        type = "sprite-button",
        style = mod_gui.button_style,
        sprite = self.mod_gui_sprite,
        tooltip = self.mod_gui_tooltip,
        mouse_button_filter = {"left", "right"},
        actions = {
            on_click = "on_click"
        }
    })
end

function ModGuiButton:is_on_click(event, refs)
    return event.element == refs.mod_gui_button
end

function ModGuiButton:on_click(event, refs)
end

return ModGuiButton
