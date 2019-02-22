local gui = require('klib/gui/gui')

local DebugPanel = gui.flow({
    name = 'debug_panel_flow',
    direction = 'vertical'
})
:visible(false)
:attach(gui.left)
:with(function(parent)
    gui.flow({
        name = 'debug_panel_position_info_flow',
        direction = 'horizontal'
    }):attach(parent)
    :with(function(parent)
        gui.label({
            name = 'debug_panel_position_info_label',
            caption = 'position: '
        }):attach(parent)

        gui.label({
            name = 'debug_panel_position_info_value'
        }):attach(parent)
        :on(defines.events.on_player_changed_position, function(event, self)
            local pos = game.players[event.player_index].position
            self:get_element(event.player_index).caption = pos.x .. ', ' .. pos.y
        end)
    end)

    gui.flow({
        name = 'debug_panel_pollution_info_flow',
        direction = 'horizontal'
    }):attach(parent)
    :with(function(parent)
        gui.label({
            name = 'debug_panel_pollution_info_label',
            caption = 'pollution: '
        }):attach(parent)

        gui.label({
            name = 'debug_panel_pollution_info_value'
        }):attach(parent)
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


gui.button({
    name = 'debug_panel_menu',
    caption = 'DEBUG'
})
   :attach(gui.top)
   :on_click(function(event)
    DebugPanel:toggle_visibility(event.player_index)
end)

