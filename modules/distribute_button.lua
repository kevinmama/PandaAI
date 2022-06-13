local KC = require 'klib/container/container'
local BottomButton = require 'klib/fgui/bottom_button'
local Entity = require 'klib/gmo/entity'
local GE = require 'klib/fgui/gui_element'

local DistributeButton = KC.singleton('modules.DistributeButton', BottomButton, function(self)
    BottomButton(self)
end)

DistributeButton.RADIUS = 32

function DistributeButton:build_button(player)
    return GE.sprite_button( self,
            "item/stone-furnace",
            "quick_bar_page_button",
            {"distribute_button.tooltip"}
    )
end

function DistributeButton:on_click(event, element)
    local player = GE.get_player(event)
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