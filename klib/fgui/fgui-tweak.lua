--- Tweak fui with stdlib
--- rewrite fgui's event hook

local gui = require("__flib__.gui-beta")
local Event = require('__stdlib__/stdlib/event/event')

local gui_event_defines = {}
for name, id in pairs(defines.events) do
    if string.find(name, "^on_gui") then
        gui_event_defines[name] = id
        --event_id_to_string_mapping[id] = string.gsub(name, "^on_gui", "on")
    end
end

function gui.hook_events(callback)
    --local on_event = script.on_event
    for _, id in pairs(gui_event_defines) do
        --on_event(id, callback)
        Event.register(id, callback)
    end
end
