local KC = require 'klib/container/container'
local Table = require 'klib/utils/table'
local BottomButton = require 'klib/fgui/bottom_button'
local GE = require 'klib/fgui/gui_element'
local Entity = require 'klib/gmo/entity'
local SelectionTool = require 'klib/gmo/selection_tool'

local Config = require 'scenario/mobile_factory/config'
local Player = require 'scenario/mobile_factory/player/player'
local Team = require 'scenario/mobile_factory/player/team'
local TeamCenter = require 'scenario/mobile_factory/base/team_center'
local MobileBase = require 'scenario/mobile_factory/base/mobile_base'


local BaseTeleportButton = KC.singleton(Config.PACKAGE_BASE_GUI_PREFIX .. "BaseTeleportButton", BottomButton, function(self)
    BottomButton(self)
end)

function BaseTeleportButton:build_button(player)
    local structure = GE.sprite_button(
            "entity/character",
            "quick_bar_page_button",
            {"mobile_factory_base_gui.base_teleport_button_tooltip"}
    )
    structure.actions = nil
    return structure
end

function BaseTeleportButton:on_click(event, refs)
    SelectionTool.start_selection(GE.get_player(event), Config.SELECTION_TYPE_SELECT_BASE)
end

SelectionTool.register_selection(Config.SELECTION_TYPE_TELEPORT_BASE, function(event)
    -- 如果做索引，找基地起来会更快。但我觉得这个不很必需
    local mf_player = Player.get(event.player_index)
    if mf_player.team then
        local player = mf_player.player
        local position = mf_player.visiting_base and mf_player.visiting_base:get_position() or player.position
        local bases = MobileBase.find_bases_in_radius(position, Config.PLAYER_NEAR_BASE_DISTANCE, mf_player.team:get_id())
        local base = Table.find(bases, function(base)
            return base:is_position_inside(event.area.left_top)
        end)
        if base then
            if not base:teleport_player_to_exit(player) then
                player.print({"mobile_factory_base_gui.teleport_to_selected_base_failed"})
            end
        else
            player.print({"mobile_factory_base_gui.you_are_too_far_from_the_selected_base"})
        end
    end
end)

SelectionTool.register_reverse_selection(Config.SELECTION_TYPE_TELEPORT_BASE, function(event)
    local mf_player = Player.get(event.player_index)
    if mf_player.visiting_base then
        mf_player.visiting_base:teleport_player_to_vehicle(mf_player.player)
    end
end)

return BaseTeleportButton
