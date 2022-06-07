local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local gui = require 'flib/gui'
local Table = require 'klib/utils/table'
local GE = require 'klib/fgui/gui_element'
local Entity = require 'klib/gmo/entity'
local Direction = require 'klib/gmo/direction'
local SelectionTool = require 'klib/gmo/selection_tool'
local ColorList = require 'stdlib/utils/defines/color_list'

local Config = require 'scenario/mobile_factory/config'

local MobileBaseUtils = require 'scenario/mobile_factory/base/mobile_base_utils'

local IOBelts = {}

function IOBelts.create_structures()
    return {
        GE.hr(),
        GE.flow(false, nil, {
            GE.h1({"mobile_factory_base_gui.information_tab_io_belts_caption"}),
            GE.fill_horizontally(),
            GE.sprite_button("utility/side_menu_blueprint_library_icon", "tool_button_blue",
                    {"mobile_factory_base_gui.information_tab_show_io_area"},
                    {"show_io_area_button"}, "show_io_area"),
        }),
        GE.hr(),
        GE.flow(false, nil, {
            GE.h3({"mobile_factory_base_gui.information_tab_input_belt_label"}),
            GE.sprite_button("entity/linked-belt", "slot_button",
                    {"mobile_factory_base_gui.information_tab_input_belt"},
                    {"update_input_belt_button"}, "update_input_belt"),
            GE.h3({"mobile_factory_base_gui.information_tab_output_belt_label"}),
            GE.sprite_button("entity/linked-belt", "slot_button",
                    {"mobile_factory_base_gui.information_tab_output_belt"},
                    {"update_output_belt_button"}, "update_output_belt")
        })
    }
end


local actions = {}
IOBelts.actions = actions

function actions:is_show_io_area(e, refs)
    return e.element == refs.show_io_area_button
end

function actions:show_io_area(e, refs)
    local selected_base_id = self:get_selected_base_id(e.player_index)
    local base = selected_base_id and KC.get(selected_base_id)
    base:toggle_display_io_area()
end

function actions:is_update_input_belt(e, refs)
    return e.element == refs.update_input_belt_button
end

function actions:update_input_belt(e, refs)
    local selected_base_id = self:get_selected_base_id(e.player_index)
    if not selected_base_id then return end
    SelectionTool.start_selection(GE.get_player(e), Config.SELECTION_TYPE_UPDATE_IO_BELTS, {
        base_id = selected_base_id,
        input_belt = true
    })
end

function actions:is_update_output_belt(e, refs)
    return e.element == refs.update_output_belt_button
end

function actions:update_output_belt(e, refs)
    local selected_base_id = self:get_selected_base_id(e.player_index)
    if not selected_base_id then return end
    SelectionTool.start_selection(GE.get_player(e), Config.SELECTION_TYPE_UPDATE_IO_BELTS, {
        base_id = selected_base_id,
        input_belt = false
    })
end

SelectionTool.register_selections(
        {SelectionTool.SELECT_MODE, SelectionTool.ALT_SELECT_MODE},
        Config.SELECTION_TYPE_UPDATE_IO_BELTS,
        function(event)
    local tags = event.tags
    local base = KC.get(tags.base_id)
    if KC.is_valid(base) then
        local player = GE.get_player(event)
        local area = event.area
        if tags.input_belt then
            base:build_input_belt(area.left_top, {player = player})
        else
            if event.mode == SelectionTool.SELECT_MODE then
                base:build_output_belt_input_end(area.left_top, {player = player})
            else
                local target_bases = MobileBaseUtils.find_bases_in_area(area, base.team:get_id())
                local target = next(target_bases) and target_bases[1] or area.left_top
                base:build_output_belt_output_end(target, {player = player})
            end
        end
    end
end)

SelectionTool.register_reverse_selection(Config.SELECTION_TYPE_UPDATE_IO_BELTS, function(event)
    local tags = event.tags
    local base = KC.get(tags.base_id)
    if KC.is_valid(base) then
        local player = GE.get_player(event)
        if tags.input_belt then
            base:remove_input_belt(event.area, {player = player})
        else
            base:remove_output_belt(event.area, {player = player})
        end
    end
end)

return IOBelts