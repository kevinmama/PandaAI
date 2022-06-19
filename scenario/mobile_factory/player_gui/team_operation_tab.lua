local KC = require 'klib/container/container'
local GE = require 'klib/fgui/gui_element'
local Table = require 'klib/utils/table'
local TabAndContent = require 'klib/fgui/tab_and_content'
local gui = require 'flib/gui'

local Config = require 'scenario/mobile_factory/config'
local Team = require 'scenario/mobile_factory/player/team'
local Player = require 'scenario/mobile_factory/player/player'

local TeamOperationTab = KC.class(Config.PACKAGE_PLAYER_GUI_PREFIX .. 'TeamOperationTab', TabAndContent, function(self, tabbed_pane)
    TabAndContent(self, tabbed_pane)
    self.caption = {"mobile_factory_team_gui.team_operation_tab"}
end)

function TeamOperationTab:build_content(player, parent)
    local structures = {
        GE.flow(false, {
            ref = {"create_or_join_team_flow"},
            elem_mods = {visible = false}
        }, {
            GE.drop_down(nil, {"join_team_drop_down"}),
            GE.button(self, {"mobile_factory_team_gui.team_operation_tab_join_team"},
                    "confirm_button", nil, "on_request_join_team"),
            GE.fill_horizontally(),
            GE.button(self, {"mobile_factory_team_gui.team_operation_tab_create_team"},
                    "confirm_button", nil, "on_create_team", {
                        ref = {"create_team_button"}
                    })
        }),
        GE.flow(false, {
            ref = {"allow_join_team_flow"},
            elem_mods = {visible = false}
        }, {
            GE.checkbox(self, {"mobile_factory_team_gui.team_operation_tab_allow_join"}, nil, true,
                    {"allow_join_checkbox"}, "on_set_allow_join"),
            GE.checkbox(self, {"mobile_factory_team_gui.team_operation_tab_allow_auto_join"}, nil, false,
                    {"allow_auto_join_checkbox"}, "on_set_allow_auto_join"),
            GE.fill_horizontally(),
            GE.button(self, {"mobile_factory_team_gui.reset_button_caption"},
                    "red_back_button", nil, "on_reset_player", {
                        ref = {"reset_button"}
                    })
        }),
        GE.hr(),
        GE.table(self, nil, 4, {"join_requests_table"}, nil, {
            GE.h2({"mobile_factory_team_gui.team_operation_tab_player"}, {width = 100}),
            GE.placeholder(3)
        })
    }
    local refs = gui.build(parent, structures)
    self.refs[player.index] = refs
    refs.create_team_button.visible = Config.ALLOW_CREATE_TEAM
end

function TeamOperationTab:on_selected(event, refs)
    self:update_operation_tab(event, refs)
end

function TeamOperationTab:on_create_team(event)
    if Team.get_by_player_index(event.player_index) then
        local player = game.get_player(event.player_index)
        player.print({"mobile_factory.has_join_team_message"})
        return
    end
    local team = Team:new(event.player_index)
    self:update_operation_tab(event)
    game.print({"mobile_factory.create_team_message", team:get_name()})
end

function TeamOperationTab:on_request_join_team(event, refs)
    local player = game.get_player(event.player_index)
    local drop_down = refs.join_team_drop_down

    -- 检查团队是否存在
    local selected_index = drop_down.selected_index
    local team_id = gui.get_tags(drop_down)[selected_index]
    local team = team_id and KC.get(team_id)
    if not team or team.destroyed then
        player.print({"mobile_factory.team_not_exists"})
        self:update_operation_tab(event)
        return
    end

    local team_name = team:get_name()
    -- 检查团队是否允许申请加入
    if not team:can_player_join(player.index) then
        player.print({"mobile_factory.cannot_join_team", team_name})
        self:update_operation_tab(event)
        return
    end

    -- 执行申请并向玩家发送消息
    team:request_join(player.index)
    self:update_operation_tab(event)

    if not team.allow_auto_join then
        player.print({"mobile_factory.request_join_team", team_name})

        -- 向团长发送消息
        team:get_captain_player().print({"mobile_factory.receive_join_team_request", player.name})
        self:update_operation_tab({
            player_index = team:get_captain_player_index()
        })
    else
        game.print({"mobile_factory.join_team_message", player.name, team_name})
    end
end

function TeamOperationTab:on_set_allow_join(event)
    local team = Team.get_by_player_index(event.player_index)
    team:set_allow_join(event.element.state)
    self:update_operation_tab(event)
