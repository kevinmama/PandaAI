local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local Table = require 'klib/utils/table'
local Entity = require 'klib/gmo/entity'
local Config = require 'scenario/mobile_factory/config'
local Time = require 'stdlib/utils/defines/time'
local Area = require 'klib/gmo/area'
local Position = require 'klib/gmo/position'
local Chunk = require 'klib/gmo/chunk'
local Rendering = require 'klib/gmo/rendering'
local ColorList = require 'stdlib/utils/defines/color_list'
local IterableLinkedList = require 'klib/classes/iterable_linked_list'

local MobileBase = require 'scenario/mobile_factory/base/mobile_base'

local CHUNK_SIZE = Config.CHUNK_SIZE
local MAX_GROUP_SIZE = 200
local MIN_GATHERING_TIME = 2 * Time.minute
local MAX_GATHERING_TIME = 10 * Time.minute
local TTL_AFTER_GATHERED = 3 * Time.minute

local SEARCH_RADIUS = 8 * CHUNK_SIZE
local ATTACK_AREA_RADIUS = CHUNK_SIZE
local SEPARATE_DISTANCE = 2 * CHUNK_SIZE
local COMBINE_DISTANCE = CHUNK_SIZE / 2

local EnemyGroup = {}
EnemyGroup = KC.class('scenario.MobileFactory.enemy.EnemyGroup', {
    regrouping = false,
    group_map = {},
    "group_list", function()
        return {group_list = IterableLinkedList:new_local()}
    end
}, function(self, group)
    self.group = group
    self.group_number = group.group_number
    self.tick = game.tick
    self.idle = true
    self.gathering_time = math.random(MIN_GATHERING_TIME, MAX_GATHERING_TIME)
    self.ttl = self.gathering_time + TTL_AFTER_GATHERED
    self.attacking_base = nil

    self.force = group.force
    self.last_position = group.position
    self.surface = group.surface
    self.combined = true
    self.combined_members = {}
    self.separate_tick = 0
    EnemyGroup:get_group_map()[self.group_number] = self
    EnemyGroup:get_group_list():append(self)
end)

Event.on_init(function()
    local s = game.map_settings.unit_group
    s.min_group_gathering_time = MAX_GATHERING_TIME + Time.minute
    s.max_group_gathering_time = MAX_GATHERING_TIME + Time.minute
    s.max_gathering_unit_groups = 30
    s.max_wait_time_for_late_members = 0
    s.max_unit_group_size = MAX_GROUP_SIZE + 50
end)

function EnemyGroup:get_by_entity(entity)
    local group = entity.type == 'unit' and entity.unit_group
    return group and group.valid and EnemyGroup:get_group_map()[group.group_number]
end

function EnemyGroup:add_member(unit)
    if self.combined then
        Table.added(self.combined_members, {
            [unit.name] = 1
        })
        if self.group.members[3] then
            unit.destroy()
        end
        self:update_combine_display()
    end
end

function EnemyGroup:size()
    return #self.group.members + (self.combined and Table.sum(self.combined_members) or 0)
end

function EnemyGroup:separate(options)
    if self.combined then
        self.combined = false
        self.separate_tick = game.tick
        local group_valid = self.group and self.group.valid
        options = options or {}
        local surface = options.surface or self.surface
        local position = Position(options.position or (group_valid and self.group.position) or self.last_position)
        local force = options.force or self.force

        --game.print(string.format("separate group %s", Position.to_gps(position)))
        local index = 0
        for name, count in pairs(self.combined_members) do
            for created_count = 1, count do
                index = index + 1
                local offset = Position.from_spiral_index(index)
                local entity_position = { position.x + offset.x, position.y + offset.y }
                local unit = Entity.create_unit(surface, {
                    name = name, position = entity_position, force = force,
                    find_radius = 16, find_precision = 0.5,
                })
                if unit then
                    if group_valid then
                        self.group.add_member(unit)
                    end
                else
                    self.combined_members[name] = self.combined_members[name] - created_count + 1
                    game.print(string.format("[error] cannot created all combine members at %s, remains: %s",
                            Position.to_gps(position), self:combined_members_to_rich_text())
                    )
                end
            end
            self.combined_members[name] = nil
        end
        self:update_combine_display()
    end
end

