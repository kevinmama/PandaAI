local KC = require 'klib/container/container'
local AbstractComponent = require 'klib/gui/component/abstract_component'
local dlog = require 'klib/utils/dlog'

local RootComponent = KC.singleton('klib.gui.component.RootComponent', AbstractComponent, function(self)
    AbstractComponent(self)
end)

function RootComponent:get_element(player_index)
    return game.players[player_index].gui[self:get_name()]
end

function RootComponent:get_name()
    return KC.get_class(self).name
end

RootComponent.Top = KC.singleton('klib.gui.component.RootComponent.Top', RootComponent, function(self)
    RootComponent(self)
end)
RootComponent.Top.name = "top"

RootComponent.Left = KC.singleton('klib.gui.component.RootComponent.Left', RootComponent, function(self)
    RootComponent(self)
end)
RootComponent.Left.name = "left"

RootComponent.Center = KC.singleton('klib.gui.component.RootComponent.Center', RootComponent, function(self)
    RootComponent(self)
end)
RootComponent.Center.name = "center"

return RootComponent
