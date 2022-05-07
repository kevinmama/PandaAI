--- original code: https://github.com/Oarcinae/FactorioScenarioMultiplayerSpawn/commits/master
--- modify by kevinma

local ScriptHelper = require 'klib/helper/script_helper'
local KC = require 'klib/container/container'

local AUTOFILL_TURRET_AMMO_QUANTITY = 10
local AUTOFILL_VEHICLE_FUEL_QUANTITY = 50
local AUTOFILL_VEHICLE_AMMO_QUANTITY = 100
local SAFE_DISTANCE = 50
local COLOR_RED = { r=1, g=0.1, b=0.1}

local AutoFill = KC.singleton('klib/addon/Autofill', function(self)
end)

-- Transfer Items Between Inventory
-- Returns the number of items that were successfully transferred.
-- Returns -1 if item not available.
-- Returns -2 if can't place item into destInv (ERROR)
function AutoFill:transfer_items(src_inv, dest_entity, item_stack)
    -- Check if item is in srcInv
    if (src_inv.get_item_count(item_stack.name) == 0) then
        return -1
    end

    -- Check if can insert into destInv
    if (not dest_entity.can_insert(item_stack)) then
        return -2
    end

    -- Insert items
    local itemsRemoved = src_inv.remove(item_stack)
    item_stack.count = itemsRemoved
    return dest_entity.insert(item_stack)
end


-- Attempts to transfer at least some of one type of item from an array of items.
-- Use this to try transferring several items in order
-- It returns once it successfully inserts at least some of one type.
function AutoFill:transfer_item_multiple_types(src_inv, dest_entity, item_name_array, item_count)
    local ret = 0
    for _,itemName in pairs(item_name_array) do
        ret = self:transfer_items(src_inv, dest_entity, { name=itemName, count= item_count })
        if (ret > 0) then
            return ret -- Return the value succesfully transferred
        end
    end
    return ret -- Return the last error code
end

-- Autofills a turret with ammo
function AutoFill:autofill_turret(player, turret)
    local mainInv = player.get_inventory(defines.inventory.player_main)

    -- Attempt to transfer some ammo
    local ret = self:transfer_item_multiple_types(mainInv, turret, {"uranium-rounds-magazine", "piercing-rounds-magazine", "firearm-magazine"}, AUTOFILL_TURRET_AMMO_QUANTITY)

    -- Check the result and print the right text to inform the user what happened.
    if (ret > 0) then
        -- Inserted ammo successfully
        -- FlyingText("Inserted ammo x" .. ret, turret.position, my_color_red, player.surface)
    elseif (ret == -1) then
        ScriptHelper.flying_text("Out of ammo!", turret.position, COLOR_RED, player.surface)
    elseif (ret == -2) then
        ScriptHelper.flying_text("Autofill ERROR! - Report this bug!", turret.position, COLOR_RED, player.surface)
    end
end

-- Autofills a vehicle with fuel, bullets and shells where applicable
function AutoFill:autofill_vehicle(player, vehicle)
    local mainInv = player.get_inventory(defines.inventory.player_main)

    -- Attempt to transfer some fuel
    if ((vehicle.name == "car") or (vehicle.name == "tank") or (vehicle.name == "locomotive")) then
        self:transfer_item_multiple_types(mainInv, vehicle, {"nuclear-fuel", "rocket-fuel", "solid-fuel", "coal", "raw-wood"}, AUTOFILL_VEHICLE_FUEL_QUANTITY)
    end

    -- Attempt to transfer some ammo
    if ((vehicle.name == "car") or (vehicle.name == "tank")) then
        self:transfer_item_multiple_types(mainInv, vehicle, {"uranium-rounds-magazine", "piercing-rounds-magazine", "firearm-magazine"}, AUTOFILL_VEHICLE_AMMO_QUANTITY)
    end

    -- Attempt to transfer some tank shells
    if (vehicle.name == "tank") then
        self:transfer_item_multiple_types(mainInv, vehicle, {"explosive-uranium-cannon-shell", "uranium-cannon-shell", "explosive-cannon-shell", "cannon-shell"}, AUTOFILL_VEHICLE_AMMO_QUANTITY)
    end
end

function AutoFill:can_autofill(player, event_entity)
    local surface = player.surface
    if player.character.in_combat then
        ScriptHelper.flying_text("In Combat!", event_entity.position, COLOR_RED, surface)
        return false
    end

    if nil ~= surface.find_nearest_enemy({
        position = event_entity.position,
        max_distance = SAFE_DISTANCE,
        player.force
    }) then
        ScriptHelper.flying_text("Too Close To Enemy", event_entity.position, COLOR_RED, surface)
        return false
    end

    return true
end

AutoFill:on(defines.events.on_built_entity, function(self, event)
    local player = game.players[event.player_index]
    local event_entity = event.created_entity

    if self:can_autofill(player, event_entity) then
        if (event_entity.name == "gun-turret") then
            self:autofill_turret(player, event_entity)
        end

        if ((event_entity.name == "car") or (event_entity.name == "tank") or (event_entity.name == "locomotive")) then
            self:autofill_vehicle(player, event_entity)
        end
    end
end)

return AutoFill

