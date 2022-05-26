local KC = require 'klib/container/container'
local BottomButton = require 'klib/fgui/bottom_button'
local Entity = require 'klib/gmo/entity'

local DistributeButton = KC.singleton('modules.DistributeButton', BottomButton, function(self)
    BottomButton(self)
end)

DistributeButton.RADIUS = 32

function DistributeButton:build_button(player)
    return {
        type = 'sprite-button',
        sprite = 'item/stone-furnace',
        tooltip = {'distribute_button.tooltip'},
        style = 'quick_bar_page_button'
    }
end

function DistributeButton:on_click(event, element)
    local player = game.get_player(event.player_index)
    local p_inv = player.get_main_inventory()
    if not p_inv then
        player.print({"distribute_button.inventory_not_exists"})
        return
    end

    local entities = player.surface.find_entities_filtered({
        type = 'furnace',
        position = player.position,
        radius = DistributeButton.RADIUS,
        force = player.force
    })

    Entity.distribute_fuel(player, entities, true)
    Entity.distribute_smelting_ingredients(player, entities, true)
end

return DistributeButton