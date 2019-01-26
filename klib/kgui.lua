require 'stdlib/event/gui'
local KGui = {}

local event_handlers = {}

local function register_gui(event_id, name)
    Gui.register(event_id, name, function(event)
        event_handlers[event_id][name][event.player_index]()
    end)
end

local function register(event_id, element, handler)
    local need_register_gui = false
    if not event_handlers[event_id] then
        event_handlers[event_id] = {}
        need_register_gui = true
    end

    if not event_handlers[event_id][element.name] then
        event_handlers[event_id][element.name] = {}
        need_register_gui = true
    end

    if need_register_gui then
        register_gui(event_id, element.name)
    end

    event_handlers[event_id][element.name][element.player_index] = handler
end

function KGui.on_click(element, handler)
    register(defines.events.on_gui_click, element, handler)
end

return KGui