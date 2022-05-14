local KC = require 'klib/container/container'
local gui = require 'flib/gui'
local ModGuiButton = require 'klib/fgui/mod_gui_button'
local Player = require 'scenario/mobile_factory/player'

local RechargeGui = KC.singleton('scenario.MobileFactory.RechargeGui', ModGuiButton, function(self)
    ModGuiButton(self)
    self.mod_gui_sprite = "item/battery-mk2-equipment"
    self.mod_gui_tooltip = {"mobile_factory.mod_gui_recharge"}
end)

function RechargeGui:on_mod_gui_button_click(event, refs)
    local k_player = Player.get(event.player_index)
    k_player:recharge_equipment()
end

return RechargeGui