local KC = require('klib/container/container')
local Table = require 'klib/utils/table'
local Player = require 'scenario/mobile_factory/player'


local REQUESTING_JOIN = 1

local Team = KC.class('Scenario.MobileFactory.Team', function(self, player_index)
    self.captain = player_index
    self.allow_join = false
    self.allow_auto_join = false
    self.join_requests = {}
    self:_create_force()
end)

function Team:get_name()
    return game.get_player(self.captain).name
end

function Team.get_by_player(player_index)
    local team_id = Player.get(player_index).team_id
    if team_id then
        return KC.get(team_id)
    else
        return nil
    end
end

function Team.get_by_name(name)
    local player = Player.get(game.get_player(name).index)
    return KC.get(player.team_id)
end

function Team:_add_member(player)
    local k_player = Player.get(player.index)
    if not k_player.team_id then
        k_player.team_id = self:get_object_id()
        player.force = self.force
        return true
    else
        return false
    end
end

function Team:_create_force()
    self.force = game.create_force("mf_" .. self.captain)
    -- all forces are friends
    self.force.share_chart = true
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

Team:on(defines.events.on_player_changed_force, function(self, event)
    self.join_requests[event.player_index] = nil
end)

return Team