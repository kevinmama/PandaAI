local gui = require('klib/gui/gui')

return gui.button('debug_panel_menu', 'Debug'):toggle_component(function(self)
    return gui.flow('debug_panel_flow', gui.left):with(function(parent)
        gui.flow('debug_panel_position_info_flow', 'horizontal', parent):with(function(parent)
            gui.label('debug_panel_position_info_label', 'position: ', parent)
            gui.label('debug_panel_position_info_value', '', parent)
               :on(defines.events.on_player_changed_position, function(event, self)
                local pos = game.players[event.player_index].position
                self:get_element(event.player_index).caption = pos.x .. ', ' .. pos.y
            end)
        end)

        gui.flow('debug_panel_pollution_info_flow', 'horizontal', parent):with(function(parent)
            gui.label('debug_panel_pollution_info_label', 'pollution: ', parent)
            gui.label('debug_panel_pollution_info_value', '', parent)
                :on(defines.events.on_player_changed_position, function(event, self)
                    local player = game.players[event.player_index]
                    self:get_element(event.player_index).caption = player.surface.get_pollution(player.position)
                end)
                :on(defines.events.on_tick, function(event, self)
                    if event.tick % 60 == 0 then
                        for _, player in pairs(game.connected_players) do
                            self:get_element(player.index).caption = player.surface.get_pollution(player.position)
                        end
                    end
                end)
        end)
    end)
end)

