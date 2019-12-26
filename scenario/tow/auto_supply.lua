local KC = require('klib/container/container')
local RandomWeapon = require('scenario/tow/random_weapon')

local AutoSupply = KC.class('AmmoSupply', function(self)

end)

function AutoSupply:supply_ammo(character, item)
    local inv = character.get_inventory(defines.inventory.character_ammo)
    if (inv.can_insert(item)) then
        inv.insert(item)
    end
end

function AutoSupply:supply_weapon(character, item)
    local inv = character.get_inventory(defines.inventory.character_guns)
    if inv.get_item_count(item.name) == 0 and inv.can_insert(item) then
        inv.insert(item)
    end
end

function AutoSupply:random_weapon_and_ammo(character)
    local wp = RandomWeapon[math.random(1, #RandomWeapon)]
    self:supply_weapon(character, wp.weapon)
    self:supply_ammo(character, wp.ammo)
end

function AutoSupply:supply_weapon_and_ammo(characters)
    for _, character in pairs(characters) do
        self:random_weapon_and_ammo(character)
    end
end

return AutoSupply

