local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local gui = require 'flib/gui'
local Table = require 'klib/utils/table'
local GE = require 'klib/fgui/gui_element'
local Entity = require 'klib/gmo/entity'
local Direction = require 'klib/gmo/direction'
local SelectionTool = require 'klib/gmo/selection_tool'
local ColorList = require 'stdlib/utils/defines/color_list'
local BaseComponent = require 'klib/fgui/base_component'

local Config = require 'scenario/mobile_factory/config'

local icon_header_caption = { "mobile_factory_base_gui.resource_table_icon_header" }
local icon_header_style_mods = { width = 100, font = "heading-2" }
local icon_style_mods = { width = 100}
local amount_header_caption = { "mobile_factory_base_gui.resource_table_count_header" }
local amount_header_style_mods = { width = 100, font = "heading-2"}
local amount_style_mods = { width = 100 }

local ResourceTable = KC.class(Config.PACKAGE_BASE_GUI_PREFIX .. 'ResourceTable', BaseComponent, function(self, parent)
    BaseComponent(self)
    self.parent = parent
end)

ResourceTable:delegate_method("parent", {
    "get_selected_base",
    "get_selected_base_id"
})

function ResourceTable:build(player, parent)
    local refs = gui.build(parent, {
        GE.hr(),
        GE.flow(false, nil, {
            GE.h1({"mobile_factory_base_gui.information_tab_resource_caption"}, {width=100}),
            GE.h3("", {font_color = ColorList.green, width = 100}, {ref = {"warping_resource_state_label"}}),
            GE.h3("0", {font_color = ColorList.orange, left_margin = "10"},
                    {ref = {"output_resource_count"}, tooltip={"mobile_factory_base_gui.information_tab_output_resource_tooltip"}}),
            GE.h3("/" .. Config.RESOURCE_WARP_OUT_POINT_LIMIT),
            GE.fill_horizontally(),
            GE.sprite_button(self, "entity/offshore-pump", "tool_button", {"mobile_factory_base_gui.create_well_pump"},
                    "create_well_pump"),
            GE.sprite_button(self, "entity/electric-mining-drill", "tool_button_green", {"mobile_factory_base_gui.toggle_warping_resource_tooltip"},
                    "toggle_warping_resource", {ref= {"toggle_warping_resource_button"}}),
            GE.sprite_button(self, "utility/side_menu_blueprint_library_icon", "tool_button_blue", {"mobile_factory_base_gui.information_tab_show_warp_resource_area"},
                    "show_warp_resource_area"),
            GE.sprite_button(self, "utility/trash", "tool_button_red", {"mobile_factory_base_gui.remove_output_resource_tooltip"},
                    "remove_output_resources"),
        }),
        GE.hr(),
        ResourceTable.create_table_structure()
    })
    self.refs[player.index] = refs
    GE.column_alignments(refs.resource_table, "center")
end

function ResourceTable.create_table_structure()
    local structure = GE.table(self, nil, 6, {"resource_table"}, nil, {})
    for _ = 1, structure.column_count / 2 do
        Table.insert(structure.children, { type='label', caption = icon_header_caption, style_mods = icon_header_style_mods })
        Table.insert(structure.children, { type='label', caption = amount_header_caption, style_mods = amount_header_style_mods })
    end
    return structure
end

function ResourceTable:update(player)
    local base = self:get_selected_base(player.index)
    local refs = self.refs[player.index]
    self:update_others(refs, base)
    self:update_table(refs, base)
end

