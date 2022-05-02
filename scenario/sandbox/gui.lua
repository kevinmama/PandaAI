require 'klib/fgui/fgui-tweak'
--local Event = require('stdlib/event/event')
local Event = require('klib/event/event')
local gui = require("__flib__.gui-beta")

local log = (require 'stdlib/misc/logger')('sandbox_fgui', DEBUG)

-- gui.hook_events(function(e)
--    local msg = gui.read_action(e)
--    if msg then
--         read the action to determine what to do
    --end
--end)

Event.register(defines.events.on_gui_click, function(e)
    local msg = gui.read_action(e)
    log(msg)
    if msg then
        if msg.action == 'close' then
            log(global.guis[e.player_index])
            log(msg.gui)
            log(global.guis[e.player_index][msg.gui])
            global.guis[e.player_index][msg.gui].window.destroy()
        end
    end
end)

--event.on_gui_click(function(e)
--    local action = gui.read_action(e)
--    if action then
--        -- do stuff
--    end
--end)

if not global.guis then
    global.guis = {}
end

local function create_gui(player)
    local elems = gui.build(player.gui.screen, {
        {
            type = "frame",
            direction = "vertical",
            ref  =  {"window"},
            actions = {
                on_closed = {gui = "demo", action = "close"}
            },
            children = {
                -- titlebar
                {type = "flow", ref = {"titlebar", "flow"}, children = {
                    {type = "label", style = "frame_title", caption = "Menu", ignored_by_interaction = true},
                    {type = "empty-widget", ref = {"titlebar", "drag_handle"}, style = "flib_titlebar_drag_handle"},
                    {
                        type = "sprite-button",
                        style = "frame_action_button",
                        sprite = "utility/close_white",
                        hovered_sprite = "utility/close_black",
                        clicked_sprite = "utility/close_black",
                        ref = {"titlebar", "close_button"},
                        actions = {
                            on_click = {gui = "demo", action = "close"}
                        }
                    }
                }},
                {type = "frame", style = "inside_deep_frame_for_tabs", children = {
                    {type = "tabbed-pane", tabs = {
                        {
                            tab = {type = "tab", caption = "1"},
                            content = {type = "table", style = "slot_table", column_count = 10, ref = {"tables", 1}}
                        },
                        {
                            tab = {type = "tab", caption = "2"},
                            content = {type = "table", style = "slot_table", column_count = 10, ref = {"tables", 2}}
                        }
                    }}
                }}
            }
        }
    })

    elems.titlebar.drag_handle.drag_target = elems.window
    global.guis[player.index] = {demo = elems}
end

Event.on_game_ready(function(e)
     create_gui(game.get_player(1))
end)

-- Event.on_event(defines.events.on_player_created, function(e)
--    create_gui(game.get_player(e.player_index))
-- end)

-- Event.on_configuration_changed(function()
--    create_gui(game.get_player(1))
-- end)