end

function TeamOperationTab:on_set_allow_auto_join(event)
    local team = Team.get_by_player_index(event.player_index)
    team:set_allow_auto_join(event.element.state)
    self:update_operation_tab(event)
end

function TeamOperationTab:on_accept_player_request(event)
    local team = Team.get_by_player_index(event.player_index)
    local request_player_index = gui.get_tags(event.element).request_player_index
    if team:can_player_join(request_player_index) then
        team:accept_join(request_player_index)
        game.print({"mobile_factory.join_team_message", game.get_player(request_player_index).name, team:get_name()})
    else
        team:cancel_join_request(request_player_index)
        game.get_player(event.player_index).print({"mobile_factory.cannot_accept_join_request"})
    end
    self:update_operation_tab(event)
    self:update_operation_tab({
        player_index = request_player_index
    })
end

function TeamOperationTab:on_reject_player_request(event)
    local team = Team.get_by_player_index(event.player_index)
    local request_player_index = gui.get_tags(event.element).request_player_index
    team:reject_join(request_player_index)
    game.get_player(request_player_index).print({"mobile_factory.reject_join_team_message", team:get_name()})
    self:update_operation_tab(event)
end

function TeamOperationTab:on_reset_player(event)
    local k_player = Player.get(event.player_index)
    if not k_player:can_reset() then
        k_player.player.print({"mobile_factory.cannot_reset_player"})
    else
        k_player:reset()
    end
    self:update_operation_tab(event)
end

function TeamOperationTab:update_operation_tab(event)
    local team = Team.get_by_player_index(event.player_index)
    local refs = self.refs[event.player_index]
    local has_team = team ~= nil
    refs.create_or_join_team_flow.visible = not has_team
    refs.allow_join_team_flow.visible = has_team
    if not has_team then
        self:update_select_team_drop_down(refs)
    else
        local allow_checkbox_visible = event.player_index == team:get_captain_player_index()
        refs.allow_join_checkbox.visible = allow_checkbox_visible
        refs.allow_auto_join_checkbox.visible = allow_checkbox_visible
        refs.allow_join_checkbox.state = team.allow_join
        refs.allow_auto_join_checkbox.state = team.allow_auto_join
        local reset_button = refs.reset_button
        reset_button.visible = Player.get(event.player_index):can_reset()
        self:update_join_request_table(refs.join_requests_table, team)
    end
end

function TeamOperationTab:update_select_team_drop_down(refs)
    local drop_down = refs.join_team_drop_down
    drop_down.clear_items()
    local team_ids = {}
    local has_item = false
    KC.for_each_object(Team, function(team)
        drop_down.add_item(team:get_name())
        Table.insert(team_ids, team:get_id())
        has_item= true
    end)
    gui.set_tags(drop_down, team_ids)
    if has_item then
        drop_down.selected_index = 1
    end
end

function TeamOperationTab:update_join_request_table(table, team)
    GE.update_table(table, {
        skip_row = 1,
        records = team.join_requests,
        create_row = function(t, row, request_player_index, rc)
            local request_player_name = game.get_player(request_player_index).name
            gui.build(t, {
                GE.label(request_player_name, nil, {width = 100}),
                GE.fill_horizontally(),
                GE.sprite_button(self, "utility/check_mark_green", "tool_button_green",
                        nil, "on_accept_player_request", {
                            tags = {request_player_index = request_player_index}
                        }),
                GE.sprite_button(self, "utility/close_black", "tool_button_red",
                        nil, "on_reject_player_request", {
                            tags = {request_player_index = request_player_index}
                        })
            })
        end,
        update_row = function(elems, row, request_player_index, rc)
            local request_player_name = game.get_player(request_player_index).name
            elems[1].caption = request_player_name
            gui.update_tags(elems[3], {request_player_index = request_player_index})
            gui.update_tags(elems[4], {request_player_index = request_player_index})
        end
    })
end

TeamOperationTab:on({
    Config.ON_TEAM_CREATED, Config.ON_TEAM_DESTROYED,
    Config.ON_PLAYER_JOINED_TEAM, Config.ON_PLAYER_LEFT_TEAM
}, function(self, event)
    Table.each(self.refs, function(refs, player_index)
        self:update_operation_tab({
            player_index = player_index
        }, refs)
    end)
end)

return TeamOperationTab
