local KC = require 'klib/container/container'
local Table = require 'klib/utils/table'
local Entity = require 'klib/gmo/entity'
local Position = require 'klib/gmo/position'
local Area = require 'klib/gmo/area'

local U = require 'scenario/mobile_factory/base/mobile_base_utils'
local Config = require 'scenario/mobile_factory/config'

local LinkController = KC.class(Config.PACKAGE_BASE_PREFIX .. 'LinkController', function(self, base)
    self.base = base
    self.linked_belt_pairs = {}
end)

function LinkController:on_destroy()
    for _, p in pairs(self.linked_belt_pairs) do
        self:remove_linked_belt_pair(p.id)
    end
end

function LinkController:update()
    for _, p in pairs(self.linked_belt_pairs) do
        self:update_linked_belt_pair(p)
    end
end

function LinkController:can_create_linked_belt_pair()
    return Table.size(self.linked_belt_pairs) < Config.MAXIMAL_LINKED_BELT_PAIRS
end

function LinkController:create_linked_belt_pair()
    if self:can_create_linked_belt_pair() then
        local id = KC.next_id()
        self.linked_belt_pairs[id] = {
            id = id,
            input_belt = nil,
            input_base = nil,
            output_belt = nil,
            output_base = nil
        }
        return true
    else
        return false, {"mobile_factory.too_many_linked_belt_pairs", self.base:get_name()}
    end
end

function LinkController:build_linked_belt(pair_id, position, linked_belt_type)
    local pair = self.linked_belt_pairs[pair_id]
    if not pair then
        return false, { "mobile_factory.cannot_find_linked_belt_by_id", self.base:get_name(), pair_id }
    end
    local current_belt = linked_belt_type == "input" and "input_belt" or "output_belt"
    local current_base = linked_belt_type == "input" and "input_base" or "output_base"
    local opposite_base = linked_belt_type == "input" and "output_base" or "input_base"
    if Position.inside(position, U.get_valid_area(self.base, true)) then
        -- 本基地
        if pair[opposite_base] and pair[opposite_base]:get_id() == self.base:get_id() then
            return false, {"mobile_factory.input_output_belts_cannot_be_both_in_the_same_base", self.base:get_name()}
        else
            return self:set_linked_belt_pair(pair, current_base, self.base, current_belt, position, linked_belt_type)
        end
    elseif not pair[opposite_base] or pair[opposite_base]:get_id() ~= self.base:get_id() then
        -- 至少一端要在本基地
        return false, {"mobile_factory.either_input_or_output_belt_must_be_in_base", self.base:get_name()}
    elseif position.y < Config.BASE_POSITION_Y then
        -- 世界地图
        if not Position.inside(position, U.get_io_area(self.base, true)) then
            return false, {"mobile_factory.cannot_build_linked_belt_out_of_range", self.base:get_name()}
        else
            return self:set_linked_belt_pair(pair, current_base, nil, current_belt, position, linked_belt_type)
        end
    else
        -- 其它基地
        local bases = U.find_bases_in_area(U.get_io_area(self.base, true), self.base.team:get_id())
        local base = Table.find(bases, function(base)
            return base:get_id() ~= self.base:get_id() and base:is_position_inside(position)
        end)
        if base then
            return self:set_linked_belt_pair(pair, current_base, base, current_belt, position, linked_belt_type)
        else
            return false, {"mobile_factory.cannot_build_linked_belt_out_of_range", self.base:get_name()}
        end
    end
end

function LinkController:set_linked_belt_pair(linked_belt_pair, current_base, base, current_belt, position, linked_belt_type)
    local last_base = linked_belt_pair[current_base]
    -- 检查目标基地是否能创建新的连接带
    if base and not KC.equals(base, self.base) and not KC.equals(base, last_base)
            and not base.link_controller:can_create_linked_belt_pair() then
        return false, {"mobile_factory.too_many_linked_belt_pairs", base:get_name()}
    end
    if last_base and not KC.equals(last_base, base) then
        last_base.link_controller.linked_belt_pairs[linked_belt_pair.id] = nil
    end
    linked_belt_pair[current_base] = base
    if base and base:get_id() ~= self.base:get_id() then
        base.link_controller.linked_belt_pairs[linked_belt_pair.id] = linked_belt_pair
    end

    local success, belt = self:create_or_teleport_linked_belt(linked_belt_pair[current_belt], position, linked_belt_type)
    if success then
        linked_belt_pair[current_belt] = belt
        self:update_linked_belt_pair(linked_belt_pair)
        return true
    else
        return false, {"mobile_factory.cannot_create_or_teleport_linked_belt"}
    end
