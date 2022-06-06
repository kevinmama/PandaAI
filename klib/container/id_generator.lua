local Symbols = require 'klib/container/symbols'

--- inspire by https://github.com/sony/sonyflake/blob/master/sonyflake.go

--- lua number has 52 bit

--- SnowFlake unique id generation algorithm

local BIT_LEN_SEQUENCE = 8
local BIT_LEN_TICK = 52 - BIT_LEN_SEQUENCE

local MASK_SEQUENCE = bit32.lshift(1, BIT_LEN_SEQUENCE) - 1
local TICK_BIT_OFFSET = bit32.lshift(1, BIT_LEN_SEQUENCE)
local TICK_LIMIT = math.pow(2, BIT_LEN_TICK)

local function get_or_create_registry()
    local  registry = global[Symbols.ID_REGISTRY]
    if not registry then
        registry = { tick = 0, sequence = 0}
        global[Symbols.ID_REGISTRY] = registry
    end
    return registry
end

local function next_id()
    if game then
        local registry = get_or_create_registry()
        if registry.tick < game.tick then
            registry.tick = game.tick
            registry.sequence = 0
        else
            registry.sequence = bit32.band((registry.sequence + 1),  MASK_SEQUENCE)
            if registry.sequence == 0 then
                registry.tick = registry.tick + 1
            end
        end

        if registry.tick >= TICK_LIMIT then
            error("over the time limit")
        end
        return registry.tick * TICK_BIT_OFFSET + registry.sequence
    else
        error("id generator must be working on game object available")
    end
end

return next_id

