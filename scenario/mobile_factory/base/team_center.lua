local KC = require 'klib/container/container'
local Table = require 'klib/utils/table'
local Event = require 'klib/event/event'
local Area = require 'klib/gmo/area'
local Surface = require 'klib/gmo/surface'
local Tasks = require 'klib/task/tasks'

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
    TeamCenterRegistry[self.team:get_id()] = self
    self.team_position_index = self:get_team_position_index_allocator():alloc()
    self.base_position_index_allocator = IndexAllocator:new_local()

    self.bases = {MobileBase:new(self, team:init_preserved_vehicle())}
    local first_base = self.bases[1]
    U.give_base_initial_items(first_base)
    U.give_base_initial_resources(first_base)
    --team.force.set_spawn_position(self.bases[1].center, self.bases[1].surface)
    if team.captain then
        first_base:teleport_player_to_vehicle(team.captain.player)
    end

    -- 如果是主队，多创建几只
    if (__DEBUG__ or Config.DEFEND_MODE) and team:is_main_team() then
        for _ = 1, 2 do
            local extra_base = MobileBase:new(self)
            U.give_base_initial_items(extra_base)
            table.insert(self.bases, extra_base)
        end
    end

    Surface.clear_enemies_in_area(first_base.surface, Area.from_dimensions(Config.STARTING_AREA_DIMENSIONS, first_base:get_position()) )
    game.print({"mobile_factory.removed_starting_area_enemies", team:get_name()})
end)

TeamCenter:delegate_method("base_position_index_allocator", "alloc", "alloc_base_position_index")
TeamCenter:delegate_method("base_position_index_allocator", "free", "free_base_position_index")

TeamCenter.get_by_team_id = TeamCenterRegistry.get_by_team_id
TeamCenter.get_by_force_index = TeamCenterRegistry.get_by_force_index
TeamCenter.get_first_base_by_team_id = TeamCenterRegistry.get_first_base_by_team_id
TeamCenter.get_bases_by_team_id = TeamCenterRegistry.get_bases_by_team_id
TeamCenter.get_by_player_index = TeamCenterRegistry.get_by_player_index
TeamCenter.get_first_base_by_player_index = TeamCenterRegistry.get_first_base_by_player_index
TeamCenter.get_bases_by_player_index = TeamCenterRegistry.get_bases_by_player_index

function TeamCenter:on_load()
    TeamCenterRegistry[self.team:get_id()] = self
end

function TeamCenter:on_destroy()
    if self.bases[1] and not self.team:is_main_team() then
        self.team.captain:clone_vehicle_for_reset(self.bases[1].vehicle)
    end
    for _, base in pairs(self.bases) do
        base:destroy()
    end
    self.bases = {}
    self:get_team_position_index_allocator():free(self.team_position_index)
    TeamCenterRegistry[self.team:get_id()] = nil
end

function TeamCenter:create_bonus_base()
    local base = MobileBase:new(self, self.bases[1].vehicle.position)
    table.insert(self.bases, base)
end


Event.register(Config.ON_TEAM_CREATED, function(event)
    local team = KC.get(event.team_id)
    TeamCenter:new(team)
end)

Event.register(Config.ON_PRE_TEAM_DESTROYED, function(event)
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
        base:teleport_player_on_respawned(player)
    end
end)

Event.on_built_entity(function(event)
    if event.created_entity.type == 'spider-vehicle' and event.created_entity.position.y < Config.BASE_OUT_OF_MAP_Y then
        local team_center = TeamCenter.get_by_player_index(event.player_index)
        if team_center then
            local base = MobileBase:new(team_center, event.created_entity)
            table.insert(team_center.bases, base)
            team_center.team:update_goal_description("")
        end
    end
end)

--- 研究坦克额外送基地
Event.register(defines.events.on_research_finished, function(event)
    if event.research.name == 'tank' then
        local team_center = TeamCenterRegistry.get_by_force_index(event.research.force.index)
        if team_center then
            team_center:create_bonus_base()
            team_center.team:update_goal_description({"mobile_factory.goal_more_base"})
        end
    end
end)

return TeamCenter