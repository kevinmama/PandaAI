local KC = require 'klib/container/container'
local ModGuiButton = require 'klib/fgui/mod_gui_button'
local Config = require 'scenario/mobile_factory/config'
local Player = require 'scenario/mobile_factory/player/player'

local SpectatorGui = KC.singleton(Config.PACKAGE_PLAYER_PREFIX .. 'SpectatorGui', ModGuiButton, function(self)
    ModGuiButton(self)
    self.mod_gui_sprite = "item/raw-fish"
    self.mod_gui_tooltip = {"mobile_factory.mod_gui_spectator_mode"}
end)

function SpectatorGui:on_click(event, refs)
    local k_player = Player.get(event.player_index)
    k_player:toggle_spectator_mode()
end

return SpectatorGui

