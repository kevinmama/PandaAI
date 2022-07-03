local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local Table = require 'klib/utils/table'
local Entity = require 'klib/gmo/entity'
local Area = require 'klib/gmo/area'
local Position = require 'klib/gmo/position'
local Command = require 'klib/gmo/command'
local String = require 'stdlib/utils/string'

local Config = require 'scenario/mobile_factory/config'
local U = require 'scenario/mobile_factory/player/player_utils'
local PlayerRegistry = require 'scenario/mobile_factory/player/player_registry'
local PlayerSpectator = require 'scenario/mobile_factory/player/player_spectator'

local INIT_GOAL_DESCRIPTION = {"mobile_factory.goal_create_or_join_base"}

local Player = KC.class(Config.PACKAGE_PLAYER_PREFIX .. 'Player', function(self, player)
    self.player = player
    PlayerRegistry[player.index] = self
    self.team_id = nil
    self.should_give_player_items = true
    self.should_give_spider_items = true
    self.initialized = false
    self.team = nil
    self.spectator = PlayerSpectator:new_local(self)
    self.spectator:spectate_position(self.player.position)
    self.visiting_base = nil
    self.selected_bases = {}
    self.base_selection_markers = {}
    self.player.set_goal_description(INIT_GOAL_DESCRIPTION, nil)
end)

Player:delegate_method("spectator", {"is_spectating", "spectate_position", "spectate_team", "exit_spectate", "toggle_spectator_mode"})

function Player.get(index)
    return PlayerRegistry[index]
end

function Player:on_load()
    PlayerRegistry[self.player.index] = self
end

function Player:get_name()
    return self.player.name
end

function Player:get_index()
    return self.player.index
end

function Player:set_should_give_items(enable)
    self.should_give_player_items = enable
    self.should_give_spider_items = enable
end

function Player:init_on_create_or_join_team()
    if self.team then
        self:exit_spectate()
        if self.should_give_player_items then
            Entity.give_unit_armoury(self.player.character, Config.PLAYER_INIT_ITEMS)
            self.should_give_player_items = false
        end
        self.player.set_goal_description(self.team.goal_description)
        self.initialized = true
    end
end

function Player:is_new()
    return self.player.online_time < Config.RESET_TICKS_LIMIT
end

--- 加入 15 分钟前，自己是团员，且团队只有自己时，可以重置
function Player:can_reset()
    if not self:is_new() or not Config.ALLOW_RESET then
        return false
    end

    if self.team then
        return self.team:get_captain_player() ~= self.player or #self.team:get_members() == 1
    else
        return false
    end
end

function Player:do_reset()
    self.spectator:exit_spectate()
    self:set_visiting_base(nil)
    self:clear_selected_bases()
    local team_id = self.team:get_id()
    self.team = nil
    local x,y = self.player.position.x, self.player.position.y
    self.player.force = "player"
    self.player.set_goal_description(INIT_GOAL_DESCRIPTION)
    self.initialized = false
    self.spectator:spectate_position(self.player.position)
    game.print({"mobile_factory.player_reset", self.player.name, x, y})

    Event.raise_event(Config.ON_PLAYER_LEFT_TEAM, {
        player_index = self.player.index,
        team_id = team_id
    })
end

function Player:on_soft_reset()
    self:set_should_give_items(true)
    self.spectator:on_soft_reset()
end

function Player:reset(force)
    if not self.initialized then return end

    if force or self:can_reset() then
        if self.team and self.team:get_captain_player() == self.player then
            self.team:destroy()
        else
            self:do_reset()
        end
    end
end

function Player:recharge_equipment()
    local character = self.player.character
    local grid = character and character.valid and character.grid
    if not grid then return end
    local base = U.find_near_base(self.player)
    if not base then
        self.player.print({"mobile_factory.too_far_from_base_for_recharging"})
        return
    end
    -- 执行充电
    base:recharge_equipment_for_character(character)
end

