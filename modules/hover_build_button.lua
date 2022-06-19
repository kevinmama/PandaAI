local KC = require 'klib/container/container'
local BottomButton = require 'klib/fgui/bottom_button'
local Entity = require 'klib/gmo/entity'

local HoverBuildButton = KC.singleton('modules.HoverBuildButton', BottomButton, function(self)
    BottomButton(self)
end)

HoverBuildButton:define_player_data("enabled")

function HoverBuildButton:build_button(player)
    local enabled = true
    self:set_enabled(player.index, enabled)
    return {
        type = 'sprite-button',
        sprite = 'item/dummy-steel-axe',
        tooltip = {'hover_build_button.tooltip'},
        style = enabled and "quick_bar_page_button" or "quick_bar_slot_button"
    }
end

function HoverBuildButton:on_click(event, element)
    local enabled = not self:get_enabled(event.player_index)
    self:set_enabled(event.player_index, enabled)
    element.style = enabled and "quick_bar_page_button" or "quick_bar_slot_button"
end

local ItemEntityMapping
local function get_mapping_item(entity_name)
    if not ItemEntityMapping then
        ItemEntityMapping = {}
        for name, prototype in pairs(game.item_prototypes) do
            local result = prototype.place_result
            -- 暂时无法支持铁路
            if result and result.name ~= name and name ~= 'rail' then
                ItemEntityMapping[result.name] = name
            end
        end
    end
    return ItemEntityMapping[entity_name] or entity_name
end

HoverBuildButton:on(defines.events.on_selected_entity_changed, function(self, event)
    if self:get_enabled(event.player_index) then
        local player = game.get_player(event.player_index)
        local entity = event.last_entity
        if entity and entity.valid and (entity.name == 'entity-ghost' or entity == 'tile-ghost') then
            local item_name = get_mapping_item(entity.ghost_name)
            local cursor_stack = player.cursor_stack
            local current_stack
            if cursor_stack and cursor_stack.valid and cursor_stack.valid_for_read then
                if (cursor_stack.name == item_name) and Entity.can_build_reach(player, entity) then
                    current_stack = cursor_stack
                end
            else
                local stack = player.get_main_inventory().find_item_stack(item_name)
                if stack and Entity.can_build_reach(player, entity) then
                    current_stack = stack
                end
            end

            if current_stack then
                local _ , created_entity = entity.revive()
                created_entity.health = created_entity.prototype.max_health * current_stack.health
                current_stack.count = current_stack.count - 1
            end
        end
    end
end)

return HoverBuildButton