local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local String = require 'klib/utils/string'
local gui = require 'flib/gui'
local Table = require 'klib/utils/table'
local GE = require 'klib/fgui/gui_element'
local Entity = require 'klib/gmo/entity'
local Direction = require 'klib/gmo/direction'
local SelectionTool = require 'klib/gmo/selection_tool'
local ColorList = require 'stdlib/utils/defines/color_list'
local BaseComponent = require 'klib/fgui/base_component'

local Config = require 'scenario/mobile_factory/config'

local column_style_mods = { width = 100, horizontal_align = "center"}

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
            GE.h3("", {font_color = ColorList.green, width = 100, horizontal_align = "center"}, {ref = {"warping_resource_state_label"}}),
            GE.flow(false, {style_mods = {width = 100, horizontal_align = "center"}}, {
                GE.h3("0", {font_color = ColorList.orange},
                        {ref = {"output_resource_count"}, tooltip={"mobile_factory_base_gui.information_tab_output_resource_tooltip"}}),
                GE.h3("/" .. Config.RESOURCE_WARP_OUT_POINT_LIMIT),
            }),
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
        GE.table(self, "table", 4, {"resource_table"}, nil, {
            GE.h2({ "mobile_factory_base_gui.resource_table_icon_header" }, column_style_mods),
            GE.h2({ "mobile_factory_base_gui.resource_table_amount_header" }, column_style_mods),
            GE.h2({"mobile_factory_base_gui.resource_table_request_header"}, column_style_mods),
            GE.h2({"mobile_factory_base_gui.resource_table_reserve_header"}, column_style_mods)
        })
    })
    refs.request_label = {}
    refs.request_textfield = {}
    refs.reserve_label = {}
    refs.reserve_textfield = {}
    self.refs[player.index] = refs
    GE.column_alignments(refs.resource_table, "center")
end

function ResourceTable:update(player)
    local base = self:get_selected_base(player.index)
    local refs = self.refs[player.index]
    self:update_others(player, refs, base)
    self:update_table(player, refs, base)
end

function ResourceTable:update_table(player, refs, base)
    local tbl = refs.resource_table
    local information = base and base:get_resource_information() or {}
    local function get_amount_label(name, amount)
        local is_fluid_resource = Entity.is_fluid_resource(name)
        return (is_fluid_resource and String.exponent_string(math.floor(amount / 3000), 2) .. '%' ) or String.exponent_string(amount,2)
    end
    GE.update_table(tbl,{
        skip_row = 1,
        column_count = 4,
        records = base and information or {},
        create_row = function(table, row, name, rc)
            local new_refs = gui.build(table, {
                GE.flow(false,nil, {
                    GE.sprite_button(self, 'entity/' .. name, 'slot_button',
                            {"mobile_factory_base_gui.create_output_resource_button"},
                            "create_output_resource", {
                                tags = {resource_name = name}
                            })
                }),
                GE.label(get_amount_label(name, rc.amount)),
                GE.editable_label(self, {
                    caption = rc.request,
                    tooltip = {"mobile_factory_base_gui.click_to_edit_tooltip"},
                    textfield_style_mods = column_style_mods,
                    ref = {"request_label", name},
                    textfield_ref = {"request_textfield", name},
                    --textfield_elem_mods = {numeric = true},
                    on_edit = "edit_resource_exchange_schema",
                    on_submit = "submit_resource_exchange_schema",
                    tags = { type = "request", name = name},
                    textfield_tags = { type = "request", name = name}
                }),
                GE.editable_label(self, {
                    caption = rc.reserve,
                    tooltip = {"mobile_factory_base_gui.click_to_edit_tooltip"},
                    textfield_style_mods = column_style_mods,
                    --textfield_elem_mods = {numeric = true},
                    ref = {"reserve_label", name},
                    textfield_ref = {"reserve_textfield", name},
                    on_edit = "edit_resource_exchange_schema",
                    on_submit = "submit_resource_exchange_schema",
                    tags = { type = "reserve", name = name},
                    textfield_tags = { type = "reserve", name = name}
                }),
            })
            local refs = self.refs[player.index]
            Table.merge(refs.request_label, new_refs.request_label)
            Table.merge(refs.request_textfield, new_refs.request_textfield)
            Table.merge(refs.reserve_label, new_refs.reserve_label)
            Table.merge(refs.reserve_textfield, new_refs.reserve_textfield)
        end,
        update_row = function(elems, row, name, rc)
            elems[2].caption = get_amount_label(name, rc.amount)
            elems[3].children[1].caption = get_amount_label(name, rc.request)
            elems[4].children[1].caption = get_amount_label(name, rc.reserve)
        end
    })
end

function ResourceTable:update_others(player, refs, base)
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

local function start_selection(self, player, type, tags, options)
    local selected_base_id = self:get_selected_base_id(player.index)
    if not selected_base_id then return end
    return SelectionTool.start_selection(player, type, Table.merge({
        base_id = selected_base_id
    }, tags), options)
end

function ResourceTable:create_output_resource(event, refs)
    local tag = gui.get_tags(event.element)
    local resource_name = tag.resource_name
    start_selection(self, GE.get_player(event), Config.SELECTION_TYPE_CREATE_OUTPUT_RESOURCES, {
        resource_name = resource_name
    })
end

function ResourceTable:remove_output_resources(event, refs)
    start_selection(self, GE.get_player(event), Config.SELECTION_TYPE_REMOVE_OUTPUT_RESOURCES)
end

function ResourceTable:create_well_pump(event, refs)
    start_selection(self, GE.get_player(event), Config.SELECTION_TYPE_CREATE_WELL_PUMP, {
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
        }), {
            force = true
        })
    end
end)

function ResourceTable:edit_resource_exchange_schema(event, refs)
    local tags = gui.get_tags(event.element)
    local label = refs[tags.type .. '_label'][tags.name]
    local textfield = refs[tags.type .. '_textfield'][tags.name]
    label.visible = false
    textfield.visible = true
    textfield.text = string.gsub(label.caption, '%%', '')
end

function ResourceTable:submit_resource_exchange_schema(event, refs)
    local tags = gui.get_tags(event.element)
    local label = refs[tags.type .. '_label'][tags.name]
    local textfield = refs[tags.type .. '_textfield'][tags.name]
    label.visible = true
    textfield.visible = false
    local base = self:get_selected_base(event.player_index)
    if base then
        label.caption = textfield.text
        local request, reserve
        if tags.type == 'request' then
            request = String.exponent_number(textfield.text)
        else
            reserve = String.exponent_number(textfield.text)
        end
        base:set_resource_exchange(tags.name, request, reserve)
    end
end

return ResourceTable