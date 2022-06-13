local KC = require 'klib/container/container'
local BottomButton = require 'klib/fgui/bottom_button'
local Entity = require 'klib/gmo/entity'
local GE = require 'klib/fgui/gui_element'

local CollectOutputButton = KC.singleton('modules.CollectOutputButton', BottomButton, function(self)
    BottomButton(self)
end)

CollectOutputButton.RADIUS = 32

function CollectOutputButton:build_button(player)
    return GE.sprite_button( self,
            'item/assembling-machine-2',
            "quick_bar_page_button",
            {'collect_output_button.tooltip'}
    )
end

function CollectOutputButton:on_click(event, element)
    local player = GE.get_player(event)
    local p_inv = player.get_main_inventory()
    if not p_inv then
        player.print({"collect_output_button.inventory_not_exists"})
        return
    end

    local entities = player.surface.find_entities_filtered({
        type = {'furnace', 'assembling-machine'},
        position = player.position,
        radius = CollectOutputButton.RADIUS,
        force = player.force
    })

    Entity.collect_outputs(player, entities, true)
end

return CollectOutputButton