local KC = require 'klib/container/container'
local ModGuiFrame = require 'klib/fgui/mod_gui_frame'
local Entity = require 'klib/gmo/entity'
local Inventory = require 'klib/gmo/inventory'
local Player = require 'klib/gmo/player'
local Table = require 'klib/utils/table'
local gui = require 'flib/gui'
local Unit = require 'kai/agent/unit'
local Commands = require 'kai/command/commands'
local Behaviors = require 'kai/behavior/behaviors'

local InfantryGroup = require 'scenario/nauvis_war/infantry_group'

local BuyGui = KC.singleton('scenario.NauvisWar.BuyGui', ModGuiFrame, function(self)
    ModGuiFrame(self)
    self.mod_gui_sprite = "item/coin"
    self.mod_gui_tooltip = "左键打开购买士兵，右键收集金币，分子弹"
    self.mod_gui_frame_caption = "购买士兵"
    self.mod_gui_frame_minimal_width = 0
end)

function BuyGui:build_main_frame_structure()
    return {
        type = 'flow',
        direction = 'vertical',
        self:build_buy_soldier_button('item/raw-fish', 100, {
            ['_item'] = true,
            ['raw-fish'] = 20
        }),
        self:build_buy_soldier_button('item/pistol', 50, {
            ["pistol"] = 1, ["firearm-magazine"] = 50, ["light-armor"] = 1, ['raw-fish'] = 5
        }),
        self:build_buy_soldier_button("item/shotgun", 250, {
            ["shotgun"] = 1, ["shotgun-shell"] = 200, ["heavy-armor"] = 1, ['raw-fish'] = 20
        }),
        self:build_buy_soldier_button("item/submachine-gun", 500, {
            ["submachine-gun"] = 1, ["piercing-rounds-magazine"] = 200, ["heavy-armor"] = 1, ['raw-fish'] = 20
        }),
        self:build_buy_soldier_button("item/rocket-launcher", 1000, {
            ["rocket-launcher"] = 1, ["rocket"] = 200, ["heavy-armor"] = 1, ['raw-fish'] = 20
        }),
        self:build_buy_soldier_button("item/flamethrower", 2000, {
            ["flamethrower"] = 1, ["flamethrower-ammo"] = 100, ["modular-armor"] = 1, ['raw-fish'] = 100,
            ['battery-mk2-equipment'] = 1, ['energy-shield-equipment'] = 2, ['solar-panel-equipment'] = 15
        }),
        self:build_buy_soldier_button("item/combat-shotgun", 5000, {
            ["combat-shotgun"] = 1, ["piercing-shotgun-shell"] = 200, ["power-armor"] = 1, ['raw-fish'] = 500,
            ["fusion-reactor-equipment"] = 1, ['energy-shield-mk2-equipment'] = 2,
            ["personal-laser-defense-equipment"] = 3, ['battery-mk2-equipment'] = 3, ['solar-panel-equipment'] = 7
        }),
        --self:build_buy_soldier_button("technology/discharge-defense-equipment", 50000, {
        self:build_buy_soldier_button("entity/character", 50000, {
            ["pistol"] = 1, ["uranium-rounds-magazine"] = 200,
            ["power-armor-mk2"] = 1, ['raw-fish'] = 1000,
            ["fusion-reactor-equipment"] = 2, ['battery-mk2-equipment'] = 4,
            ['energy-shield-mk2-equipment'] = 5, ["personal-laser-defense-equipment"] = 10,
            ['discharge_defense'] = true
        }),
    }
end

function BuyGui:build_buy_soldier_button(sprite, price, tags)
    return {
        type = 'flow',
        direction = 'horizontal',
        style_mods = {vertical_align = "center"},
        {
            type = "sprite-button",
            style = "slot_button",
            sprite = sprite,
            mouse_button_filter = {"left"},
            actions = { on_click = "on_buy_soldier" },
            tags = Table.merge({price=price}, tags)
        },{
            type = 'label',
            style = "bold_label",
            style_mods = { font = "heading-1"},
            caption = price .. "[item=coin]",
        }
    }
end

function BuyGui:post_build_mod_gui_frame(refs, player)
    gui.update(refs.mod_gui_button, {
        elem_mods = {mouse_button_filter = {"left", "right"}},
    })
end

function BuyGui:toggle_mod_gui_frame(event, refs)
    if event.button == defines.mouse_button_type.left then
        ModGuiFrame.toggle_mod_gui_frame(self, event, refs)
    elseif event.button == defines.mouse_button_type.right then
        self:on_redistribute(event, refs)
    end
end

function BuyGui:on_redistribute(event, refs)
    local player = game.get_player(event.player_index)
    if not (player.character and player.character.valid) then
        player.print("死亡状态不能交换物品")
        return
    end

    local group_id = Player.get_data(player.index, "group_id")
    local group = KC.get(group_id)
    local function reduce_entities(entities, member)
            if member:is_valid() then
                if  KC.is_object(member, Unit) then
                    Table.insert(entities, member.entity)
                else
                    Table.reduce(member:get_members(), reduce_entities, entities)
                end
            end
            return entities
    end
    local entities = Table.reduce(group:get_members(), reduce_entities, {})

    Inventory.collect_items(player.character, entities, {"coin"})

    local source = Inventory.get_main_inventory(player.character)
    for _, entity in pairs(entities) do
        local guns = entity.get_inventory(defines.inventory.character_guns)
        local dest = entity.get_inventory(defines.inventory.character_ammo)
        if guns.get_item_count('pistol') > 0 then
            Inventory.transfer_item(source, dest, "firearm-magazine", 10, 50)
        elseif guns.get_item_count("submachine-gun") > 0 then
            Inventory.transfer_item(source, dest, "piercing-rounds-magazine", 10, 200)
        elseif guns.get_item_count('shotgun') > 0 then
            Inventory.transfer_item(source, dest, "shotgun-shell", 10, 100)
        elseif guns.get_item_count("flamethrower") then
            Inventory.transfer_item(source, dest, "flamethrower-ammo", 10, 100)
        elseif guns.get_item_count("rocket-launcher") > 0 then
            Inventory.transfer_item(source, dest, "rocket", 10, 200)
        elseif guns.get_item_count("combat-shotgun") > 0 then
            Inventory.transfer_item(source, dest, "piercing-shotgun-shell", 10, 200)
        end
        Inventory.transfer_item(source, entity.get_inventory(defines.inventory.character_main), "raw-fish", 10, 50)
    end

    -- 并捡死人尸体
    local corpses = player.surface.find_entities_filtered({
        name = 'character-corpse',
        position = player.position,
        radius = 32
    })
    for _, corpse in pairs(corpses) do
        Inventory.transfer_inventory(Inventory.get_main_inventory(corpse), Inventory.get_main_inventory(player.character))
    end
end

function BuyGui:on_buy_soldier(event)
    local player = game.get_player(event.player_index)
    if not (player.character and player.character.valid) then
        player.print("死亡状态不能买物品")
        return
    end

    local weapon_spec = gui.get_tags(event.element)
    if __DEBUG__ or Entity.buy(player, weapon_spec.price) then
        if weapon_spec._item then
            Entity.give_unit_armoury(player.character, weapon_spec)
            return
        end

        local surface = game.surfaces[1]
        local unit = Entity.create_unit(surface, {
            name = "character", position = player.position, force = player.force
        }, weapon_spec)
        local agent = Unit:new(unit)
        --agent:add_behavior(Behaviors.Formation)
        --agent:add_behavior(Behaviors.Separation)
        agent:add_behavior(Behaviors.Alert)
        --agent:set_command(Commands.Follow, player)
        if weapon_spec.discharge_defense then
            agent.discharge_defense = true
            unit.character_health_bonus = 4750
        end

        local group_id = Player.get_data(player.index, "group_id")
        local group = KC.get(group_id)

        --group:add_member(agent)
        --agent:add_behavior(Behaviors.Follow, group, {
        --    slowdown_distance = group.maximum_radius,
        --    stop_distance = group.maximum_radius / 2
        --})

        if KC.is_object(group, InfantryGroup) then
            local gun_name = unit.get_inventory(defines.inventory.character_guns)[1].name
            if gun_name == "combat-shotgun" then gun_name = 'shotgun' end
            local group_name = string.gsub(gun_name, '-', '_')
            group[group_name .. '_group']:add_member(agent)
        else
            group:add_member(agent)
        end
    else
        player.print("你没有足够的金币")
    end
end

return BuyGui