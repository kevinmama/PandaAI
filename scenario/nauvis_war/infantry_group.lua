local KC = require 'klib/container/container'

local Group = require 'kai/agent/group'
local Formations = require 'kai/formation/formations'
local Behaviors = require 'kai/behavior/behaviors'
local InfantryFormation = require 'scenario.nauvis_war.infantry_formation'

local InfantryGroup = KC.class('scenario.NauvisWar.InfantryGroup', Group, function(self, props, leader)
    Group(self, props)
    self:set_leader(leader)
    self.shotgun_group = self:create_subgroup()
    self.flamethrower_group = self:create_subgroup()
    self.submachine_gun_group = self:create_subgroup()
    self.pistol_group = self:create_subgroup()
    self.rocket_launcher_group = self:create_subgroup()
    self:set_formation(InfantryFormation)
end)

function InfantryGroup:create_subgroup()
    local subgroup = Group:new({
        surface = self:get_surface(),
        position = self:get_position(),
        force = self:get_force(),
        bounding_box = self:get_bounding_box()
    })
    subgroup:set_formation(Formations.SingleRow)
    --subgroup:add_behavior(Behaviors.Separation)
    self:add_member(subgroup)
    return subgroup
end

return InfantryGroup
