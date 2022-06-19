local KC = require 'klib/container/container'
local BottomButton = require 'klib/fgui/bottom_button'
local Entity = require 'klib/gmo/entity'

local HoverBuildButton = KC.singleton('modules.HoverBuildButton', BottomButton, function(self)
    BottomButton(self)
end)

HoverBuildButton:define_player_data("enabled")

function HoverBuildButton:build_button(player)
    self:set_enabled(player.index, false)
    return {
        type = 'sprite-button',
        sprite = 'item/dummy-steel-axe',
        tooltip = {'hover_build_button.tooltip'},
        style = 'quick_bar_page_button'
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
            local cursor_stack = player.cursor_stack
            if cursor_stack and cursor_stack.valid and cursor_stack.valid_for_read
                    and (cursor_stack.name == get_mapping_item(entity.ghost_name)) then
                if Entity.can_build_reach(player, entity) and player.can_build_from_cursor({
                    position = entity.position,
                    direction = entity.direction,
                    terrain_building_size = 1,
                    skip_fog_of_war = false
                }) then
                    local _ , created_entity = entity.revive()
                    created_entity.health = created_entity.prototype.max_health * cursor_stack.health
                    cursor_stack.count = cursor_stack.count - 1
                else
                    Entity.create_flying_text(entity, {"hover_build_button.cannot_build_from_cursor"})
                end
            end
        end
    end
end)

return HoverBuildButton