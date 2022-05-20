local KC = require 'klib/container/container'
local Entity = require 'klib/gmo/entity'
local Player = require 'klib/gmo/player'
local gui = require 'flib/gui'
local ModGuiButton = require 'klib/fgui/mod_gui_button'
local Stand = require 'kai/command/stand'
local Group = require 'kai/agent/group'

local FormationGui = KC.singleton('scenario.NauvisWar.FormationGui', ModGuiButton, function(self)
    ModGuiButton(self)
    self.mod_gui_sprite = "entity/character"
    self.mod_gui_tooltip = "左键: 停止/前进，右键：保持阵型方向"
end)

function ModGuiButton:post_build_mod_gui_button(refs, player)
    gui.update(refs.mod_gui_button, {
        elem_mods = {mouse_button_filter = {"left", "right"}},
    })
end

function FormationGui:on_mod_gui_button_click(event, refs)
    local group_id = Player.get_data(event.player_index, "group_id")
    local group = KC.get(group_id)
    if event.button == defines.mouse_button_type.left then
        local stand = not Player.get_data(event.player_index, "stand")
        group:set_command(Stand, stand)
        Player.set_data(event.player_index, "stand", stand)
    elseif event.button == defines.mouse_button_type.right then
        local hold = not group.hold_direction
        group.hold_direction = hold
        group:for_each_member_recursive(function(member)
            if KC.is_object(member, Group) then
                member.hold_direction = hold
            end
        end)
    end
end

return FormationGui

