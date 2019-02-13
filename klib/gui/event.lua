require 'stdlib/event/gui'

local GuiEvent = Gui


local event_handlers = {}

local function hook_event_handlers(event_id, name)
    Gui.register(event_id, name, function(event)
        event_handlers[event_id][name][event.player_index]()
    end)
end

local function register_by_element(event_id, element, handler)
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
        hook_event_handlers(event_id, element.name)
    end

    event_handlers[event_id][element.name][element.player_index] = handler
end

function GuiEvent.on_click_element(element, handler)
    register_by_element(defines.events.on_gui_click, element, handler)
end

return GuiEvent