end

function LinkController:create_or_teleport_linked_belt(link_belt, position, linked_belt_type)
    if link_belt then
        return Entity.teleport(link_belt, position)
    else
        local created_entity = U.create_system_entity(self.base, 'linked-belt', position)
        if created_entity then
            created_entity.destructible = true
            created_entity.linked_belt_type = linked_belt_type
        end
        return created_entity ~= nil, created_entity
    end
end

function LinkController:update_linked_belt_pair(p)
    local input_base_valid = KC.is_valid(p.input_base)
    local output_base_valid = KC.is_valid(p.output_base)
    if (p.input_belt and not p.input_belt.valid) or (p.input_base and not input_base_valid) then
        p.input_belt = nil
        p.input_base = nil
    end
    if (p.output_belt and not p.output_belt.valid) or (p.output_base and not output_base_valid) then
        p.output_belt = nil
        p.output_base = nil
    end
    if p.input_belt and p.output_belt then
        local valid = false
        if input_base_valid and output_base_valid then
            valid = Position.inside(p.input_base:get_position(), U.get_io_area(p.output_base, true))
            if not valid then
                p.input_belt.disconnect_linked_belts()
            end
        elseif input_base_valid then
            valid = Position.inside(p.output_belt.position, U.get_io_area(p.input_base, true))
            if not valid then
                Entity.die_without_corpse_and_ghost(p.output_belt, true)
                p.output_belt = nil
            end
        elseif output_base_valid then
            valid = Position.inside(p.input_belt.position, U.get_io_area(p.output_base, true))
            if not valid then
                Entity.die_without_corpse_and_ghost(p.input_belt, true)
                p.input_belt = nil
            end
        end
        if valid then
            p.input_belt.connect_linked_belts(p.output_belt)
        end
    end
end

function LinkController:remove_linked_belt(area)
    local area1 = Area.intersect(area, U.get_valid_area(self.base, true))
    local area2 = Area.intersect(area, U.get_io_area(self.base, true))
    if not area1 and not area2 then
        return false, {"mobile_factory.cannot_remove_linked_belt_outside_current_base", self.base:get_name()}
    end
    for _, the_area in pairs({area1, area2}) do
        if the_area then
            local linked_belts = self.base.surface.find_entities_filtered( {
                name = 'linked-belt',
                force = self.base.force,
                area = the_area
            })
            for _, linked_belt in pairs(linked_belts) do
                Entity.die_without_corpse_and_ghost(linked_belt, true)
            end
        end
    end
    return true
end

function LinkController:remove_linked_belt_pair(pair_id)
    local pair = self.linked_belt_pairs[pair_id]
    if pair then
        if pair.input_belt then
            Entity.die_without_corpse_and_ghost(pair.input_belt, true)
        end
        if pair.input_base and not KC.equals(self.base, pair.input_base) then
            pair.input_base.link_controller.linked_belt_pairs[pair_id] = nil
        end
        if pair.output_belt then
            Entity.die_without_corpse_and_ghost(pair.output_belt, true)
        end
        if pair.output_base and not KC.equals(self.base, pair.output_base) then
            pair.output_base.link_controller.linked_belt_pairs[pair_id] = nil
        end
        self.linked_belt_pairs[pair_id] = nil
        return true
    else
        return false, {"mobile_factory.cannot_find_linked_belt_by_id", self.base:get_name(), pair_id}
    end
end

function LinkController:get_linked_belt_information()
    return Table.map(self.linked_belt_pairs, function(pair)
        local input_belt_position = pair.input_belt and pair.input_belt.valid and pair.input_belt.position or nil
        local output_belt_position = pair.output_belt and pair.output_belt.valid and pair.output_belt.position or nil
        return {
            id = pair.id,
            input_belt_position = input_belt_position,
            output_belt_position = output_belt_position,
            working = input_belt_position and output_belt_position and pair.input_belt.linked_belt_neighbour and true or false
        }
    end)
end

function LinkController:on_entity_cloned(entity, cloned)
    for _, pair in pairs(self.linked_belt_pairs) do
        if pair.input_belt == entity then
            pair.input_belt = cloned
            return
        end
        if pair.output_belt == entity then
            pair.output_belt = cloned
            return
        end
    end
end

function LinkController:is_my_linked_belt(entity)
    if entity and entity.type == 'linked-belt' then
        for _, pair in pairs(self.linked_belt_pairs) do
            if pair.input_belt == entity or pair.output_belt == entity then
                return true
            end
        end
    end
    return false
end

return LinkController
