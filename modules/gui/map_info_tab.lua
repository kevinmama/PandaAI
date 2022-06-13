local KC = require 'klib/container/container'
local GE = require 'klib/fgui/gui_element'
local TabAndContent = require 'klib/fgui/tab_and_content'
local gui = require 'flib/gui'

local MapInfoTab = KC.class("modules.gui.MapInfoTab", TabAndContent, function(self, tabbed_pane)
    TabAndContent(self, tabbed_pane)
    self.caption = {"map_info_tab.tab_captain"}
    self.map_info_main_caption = nil
    self.map_info_sub_caption = nil
    self.map_info_text = nil
end)

function MapInfoTab:build_content(player, parent)
    gui.build(parent, {
        GE.table(nil, "table", 1, nil, {
            GE.hr(),
            GE.label(self.map_info_main_caption, "label", {
                font = "heading-1",
                font_color = { r = 0.6, g = 0.3, b = 0.99 },
                minimal_width = 780,
                horizontal_align = "center",
                vertical_align = "center"
            }),
            GE.label(self.map_info_sub_caption, "label", {
                font = "heading-2",
                font_color = { r = 0.2, g = 0.9, b = 0.2 },
                minimal_width = 780,
                horizontal_align = "center",
                vertical_align = "center"
            }),
            GE.hr()
        }),
        GE.scroll_pane(true, nil, "never", "auto", {
            style_mods = { maximal_height = 320, minimal_height = 320 },
        }, {
            GE.label(self.map_info_text, nil, {
                font = "heading-2",
                single_line = false,
                font_color = { r = 0.85, g = 0.85, b = 0.88 },
                minimal_width = 780,
                horizontal_align = "center",
                vertical_align = "center"
            })
        })
    })
end

return MapInfoTab