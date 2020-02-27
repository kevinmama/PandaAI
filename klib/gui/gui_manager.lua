local KC = require('klib/container/container')
local RootComponent = require('klib/gui/component/root_component')

local GuiManager = KC.singleton('klib.gui.GuiManager', function(self)
end)

GuiManager:on(defines.events.on_player_created, function(self, event)
    KC.get(RootComponent.Top):create_children(event.player_index)
    KC.get(RootComponent.Left):create_children(event.player_index)
    KC.get(RootComponent.Center):create_children(event.player_index)
end)

return GuiManager
