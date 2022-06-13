local KC = require 'klib/container/container'
local gui = require 'flib/gui'
local GE = require 'klib/fgui/gui_element'
local SelectionTool = require 'klib/gmo/selection_tool'
local BaseComponent = require 'klib/fgui/base_component'

local Config = require 'scenario/mobile_factory/config'

local MobileBaseUtils = require 'scenario/mobile_factory/base/mobile_base_utils'

local IOBelts = KC.class(Config.PACKAGE_BASE_GUI_PREFIX .. 'IOBelts', BaseComponent, function(self, parent)
    BaseComponent(self)
    self.parent = parent
end)

IOBelts:delegate_method("parent", {
    "get_selected_base",
    "get_selected_base_id"
})

function IOBelts:build(player, parent)
    self.refs[player.index] = gui.build(parent, {
        GE.hr(),
        GE.flow(false, nil, {
            GE.h1({"mobile_factory_base_gui.information_tab_io_belts_caption"}),
            GE.fill_horizontally(),
            GE.sprite_button(self, "utility/side_menu_blueprint_library_icon", "tool_button_blue",
                    {"mobile_factory_base_gui.information_tab_show_io_area"},
                    "show_io_area"),
        }),
        GE.hr(),
        GE.flow(false, nil, {
            GE.h3({"mobile_factory_base_gui.information_tab_input_belt_label"}),
            GE.sprite_button(self, "entity/linked-belt", "slot_button",
                    {"mobile_factory_base_gui.information_tab_input_belt"},
                    "update_input_belt"),
            GE.h3({"mobile_factory_base_gui.information_tab_output_belt_label"}),
            GE.sprite_button(self, "entity/linked-belt", "slot_button",
                    {"mobile_factory_base_gui.information_tab_output_belt"},
                    "update_output_belt")
        })
    })
end

function IOBelts:show_io_area(e, refs)
    local selected_base_id = self:get_selected_base_id(e.player_index)
    local base = selected_base_id and KC.get(selected_base_id)
    base:toggle_display_io_area()
end

function IOBelts:update_input_belt(e, refs)
    local selected_base_id = self:get_selected_base_id(e.player_index)
    if not selected_base_id then return end
    SelectionTool.start_selection(GE.get_player(e), Config.SELECTION_TYPE_UPDATE_IO_BELTS, {
        base_id = selected_base_id,
        input_belt = true
    })
end

function IOBelts:update_output_belt(e, refs)
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