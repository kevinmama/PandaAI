local KC = require 'klib/container/container'
local Table = require 'klib/utils/table'
local ModGuiFrameButton = require 'klib/fgui/mod_gui_frame_button'
local gui = require 'flib/gui'

local Config = require 'scenario/mobile_factory/config'
local Team = require 'scenario/mobile_factory/player/team'
local Player = require 'scenario/mobile_factory/player/player'

local TeamGui = KC.singleton(Config.PACKAGE_PLAYER_PREFIX .. 'TeamGui', ModGuiFrameButton, function(self)
    ModGuiFrameButton(self)
    self.mod_gui_sprite = "virtual-signal/signal-T"
    self.mod_gui_tooltip = {"mobile_factory.mod_gui_team_tooltip"}
    self.mod_gui_frame_caption = {"mobile_factory.mod_gui_team_caption"}
    self.force_check_action = false
end)

function TeamGui:create_frame_structure()
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
                type = "table", ref = { "overview_table_header" }, column_count = 4, children = {
                    { type = "label", caption = { "mobile_factory.team_overview_tab_name" }, style_mods = { width = 100, font = "heading-2" } },
                    { type = "label", caption = { "mobile_factory.team_overview_tab_player" }, style_mods = { font = "heading-2", horizontally_stretchable = true } },
                    --{ type = "label", caption = { "mobile_factory.team_overview_tab_kills" }, style_mods = { font = "heading-2", width = 100 } },
                    { type = "label", caption = { "mobile_factory.team_overview_tab_rockets" }, style_mods = { font = "heading-2", width = 100 } },
                    { type = "label", caption = { "mobile_factory.team_overview_tab_spectate" }, style_mods = { font = "heading-2", width = 50 } },
                }
            }, {
                type = "table", ref={"overview_table"}, column_count = 4, style_mods={minimal_height=100}, children = {}
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
                    {  type = "drop-down", ref = {"join_team_drop_down"} },
                    {
                        type = "button",
                        style = "confirm_button",
                        caption = {"mobile_factory.team_join_requests_tab_join_team"} ,
                        actions = {
                            on_click = "on_request_join_team"
                        }
                    },
                    { type = "empty-widget", style_mods = {horizontally_stretchable = true}},
                    {
                        type = "button",
                        style = "confirm_button",
                        caption = {"mobile_factory.team_join_requests_tab_create_team"},
                        actions = {
                            on_click = "on_create_team"
                        }
                    },
                }
            }, {
                type = "flow", direction = "horizontal", ref = {"allow_join_team_flow"}, elem_mods = {visible = false}, children = {
                    {
                        type = "checkbox",
                        ref = {"allow_join_checkbox"},
                        caption = {"mobile_factory.team_join_requests_tab_allow_join"},
                        state = true,
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
                    },
                    { type = "empty-widget", style_mods = {horizontally_stretchable = true}},
                    {
                        type = "button",
                        ref = {"reset_button"},
                        style = "red_back_button",
                        caption = {"mobile_factory.reset_button_caption"},
                        elem_mods = {visible = false},
                        actions = {
                            on_click = "on_reset_player"
                        }
                    }
                }
            },{
                type = "line", style = "line", style_mods = ModGuiFrameButton.SEPARATE_LINE_STYLE_MODS
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

function TeamGui:post_build(refs, player)
    refs.tabbed_pane.selected_tab_index = 1
    local overview_table_header = refs.overview_table_header
    for i=1, overview_table_header.column_count do
        overview_table_header.style.column_alignments[i] = "center"
        refs.overview_table.style.column_alignments[i] = "center"
    end
end

function TeamGui:on_spectate_team(event)
    local k_player = Player.get(event.player_index)
    local team_id = gui.get_tags(event.element).team_id
    k_player:spectate_team(team_id and KC.get(team_id))
end

function TeamGui:on_create_team(event)
    if Team.get_by_player_index(event.player_index) then
        local player = game.get_player(event.player_index)
        player.print({"mobile_factory.has_join_team_message"})
        return
    end
    local team = Team:new(event.player_index)
    self:update_join_requests_tab(event)
    game.print({"mobile_factory.create_team_message", team:get_name()})
end

function TeamGui:on_request_join_team(event, refs)
    local player = game.get_player(event.player_index)
    local drop_down = refs.join_team_drop_down

    -- 检查团队是否存在
    local selected_index = drop_down.selected_index
    local team_id = gui.get_tags(drop_down)[selected_index]
    local team = team_id and KC.get(team_id)
    if not team or team.destroyed then
        player.print({"mobile_factory.team_not_exists"})
        self:update_join_requests_tab(event)
        return
    end

    local team_name = team:get_name()
    -- 检查团队是否允许申请加入
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
        team.captain.print({"mobile_factory.receive_join_team_request", player.name})
        self:update_join_requests_tab({
            player_index = team.captain.index
        })
    else
        game.print({"mobile_factory.join_team_message", player.name, team_name})
    end
end

function TeamGui:on_set_allow_join(event)
    local team = Team.get_by_player_index(event.player_index)
    team:set_allow_join(event.element.state)
    self:update_join_requests_tab(event)
end

function TeamGui:on_set_allow_auto_join(event)
    local team = Team.get_by_player_index(event.player_index)
    team:set_allow_auto_join(event.element.state)
    self:update_join_requests_tab(event)
end

function TeamGui:on_accept_player_request(event)
    local team = Team.get_by_player_index(event.player_index)
    local request_player_index = gui.get_tags(event.element).request_player_index
    if team:can_player_join(request_player_index) then
        team:accept_join(request_player_index)
        game.print({"mobile_factory.join_team_message", game.get_player(request_player_index).name, team:get_name()})
    else
        team:cancel_join_request(request_player_index)
        game.get_player(event.player_index).print({"mobile_factory.cannot_accept_join_request"})
    end
    self:update_join_requests_tab(event)
    self:update_join_requests_tab({
        player_index = request_player_index
    })
end

function TeamGui:on_reject_player_request(event)
    local team = Team.get_by_player_index(event.player_index)
    local request_player_index = gui.get_tags(event.element).request_player_index
    team:reject_join(request_player_index)
    game.get_player(request_player_index).print({"mobile_factory.reject_join_team_message", team:get_name()})
    self:update_join_requests_tab(event)
end

function TeamGui:on_reset_player(event)
    local k_player = Player.get(event.player_index)
    if not k_player:can_reset() then
        k_player.player.print({"mobile_factory.cannot_reset_player"})
    else
        k_player:reset()
    end
    self:update_join_requests_tab(event)
end

local function get_team_overview_data()
    local overview_data = {}
    KC.for_each_object(Team, function(team)
        local rc = {}
        rc.team_id = team:get_id()
        rc.name = team:get_name()
        rc.player_name_list = Table.reduce(team:get_members(), function(name_list, player)
            return name_list .. ' ' .. player.name
        end, '')
        --rc.kills = 0 -- FIXME
        rc.rockets_launched = team.force.rockets_launched or 0
        if team:is_main_team() then
            Table.insert(overview_data, 1, rc)
        else
            Table.insert(overview_data, rc)
        end
    end)
    return overview_data
end

function TeamGui:update_overview_tab(event, refs)
    local overview_data = get_team_overview_data()
    local t = refs.overview_table
    local column_count = t.column_count
    local children = t.children
    --game.print(#children .. " - 更新" .. serpent.line(overview_data))
    --t.clear()
    Table.each(overview_data, function(rc, i)
        local child = children[i*column_count]
        if child then
            children[i*column_count-3].caption = rc.name
            children[i*column_count-2].caption = rc.player_name_list
            --children[i*4-1].caption = rc.kills
            children[i*column_count-1].caption = rc.rockets_launched
            gui.set_tags(children[i*column_count], {team_id = rc.team_id})
            gui.set_action(children[i*column_count], "on_click", "on_spectate_team")
        else
            gui.build(t, {
                { type = "label", caption = rc.name, style_mods = { width = 100 } },
                { type = "label", caption = rc.player_name_list, style_mods = { horizontally_stretchable = true } },
                --{ type = "label", caption = rc.kills , style_mods = { width = 100 } },
                { type = "label", caption = rc.rockets_launched, style_mods = {  width = 100 } },
                { type = 'sprite-button', style='slot_button', sprite='item/raw-fish', actions = {
                    on_click = "on_spectate_team"
                }, tags = {team_id = rc.team_id}}
            })
        end
    end)
    for j = #overview_data*column_count + 1, #children do
        children[j].destroy()
    end
end

function TeamGui:update_join_requests_tab(event)
    local team = Team.get_by_player_index(event.player_index)
    local refs = self.refs[event.player_index]
    local has_team = team ~= nil
    refs.create_or_join_team_flow.visible = not has_team
    refs.allow_join_team_flow.visible = has_team
    if not has_team then
        self:update_select_team_drop_down(refs)
    else
        local allow_checkbox_visible = event.player_index == (team.captain and team.captain.index)
        refs.allow_join_checkbox.visible = allow_checkbox_visible
        refs.allow_auto_join_checkbox.visible = allow_checkbox_visible
        refs.allow_join_checkbox.state = team.allow_join
        refs.allow_auto_join_checkbox.state = team.allow_auto_join
        local reset_button = refs.reset_button
        reset_button.visible = Player.get(event.player_index):can_reset()
        self:update_join_request_table(refs.join_requests_table, team)
    end
end

function TeamGui:update_select_team_drop_down(refs)
    local drop_down = refs.join_team_drop_down
    drop_down.clear_items()
    local teams = {}
    local has_item = false
    KC.for_each_object(Team, function(team)
        drop_down.add_item(team:get_name())
        Table.insert(teams, team:get_id())
        has_item= true
    end)
    gui.set_tags(drop_down, teams)
    if has_item then
        drop_down.selected_index = 1
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

TeamGui:on({
    Config.ON_TEAM_CREATED,
    Config.ON_TEAM_DESTROYED,
    Config.ON_PLAYER_JOINED_TEAM,
    Config.ON_PLAYER_LEFT_TEAM
}, function(self, event)
    Table.each(self.refs, function(refs, player_index)
        self:update_overview_tab({
            player_index = player_index
        }, refs)
        self:update_join_requests_tab({
            player_index = player_index
        })
    end)
end)

return TeamGui