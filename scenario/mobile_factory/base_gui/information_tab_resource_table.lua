local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local gui = require 'flib/gui'
local Table = require 'klib/utils/table'
local GE = require 'klib/gmo/gui_element'
local KPlayer = require 'klib/gmo/player'
local Entity = require 'klib/gmo/entity'
local ColorList = require 'stdlib/utils/defines/color_list'

local Config = require 'scenario/mobile_factory/config'
local Player = require 'scenario/mobile_factory/player/player'

local ResourceTable = {}
local icon_header_caption = { "mobile_factory_base_gui.resource_table_icon_header" }
local icon_header_style_mods = { width = 100, font = "heading-2" }
local icon_style_mods = { width = 100}
local amount_header_caption = { "mobile_factory_base_gui.resource_table_count_header" }
local amount_header_style_mods = { width = 100, font = "heading-2"}
local amount_style_mods = { width = 100 }
local CreateBtnRefName = "create_output_resource_buttons"
local RemoveBtnRefName = "remove_output_resource_button"
local CreateWellPumpRefName = "create_well_pump_button"

function ResourceTable.create_structures()
    return {
        GE.hr(),
        GE.flow(false, nil, {
            GE.h1({"mobile_factory_base_gui.information_tab_resource_caption"}, {width=100}),
            GE.h3("", {font_color = ColorList.green, width = 100}, {ref = {"warping_resource_state_label"}}),
            GE.h3("0", {font_color = ColorList.orange, left_margin = "10"},
                    {ref = {"output_resource_count"}, tooltip={"mobile_factory_base_gui.information_tab_output_resource_tooltip"}}),
            GE.h3("/" .. Config.RESOURCE_WARP_OUT_POINT_LIMIT),
            GE.fill_horizontally(),
            GE.sprite_button("entity/offshore-pump", "tool_button", {"mobile_factory_base_gui.create_well_pump"},
                    {CreateWellPumpRefName}, "create_well_pump"),
            GE.sprite_button("entity/electric-mining-drill", "tool_button_green", {"mobile_factory_base_gui.toggle_warping_resource_tooltip"},
                    {"toggle_warping_resource_button"}, "toggle_warping_resource"),
            GE.sprite_button("utility/side_menu_blueprint_library_icon", "tool_button_blue", {"mobile_factory_base_gui.information_tab_show_warp_resource_area"},
                    {"show_warp_resource_area_button"}, "show_warp_resource_area"),
            GE.sprite_button("utility/trash", "tool_button_red", {"mobile_factory_base_gui.remove_output_resource_tooltip"},
                    {RemoveBtnRefName}, "remove_output_resources"),
        }),
        GE.hr(),
        ResourceTable.create_table_structure()
    }
end

function ResourceTable.create_table_structure()
    local structure = {
        type = "table",
        ref = {"resource_table"},
        column_count = 6,
        children = {}
    }
    for _ = 1, structure.column_count / 2 do
        Table.insert(structure.children, { type='label', caption = icon_header_caption, style_mods = icon_header_style_mods })
        Table.insert(structure.children, { type='label', caption = amount_header_caption, style_mods = amount_header_style_mods })
    end
    return structure
end

function ResourceTable:post_build(player, refs)
    local table = refs.resource_table
    for i = 1, 6 do
        table.style.column_alignments[i] = "center"
    end
end

function ResourceTable:update(refs, selected_base_id)
    local base = selected_base_id and KC.get(selected_base_id)
    ResourceTable:update_others(refs, base)
    ResourceTable:update_table(refs, base)
end

function ResourceTable:update_table(refs, base)
    local tbl = refs.resource_table
    if not base then tbl.clear() return end
    local resources = game.get_filtered_entity_prototypes({{ filter = "type", type = "resource" }})
    if refs[CreateBtnRefName] == nil then refs[CreateBtnRefName] = {} end
    local function get_amount_label(name)
        local is_fluid_resource = Entity.is_fluid_resource(name)
        return (is_fluid_resource and math.floor(base.resource_amount[name] / 3000) .. '%' ) or base.resource_amount[name]
    end
    GE.update_table(tbl,{
        skip_row = 3,
        column_count = 2,
        records = resources,
        create_row = function(table, row, name, resource)
            local row_refs = gui.build(table, {
                GE.flow(false, {style_mods=icon_style_mods}, {
                    {
                        type = 'sprite-button',
                        style = 'slot_button',
                        sprite = 'entity/' .. name,
                        tooltip = {"mobile_factory_base_gui.create_output_resource_button"},
                        ref = { CreateBtnRefName, name},
                        actions = {
                            on_click = "create_output_resource"
                        },
                        tags = {
                            resource_name = name
                        }
                    }
                }),
                GE.label(get_amount_label(name), nil, amount_style_mods),
            })
            Table.merge(refs[CreateBtnRefName], row_refs[CreateBtnRefName])
        end,
        update_row = function(elems, row, name, resource)
            elems[2].caption = get_amount_label(name)
        end
    } )
