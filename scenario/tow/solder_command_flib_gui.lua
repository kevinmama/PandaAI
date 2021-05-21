local KLib = require 'klib/klib'
local Event = KLib.Event
local KC = KLib.Container

local FGuiManager = KLib.FGuiManager
local gui = FGuiManager.gui

-- similar to CSS style
gui.add_templates({
    base = {
        drag_handle = {
            type = "empty-widget",
            style = "draggable_space_header",
            style_mods = { minimal_width = 30, height = 24, right_margin = 4, horizontally_stretchable = true }
        },
        mouse_filter = { type = "button", mouse_button_filter = { "left" } },
    },
    main = {
        frame = {
            type = 'frame',
            style = 'inner_frame_in_outer_frame',
            style_mods = { minimal_width = 800 },
            direction = 'vertical'
        },
        frame_action_button = {
            template = 'base.mouse_filter',
            style = 'frame_action_button'
        },
        tabbed_pane = {
            type = "tabbed-pane",
            style_mods = { minimal_width = 600, height = 24, left_margin = 4, right_margin = 4 }
        },
        tab_label = {
            type = "tab"
        },
        tab_content = {
            type = 'label'
        }
    },
})

FGuiManager:register_gui_creator(function(player)
    local elems = gui.build(player.gui.screen, {
        { template = 'main.frame', save_as = 'window', children = {
            { type = "flow", children = {
                { type = "label", style = "frame_title", caption = "TOW" },
                { template = "main.tabbed_pane", save_as = "title_bar.tabbed_pane", children = {
                    { type = 'tab-and-content',
                      tab = { template = 'main.tab_label', caption = 'info'},
                      content = { template = 'main.tab_content', caption = 'info-content'}
                    },
                    { type = 'tab-and-content',
                      tab = { template = 'main.tab_label', caption = 'path-finder'},
                      content = { template = 'main.tab_content', caption = 'path-finder-content'}
                    },
                } },
                { template = "base.drag_handle", save_as = "title_bar.drag_handle" },
                { template = "main.frame_action_button", caption = "X" },
            } },
        } }
    })

    elems.title_bar.drag_handle.drag_target = elems.window
    elems.window.force_auto_center()
end)
