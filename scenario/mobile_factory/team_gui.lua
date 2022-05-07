local Table = require 'klib/utils/table'
local KC = require 'klib/container/container'
local ModGuiFrame = require 'klib/fgui/mod_gui_frame'
local Team = require 'scenario/mobile_factory/team'
local gui = require 'flib/gui'

local TeamGui = KC.singleton('scenario.MobileFactory.TeamGui', ModGuiFrame, function(self)
    ModGuiFrame(self)
    self.mod_gui_sprite = "virtual-signal/signal-T"
    self.mod_gui_tooltip = {"mobile_factory.mod_gui_team_tooltip"}
    self.mod_gui_frame_caption = {"mobile_factory.mod_gui_team_caption"}
end)

function TeamGui:build_main_frame_structure()
    return {
        type = "frame", style = "tabbed_pane_frame", style_mods = {horizontally_stretchable = true},
        {type = "tabbed-pane", style = "tabbed_pane", ref = {"tabbed_pane"}, style_mods = {horizontally_stretchable = true}, tabs = {
            self:build_overview_tab_structure(),
            self:build_join_requests_tab_structure(),
            --self:build_bonus_tab_structure()
        }}
    }
end

function TeamGui:build_overview_tab_structure()
    return {
        tab = {
            type = "tab",
            caption = {"mobile_factory.team_overview_tab"},
            actions = {
                on_click = "update_overview_tab"
            }
        },
        content = {
            type = "frame", direction = "vertical", {
                type = "table", ref = { "overview_table_header" }, column_count = 3, children = {
                    { type = "label", caption = { "mobile_factory.team_overview_tab_name" }, style_mods = { width = 100, font = "heading-2" } },
                    { type = "label", caption = { "mobile_factory.team_overview_tab_player" }, style_mods = { font = "heading-2", horizontally_stretchable = true } },
                    --{ type = "label", caption = { "mobile_factory.team_overview_tab_kills" }, style_mods = { font = "heading-2", width = 100 } },
                    { type = "label", caption = { "mobile_factory.team_overview_tab_rockets" }, style_mods = { font = "heading-2", width = 100 } }
                }
            }, {
                type = "table", ref={"overview_table"}, column_count = 3, style_mods={minimal_height=100}, children = {}
            }
        }
    }
end

function TeamGui:build_join_requests_tab_structure()
    return {
        tab = {
            type = "tab",
            caption = { "mobile_factory.team_join_requests_tab" },
            actions = {
                on_click = "update_join_requests_tab"
            }
        },
        content = {
            type = "frame", direction = "vertical", {
                type = "flow", direction = "horizontal", ref = {"create_or_join_team_flow"}, elem_mods = {visible = false}, children = {
                    {
                        type = "button",
                        caption = {"mobile_factory.team_join_requests_tab_create_team"},
                        actions = {
                            on_click = "on_create_team"
                        }
                    },
                    { type = "empty-widget", style_mods = {horizontally_stretchable = true}},
                    {  type = "drop-down", ref = {"join_team_drop_down"} },
                    {
                        type = "button",
                        caption = {"mobile_factory.team_join_requests_tab_join_team"} ,
                        actions = {
                            on_click = "on_request_join_team"
                        }
                    }
                }
            }, {
                type = "flow", direction = "horizontal", ref = {"allow_join_team_flow"}, elem_mods = {visible = false}, children = {
                    {
                        type = "checkbox",
                        ref = {"allow_join_checkbox"},
                        caption = {"mobile_factory.team_join_requests_tab_allow_join"},
                        state = false,
                        actions = {
                            on_checked_state_changed = "on_set_allow_join"
                        }
                    },
                    {
                        type = "checkbox",
                        ref = {"allow_auto_join_checkbox"},
                        caption = {"mobile_factory.team_join_requests_tab_allow_auto_join"},
                        state = false,
                        actions = {
                            on_checked_state_changed = "on_set_allow_auto_join"
                        }
                    }
                }
            },{
                type = "line", style = "line", style_mods = ModGuiFrame.SEPARATE_LINE_STYLE_MODS
            },{
                type = "table", ref = { "join_requests_table_header" }, column_count = 4, children = {
                    {
                        type = "label",
                        caption = { "mobile_factory.team_join_requests_tab_player" },
                        style_mods = { font = "heading-2", width = 100 }
                    }
                }
            },{
                type = "table", ref = { "join_requests_table"}, column_count = 4, children = {}
            }
        }
    }
end

function TeamGui:build_bonus_tab_structure()

end

function TeamGui:post_build_mod_gui_frame(data, player)
    data.refs.tabbed_pane.selected_tab_index = 1
    local overview_table_header = data.refs.overview_table_header
    for i=1, overview_table_header.column_count do
        overview_table_header.style.column_alignments[i] = "center"
        data.refs.overview_table.style.column_alignments[i] = "center"
    end
end

function TeamGui:on_create_team(event)
    local team = Team:new(event.player_index)
    self:update_join_requests_tab(event)
    game.print({"mobile_factory.create_team_message", game.get_player(event.player_index).name})
end

