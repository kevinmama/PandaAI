local KC = require 'klib/container/container'
local gui = require 'flib/gui'
local Type = require 'klib/utils/type'
local GE = require 'klib/fgui/gui_element'
local BaseComponent = require 'klib/fgui/base_component'
local ColorList = require 'stdlib/utils/defines/color_list'

local Config = require 'scenario/mobile_factory/config'
local TeamCenter = require 'scenario/mobile_factory/base/team_center'
local MobileBase = require 'scenario/mobile_factory/base/mobile_base'

local DEFAULT_BASE_NAME = {"mobile_factory_base_gui.information_tab_default_base_name"}
local SelectBaseElemRef = "select_base_list_box"


local SelectBaseFlow = KC.class(Config.PACKAGE_BASE_GUI_PREFIX .. 'SelectBaseFlow', BaseComponent, function(self, parent)
    BaseComponent(self)
    self.parent = parent
end)

SelectBaseFlow:delegate_method("parent", {
    "get_selected_base",
    "get_selected_base_id"
})

function SelectBaseFlow:build(player, parent)
    self.refs[player.index] = gui.build(parent, {
        GE.flow(false, nil, {
            GE.h1(DEFAULT_BASE_NAME, {font_color=ColorList.lightblue},
                    {ref={"base_name_label"}, tooltip = {"mobile_factory_base_gui.information_tab_base_name_tooltip"}, actions = {on_click="on_open_base_rename"}}),
            GE.textfield("titlebar_search_textfield", {"base_rename_textfield"}, "on_base_renamed", {
                elem_mods = {visible = false}
            }),
            GE.fill_horizontally(),
            GE.sprite_button(self, "item/spidertron-remote", "tool_button", {"mobile_factory_base_gui.information_tab_connect_remote"},
                     "on_connect_remote"),
            GE.sprite_button(self, "entity/spidertron", "tool_button", {"mobile_factory_base_gui.information_tab_base_vehicle_position"},
                     "on_locate_base_vehicle"),
            GE.sprite_button(self, "utility/gps_map_icon", "tool_button", {"mobile_factory_base_gui.information_tab_base_position"},
                     "on_locate_base"),
            GE.sprite_button(self, "entity/character", "tool_button", {"mobile_factory_base_gui.information_tab_select_visiting_base_tooltip"},
                     "on_select_visiting_base"),
            GE.sprite_button(self, "utility/dropdown",  "tool_button", {"mobile_factory_base_gui.information_tab_select_base_tooltip"},
                     "on_open_select_base")

        }),
        GE.list_box("saves_list_box",{SelectBaseElemRef}, "on_selected_base", {
            style_mods = {maximal_width = 1000, horizontally_stretchable = true},
            elem_mods = {visible = false}
        })
    })
end

function SelectBaseFlow:update(player)
    self:update_select_base(player)
    self:update_base_name_label(player)
end

function SelectBaseFlow:on_open_select_base(event, refs)
    local player = GE.get_player(event)
    local visible = not refs[SelectBaseElemRef].visible
    self:update_select_base(player, refs)
    refs[SelectBaseElemRef].visible = visible
end

function SelectBaseFlow:update_select_base(player)
    if self.updating_select_base then return end
    local refs = self.refs[player.index]
    local elem = refs[SelectBaseElemRef]
    local selected_base_id = self:get_selected_base_id(player.index)
    local selected_index
    GE.update_items(elem, {
        records = TeamCenter.get_bases_by_player_index(player.index),
        tag = "base_ids",
        update = function(i, key, base)
            local id = base:get_id()
            if selected_base_id == id then
                selected_index = i
            end
           return base:get_name(), id
        end
    })
    if selected_index then
        elem.selected_index = selected_index
    else
        if #elem.items > 0 then
            elem.selected_index = 1
        end
        -- 这里触发的函数可能会再调用一些本函数
        self.updating_select_base = true
        self:on_selected_base({player_index = player.index}, refs)
        self.updating_select_base = false
    end
end

function SelectBaseFlow:update_base_name_label(player)
    local refs = self.refs[player.index]
    local base = self:get_selected_base(player.index)
    refs.base_name_label.caption = base and base:get_name() or DEFAULT_BASE_NAME
end

function SelectBaseFlow:on_selected_base(event, refs)
    local elem = refs[SelectBaseElemRef]
    local player = game.get_player(event.player_index)
    local base_id = gui.get_tags(elem).base_ids[elem.selected_index]
    refs[SelectBaseElemRef].visible = false
    self.parent:set_selected_base_id(player.index, base_id)
    self.parent:update(player)
end

function SelectBaseFlow:on_select_visiting_base(e, refs)
    local player = GE.get_player(e)
    local base = MobileBase.get_by_visitor(player) or MobileBase.get_by_controller(player)
    if base then
        self.parent:set_selected_base_id(player.index, base:get_id())
        self.parent:update(player)
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

function SelectBaseFlow:on_open_base_rename(e, refs)
    local base = self:get_selected_base(e.player_index)
    local player = GE.get_player(e)
    if can_rename(base, player, refs) then
        local name = base:get_name()
        name = Type.is_string(name) and name or ""
        refs.base_rename_textfield.text = name
        refs.base_rename_textfield.visible = not refs.base_rename_textfield.visible
    end
end

function SelectBaseFlow:on_base_renamed(e, refs)
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

function SelectBaseFlow:on_locate_base(e, refs)
    local base = self:get_selected_base(e.player_index)
    if base then
        GE.get_player(e).open_map(base.center, 1)
    end
end

function SelectBaseFlow:on_locate_base_vehicle(e, refs)
    local base = self:get_selected_base(e.player_index)
    if base then
        GE.get_player(e).open_map(base.vehicle.position, 1)
    end
end

function SelectBaseFlow:on_connect_remote(e, refs)
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