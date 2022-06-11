require 'klib/fgui/tweak'
local KC = require 'klib/container/container'
local BaseComponent = require 'klib/fgui/base_component'

local BaseGui = KC.class('klib.fgui.BaseGui', BaseComponent, function(self)
    BaseComponent(self)
end)

function BaseGui:build(player)
end

function BaseGui:remove(player)
end

BaseGui:on(defines.events.on_player_created, function(self, event)
    self:build(game.get_player(event.player_index))
end)
BaseGui:on(defines.events.on_pre_player_removed, function(self, event)
    self:remove(game.get_player(event.player_index))
end)

return BaseGui
