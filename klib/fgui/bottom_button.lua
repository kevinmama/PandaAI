local KC = require 'klib/container/container'
local GE = require 'klib/fgui/gui_element'
local Event = require 'klib/event/event'
local BaseGui = require 'klib/fgui/base_gui'
local gui = require 'flib/gui'

local REF_FRAME = "custom_quick_bar_frame"
local REF_INNER_FRAME = "custom_quick_bar_inner_frame"
local REF_DRAGGABLE_FLOW = "custom_quick_bar_flow"
local BUTTON_PER_COLUMN = 2

local BottomButton = KC.class('klib.fgui.BottomButton', BaseGui, {
    bottom_frame_refs = {}
}, function(self)
    BaseGui(self)
end)

local function get_location(player, above, state)
    local location, alignment
    local resolution = player.display_resolution
    local scale = player.display_scale
    above = above or true
    state = state or "bottom_right"
    if state == 'bottom_left' then
        if above then
            location = {
                x = (resolution.width / 2) - ((259) * scale),
                y = (resolution.height - (150 * scale))
            }
            alignment = 'horizontal'
        else
            location = {
                x = (resolution.width / 2) - ((54 + 444) * scale),
                y = (resolution.height - (96 * scale))
            }
            alignment = "vertical"
        end
    elseif state == 'bottom_right' then
        if above then
            location = {
                x = (resolution.width / 2) - ((-376) * scale),
                y = (resolution.height - (150 * scale))
            }
            alignment = 'horizontal'
        else
            location = {
                x = (resolution.width / 2) - ((54 + -528) * scale),
                y = (resolution.height - (96 * scale))
            }
            alignment = "vertical"
        end
    else
        location = {
            x = (resolution.width / 2) - ((54 + -528) * scale),
            y = (resolution.height - (96 * scale))
        }
        alignment = "vertical"
    end
    return location, alignment
end

function BottomButton:build(player)
    local container = self:get_button_container(player)
    local structure = self:build_button(player)
    GE.set_action_if_absent(structure, "on_click", "on_click")
    self:set_component_tag(structure)
    local element = gui.add(container, structure)
    self.refs[player.index] = element
end

function BottomButton:build_button(player)
end

function BottomButton:on_click(event, element)
end

function BottomButton:get_button_container(player)
    local frame = self:get_button_frame(player)
    local children = frame.children
    local last_flow = children and children[#children]
    if last_flow then
        if #last_flow.children < BUTTON_PER_COLUMN then
            return last_flow
        end
    end
    return gui.add(frame, {
        type = 'flow',
        style = 'shortcut_bar_column',
        direction = 'vertical'
    })
end

function BottomButton:get_button_frame(player)
    local all_frame_refs = BottomButton:get_bottom_frame_refs()
    if not all_frame_refs then
        all_frame_refs = {}
        BottomButton:set_bottom_frame_refs(all_frame_refs)
    end

    local refs = all_frame_refs[player.index]
    if not refs then
        refs = gui.build(player.gui.screen, {
            GE.frame(true, "shortcut_bar_window_frame", {REF_FRAME}, nil, {
                GE.flow(true, {ref = {REF_DRAGGABLE_FLOW}}, {
                    GE.drag_widget({style_mods = {horizontally_stretchable = true, height = 10}}),
                    GE.frame(false, 'shortcut_bar_inner_panel', {REF_INNER_FRAME})
                })
            })
        })
        refs[REF_DRAGGABLE_FLOW].drag_target = refs[REF_FRAME]
        refs[REF_FRAME].location = {x = 0, y = 200}
        all_frame_refs[player.index] = refs
    end
    return refs[REF_INNER_FRAME]
end

function BottomButton:set_button_frame_visible(player_index, visible)
    local all_frame_refs = BottomButton:get_bottom_frame_refs()
    local refs = all_frame_refs and all_frame_refs[player_index]
    local frame = refs and refs[REF_FRAME]
    if frame then
        frame.visible = visible
    end
end

function BottomButton.relocation(player_index)
    local player = game.get_player(player_index)
    local location = get_location(player)
    BottomButton:get_bottom_frame_refs()[player_index][REF_FRAME].location = location
end

Event.register({
    defines.events.on_player_display_resolution_changed,
    defines.events.on_player_display_scale_changed,
}, function(event)
    BottomButton.relocation(event.player_index)
end)

return BottomButton