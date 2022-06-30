local KC = require 'klib/container/container'
local gui = require 'flib/gui'
local GE = require 'klib/fgui/gui_element'
local Rendering = require 'klib/gmo/rendering'
local SelectionTool = require 'klib/gmo/selection_tool'
local ColorList = require 'stdlib/utils/defines/color_list'
local BaseComponent = require 'klib/fgui/base_component'

local Config = require 'scenario/mobile_factory/config'

local column_style_mods = { width = 100, horizontal_align = "center"}

local LinkedBeltTable = KC.class(Config.PACKAGE_BASE_GUI_PREFIX .. 'LinkedBeltTable', BaseComponent, function(self, parent)
    BaseComponent(self)
    self.parent = parent
end)

LinkedBeltTable:delegate_method("parent", {
    "get_selected_base",
    "get_selected_base_id"
})

function LinkedBeltTable:build(player, parent)
    local structure = {
        GE.hr(),
        GE.flow(false, nil, {
            GE.h1({"mobile_factory_base_gui.linked_belt_table_caption"}),
            GE.fill_horizontally(),
            GE.sprite_button(self, "utility/side_menu_blueprint_library_icon", "tool_button_blue",
                    {"mobile_factory_base_gui.linked_belt_table_show_io_area"},
                    "show_io_area"),
        }),
        GE.hr(),
        GE.table(self, nil, 5, {"linked_belt_table"}, nil, {
            GE.h2({"mobile_factory_base_gui.linked_belt_table_id"}, column_style_mods),
            GE.h2({"mobile_factory_base_gui.linked_belt_table_input_belt"}, column_style_mods),
            GE.h2({"mobile_factory_base_gui.linked_belt_table_output_belt"}, column_style_mods),
            GE.h2({"mobile_factory_base_gui.linked_belt_table_status"}, column_style_mods),
            GE.placeholder()
        }),
        GE.hr(),
        GE.flow(false, nil, {
            GE.sprite_button(self, "utility/add", "tool_button", nil, "create_linked_belt_pair"),
            GE.sprite_button(self, "utility/trash", "tool_button_red", nil, "remove_linked_belt", {
                style_mods = {left_margin=5}
            })
        }),
    }
    local refs = gui.build(parent, structure)
    self.refs[player.index] = refs
    GE.column_alignments(refs.linked_belt_table, "center")
end

function LinkedBeltTable:update(player)
    local refs = self.refs[player.index]
    local base = self:get_selected_base(player.index)
    local records = base and base:get_linked_belt_information() or {}
    local tbl = refs.linked_belt_table
    GE.update_table(tbl, {
        skip_row = 1,
        records = records,
        create_row = function(table, row, key, rc)
            local structure = {
                GE.label(rc.id),
                GE.flow(false, nil, {
                    GE.sprite_button(self, "utility/gps_map_icon", "slot_button",
                            {"mobile_factory_base_gui.linked_belt_table_linked_belt_position"},
                            "show_linked_belt_position", {
                                elem_mods = {visible = rc.input_belt_position ~= nil},
                                tags = { position = rc.input_belt_position },
                            }),
                }),
                GE.flow(false, nil, {
                    GE.sprite_button(self, "utility/gps_map_icon", "slot_button",
                            {"mobile_factory_base_gui.linked_belt_table_linked_belt_position"},
                            "show_linked_belt_position", {
                                elem_mods = {visible = rc.output_belt_position ~= nil},
                                tags = { position = rc.output_belt_position }
                            }),
                }),
                GE.label(rc.working and {"mobile_factory_base_gui.linked_belt_table_working"}
                        or {"mobile_factory_base_gui.linked_belt_table_not_working"}),
                GE.flow(false, nil, {
                    GE.sprite_button(self, "entity/linked-belt", "tool_button",
                            { "mobile_factory_base_gui.linked_belt_table_build_linked_belt" },
                            "build_linked_belt", {
                                tags = { pair_id = rc.id }
                            }),
                    GE.sprite_button(self, "utility/trash", "tool_button_red",
                            { "mobile_factory_base_gui.linked_belt_table_remove_linked_belt_pair" },
                            "remove_linked_belt_pair", {
                                style_mods = {left_margin = 5},
                                tags = { pair_id = rc.id }
                            }),
                })
            }
            gui.build(table, structure)
        end,
        update_row = function(elems, row, key, rc)
            elems[1].caption = rc.id
            elems[2].children[1].visible = rc.input_belt_position ~= nil
            gui.update_tags(elems[2].children[1], {position = rc.input_belt_position})
            elems[3].children[1].visible = rc.output_belt_position ~= nil
            gui.update_tags(elems[3].children[1], {position = rc.output_belt_position})
            if rc.working then
                elems[4].caption = {"mobile_factory_base_gui.linked_belt_table_working"}
                elems[4].style.font_color = ColorList.green
            else
                elems[4].caption = {"mobile_factory_base_gui.linked_belt_table_not_working"}
                elems[4].style.font_color = ColorList.red
            end
            gui.update_tags(elems[5].children[1], {pair_id = rc.id})
            gui.update_tags(elems[5].children[2], {pair_id = rc.id})
        end
    })
