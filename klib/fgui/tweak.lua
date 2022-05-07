--- tweak fui with stdlib
--- rewrite fgui's event hook

local gui = require("flib/gui")
local Event = require('klib/event/event')

local gui_event_defines = {}
for name, id in pairs(defines.events) do
    if string.find(name, "^on_gui") then
        gui_event_defines[name] = id
    end
end

function gui.hook_events(callback)
    for _, id in pairs(gui_event_defines) do
        Event.register(id, callback)
    end
end
