local KC = require 'klib/container/container'
local ModGuiFrameButton = require 'klib/fgui/mod_gui_frame_button'

local KPanel = KC.singleton("modules.KPanel.KPanel", ModGuiFrameButton, function(self)
    ModGuiFrameButton(self)
    self.mod_gui_sprite = "virtual-signal/signal-K"
    self.mod_gui_tooltip = {"k_panel.mod_gui_button_tooltip"}
    self.mod_gui_frame_caption = {"k_panel.mod_gui_frame_caption"}

    self.map_info_main_caption = {"k_panel.map_info_main_caption"}
    self.map_info_sub_caption = {"k_panel.map_info_sub_caption"}
    self.map_info_text = {"k_panel.map_info_text"}
end)

local SEPARATE_LINE_STYLE_MODS = {
    top_margin = 4,
    bottom_margin = 4
}

function KPanel:create_frame_structure()
    return {
        type = "frame", style = "tabbed_pane_frame", style_mods = { horizontally_stretchable = true },
        { type = "tabbed-pane", style = "tabbed_pane", ref = { "tabbed_pane" }, style_mods = { horizontally_stretchable = true },
          {
              tab = { type = "tab", caption = { "k_panel.map_info_title" } },
              content = {
                  type = "frame", style = "frame", direction = "vertical", {
                      type = "table", style = "table", column_count = 1, children = {
                          { type = "line", style = "line", style_mods = SEPARATE_LINE_STYLE_MODS },
                          { type = "label", style = "label", caption = self.map_info_main_caption, style_mods = {
                              font = "heading-1",
                              font_color = { r = 0.6, g = 0.3, b = 0.99 },
                              minimal_width = 780,
                              horizontal_align = "center",
                              vertical_align = "center"
                          } },
                          { type = "label", style = "label", caption = self.map_info_sub_caption, style_mods = {
                              font = "heading-2",
                              font_color = { r = 0.2, g = 0.9, b = 0.2 },
                              minimal_width = 780,
                              horizontal_align = "center",
                              vertical_align = "center"
                          } },
                          { type = "line", style = "line", style_mods = SEPARATE_LINE_STYLE_MODS }
                      }
                  }, {
                      type = "scroll-pane",
                      direction = "vertical",
                      horizontal_scroll_policy = 'never',
                      vertical_scroll_policy = 'auto',
                      style_mods = { maximal_height = 320, minimal_height = 320 },
                      children = {
                          {
                              type = "label",
                              caption = self.map_info_text,
                              style_mods = {
                                  font = "heading-2",
                                  single_line = false,
                                  font_color = { r = 0.85, g = 0.85, b = 0.88 },
                                  minimal_width = 780,
                                  horizontal_align = "center",
                                  vertical_align = "center"
                              }
                          }
                      }
                  }
              },
              --content = {type = "table", style = "slot_table", column_count = 10, ref = {"tables", 1}}
          },
            --{
            --    tab = {type = "tab", caption = "2"},
            --    content = {type = "table", style = "slot_table", column_count = 10, ref = {"tables", 2}}
            --}
        }
    }
end

function KPanel:post_build(refs, player)
    refs.tabbed_pane.selected_tab_index = 1
    refs.mod_gui_frame.visible = true
end

return KPanel