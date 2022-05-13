local KC = require 'klib/container/container'
local gui = require 'flib/gui'
local ModGuiButton = require 'klib/fgui/mod_gui_button'
local Player = require 'scenario/mobile_factory/player'

local SpectatorGui = KC.singleton('scenario.MobileFactory.SpectatorGui', ModGuiButton, function(self)
    ModGuiButton(self)
    self.mod_gui_sprite = "item/raw-fish"
    self.mod_gui_tooltip = {"mobile_factory.mod_gui_spectator_mode"}
end)

function SpectatorGui:on_mod_gui_button_click(event, refs)
    local k_player = Player.get(event.player_index)
    k_player:toggle_spectator_mode()
end

return SpectatorGui