end

function ResourceTable:update_others(refs, base)
    if base then
        refs.warping_resource_state_label.caption = base:is_warping_in_resources() and {"mobile_factory_base_gui.warping_in_resource_hint"} or ""

        refs.output_resource_count.caption = base:get_output_resources_count()

        local enable = base:is_enable_warping_in_resources()
        refs.toggle_warping_resource_button.style = enable and "tool_button_green" or "tool_button"
    end
end

local actions = {}
ResourceTable.actions = actions

function actions:is_show_warp_resource_area(e, refs)
    return e.element == refs.show_warp_resource_area_button
end

function actions:show_warp_resource_area(e, refs)
    self:get_selected_base(e.player_index):toggle_display_warp_resource_area()
end

function actions:is_toggle_warping_resource(e, refs)
    return e.element == refs.toggle_warping_resource_button
end

function actions:toggle_warping_resource(e, refs)
    local base = self:get_selected_base(e.player_index)
    local enable = base:toggle_warping_in_resources()
    e.element.style = enable and "tool_button_green" or "tool_button"
end

function actions:is_create_output_resource(event, refs)
    local resource_name = gui.get_tags(event.element).resource_name
    return resource_name and event.element == refs[CreateBtnRefName][resource_name]
end

local function pick_selection_tool(self, player, mode, tag)
    local selected_base_id = self:get_selected_base_id(player.index)
    if not selected_base_id then return end
    local mf_player = Player.get(player.index)
    if KPlayer.pick_selection_tool(player) then
        mf_player:set_selection_state(mode, Table.merge({
            base_id = selected_base_id
        }, tag or {}))
    end
end

function actions:create_output_resource(event, refs)
    local tag = gui.get_tags(event.element)
    local resource_name = tag.resource_name
    pick_selection_tool(self, GE.get_player(event), Config.SELECTION_MODE_CREATE_OUTPUT_RESOURCES, {
        resource_name = resource_name
    })
end

function actions:is_remove_output_resources(event, refs)
    return event.element == refs[RemoveBtnRefName]
end

function actions:remove_output_resources(event, refs)
    pick_selection_tool(self, GE.get_player(event), Config.SELECTION_MODE_REMOVE_OUTPUT_RESOURCES)
end

function actions:is_create_well_pump(event, refs)
    return event.element == refs[CreateWellPumpRefName]
end

function actions:create_well_pump(event, refs)
    pick_selection_tool(self, GE.get_player(event), Config.SELECTION_MODE_CREATE_WELL_PUMP)
end

local SUPPORTED_SELECTION_MODE = {
    [Config.SELECTION_MODE_CREATE_OUTPUT_RESOURCES] = true,
    [Config.SELECTION_MODE_REMOVE_OUTPUT_RESOURCES] = true,
    [Config.SELECTION_MODE_CREATE_WELL_PUMP] = true
}

Event.register(defines.events.on_player_selected_area, function(event)
    if event.item == 'selection-tool' then
        local mf_player = Player.get(event.player_index)
        local mode, tag = mf_player:get_selection_state()
        if SUPPORTED_SELECTION_MODE[mode] then
            local base = KC.get(tag.base_id)
            local player = game.get_player(event.player_index)
            if base and not base.destroyed then
                if mode == Config.SELECTION_MODE_CREATE_OUTPUT_RESOURCES then
                    base:create_output_resources(tag.resource_name, event.area, {player=player})
                elseif mode == Config.SELECTION_MODE_REMOVE_OUTPUT_RESOURCES then
                    base:remove_output_resources(event.area, {player=player})
                elseif mode == Config.SELECTION_MODE_CREATE_WELL_PUMP then
                    base:create_well_pump(event.area, {player = player})
                end
            end
        end
    end
end)

return ResourceTable