function EnemyGroup:combine()
    if not self.combined then
        --game.print(string.format("combile group %s", Position.to_gps(self.group.position)))
        self.combined = true
        local members = self.group.members
        for i = #members, 3, -1 do
            local member = members[i]
            Table.added(self.combined_members, {
                [member.name] = 1
            })
            member.destroy()
        end
        self:update_combine_display()
    end
end

function EnemyGroup:combined_members_to_rich_text()
    local text = ""
    for name, count in pairs(self.combined_members) do
        text = text .. count .. "[img=entity/" .. name .. "]"
    end
    return text
end

--- 仅仅销毁包装类，其成员可能加入别的组
function EnemyGroup:on_destroy()
    Rendering.destroy_all(self.group_display_ids)
    EnemyGroup:get_group_map()[self.group_number] = nil
end

--- 当组生命周期结束时调用，删除组及其成员
function EnemyGroup:destroy_all()
    if self.group and self.group.valid then
        --game.print(string.format("group%s destroyed", Position.to_gps(self.group.position)))
        for _, member in pairs(self.group.members) do
            if member.valid then
                member.destroy()
            end
        end
        self.group.destroy()
    end
    self:destroy()
end

function EnemyGroup:regroup_or_destroy()
    --if not self.group.valid and self.combined and next(self.combined_members)
    --        and self.surface.is_chunk_generated(Position.to_chunk_position(self.last_position)) then
    --    self:regroup()
    --    return true
    --else
    --    self:destroy()
    --    return false
    --end

    -- 重组会导致不同步
    self:destroy()
    return false
end

function EnemyGroup:regroup()
    --game.print("regrouping: " .. Position.to_gps(self.last_position))
    local group_map = EnemyGroup:get_group_map()
    group_map[self.group_number] = nil
    self.group.destroy()

    EnemyGroup:set_regrouping(true)
    self.group = self.surface.create_unit_group({
        position = self.last_position,
        force = self.force
    })
    self.group_number = self.group.group_number
    group_map[self.group_number] = self
    EnemyGroup:set_regrouping(false)

    -- create first member
    local name, count = next(self.combined_members)
    if count > 0 then
        local unit = Entity.create_unit(self.group.surface, {
            name = name, position = self.group.position, force = self.force,
            find_radius = 16, find_precision = 0.5,
        })
        if unit then
            self.group.add_member(unit)
            count = count - 1
            self.combined_members[name] = count > 0 and count or nil
        end
    end

    self.idle = true
end

function EnemyGroup:is_valid()
    return self.group.valid
end

function EnemyGroup:can_set_off()
    return (game.tick >= self.tick + self.gathering_time or self:size() >= MAX_GROUP_SIZE)
        or (game.tick >= self.tick + MAX_GATHERING_TIME)
end

function EnemyGroup:update_combine_display()
    Rendering.destroy_all(self.group_display_ids)
    if not self.combined then
        self.group_display_ids = nil
    else
        local leader = self.group.members[1]
        if not leader then return end

        self.group_display_ids = Rendering.draw_rich_text_of_item_counts({
            items = self.combined_members,
            sprite_params_getter = function(name)
                local proto = game.entity_prototypes[name]
                return {
                    sprite = 'entity/' .. name,
                    tint = proto.color
                }
            end,
            digit_color = ColorList.red,
            surface = leader.surface,
            target = leader,
            offset_y = -4,
            digit_scale = 2,
            digit_width = 0.66,
            sprite_scale = 1,
            sprite_width = 1
        })

        Table.insert(self.group_display_ids, rendering.draw_circle({
            color = ColorList.red,
            radius = 2,
            width = 4,
            target = leader,
            surface = leader.surface,
            draw_on_ground = true
        }))
    end
end

function EnemyGroup:update()
    if game.tick > self.tick + self.ttl then
        self:destroy_all()
        return
    end
    self:combine_if_not_attacking()
    self.last_position = self.group.position
    if self.idle and self:can_set_off() then
        self:update_command()
    end
end

function EnemyGroup:combine_if_not_attacking()
    -- 没移动且没攻击目标时，尝试组合
    if not self.combined and not self.attacking_base and game.tick > self.separate_tick + 3600 and
            Position.manhattan_distance(self.last_position, self.group.position) < COMBINE_DISTANCE
        --and not self.surface.find_nearest_enemy({
        --position = self.group.position,
        --max_distance = SEPARATE_DISTANCE,
        --force = self.force })
    then
        self:combine()
    end
