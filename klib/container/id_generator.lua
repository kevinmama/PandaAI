--- inspire by https://github.com/sony/sonyflake/blob/master/sonyflake.go

--- lua number has 52 bit

--- SnowFlake unique id generation algorithm

local BIT_LEN_SEQUENCE = 8
local BIT_LEN_TICK = 52 - BIT_LEN_SEQUENCE

local MASK_SEQUENCE = bit32.lshift(1, BIT_LEN_SEQUENCE) - 1
local TICK_BIT_OFFSET = bit32.lshift(1, BIT_LEN_SEQUENCE)
local TICK_LIMIT = math.pow(2, BIT_LEN_TICK)

local tick = 0
local sequence = 0

local function to_id()
    if tick >= TICK_LIMIT then
        error("over the time limit")
    end
    return tick * TICK_BIT_OFFSET + sequence
end

local function next_id()
    if game and tick < game.tick then
        tick = game.tick
        sequence = 0
    else
        sequence = bit32.band((sequence + 1),  MASK_SEQUENCE)
        if sequence == 0 then
            tick = tick + 1
        end
    end

    --return 'k' .. self:to_id()
    return to_id()
end

return next_id