function Player:find_near_bases()
    local position = self.visiting_base and self.visiting_base.position or self.player.position
    return U.find_near_bases(self.player, position)
end

function Player:set_visiting_base(base)
    if not KC.equals(base, self.visiting_base) then
        local left_base = self.visiting_base
        self.visiting_base = base
        if left_base then
            Event.raise_event(Config.ON_PLAYER_LEFT_BASE, {
                player_index = self.player.index,
                base_id = left_base:get_id()
            })
        end
        if self.visiting_base then
            Event.raise_event(Config.ON_PLAYER_ENTER_BASE, {
                player_index = self.player.index,
                base_id = self.visiting_base:get_id()
            })
        end
    end
end

function Player:set_selected_bases(bases)
    self.selected_bases = bases
    self:update_base_selection_markers()
end

function Player:add_selected_bases(bases)
    Table.each(bases, function(base)
        local selected_base = Table.find(self.selected_bases, function(selected_base)
            return selected_base:get_id() == base:get_id()
        end)
        if not selected_base then
            Table.insert(self.selected_bases, base)
            self:render_base_selection_marker(base)
        end
    end)
end

function Player:clear_selected_bases()
    self.selected_bases = {}
    self:update_base_selection_markers()
end

function Player:render_base_selection_marker(base)
    local marker = base:render_selection_marker(self.player)
    if marker then
        Table.insert(self.base_selection_markers, marker)
    end
end

function Player:update_base_selection_markers()
    for _, marker in pairs(self.base_selection_markers) do
        if rendering.is_valid(marker) then
            rendering.destroy(marker)
        end
    end
    self.base_selection_markers = {}
    for _, base in pairs(self.selected_bases) do
        self:render_base_selection_marker(base)
    end
end

function Player:order_selected_bases(order, area)
    Table.array_each_reverse(self.selected_bases, function(base, i)
        if base.destroyed then
            Table.remove(self.selected_bases, i)
        elseif order == Config.ORDER_MOVE then
            local position = Position.from_spiral_index(i)
            base:move_to_position({x=area.left_top.x + position.x*2, y=area.left_top.y+position.y*2})
        elseif order == Config.ORDER_FOLLOW then
            local entities = self.player.surface.find_entities_filtered({
                area = area
            })
            if entities[1] then
                base:follow_target(entities[1])
            end
        end
    end)
end

function Player:clone_vehicle_for_reset(vehicle)
    local cloned = vehicle.clone({
        surface = game.surfaces[Config.ALT_SURFACE_NAME],
        position = Position.from_spiral_index(self.player.index*2+1),
        force = self.player.force
    })
    if cloned then
        Entity.set_frozen(cloned, true)
        Entity.set_indestructible(cloned, true)
        cloned.health = cloned.prototype.max_health
        self.preserved_vehicle = cloned
        return true
    else
        return false
    end
end

Event.register(defines.events.on_player_created, function(event)
    local player = game.get_player(event.player_index)
    Player:new(player)
end)

--Event.register(defines.events.on_player_removed, function(event)
--    Player.players[event.player_index]:destroy()
--    Player.players[event.player_index] = nil
--end)

Event.register(defines.events.on_pre_player_left_game, function(event)
    local mf_player = Player.get(event.player_index)
    if mf_player:is_new() then
        game.print({"mobile_factory.reset_quick_quit", mf_player.player.name})
        mf_player:reset(true)
    end
end)


Command.add_admin_command("force-reset-player", {"mobile_factory.force_reset_player"}, function(data)
    local name, enable = Table.unpack(String.split(data.parameter, " +", true))
    local player = game.get_player(name)
    local admin = data.player_index and game.get_player(data.player_index)
    if not player then
        if admin then
            admin.print({"mobile_factory.player_not_exists"})
        end
    else
        game.print({"mobile_factory.force_reset_player_message", player.name, admin and admin.name or "[server]"})
        local mf_player = Player.get(player.index)
        mf_player:reset(true)
        if enable then
            mf_player:set_should_give_items(true)
        end
    end
end)


return Player