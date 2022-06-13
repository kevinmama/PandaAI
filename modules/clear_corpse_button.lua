local KC = require 'klib/container/container'
local BottomButton = require 'klib/fgui/bottom_button'
local GE = require 'klib/fgui/gui_element'

local ClearCorpseButton = KC.singleton('modules.ClearCorpseButton', BottomButton, function(self)
    BottomButton(self)
end)

ClearCorpseButton.RADIUS = 32

function ClearCorpseButton:build_button(player)
    return GE.sprite_button( self,
            'entity/behemoth-biter-corpse',
            "quick_bar_page_button",
            {'clear_corpse_button.tooltip'}
    )
end

function ClearCorpseButton:on_click(event, element)
    local player = GE.get_player(event)
    local entities = player.surface.find_entities_filtered({
        type = 'corpse',
        position = player.position,
        radius = ClearCorpseButton.RADIUS
    })
    for _, corpse in pairs(entities) do
        corpse.destroy()
    end
end

return ClearCorpseButton