end

function LinkedBeltTable:show_io_area(e, refs)
    local base = self:get_selected_base(e.player_index)
    if base then
        base:toggle_display_io_area()
    end
end

function LinkedBeltTable:show_linked_belt_position(e, refs)
    local position = gui.get_tags(e.element).position
    if position then
        local player = GE.get_player(e)
        local surface = game.surfaces[Config.GAME_SURFACE_NAME]
        Rendering.draw_small_hint_rectangle(surface, position, player)
        player.open_map(position, 1)
    end
end

function LinkedBeltTable:create_linked_belt_pair(e, refs)
    local base = self:get_selected_base(e.player_index)
    if base then
        local success, errmsg = base:create_linked_belt_pair()
        if not success then
            GE.get_player(e).print(errmsg)
        end
    end
end

function LinkedBeltTable:remove_linked_belt_pair(e, refs)
    local base = self:get_selected_base(e.player_index)
    if base then
        local pair_id = gui.get_tags(e.element).pair_id
        local success, errmsg = base:remove_linked_belt_pair(pair_id)
        if not success then
            GE.get_player(e).print(errmsg)
        end
    end
end

function LinkedBeltTable:build_linked_belt(e, refs)
    local base = self:get_selected_base(e.player_index)
    if base then
        local pair_id = gui.get_tags(e.element).pair_id
        SelectionTool.start_selection(GE.get_player(e), Config.SELECTION_TYPE_BUILD_LINKED_BELT, {
            base_id = base:get_id(),
            pair_id = pair_id,
        })
    end
end

function LinkedBeltTable:remove_linked_belt(e, refs)
    local base = self:get_selected_base(e.player_index)
    if base then
        SelectionTool.start_selection(GE.get_player(e), Config.SELECTION_TYPE_REMOVE_LINKED_BELT, {
            base_id = base:get_id(),
        })
    end
end

SelectionTool.register_selections({
    SelectionTool.SELECT_MODE, SelectionTool.ALT_SELECT_MODE
}, Config.SELECTION_TYPE_BUILD_LINKED_BELT, function(e)
    local base = KC.get(e.tags.base_id)
    if KC.is_valid(base) then
        local success, errmsg = base:build_linked_belt(
                e.tags.pair_id, e.area.left_top,
                e.mode == SelectionTool.SELECT_MODE and "input" or "output"
        )
        if not success then
            GE.get_player(e).print(errmsg)
        end
    end
end)

local function do_remove_linked_belt(e)
    local base = KC.get(e.tags.base_id)
    if KC.is_valid(base) then
        local success, errmsg = base:remove_linked_belt(e.area)
        if not success then
            GE.get_player(e).print(errmsg)
        end
    end
end

SelectionTool.register_reverse_selection(Config.SELECTION_TYPE_BUILD_LINKED_BELT, function(e)
    do_remove_linked_belt(e)
end)

SelectionTool.register_selection(Config. SELECTION_TYPE_REMOVE_LINKED_BELT, function(e)
    do_remove_linked_belt(e)
end)

return LinkedBeltTable
