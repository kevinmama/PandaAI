local mod_gui = require '__core__/lualib/mod-gui'
local gui = require 'flib/gui'
local KC = require 'klib/container/container'
local Type = require 'klib/utils/type'

local ModGuiButton = KC.class('klib.fgui.ModGuiButton', function(self)
    self.refs = {}
    self.mod_gui_sprite = "utility/notification"
    self.mod_gui_tooltip = {"missing_text"}
end)


function ModGuiButton:build(player)
    local refs = {
        mod_gui_button = self:build_mod_gui_button(player)
    }
    self.refs[player.index] = refs
    self:post_build_mod_gui_button(refs, player)
end

function ModGuiButton:build_mod_gui_button(player)
    return gui.add(mod_gui.get_button_flow(player), {
        type = "sprite-button",
        style = mod_gui.button_style,
        sprite = self.mod_gui_sprite,
        tooltip = self.mod_gui_tooltip,
        mouse_button_filter = {"left"},
        actions = {
            on_click = "on_mod_gui_button_click"
        }
    })
end

function ModGuiButton:post_build_mod_gui_button(refs, player)

end

function ModGuiButton:ensure_on_mod_gui_button_click(event, refs)
    return event.element == refs.mod_gui_button
end

function ModGuiButton:on_mod_gui_button_click(event, refs)

end

function ModGuiButton:hook_events()
    gui.hook_events(function(e)
        local action = gui.read_action(e)
        if action then
            local refs = e.player_index and self.refs[e.player_index]

            local ensure_func = self['ensure_' .. action]
            if Type.is_function(ensure_func) then
                if not ensure_func(self, e, refs) then
                    return
                end
            end

            if Type.is_function(self[action]) then
                self[action](self, e, refs)
            end
        end
    end)
end

function ModGuiButton:on_ready()
    self:on(defines.events.on_player_created, function(self, event)
        self:build(game.get_player(event.player_index))
    end)
    self:hook_events()
end

return ModGuiButton
