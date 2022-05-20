local KC = require('klib/container/container')
local Behavior = require 'kai/behavior/behavior'

local BEAM_COOL_DOWN = 15
local STUN_COOL_DOWN = 300

local Alert = KC.class('kai.behavior.Alert', Behavior, function(self, agent)
    Behavior(self, agent)
    self.beam_tick = 0
    self.stun_tick = 0
end)

function Alert:get_name()
    return "alert"
end

function Alert:update()
    local agent = self:get_agent()
    if not agent:is_unit() then
        return
    end
    self:update_shoot_target()
    self:update_health()
    self:update_discharge_defend()
end

function Alert:update_shoot_target()
    local agent = self:get_agent()
    local entity = agent.entity
    local gun_inv = entity.get_inventory(defines.inventory.character_guns)
    local ammo_inv = entity.get_inventory(defines.inventory.character_ammo)
    for i = 1, #gun_inv do
        local gun_stack, ammo_stack = gun_inv[i], ammo_inv[i]
        if gun_stack.count > 0 and ammo_stack.count > 0 then
            entity.selected_gun_index = i
            local range = gun_stack.prototype.attack_parameters.range
            local enemy = entity.surface.find_nearest_enemy({
                position = entity.position,
                max_distance = range,
                entity.force
            })
            if (enemy ~= nil) then
                entity.shooting_state = {
                    state = defines.shooting.shooting_enemies,
                    position = enemy.position
                }
            else
                entity.shooting_state = {
                    state = defines.shooting.not_shooting
                }
            end
            return
        end
    end

    entity.shooting_state = {
        state = defines.shooting.not_shooting
    }
end

function Alert:update_health()
    local agent = self:get_agent()
    local entity = agent.entity
    if entity.get_health_ratio() < 0.6 then
        local inv = entity.get_inventory(defines.inventory.character_main)
        if inv.get_item_count('raw-fish') > 0 then
            entity.health = entity.health + 80
            inv.remove({name='raw-fish', count = 1})
        end
    end
end

function Alert:update_discharge_defend()
    local agent = self:get_agent()
    if agent.discharge_defense and game.tick > self.beam_tick + BEAM_COOL_DOWN then
        local entity = agent.entity
        --local enemies = entity.surface.find_enemy_units(entity.position, 20, entity.force)
        local enemies = entity.surface.find_entities_filtered({
            type = {'unit', 'unit-spawner', 'turret'},
            position = entity.position,
            radius = 30,
            force = 'enemy'
        })
        if #enemies > 0 then
            local stun = game.tick > self.stun_tick + STUN_COOL_DOWN
            for _, enemy in pairs(enemies) do
                if stun and enemy.type == 'unit' then
                    entity.surface.create_entity({
                        name = 'stun-sticker',
                        target = enemy,
                        position = enemy.position
                    })
                end
                entity.surface.create_entity({
                    name = 'electric-beam-no-sound',
                    source = entity,
                    target = enemy,
                    position = entity.position,
                    force = entity.force,
                    max_length = 32,
                    duration = 15,
                    source_offset = {0,-0.5}
                })
            end
            if stun then
                self.stun_tick = game.tick
            end
            self.beam_tick = game.tick
        end
    end
end

return Alert