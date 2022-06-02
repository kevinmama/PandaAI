local KC = require 'klib/container/container'
local Table = require 'klib/utils/table'
local LazyTable = require 'klib/utils/lazy_table'
local Event = require 'klib/event/event'
local ColorList = require 'stdlib/utils/defines/color_list'

local Position = require 'klib/gmo/position'
local Area = require 'klib/gmo/area'
local Entity = require 'klib/gmo/entity'
local Inventory = require 'klib/gmo/inventory'
local Command = require 'klib/gmo/command'

local Config = require 'scenario/mobile_factory/config'
local Team = require 'scenario/mobile_factory/player/team'
local Player = require 'scenario/mobile_factory/player/player'

local U = require 'scenario/mobile_factory/base/mobile_base_utils'

local ResourceWarpingController = KC.class(Config.PACKAGE_BASE_PREFIX .. 'ResourceWarpingController', function(self, base)
    self.base = base
    self.enable_warping_in_resources = true
    self.warping_in_resources = false
    self.input_resources = {}
    self.output_resources = {}
end)

function ResourceWarpingController:update()
    local base = self.base
    if base:is_heavy_damaged() then return end
    self:update_warp_in_resources()
    self:update_output_resources()
    self:warp_vehicle_inventory()
end

function ResourceWarpingController:on_destroy()
    self:for_each_output_resources(function(resource)
        resource.destroy()
    end)
end

function ResourceWarpingController:toggle_warping_in_resources()
    self.enable_warping_in_resources = not self.enable_warping_in_resources
    return self.enable_warping_in_resources
end

function ResourceWarpingController:is_enable_warping_in_resources()
    return self.enable_warping_in_resources
end

function ResourceWarpingController:is_warping_in_resources()
    return self.warping_in_resources
end

