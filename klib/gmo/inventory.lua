local Table = require('klib/utils/table')

local Inventory = {}

--- 尽可能把 source 的物品传送到 destination
function Inventory.transfer_inventory(source, destination)
    for name, count in pairs(source.get_contents()) do
        local inserted_count = destination.insert({name=name, count=count})
        if inserted_count > 0 then
            source.remove({name=name,count=inserted_count})
        end
    end
end

--- 交换两车物品，设置过滤器的格式作输入，其余的作输出
-- 可以尝试做多载具物品交换，一般化之
function Inventory.exchange_car_inventory(inv1, inv2)
    -- 目前这种实现只能处理简单的整堆传送
    local providedItemStack1 = {}
    local requestItemStack1 = {}
    for i=1, #inv1 do
        local filter_name = inv1.get_filter(i)
        if filter_name then
            -- 统计需要的物品
            local stack = inv1[i]
            if stack.count == 0 then
                Table.insert(requestItemStack1, {name=filter_name, stack=stack})
            end
        else
            -- 统计可提供物品
            local stack = inv1[i]
            if stack.valid_for_read then
                local pl = providedItemStack1[stack.name]
                if not pl then
                    pl = {}
                    providedItemStack1[stack.name] = pl
                end
                Table.insert(pl, stack)
            end
        end
    end

    local providedItemStack2 = {}
    local requestItemStack2 = {}
    for i=1, #inv2 do
        local filter_name = inv2.get_filter(i)
        if filter_name then
            -- 统计需要的物品
            local stack = inv2[i]
            if stack.count == 0 then
                Table.insert(requestItemStack2, {name=filter_name, stack=stack})
            end
        else
            -- 统计可提供物品
            local stack = inv2[i]
            if stack.valid_for_read then
                local pl = providedItemStack2[stack.name]
                if not pl then
                    pl = {}
                    providedItemStack2[stack.name] = pl
                end
                Table.insert(pl, stack)
            end
        end
    end

    -- transfer item stack
    for _, t in ipairs(requestItemStack1) do
        local name, stack = t.name, t.stack
        local stack_list = providedItemStack2[name]
        if stack_list and not Table.is_empty(stack_list) then
            local p_stack = Table.remove(stack_list)
            stack.transfer_stack(p_stack)
        end
    end

    for _, t in pairs(requestItemStack2) do
        local name, stack = t.name, t.stack
        local stack_list = providedItemStack1[name]
        if stack_list and not Table.is_empty(stack_list) then
            local p_stack = Table.remove(stack_list)
            stack.transfer_stack(p_stack)
        end
    end
end

return Inventory