end

function EnemyGroup:update_command()
    -- 寻找附近的蜘蛛，如果没有，就有污染最重的地方建基地
    -- 另外可以令虫子优先在有资源的地方建基地
    if self:attack_mobile_base()
    or self:attack_most_polluted_chunk() then
        --game.print("group command updated " .. RichText.gps(self.group.position))
    end
end

function EnemyGroup:attack_mobile_base()
    if KC.is_valid(self.attacking_base) and self.attacking_base:is_active()
            and not self.attacking_base:is_heavy_damaged() then
        self:set_attack_base_command(self.attacking_base)
        return true
    else
        local group = self.group
        local bases = Table.filter(MobileBase.find_bases_in_radius(group.position, SEARCH_RADIUS), function(base)
            return base:is_active() and not base:is_heavy_damaged()
        end, true)
        if next(bases) then
            local selected = math.random(#bases)
            local base = bases[selected]
            self.attacking_base = base
            self:set_attack_base_command(base)
            return true
        else
            self.attacking_base = nil
        end
    end
end

function EnemyGroup:set_attack_base_command(base)
    local group = self.group
    local vehicle = base.vehicle
    group.set_command({
        type = defines.command.attack_area,
        destination = vehicle.position,
        radius = ATTACK_AREA_RADIUS
    })
    if group.valid then
        group.start_moving()
        self.idle = false
        --base.force.print("一波虫子正在靠近")
        --game.print(string.format("attacking vehicle %s from: %s",
        --        Position.to_gps(vehicle.position), RichText.gps(group.position)))
        if self.combined and Position.manhattan_distance(group.position, base:get_position()) < SEPARATE_DISTANCE then
            self:separate()
        end
    end
end

function EnemyGroup:attack_most_polluted_chunk()
    local group = self.group
    local dest = group.position
    local max_pollution = 0
    Chunk.each_from_dimensions({width=SEARCH_RADIUS*2, height=SEARCH_RADIUS*2}, group.position, function(c_pos)
        local pos = Position.from_chunk_position(c_pos)
        local pollution = group.surface.get_pollution(pos)
        if pollution > max_pollution then
            max_pollution = pollution
            dest = pos
        end
    end)

    if Position.manhattan_distance(dest, group.position) > 2 * CHUNK_SIZE then
        group.set_command({
            type = defines.command.attack_area,
            destination = dest,
            radius = ATTACK_AREA_RADIUS
        })
        --game.print("attack area: " .. RichText.gps(dest))
    else
        group.set_command({
            type = defines.command.build_base,
            destination = dest,
        })
        --game.print(string.format("group %s build base at %s", self:get_id(), Position.to_gps(dest)))
    end
    if group.valid then -- set_command 之后有可能会失效
        group.start_moving()
    end
    self.idle = false
end

Event.register(defines.events.on_unit_group_created, function(event)
    if not EnemyGroup:get_regrouping() then
        --game.print("group created: " .. Position.to_gps(event.group.position))
        EnemyGroup:new(event.group)
    else
        --game.print("regroup: " .. Position.to_gps(event.group.position))
    end
end)

local function ensure_group(group_number, handler)
    local enemy_group = EnemyGroup:get_group_map()[group_number]
    if enemy_group and enemy_group:is_valid() then
        handler(enemy_group)
    end
end

Event.register(defines.events.on_ai_command_completed, function(event)
    ensure_group(event.unit_number, function(enemy_group)
        enemy_group.idle = true
    end)
end)

Event.register(defines.events.on_unit_added_to_group, function(event)
    ensure_group(event.group.group_number, function(enemy_group)
        enemy_group:add_member(event.unit)
    end)
end)

Event.register(defines.events.on_entity_died, function(event)
    local entity = event.entity
    local enemy_group = EnemyGroup:get_by_entity(entity)
    if enemy_group then
        enemy_group:separate({
            position = entity.position
        })
        enemy_group:update()
    end
end)

EnemyGroup:on_nth_tick(2 * Time.second, function()
    local list = EnemyGroup:get_group_list()
    while not list:is_empty() do
        local enemy_group = list:next()
        if not enemy_group then enemy_group = list:rewind() end

        if enemy_group:is_valid() or enemy_group:regroup_or_destroy() then
            enemy_group:update()
            break
        else
            list:remove()
        end
    end
end)

return EnemyGroup