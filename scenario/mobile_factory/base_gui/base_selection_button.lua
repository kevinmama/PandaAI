local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local Table = require 'klib/utils/table'
local BottomButton = require 'klib/fgui/bottom_button'
local GE = require 'klib/fgui/gui_element'
local SelectionTool = require 'klib/gmo/selection_tool'

local Config = require 'scenario/mobile_factory/config'
local Player = require 'scenario/mobile_factory/player/player'
local Team = require 'scenario/mobile_factory/player/team'
local MobileBase = require 'scenario/mobile_factory/base/mobile_base'


local BaseSelectionButton = KC.singleton(Config.PACKAGE_BASE_GUI_PREFIX .. "BaseSelectionButton", BottomButton, function(self)
    BottomButton(self)
end)

function BaseSelectionButton:build_button(player)
    return GE.sprite_button(self,
            "item/spidertron-remote",
            "quick_bar_page_button",
            {"mobile_factory_base_gui.base_selection_button_tooltip"}
    )
end

function BaseSelectionButton:on_click(event, refs)
    SelectionTool.start_selection(GE.get_player(event), Config.SELECTION_TYPE_SELECT_BASE)
end

Event.register(defines.events.on_player_cursor_stack_changed, function(event)
    local player = game.get_player(event.player_index)
    local type, tags = SelectionTool.get_selection_state(player)
    if type == Config.SELECTION_TYPE_SELECT_BASE then
        local base_ids = tags and tags.base_ids or {}
        local bases = Table.map(base_ids, function(base_id)
            return KC.get_valid(base_id)
        end, true)
        local mf_player = Player.get(event.player_index)
        mf_player:set_selected_bases(bases)
    end
end)

SelectionTool.register_selection(Config.SELECTION_TYPE_SELECT_BASE, function(event)
    local team_id = Team.get_id_by_player_index(event.player_index)
    if team_id then
        local bases = MobileBase.find_bases_in_area(event.area, team_id)
        local base_ids = Table.map(bases, function(base) return base:get_id()  end)
        local mf_player = Player.get(event.player_index)
        local player = mf_player.player
        SelectionTool.update_selection_tags(player, {
            base_ids = base_ids
        })
        player.cursor_stack.label = Table.concat(base_ids, ',')
        mf_player:set_selected_bases(bases)
    end
end)

SelectionTool.register_alt_selection(Config.SELECTION_TYPE_SELECT_BASE, function(event)
    local mf_player = Player.get(event.player_index)
    mf_player:order_selected_bases(Config.ORDER_FOLLOW, event.area)
end)

SelectionTool.register_reverse_selection(Config.SELECTION_TYPE_SELECT_BASE, function(event)
    local mf_player = Player.get(event.player_index)
    mf_player:order_selected_bases(Config.ORDER_MOVE, event.area)
end)

return BaseSelectionButton
