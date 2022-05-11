local gui = require 'flib/gui'
local mod_gui = require '__core__/lualib/mod-gui'
local KC = require 'klib/container/container'
local Type = require 'klib/utils/type'

local KPanel = KC.singleton("modules.k_panel.KPanel", function(self)
    self.data = {}
    --self.map_info_main_caption = "Mobile Factory"
    --self.map_info_sub_caption = "Warp Resources And Build Your Base"
    self.map_info_main_caption = "移动工厂"
    self.map_info_sub_caption = "折跃资源，建设基地"
    self.map_info_text = "1. 创建或加入团队可开始游戏。\n2. 蜘蛛停在资源上会折跃资源。\n3. 设置蜘蛛物品过滤器可交换物品。过滤器的格子作输出，无过滤器作输入。\n4. 蜘蛛严重受损不可移动，停止折跃资源，电力系统停止工作。\n5. 作者 kevinma 开发交流群 780980177"
end)

function KPanel:build(player)
    self.data[player.index] = {}
    self:build_mod_gui_button(player)
    self:build_k_panel_frame(player)
end

function KPanel:build_mod_gui_button(player)
    gui.add(mod_gui.get_button_flow(player), {
        type = "sprite-button",
        style = mod_gui.button_style,
        sprite = "virtual-signal/signal-K",
        tooltip = {"k_panel.title"},
        actions = {
            on_click = "toggle_scenario_information"
        }
    })
end

local SEPARATE_LINE_STYLE_MODS = {
    top_margin = 4,
    bottom_margin = 4
}

function KPanel:build_k_panel_frame(player)
    local refs = gui.build(mod_gui.get_frame_flow(player), {
        {
            type = "frame",
            direction = "vertical",
            ref = {"k_panel"},
            style = mod_gui.frame_style,
            style_mods = { minimal_width = 800 },
            actions = {
                on_closed = "close"
            },
            { type = "flow", ref = {"title_bar_flow"}, children = {
                {type = "label", style = "frame_title", caption = {"k_panel.title"}, ignored_by_interaction = true},
                {type = "empty-widget", style = "draggable_space", style_mods = {horizontally_stretchable = true}, ignored_by_interaction = true},
                {
                    type = "sprite-button",
                    style = "frame_action_button",
                    sprite = "utility/close_white",
                    hovered_sprite = "utility/close_black",
                    clicked_sprite = "utility/close_black",
                    mouse_button_filter = {"left"},
                    actions = {
                        on_click = "close"
                    }
                }
            }},

            {type = "frame", style = "tabbed_pane_frame", style_mods = {horizontally_stretchable = true},
             {type = "tabbed-pane", style = "tabbed_pane", ref = {"tabbed_pane"}, style_mods = {horizontally_stretchable = true},
              {
                  tab = {type = "tab", caption = {"k_panel.map_info_title"}},
                  content = {
                      type = "frame", style = "frame" , direction = "vertical", {
                          type = "table", style = "table", column_count = 1, children = {
                              {type = "line", style = "line", style_mods = SEPARATE_LINE_STYLE_MODS},
                              {type = "label", style = "label", caption = self.map_info_main_caption, style_mods = {
                                  font = "heading-1",
                                  font_color = {r = 0.6, g = 0.3, b = 0.99},
                                  minimal_width = 780,
                                  horizontal_align = "center",
                                  vertical_align = "center"
                              }},
                              {type = "label", style = "label", caption = self.map_info_sub_caption, style_mods = {
                                  font = "heading-2",
                                  font_color = {r = 0.2, g = 0.9, b = 0.2},
                                  minimal_width = 780,
                                  horizontal_align = "center",
                                  vertical_align = "center"
                              }},
                              {type = "line", style = "line", style_mods = SEPARATE_LINE_STYLE_MODS}
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
                                      font_color = {r = 0.85, g = 0.85, b = 0.88},
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
        }
    })

    --refs.title_bar_flow.drag_target = refs.k_panel
    player.opened = refs.k_panel
    refs.tabbed_pane.selected_tab_index = 1
    self.data[player.index] = {
        refs = refs,
        visible = false
    }
end

function KPanel:toggle_scenario_information(event)
    local visible = self.data[event.player_index].refs.k_panel.visible
    if visible then
        self:close(event)
    else
        self:open(event)
    end
end

function KPanel:open(event)
    local player = game.get_player(event.player_index)
    local data = self.data[event.player_index]
    data.refs.k_panel.visible = true
    player.opened = data.refs.k_panel
end

function KPanel:close(event)
    local player = game.get_player(event.player_index)
    local data = self.data[event.player_index]
    data.refs.k_panel.visible = false
    if player.opened then
        player.opened = nil
    end
end

KPanel:on(defines.events.on_player_created, function(self, event)
    self:build(game.get_player(event.player_index))
end)

function KPanel:hook_events()
    gui.hook_events(function(e)
        local action = gui.read_action(e)
        if action then
            local handler = self[action]
            if Type.is_function(handler) then
                handler(self, e)
            end
        end
    end)
end

function KPanel:on_ready()
    self:hook_events()
end

return KPanel