local Gui = require  'stdlib/event/gui'

local Proxy = {
    register = Gui.register,
    on_click = Gui.on_click,
    on_checked_state_changed = Gui.on_checked_state_changed,
    on_elem_changed = Gui.on_elem_changed,
    on_selection_state_changed = Gui.on_selection_state_changed,
    on_text_changed = Gui.on_text_changed,
    remove = Gui.remove
}


return Proxy

