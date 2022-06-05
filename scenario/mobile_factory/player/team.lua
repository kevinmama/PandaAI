local KC = require('klib/container/container')
local Event = require 'klib/event/event'
local Table = require 'klib/utils/table'
local Tasks = require 'klib/task/tasks'
local Command = require 'klib/gmo/command'

local Config = require 'scenario/mobile_factory/config'
local TeamRegistry = require('scenario/mobile_factory/player/team_registry')
local Player = require 'scenario/mobile_factory/player/player'
local TeamBonus = require 'scenario/mobile_factory/player/team_bonus'

local REQUESTING_JOIN = 1

local MAIN_TEAM = -1

local BONUS_BASE_GOAL = {"mobile_factory.goal_bonus_base"}

local Team = KC.class(Config.PACKAGE_PLAYER_PREFIX .. 'Team', function(self, player_index)
    self.allow_join = true
    self.allow_auto_join = false
    self.join_requests = {}

    self.online = false
    self.last_online = game.tick
    self.goal_description = BONUS_BASE_GOAL

    -- 主队创建时不指定团长，不生成势力
    if player_index ~= MAIN_TEAM then
        local captain = game.get_player(player_index)
        self.captain = captain
        self.name = captain.name
        self.main_team = false
    else
        self.name = {"mobile_factory.main_team_name"}
        self.main_team = true
    end

    self:_create_force()
    self.bonus = TeamBonus:new_local(self)
    TeamRegistry[self.force.index] = self

    Event.raise_event(Config.ON_TEAM_CREATED, {
        team_id = self:get_id()
    })
    if self.captain then
        Event.raise_event(Config.ON_PLAYER_JOINED_TEAM, {
            player_index = self.captain.index
        })
    end
end)

Team:delegate_getter("bonus", "resource_warp_rate")

function Team:on_load()
    if self.force.valid then
        TeamRegistry[self.force.index] = self
    elseif not self.destroyed then
        -- 加载时有些对象持有过期的对象
        log(string.format("team {id=%d,name=%s} is invalid and not destroyed when on_ready", self:get_id(), self.name))
    end
end

Team.get_by_player_index = TeamRegistry.get_by_player_index
Team.get_id_by_player_index = TeamRegistry.get_id_by_player_index
Team.get_by_force = TeamRegistry.get_by_force

function Team:is_main_team()
    return self.main_team
end

function Team:get_name()
    return self.name
end

function Team:get_members()
    return self.force.players
end

function Team:_add_member(player, raise_event)
    local mf_player = Player.get(player.index)
    if not mf_player.team then
        mf_player.team = self
        player.force = self.force
        mf_player:exit_spectate()
        mf_player:init_on_create_or_join_team()

        if raise_event == nil then raise_event = true end
        if raise_event then
            Event.raise_event(Config.ON_PLAYER_JOINED_TEAM, {
                player_index = player.index,
                team_id = self:get_id()
            })
        end
        return true
    else
        return false
    end
end

function Team:_create_force()
    self.force = game.create_force("mf_" .. self:get_id())
    -- all forces are friends
    --self.force.share_chart = true
    Table.each(game.forces, function(force)
        if force.name ~= 'enemy' and force.name ~= 'neutral' then
            self.force.set_friend(force, true)
            force.set_friend(self.force, true)
        end
    end)
    if self.captain then
        self:_add_member(self.captain, false)
    end
end

--- 检查玩家是否能加入队伍
function Team:can_player_join(player_index)
    if not self.allow_join or not game.get_player(player_index).connected then
        return false
    end

    return not Team.get_by_player_index(player_index)
end

--- 申请加入队伍
function Team:request_join(player_index)
    if self:can_player_join(player_index) then
        if self.allow_auto_join then
            self:_add_member(game.get_player(player_index))
        else
            self.join_requests[player_index] = REQUESTING_JOIN
        end
    end
end

--- 同意加入
function Team:accept_join(player_index)
    if self:can_player_join(player_index) then
        local player = game.get_player(player_index)
        self:_add_member(player)
    end
    self.join_requests[player_index] = nil
end

--- 拒绝加入
function Team:reject_join(player_index)
    self.join_requests[player_index] = nil
end

function Team:cancel_join_request(player_index)
    self.join_requests[player_index] = nil
end

function Team:set_allow_join(state)
    self.allow_join = state
    if not state then
        self.allow_auto_join = false
    end
end

function Team:set_allow_auto_join(state)
    self.allow_auto_join = state
    if state then
        self.allow_join = true
    end
end

function Team:is_online()
    return #self.force.connected_players > 0
end

function Team:update_online_state()
    local online = #self.force.connected_players > 0
    if self.online ~= online then
        self.online = online
        if self.online then
            Event.raise_event(Config.ON_TEAM_ONLINE, {team_id = self:get_id(), last_online = self.last_online})
        else
            Event.raise_event(Config.ON_TEAM_OFFLINE, {team_id = self:get_id()})
            self.last_online = game.tick
        end
    end
end

function Team:update_goal_description(description)
    self.goal_description = description
    for _, p in pairs(self.force.players) do
        p.set_goal_description(description)
    end
end

function Team:on_destroy()
    local team_id = self:get_id()
    Event.raise_event(Config.ON_PRE_TEAM_DESTROYED, {
        team_id = team_id
    })
    -- 重置所有成员
    Table.each(self.force.players, function(player)
        Player.get(player.index):do_reset()
    end)
    TeamRegistry[self.force.index] = nil
    game.merge_forces(self.force, "player")
    game.print({"mobile_factory.team_reset", self:get_name()})
    Event.raise_event(Config.ON_TEAM_DESTROYED, {
        team_id = team_id
    })
end

Team:on({Config.ON_PLAYER_JOINED_TEAM, Config.ON_PLAYER_LEFT_TEAM}, function(self, event)
    self.join_requests[event.player_index] = nil
end)

Event.register({
    defines.events.on_player_joined_game,
    defines.events.on_player_left_game,
    Config.ON_PLAYER_JOINED_TEAM,
    Config.ON_PLAYER_LEFT_TEAM
}, function(event)
    local team
    if event.team_id then
        team = KC.get(event.team_id)
    else
        team = Team.get_by_player_index(event.player_index)
    end
    if team then team:update_online_state() end
end)

Tasks.submit_init_task(Config.PACKAGE_PLAYER_PREFIX .. "InitMainTeamTask", function()
    local main_team = Team:new(-1)
    main_team:set_allow_join(true)
    main_team:set_allow_auto_join(true)
end)

Command.add_admin_command("create-team", "create team for player", function(data)
    local player = game.get_player(data.parameter or 1)
    if player then
        if not Team.get_by_player_index(player.index) then
            Team:new(player.index)
        end
    end
end)

return Team