function ResourceTable:update_table(refs, base)
    local tbl = refs.resource_table
    local resources = game.get_filtered_entity_prototypes({{ filter = "type", type = "resource" }})
    local function get_amount_label(name)
        local is_fluid_resource = Entity.is_fluid_resource(name)
        return (is_fluid_resource and math.floor(base.resource_amount[name] / 3000) .. '%' ) or base.resource_amount[name]
    end
    GE.update_table(tbl,{
        skip_row = 3,
        column_count = 2,
        records = base and resources or {},
        create_row = function(table, row, name, resource)
            gui.build(table, {
                GE.flow(false, {style_mods=icon_style_mods}, {
                    GE.sprite_button(self, 'entity/' .. name, 'slot_button',
                            {"mobile_factory_base_gui.create_output_resource_button"},
                            "create_output_resource", {
                                tags = {resource_name = name}
                            })
                }),
                GE.label(get_amount_label(name), nil, amount_style_mods),
            })
        end,
        update_row = function(elems, row, name, resource)
            elems[2].caption = get_amount_label(name)
        end
    })
end

function ResourceTable:update_others(refs, base)
    if base then
        refs.warping_resource_state_label.caption = base:is_warping_in_resources() and {"mobile_factory_base_gui.warping_in_resource_hint"} or ""

        refs.output_resource_count.caption = base:get_output_resources_count()

        local enable = base:is_enable_warping_in_resources()
        refs.toggle_warping_resource_button.style = enable and "tool_button_green" or "tool_button"
    end
end

function ResourceTable:show_warp_resource_area(e, refs)
    self:get_selected_base(e.player_index):toggle_display_warp_resource_area()
end

function ResourceTable:toggle_warping_resource(e, refs)
    local base = self:get_selected_base(e.player_index)
    local enable = base:toggle_warping_in_resources()
    e.element.style = enable and "tool_button_green" or "tool_button"
end

local function pick_selection_tool(self, player, type, tags, force)
    local selected_base_id = self:get_selected_base_id(player.index)
    if not selected_base_id then return end
    return SelectionTool.start_selection(player, type, Table.merge({
        base_id = selected_base_id
    }, tags), force)
end

function ResourceTable:create_output_resource(event, refs)
    local tag = gui.get_tags(event.element)
    local resource_name = tag.resource_name
    pick_selection_tool(self, GE.get_player(event), Config.SELECTION_TYPE_CREATE_OUTPUT_RESOURCES, {
        resource_name = resource_name
    })
end

function ResourceTable:remove_output_resources(event, refs)
    pick_selection_tool(self, GE.get_player(event), Config.SELECTION_TYPE_REMOVE_OUTPUT_RESOURCES)
end

function ResourceTable:create_well_pump(event, refs)
    pick_selection_tool(self, GE.get_player(event), Config.SELECTION_TYPE_CREATE_WELL_PUMP, {
        direction = defines.direction.north
    })
end

local function handle_selection(event, handler)
    local tags = event.tags
    local base = KC.get(tags.base_id)
    if base then
        local player = game.get_player(event.player_index)
        handler(tags, event.area, player, base)
    end
end

SelectionTool.register_selection(Config.SELECTION_TYPE_CREATE_OUTPUT_RESOURCES, function(event)
    handle_selection(event, function(tags, area, player, base)
        base:create_output_resources(tags.resource_name, area, { player=player})
    end)
end)

SelectionTool.register_selection(Config.SELECTION_TYPE_REMOVE_OUTPUT_RESOURCES, function(event)
    handle_selection(event, function(tags, area, player, base)
        base:remove_output_resources(area, {player=player})
    end)
end)

SelectionTool.register_selections({SelectionTool.SELECT_MODE, SelectionTool.REVERSE_SELECT_MODE}, Config.SELECTION_TYPE_CREATE_WELL_PUMP, function(event)
    if event.mode == SelectionTool.SELECT_MODE then
        handle_selection(event, function(tags, area, player, base)
            base:create_well_pump(area, tags.direction, {player = player})
        end)
    else
        local player = game.get_player(event.player_index)
        SelectionTool.start_selection(player, event.type, Table.merge({
            base_id = event.tags.base_id,
            direction = Direction.next(event.tags.direction)
        }), true)
    end
end)

return ResourceTable