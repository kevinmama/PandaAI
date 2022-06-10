local KC = require 'klib/container/container'
local BottomButton = require 'klib/fgui/bottom_button'

local ClearCorpseButton = KC.singleton('modules.ClearCorpseButton', BottomButton, function(self)
    BottomButton(self)
end)

ClearCorpseButton.RADIUS = 32

function ClearCorpseButton:build_button(player)
    return {
        type = 'sprite-button',
        sprite = 'entity/behemoth-biter-corpse',
        tooltip = {'clear_corpse_button.tooltip'},
        style = 'quick_bar_page_button',
    }
end

function ClearCorpseButton:on_click(event, element)
    local player = game.get_player(event.player_index)
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