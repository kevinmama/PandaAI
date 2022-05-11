local mod_gui = require '__core__/lualib/mod-gui'
local gui = require 'flib/gui'
local KC = require 'klib/container/container'
local Type = require 'klib/utils/type'

--- 顶部按钮基类，一般用其子类单例
local ModGuiFrame = KC.class("klib.fgui.ModGuiFrame", function(self)
    self.data = {}
    self.mod_gui_sprite = "utility/notification"
    self.mod_gui_tooltip = {"missing_text"}
    self.mod_gui_frame_caption = {"missing_text"}
    self.mod_gui_frame_minimal_width = 800
end)

ModGuiFrame.SEPARATE_LINE_STYLE_MODS = {
    top_margin = 4,
    bottom_margin = 4
}

function ModGuiFrame:build(player)
    local mod_gui_button = self:build_mod_gui_button(player)
    local data = self:build_mod_gui_frame(player)
    self.data[player.index] = data
    data.refs.mod_gui_button = mod_gui_button
    self:post_build_mod_gui_frame(data, player)
end

function ModGuiFrame:build_mod_gui_button(player)
    return gui.add(mod_gui.get_button_flow(player), {
        type = "sprite-button",
        style = mod_gui.button_style,
        sprite = self.mod_gui_sprite,
        tooltip = self.mod_gui_tooltip,
        actions = {
            on_click = "toggle_mod_gui_frame"
        }
    })
end

function ModGuiFrame:build_mod_gui_frame(player)
    local refs = gui.build(mod_gui.get_frame_flow(player), {
        {
            type = "frame",
            direction = "vertical",
            ref = {"mod_gui_frame"},
            style = mod_gui.frame_style,
            style_mods = { minimal_width = self.mod_gui_frame_minimal_width },
            visible = false,
            actions = {
                on_closed = "close_mod_gui_frame"
            },
            { type = "flow", ref = {"mod_gui_title_bar_flow"}, children = {
                {type = "label", style = "frame_title", caption = self.mod_gui_frame_caption, ignored_by_interaction = true},
                {type = "empty-widget", style = "draggable_space", style_mods = {horizontally_stretchable = true}, ignored_by_interaction = true},
                {
                    type = "sprite-button",
                    style = "frame_action_button",
                    sprite = "utility/close_white",
                    hovered_sprite = "utility/close_black",
                    clicked_sprite = "utility/close_black",
                    mouse_button_filter = {"left"},
                    actions = {
                        on_click = "close_mod_gui_frame"
                    }
                }
            }}, self:build_main_frame_structure()
        }
    })

    return {
        refs = refs
    }
end

function ModGuiFrame:build_main_frame_structure()
end

function ModGuiFrame:post_build_mod_gui_frame(data, player)
end

function ModGuiFrame:toggle_mod_gui_frame(event)
    local data = self.data[event.player_index]
    if event.element ~= data.refs.mod_gui_button then return end
    local visible = data.refs.mod_gui_frame.visible
    if visible then
        self:close_mod_gui_frame(event)
    else
        self:open_mod_gui_frame(event)
    end
end

function ModGuiFrame:open_mod_gui_frame(event)
    local player = game.get_player(event.player_index)
    local data = self.data[event.player_index]
    if event.element ~= data.refs.mod_gui_button then return end
    data.refs.mod_gui_frame.visible = true
    player.opened = data.refs.mod_gui_frame
end

function ModGuiFrame:close_mod_gui_frame(event)
    local player = game.get_player(event.player_index)
    local data = self.data[event.player_index]
    if event.element ~= data.refs.mod_gui_button then return end
    data.refs.mod_gui_frame.visible = false
    if player.opened then
        player.opened = nil
    end
end


function ModGuiFrame:hook_events()
    gui.hook_events(function(e)
        local action = gui.read_action(e)
        if action then
            local handler = self[action]
            if Type.is_function(handler) then
                handler(self, e)
            end
        end
    end)
end


function ModGuiFrame:on_ready()
    self:on(defines.events.on_player_created, function(self, event)
        self:build(game.get_player(event.player_index))
    end)
    self:hook_events()
end

return ModGuiFrame
