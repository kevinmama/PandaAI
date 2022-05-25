local KC = require 'klib/container/container'
local BaseGui = require 'klib/fgui/base_gui'
local gui = require 'flib/gui'

local AutoDistributionGui = KC.singleton('modules.AutoDistributionGui', BaseGui, function(self)
    BaseGui(self)
end)

function AutoDistributionGui:build(player_index)
    local player = game.get_player(player_index)
    gui.build(player.gui.relative, {{
        type = 'label',
        style = 'frame_title',
        caption = "TEST",
    }})
end

return AutoDistributionGui