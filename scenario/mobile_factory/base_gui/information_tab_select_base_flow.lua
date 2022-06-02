local KC = require 'klib/container/container'
local gui = require 'flib/gui'
local Table = require 'klib/utils/table'
local Type = require 'klib/utils/type'
local GE = require 'klib/gmo/gui_element'
local ColorList = require 'stdlib/utils/defines/color_list'

local TeamCenter = require 'scenario/mobile_factory/base/team_center'
local MobileBase = require 'scenario/mobile_factory/base/mobile_base'

local SelectBaseFlow = {}

local DEFAULT_BASE_NAME = {"mobile_factory_base_gui.information_tab_default_base_name"}

local SelectBaseElemRef = "select_base_list_box"

function SelectBaseFlow.create_structures()
    return {
        GE.flow(false, nil, {
            GE.h1(DEFAULT_BASE_NAME, {font_color=ColorList.lightblue},
                    {ref={"base_name_label"}, tooltip = {"mobile_factory_base_gui.information_tab_base_name_tooltip"}, actions = {on_click="on_open_base_rename"}}),
            GE.textfield("titlebar_search_textfield", {"base_rename_textfield"}, "on_base_renamed"),
            GE.fill_horizontally(),
            GE.sprite_button("item/spidertron-remote", "tool_button", {"mobile_factory_base_gui.information_tab_connect_remote"},
                    {"connect_remote_button"}, "on_connect_remote"),
            GE.sprite_button("entity/spidertron", "tool_button", {"mobile_factory_base_gui.information_tab_base_vehicle_position"},
                    {"locate_base_vehicle_button"}, "on_locate_base_vehicle"),
            GE.sprite_button("utility/gps_map_icon", "tool_button", {"mobile_factory_base_gui.information_tab_base_position"},
                    {"locate_base_button"}, "on_locate_base"),
            GE.sprite_button("entity/character", "tool_button", {"mobile_factory_base_gui.information_tab_select_visiting_base_tooltip"},
                    {"select_visiting_base_button"}, "on_select_visiting_base"),
            GE.sprite_button("utility/dropdown",  "tool_button", {"mobile_factory_base_gui.information_tab_select_base_tooltip"},
                    {"select_base_button"}, "on_open_select_base")

        }),
        GE.list_box("saves_list_box",{SelectBaseElemRef}, "on_selected_base", {
            style_mods = {maximal_width = 1000, horizontally_stretchable = true}
        })
    }
end

local actions = {}
SelectBaseFlow.actions = actions

function SelectBaseFlow:post_build(player, refs)
    self:update_select_base(player, refs)
    refs[SelectBaseElemRef].visible = false
    refs.base_rename_textfield.visible = false
end

function SelectBaseFlow:update(player, refs)
    self:update_select_base(player, refs)
end

function actions:is_on_open_select_base(event, refs)
    return event.element == refs.select_base_button
end

function actions:on_open_select_base(event, refs)
    local player = GE.get_player(event)
    local visible = not refs[SelectBaseElemRef].visible
    self:update_select_base(player, refs)
    refs[SelectBaseElemRef].visible = visible
end

function actions:update_select_base(player, refs)
    local elem = refs[SelectBaseElemRef]
    local selected_base_id = self:get_selected_base_id(player.index)
    elem.clear_items()
    local bases = TeamCenter.get_bases_by_player_index(player.index)
    if not bases then return end
    local base_ids = {}
    local selected = false
    for i = 1, #bases do
        local base = bases[i]
        elem.add_item(base:get_name())
        Table.insert(base_ids, base:get_id())
        if selected_base_id == base:get_id() then
            elem.selected_index = i
            selected = true
        end
    end
    gui.update_tags(elem, { base_ids = base_ids})
    if #base_ids > 0 then
        if not selected then elem.selected_index = 1 end
        self:on_selected_base({player_index = player.index}, refs)
    end
end

function actions:is_on_selected_base(e, refs)
    return e.element == refs[SelectBaseElemRef]
end

function actions:on_selected_base(event, refs)
    local elem = refs[SelectBaseElemRef]
    local player = game.get_player(event.player_index)
    local base_id = gui.get_tags(elem).base_ids[elem.selected_index]
    self:set_selected_base_id(player.index, base_id)
    local base = self:get_selected_base(player.index)
    refs.base_name_label.caption = base and base:get_name() or DEFAULT_BASE_NAME
    self:update_contents(player, refs)
    refs[SelectBaseElemRef].visible = false
end

function actions:is_on_select_visiting_base(e, refs)
    return e.element == refs.select_visiting_base_button
end

function actions:on_select_visiting_base(e, refs)
    local player = GE.get_player(e)
    local base = MobileBase.get_by_visitor(player) or MobileBase.get_by_controller(player)
    if base then
        self:set_selected_base_id(player.index, base:get_id())
        self:refresh(e.player_index)
    else
        player.print({"mobile_factory.you_are_not_visiting_base"})
    end
end

local function can_rename(base, player, refs)
    if base and base:can_rename(player) then
        return true
    else
        player.print({"mobile_factory.cannot_rename_base"})
        refs.base_rename_textfield.visible = false
        return false
    end
end

function actions:is_on_open_base_rename(e, refs)
    return e.element == refs.base_name_label
end

function actions:on_open_base_rename(e, refs)
    local base = self:get_selected_base(e.player_index)
    local player = GE.get_player(e)
    if can_rename(base, player, refs) then
        local name = base:get_name()
        name = Type.is_string(name) and name or ""
        refs.base_rename_textfield.text = name
        refs.base_rename_textfield.visible = not refs.base_rename_textfield.visible
    end
end

function actions:is_on_base_renamed(e, refs)
    return e.element == refs.base_rename_textfield
end

function actions:on_base_renamed(e, refs)
    local base = self:get_selected_base(e.player_index)
    local player = GE.get_player(e)
    if can_rename(base, player, refs) then
        local element = e.element
        if element.text and element.text ~= "" then
            base:set_name(element.text)
            refs.base_name_label.caption = base:get_name()
            refs.base_rename_textfield.visible = false
        end
    end
end

function actions:is_on_locate_base(e, refs)
    return e.element == refs.locate_base_button
end

function actions:on_locate_base(e, refs)
    local base = self:get_selected_base(e.player_index)
    if base then
        GE.get_player(e).open_map(base.center, 1)
    end
end

function actions:is_on_locate_base_vehicle(e, refs)
    return e.element == refs.locate_base_vehicle_button
end

function actions:on_locate_base_vehicle(e, refs)
    local base = self:get_selected_base(e.player_index)
    if base then
        GE.get_player(e).open_map(base.vehicle.position, 1)
    end
end

function actions:is_on_connect_remote(e, refs)
    return e.element == refs.connect_remote_button
end

function actions:on_connect_remote(e, refs)
    local player = GE.get_player(e)
    local stack = player.cursor_stack
    if stack and stack.valid_for_read and stack.name == 'spidertron-remote' then
        local base = self:get_selected_base(e.player_index)
        stack.connected_entity = base.vehicle
    else
        player.print({"mobile_factory_base_gui.need_holding_spider_remote"})
    end
end

return SelectBaseFlow