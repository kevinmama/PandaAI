local KC = require 'klib/container/container'
local ModGuiFrame = require 'klib/fgui/mod_gui_frame'
local Entity = require 'klib/gmo/entity'
local Table = require 'klib/utils/table'
local gui = require 'flib/gui'
local Agent = require 'ai/agent/agent'
local Commands = require 'ai/command/commands'
local Behaviors = require 'ai/behavior/behaviors'

local BuyGui = KC.singleton('scenario.NauvisWar.BuyGui', ModGuiFrame, function(self)
    ModGuiFrame(self)
    self.mod_gui_sprite = "item/coin"
    self.mod_gui_tooltip = "购买士兵"
    self.mod_gui_frame_caption = "购买士兵"
    self.mod_gui_frame_minimal_width = 0
end)

function BuyGui:build_main_frame_structure()
    return {
        type = 'flow',
        direction = 'vertical',
        self:build_buy_soldier_button('item/pistol', 50, {
            ["pistol"] = 1, ["firearm-magazine"] = 50, ["light-armor"] = 1
        }),
        self:build_buy_soldier_button("item/shotgun", 200, {
            ["shotgun"] = 1, ["shotgun-shell"] = 200, ["light-armor"] = 1
        }),
        self:build_buy_soldier_button("item/submachine-gun", 500, {
            ["submachine-gun"] = 1, ["firearm-magazine"] = 200, ["light-armor"] = 1
        }),
        self:build_buy_soldier_button("item/flamethrower", 2000, {
            ["flamethrower"] = 1, ["flamethrower-ammo"] = 100, ["heavy-armor"] = 1
        }),
        self:build_buy_soldier_button("item/rocket-launcher", 5000, {
            ["rocket-launcher"] = 1, ["rocket"] = 200, ["heavy-armor"] = 1
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
end

function BuyGui:on_buy_soldier(event)
    local player = game.get_player(event.player_index)
    local weapon_spec = gui.get_tags(event.element)
    if Entity.buy(player, weapon_spec.price) then
        local surface = game.surfaces[1]
        local unit = Entity.create_unit(surface, {
            name = "character", position = player.position, force = player.force
        }, weapon_spec)
        local agent = Agent:new(unit)
        agent:add_behavior(Behaviors.Alert)
        agent:add_behavior(Behaviors.Separation, 1)
        agent:set_command(Commands.Follow, player)
    else
        player.print("你没有足够的金币")
    end
end

return BuyGui