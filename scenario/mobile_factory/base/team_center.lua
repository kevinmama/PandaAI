local KC = require 'klib/container/container'
local Event = require 'klib/event/event'

local Config = require 'scenario/mobile_factory/config'
local IndexAllocator = require 'scenario/mobile_factory/utils/index_allocator'

local MobileBase = require 'scenario/mobile_factory/base/mobile_base'
local U = require 'scenario/mobile_factory/base/mobile_base_utils'
local TeamCenterRegistry = require ('scenario/mobile_factory/base/team_center_registry')

local TeamCenter = KC.class(Config.PACKAGE_BASE_PREFIX .. 'TeamCenter', {
    "team_position_index_allocator", function()
        return {team_position_index_allocator = IndexAllocator:new_local()}
    end
}, function(self, team)
    self.team = team
    self.team_position_index = self:get_team_position_index_allocator():alloc()
    self.base_position_index_allocator = IndexAllocator:new_local()

    self.bases = {MobileBase:new(self)}
    --team.force.set_spawn_position(self.bases[1].center, self.bases[1].surface)
    if team.captain then
        self.bases[1]:teleport_player_to_vehicle(team.captain)
    end

    -- 如果是主队，多创建几只
    if team:is_main_team() then
        for _ = 1, 4 do
            local extra_base = MobileBase:new(self)
            U.give_base_initial_items(extra_base)
            table.insert(self.bases, extra_base)
        end
    end
end)

TeamCenter:delegate_method("base_position_index_allocator", "alloc", "alloc_base_position_index")
TeamCenter:delegate_method("base_position_index_allocator", "free", "free_base_position_index")

TeamCenter.get_by_team_id = TeamCenterRegistry.get_by_team_id
TeamCenter.get_first_base_by_team_id = TeamCenterRegistry.get_first_base_by_team_id
TeamCenter.get_bases_by_team_id = TeamCenterRegistry.get_bases_by_team_id
TeamCenter.get_by_player_index = TeamCenterRegistry.get_by_player_index
TeamCenter.get_first_base_by_player_index = TeamCenterRegistry.get_first_base_by_player_index
TeamCenter.get_bases_by_player_index = TeamCenterRegistry.get_bases_by_player_index

function TeamCenter:on_ready()
    TeamCenterRegistry[self.team:get_id()] = self
end

function TeamCenter:on_destroy()
    self:get_team_position_index_allocator():free(self.team_position_index)
end

Event.register(Config.ON_TEAM_CREATED, function(event)
    local team = KC.get(event.team_id)
    TeamCenter:new(team)
end)

Event.register(Config.ON_PRE_TEAM_DESTROYED, function(event)
    KC.for_each_object(MobileBase, function(base)
        if base.team:get_id() == event.team_id then
            base:destroy()
        end
    end)
    local tc = TeamCenterRegistry[event.team_id]
    if tc then tc:destroy() end
end)

Event.register(Config.ON_PLAYER_JOINED_TEAM, function(event)
    local base = TeamCenter.get_first_base_by_team_id(event.team_id)
    if base then
        local player = game.get_player(event.player_index)
        base:teleport_player_to_vehicle(player)
    end
end)

Event.on_player_respawned(function(event)
    local base = TeamCenter.get_first_base_by_player_index(event.player_index)
    if base then
        local player = game.get_player(event.player_index)
        base:teleport_player_to_exit(player)
    end
end)

Event.on_built_entity(function(event)
    if event.created_entity.type == 'spider-vehicle' and event.created_entity.position.y < Config.BASE_OUT_OF_MAP_Y then
        local team_center = TeamCenter.get_by_player_index(event.player_index)
        if team_center then
            local base = MobileBase:new(team_center, event.created_entity)
            table.insert(team_center.bases, base)
        end
    end
end)

return TeamCenter