function ResourceWarpingController:get_output_resources_count()
    return Table.reduce(self.output_resources, function(sum, tbl) return sum+#tbl end, 0)
end

function ResourceWarpingController:for_each_output_resources(handler)
    Table.each(self.output_resources, function(tbl) Table.each(tbl, handler)  end)
end

--------------------------------------------------------------------------------
--- 折跃资源到基地存储
--------------------------------------------------------------------------------

function ResourceWarpingController:update_warp_in_resources()
    local base = self.base
    if not self.warping_in_resources then
        if not base.moving and self.enable_warping_in_resources then
            if (game.tick - base.moving_tick) >= Config.RESOURCE_WARPING_BOOT_TIME then
                self:start_warping_in()
                self:warp_in_resources()
            else
                Entity.create_flying_text(base.vehicle, {"mobile_factory.start_warping_hint"}, {
                    color = ColorList.green
                })
            end
        end
    else
        if base.moving or not self.enable_warping_in_resources then
            self:stop_warping_in()
        else
            self:warp_in_resources()
        end
    end
end

function ResourceWarpingController:start_warping_in()
    --game.print("start warping")
    self.warping_in_resources = true
    self:find_resources()
end

function ResourceWarpingController:find_resources()
    local resources = self.base.surface.find_entities_filtered({
        area = Area.from_dimensions(Config.RESOURCE_WARPING_DIMENSIONS, self.base.vehicle.position),
        type = 'resource'
    })
    self.input_resources = resources
end

function ResourceWarpingController:stop_warping_in()
    --game.print("stop warping")
    self.warping_in_resources = false
    self.input_resources = {}
end

--- 资源折跃速率和采矿产能关联
function ResourceWarpingController:get_resource_warp_rate()
    return self.base.team:get_resource_warp_rate()
end

local function get_real_rate(resource, rate)
    local category = resource.prototype.resource_category
    if category == 'basic-solid' then
        return rate
    elseif category == 'basic-fluid' then
        return rate * 3000
    else -- default
        return rate
    end
end

--- 添加到基地资源计数
function ResourceWarpingController:warp_in_resources()
    if Table.is_empty(self.input_resources) then return end
    local base = self.base
    local delta_amount = {}
    local basic_rate = self:get_resource_warp_rate()
    Table.array_each_reverse(self.input_resources, function(resource, index)
        local delta
        if resource.valid then
            local rate = get_real_rate(resource, basic_rate)
            if resource.amount > rate then
                delta = rate
                resource.amount = resource.amount - delta
                base.resource_amount[resource.name] = base.resource_amount[resource.name] + delta
                LazyTable.add(delta_amount, resource.name, delta)
            else
                delta = resource.amount
                base.resource_amount[resource.name] = base.resource_amount[resource.name] + delta
                LazyTable.add(delta_amount, resource.name, delta)
                resource.destroy()
                Table.remove(self.input_resources, index)
            end
        else
            Table.remove(self.input_resources, index)
        end
    end)
    --game.print(serpent.line(base.resource_amount))
    local pollution = base.pollution_controller:spread_warped_resources_pollution(delta_amount)
    self:render_warped_in_resources(delta_amount, pollution)
end

function ResourceWarpingController:render_warped_in_resources(amount_map, pollution)
    local base = self.base
    local text = Table.reduce(amount_map, function(text, amount, name)
        if Entity.is_fluid_resource(name) then
            text = text .. ' [fluid=' .. name .. ']' .. (amount / 3000) .. '%'
        else
            text = text .. ' [item=' .. name .. ']' .. amount
        end
        return text
    end, "")
    text = text .. '[img=utility/show_pollution_in_map_view]' .. pollution
    base.surface.create_entity({
        name = 'flying-text',
        text = text,
        position = Position(base.vehicle.position),
        color = ColorList.green
    })
end

--------------------------------------------------------------------------------
--- 抽取资源到输出点 (不能超过一定数量点 256)
--------------------------------------------------------------------------------
function ResourceWarpingController:create_output_resources(name, position_or_area, options)
    local base = self.base
    options = Table.merge({}, options)
    local messenger = options.player or self.base.force
    if Area.is_area(position_or_area) then
        local area = Area.intersect(U.get_base_area(base, true), position_or_area)
        if not area then
            messenger.print({"mobile_factory.cannot_create_output_resource_out_of_base_area", base.name})
        else
            options.position_checked = true
            for position in Area.iterate(area, true, true, 6) do
                if not self:_create_output_resource(name, position, options) then
                    self:update_drill_connections(area)
                    return
                end
            end
            self:update_drill_connections(area)
        end
    else
        ResourceWarpingController:_create_output_resource(name, position_or_area, options)
        self:update_drill_connections(Area.from_dimensions({width=7,height=7}, position_or_area))
    end
end

function ResourceWarpingController:_create_output_resource(name, position, options)
    local base = self.base
    options = options or {}
    local messenger = options.player or self.base.force
    local is_fluid_resource = Entity.is_fluid_resource(name)
    local target_amount =  is_fluid_resource and Config.RESOURCE_WARP_OUT_MIN_AMOUNT * 3000 or Config.RESOURCE_WARP_OUT_MIN_AMOUNT

    if base.resource_amount[name] < target_amount then
        messenger.print({"mobile_factory.cannot_create_output_resource_low_amount", base.name, name, position.x, position.y, Config.RESOURCE_WARP_OUT_MIN_AMOUNT .. (is_fluid_resource and '%' or '')})
        return false
    end

    if self:get_output_resources_count() >= Config.RESOURCE_WARP_OUT_POINT_LIMIT then
        messenger.print({"mobile_factory.cannot_create_output_resource_reach_limit", base.name, name, position.x, position.y, Config.RESOURCE_WARP_OUT_POINT_LIMIT})
        return false
    end

    if not options.position_checked and not Area.contains_positions(U.get_base_area(base, true), position) then
        messenger.print({"mobile_factory.cannot_create_output_resource_out_of_base", base.name, position.x, position.y})
        return false
    end

    base.resource_amount[name] = base.resource_amount[name] - target_amount
    local resource = base.surface.create_entity({ name = name, position = position, amount = target_amount})
    LazyTable.insert(self.output_resources, resource.name, resource)
    return true
end

function ResourceWarpingController:remove_output_resources(area, options)
    local base = self.base
    local area = Area.intersect(U.get_base_area(base), area)
    if area then
        local resources = base.surface.find_entities_filtered({ type = 'resource', area = area})
        for _, resource in pairs(resources) do
            base.resource_amount[resource.name] = base.resource_amount[resource.name] + resource.amount
            -- remove exists output resource
            local tbl = self.output_resources[resource.name]
            Table.find(tbl, function(r, i)
                if r == resource then
                    Table.remove(tbl, i)
                    return true
                else
                    return false
                end
            end)
            resource.destroy()
        end
        return true
    else
        local options = options or {}
        local messenger = options.player or self.base.force
        messenger.print({"mobile_factory.cannot_remove_output_resource_out_of_base", base.name})
        return false
    end
end

function ResourceWarpingController:update_output_resources()
    local base = self.base
    for name, res_tab in pairs(self.output_resources) do
        local target_amount = Entity.is_fluid_resource(name) and Config.RESOURCE_WARP_OUT_MIN_AMOUNT * 3000 or Config.RESOURCE_WARP_OUT_MIN_AMOUNT
        local remain = base.resource_amount[name]
        for index = #res_tab, 1, -1 do
            local resource = res_tab[index]
            if remain == 0 then break end
            if resource.valid then
                local delta = target_amount - resource.amount
                if delta > remain then
                    delta = remain
                end
                resource.amount = resource.amount + delta
                remain = remain - delta
            else
                -- 因为传送失效的资源点会出错，故不再处理
                Table.remove(res_tab, index)
                --if remain >= target_amount then
                --    Table.remove(res_tab, index)
                --    local new_resource = base.surface.create_entity({
                --        name = name, position = resource.position, amount = target_amount
                --    })
                --    Table.insert(res_tab, index, new_resource)
                --    remain = remain - target_amount
                --    local drills = base.surface.find_entities_filtered({
                --        type = "mining-drill",
                --        area = Area.from_dimensions({width=7,height=7}, resource.position)
                --    })
                --    for _, drill in pairs(drills) do
                --        drill.update_connections()
                --    end
                --else
                --    break
                --end
            end
        end
        base.resource_amount[name] = remain
    end
end

function ResourceWarpingController:update_drill_connections(area)
    local drills = self.base.surface.find_entities_filtered({type = "mining-drill", area = area, force = self.base.force})
    for _, drill in pairs(drills) do
        drill.update_connections()
    end
end

function ResourceWarpingController:create_well_pump(area, options)
    local base = self.base
    options = Table.merge({}, options)
    local messenger = options.player or base.force
    area = Area.intersect(U.get_base_area(base, true), area)
    if not area then
        messenger.print({"mobile_factory.cannot_create_well_pump_out_of_base", base.name})
    else
        local player_inventory = options.player and options.player.get_main_inventory()
        for position in Area.iterate(area, true, true, 2) do
            if not Entity.is_collides_in_position("offshore-pump", base.surface, position) then
                if options.create_from_void or Inventory.consume(player_inventory, "offshore-pump", 1) then
                    base.surface.create_entity({ name = "offshore-pump", position = position, force = base.force })
                else
                    messenger.print({"mobile_factory.cannot_create_well_pump_out_of_item", base.name})
                    return
                end
            end
        end
    end
end

--- 同步基地出口车与基地车的物品栏
--- 设置了过滤器的做输出，没设置的做输入
function ResourceWarpingController:warp_vehicle_inventory()
    local base = self.base
    local inv1 = base.vehicle.get_inventory(defines.inventory.car_trunk)
    local inv2 = base.exit_entity.get_inventory(defines.inventory.car_trunk)
    Inventory.exchange_car_inventory(inv1, inv2)
end

if Config.DEBUG then
    Command.add_admin_command('create-output-resource',"create output resource for debug", function(data)
        local mf_player = Player.get(data.player_index)
        if mf_player.visiting_base then
            mf_player.visiting_base.resource_warping_controller:create_output_resources(data.parameter or "iron-ore", mf_player.player.position)
        end
    end)
    Command.add_admin_command('remove-output-resource',"remove output resource for debug", function(data)
        local mf_player = Player.get(data.player_index)
        if mf_player.visiting_base then
            mf_player.visiting_base.resource_warping_controller:remove_output_resources(
                    Area.from_dimensions({width=8, height=8}, mf_player.player.position)
            )
        end
    end)
end

return ResourceWarpingController
