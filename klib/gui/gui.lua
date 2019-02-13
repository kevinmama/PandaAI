local gui = {}

local Component = require('klib/gui/component')
local Event = require('klib/kevent')
gui.top = Component.top
gui.left = Component.left
gui.center = Component.center

local function expose(component)
    local Component = require('klib/gui/' .. component)
    gui[component] = function(options)
        if (options == gui) then
            error("you should invoke kui." .. component .. " instead of kui:" .. component )
        end
        return Component:create(options)
    end
end

for _,component in pairs({
    'button',
    'flow'
}) do
    expose(component)
end

Event.on_game_ready(function()
    for _, player in pairs(game.connected_players) do
        player.gui.left.clear()
        player.gui.center.clear()
    end
end)

return gui