function TeamGui:on_request_join_team(event)
    local player = game.get_player(event.player_index)
    local data = self.data[event.player_index]
    local drop_down = data.refs.join_team_drop_down

    -- 检查团队是否存在
    local selected_index = drop_down.selected_index
    local team_name = selected_index > 0 and selected_index <= #drop_down.items and drop_down.get_item(selected_index)
    if not team_name then
        player.print({"mobile_factory.team_not_exists"})
        self:update_join_requests_tab(event)
        return
    end

    -- 检查团队是否允许申请加入
    local team = Team.get_by_name(team_name)
    if not team:can_player_join(player.index) then
        player.print({"mobile_factory.cannot_join_team", team_name})
        self:update_join_requests_tab(event)
        return
    end

    -- 执行申请并向玩家发送消息
    team:request_join(player.index)
    self:update_join_requests_tab(event)

    if not team.allow_auto_join then
        player.print({"mobile_factory.request_join_team", team_name})

        -- 向团长发送消息
        local captain_player = game.get_player(team.captain)
        captain_player.print({"mobile_factory.receive_join_team_request", player.name})
        self:update_join_requests_tab({
            player_index = captain_player.index
        })
    else
        game.print({"mobile_factory.join_team_message", player.name, team_name})
    end
end

function TeamGui:on_set_allow_join(event)
    local team = Team.get_by_player(event.player_index)
    team:set_allow_join(event.element.state)
    self:update_join_requests_tab(event)
end

function TeamGui:on_set_allow_auto_join(event)
    local team = Team.get_by_player(event.player_index)
    team:set_allow_auto_join(event.element.state)
    self:update_join_requests_tab(event)
end

function TeamGui:on_accept_player_request(event)
    local team = Team.get_by_player(event.player_index)
    local request_player_index = gui.get_tags(event.element).request_player_index
    if team:can_player_join(request_player_index) then
        team:accept_join(request_player_index)
        game.print({"mobile_factory.join_team_message", game.get_player(request_player_index).name, team:get_name()})
    else
        game.get_player(event.player_index).print({"mobile_factory.cannot_accept_join_request"})
    end
    self:update_join_requests_tab(event)
    self:update_join_requests_tab({
        player_index = request_player_index
    })
end

function TeamGui:on_reject_player_request(event)
    local team = Team.get_by_player(event.player_index)
    local request_player_index = gui.get_tags(event.element).request_player_index
    team:reject_join(request_player_index)
    game.get_player(request_player_index).print({"mobile_factory.reject_join_team_message", team:get_name()})
    self:update_join_requests_tab(event)
end

local function get_team_overview_data()
    local overview_data = {}
    KC.for_each_object(Team, function(team)
        local rc = {}
        rc.name = team:get_name()
        rc.player_name_list = Table.reduce(team.force.players, function(name_list, player)
            return name_list .. ' ' .. player.name
        end, '')
        --rc.kills = 0 -- FIXME
        rc.rockets_launched = team.force.rockets_launched or 0
        Table.insert(overview_data, rc)
    end)
    return overview_data
end

function TeamGui:update_overview_tab(event)
    local data = self.data[event.player_index]
    local overview_data = get_team_overview_data()
    local t = data.refs.overview_table
    local column_count = t.column_count
    local children = t.children
    --game.print(#children .. " - 更新" .. serpent.line(overview_data))
    Table.each(overview_data, function(rc, i)
        local child = children[i*column_count-1]
        if child then
            children[i*column_count-2].caption = rc.name
            children[i*column_count-1].caption = rc.player_name_list
            --children[i*4-1].caption = rc.kills
            children[i*column_count].caption = rc.rockets_launched
        else
            gui.build(t, {
                { type = "label", caption = rc.name, style_mods = { width = 100 } },
                { type = "label", caption = rc.player_name_list, style_mods = { horizontally_stretchable = true } },
                --{ type = "label", caption = rc.kills , style_mods = { width = 100 } },
                { type = "label", caption = rc.rockets_launched, style_mods = {  width = 100 } }
            })
        end
    end)
end

function TeamGui:update_join_requests_tab(event)
    local team = Team.get_by_player(event.player_index)
    local refs = self.data[event.player_index].refs
    local has_team = team ~= nil
    refs.create_or_join_team_flow.visible = not has_team
    refs.allow_join_team_flow.visible = has_team
    if not has_team then
        local drop_down = refs.join_team_drop_down
        drop_down.clear_items()
        KC.for_each_object(Team, function(team)
            if team.allow_join then
                drop_down.add_item(team:get_name())
            end
        end)
    else
        refs.allow_join_checkbox.state = team.allow_join
        refs.allow_auto_join_checkbox.state = team.allow_auto_join
        self:update_join_request_table(refs.join_requests_table, team)
    end
end

function TeamGui:update_join_request_table(table, team)
    table.clear()
    for request_player_index, _ in pairs(team.join_requests) do
        local request_player_name = game.get_player(request_player_index).name
        gui.build(table, {
            { type = "label", caption = request_player_name, style_mods = { width = 100 } },
            { type = "empty-widget", style_mods = {horizontally_stretchable = true}},
            {
                type = "sprite-button",
                style = "tool_button_green",
                sprite = "utility/check_mark_green",
                actions = {
                    on_click = "on_accept_player_request"
                },
                tags = {request_player_index = request_player_index}
            },
            {
                type = "sprite-button",
                style = "tool_button_red",
                sprite = "utility/close_black",
                actions = {
                    on_click = "on_reject_player_request"
                },
                tags = {request_player_index = request_player_index}
            }
        })
    end
end

TeamGui:on(defines.events.on_player_changed_force, function(self, event)
    Table.each(self.data, function(data, player_index)
        self:update_join_requests_tab({
            player_index = player_index
        })
    end)
end)

return TeamGui