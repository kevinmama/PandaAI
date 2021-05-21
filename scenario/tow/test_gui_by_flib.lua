-- FOR TEST FLIB.GUI
-- 暂时封存

local Event = require('klib/klib').Event
local Gui = require('__flib__.gui')

Gui.add_templates {
    mouse_filter = { type = "button", mouse_button_filter = { "left" } },
    drag_handle = { type = "empty-widget",
                    style = "draggable_space_header",
                    style_mods = { minimal_width = 30, height = 24,right_margin = 4, horizontally_stretchable = true }
    },
    frame_action_button = { template = "mouse_filter", style = "frame_action_button" }
}

local function debug_print(e)
    game.print(serpent.block(e))
end

Gui.add_handlers {
    titlebar_button = {
        on_gui_click = debug_print
    },
    slot_button = {
        on_gui_click = debug_print
    }
}

Event.on_init(function()
    Gui.init()
    Gui.build_lookup_tables()
end)

Event.on_load(function()
    Gui.build_lookup_tables()
end)

--Gui.register_handlers()
local custom_register_handlers = function ()
    for name, id in pairs(defines.events) do
        if string.sub(name, 1, 6) == "on_gui" then
            Event.register(id, function(e) Gui.dispatch_handlers(e) end)
        end
    end
end
custom_register_handlers()

local function create_gui(player)
    local elems = Gui.build(player.gui.screen, {
        { type = "frame", style = "inner_frame_in_outer_frame", direction = "vertical", save_as = "window", children = {
            { type = "flow", children = {
                { type = "label", style = "frame_title", caption = "Demo GUI" },
                { template = "drag_handle", save_as = "titlebar.drag_handle" },
                { template = "frame_action_button", handlers = "titlebar_button" },
                { template = "frame_action_button", handlers = "titlebar_button" },
                { template = "frame_action_button", handlers = "titlebar_button" }
            } },
            { type = "frame", style = "inside_shallow_frame_with_padding", style_mods = { padding = 12 }, children = {
                { type = "frame", style = "deep_frame_in_shallow_frame", children = {
                    { type = "scroll-pane", style = "tab_scroll_pane", style_mods = { height = 200 }, children = {
                        { type = "table", style = "slot_table", style_mods = { width = 400 }, column_count = 10, save_as = "slot_table" }
                    } }
                } }
            } }
        } }
    })

    elems.titlebar.drag_handle.drag_target = elems.window
    elems.window.force_auto_center()

    Gui.update_filters("slot_button", player.index, { "demo_slot_button" }, "add")

    global.gui = elems
end

Event.on_configuration_changed(function()
    Gui.init()
    create_gui(game.get_player(1))
end)

Event.on_event(defines.events.on_player_created, function(e)
    create_gui(game.get_player(e.player_index))
end)

Event.on_event(defines.events.on_player_main_inventory_changed, function(e)
    -- update GUI
    local table = global.gui.slot_table
    table.clear()
    local player = game.get_player(e.player_index)
    local i = 0
    for name, count in pairs(player.get_main_inventory().get_contents()) do
        i = i + 1
        table.add { type = "sprite-button", name = "demo_slot_button__" .. i, style = "slot_button", sprite = "item/" .. name,
                    number = count }
    end
end)