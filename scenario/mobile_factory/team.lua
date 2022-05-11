local KC = require('klib/container/container')
local Event = require 'klib/event/event'
local Table = require 'klib/utils/table'
local Type = require 'klib/utils/type'
local Time = require 'stdlib/utils/defines/time'
local Force = require 'klib/gmo/force'

local Config = require 'scenario/mobile_factory/config'
local Player = require 'scenario/mobile_factory/player'

local REQUESTING_JOIN = 1

local Team = KC.class('Scenario.MobileFactory.Team', function(self, player_index)
    self.allow_join = true
    self.allow_auto_join = false
    self.join_requests = {}
    -- 主队创建时不指定团长，不生成势力
    if player_index then
        self.captain = player_index
        self:_create_force()
    end
    local base = KC.get_class(Config.CLASS_NAME_MOBILE_BASE):new(self)
    self:set_base(base)
    if self.captain then
        base:teleport_player_to_vehicle(game.get_player(self.captain))
    end
end)

Team:refs('base')

function Team.get_by_player_index(player_index)
    local team_id = Player.get(player_index).team_id
    if team_id then
        return KC.get(team_id)
    else
        return nil
    end
end

function Team.get_by_name(name)
    if not name then return nil end
    if Type.is_table(name) then return KC.get(Config.CLASS_NAME_MAIN_TEAM) end
    local player = Player.get(game.get_player(name).index)
    return player.team_id and KC.get(player.team_id)
end

function Team:get_name()
    return game.get_player(self.captain).name
end

function Team:is_main_team()
    return false
end

function Team:get_members()
    return self.force.players
end

function Team:_add_member(player)
    local k_player = Player.get(player.index)
    if not k_player.team_id then
        k_player:set_team(self)
        player.force = self.force
        k_player:init_on_create_or_join_team()

        local base = self:get_base()
        if base then base:teleport_player_to_vehicle(player) end
        Event.raise_event(Config.ON_PLAYER_JOIN_TEAM_EVENT, {
            player_index = player.index,
            team_id = self:get_id()
        })
        return true
    else
        return false
    end
end

function Team:_create_force()
    self.force = game.create_force("mf_" .. self.captain)
    -- all forces are friends
    --self.force.share_chart = true
    Table.each(game.forces, function(force)
        if force.name ~= 'enemy' and force.name ~= 'neutral' then
            self.force.set_friend(force, true)
            force.set_friend(self.force, true)
        end
    end)
    local player = game.get_player(self.captain)
    self:_add_member(player)
end

--- 检查玩家是否能加入队伍
function Team:can_player_join(player_index)
    if not self.allow_join then
        return false
    end

    local team_id = Player.get(player_index).team_id
    return not team_id
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
        self.join_requests[player_index] = nil
        self:_add_member(player)
    end
end

--- 拒绝加入
function Team:reject_join(player_index)
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

function Team:on_destroy()
    -- 重置所有成员
    Table.each(self.force.players, function(player)
        Player.get(player.index):do_reset()
    end)
    self:get_base():destroy()
    game.merge_forces(self.force, "player")
    game.print({"mobile_factory.team_reset", self:get_name()})
end

function Team:on_ready()
    self:on(defines.events.on_player_changed_force, function(self, event)
        self.join_requests[event.player_index] = nil
    end)
end


return Team