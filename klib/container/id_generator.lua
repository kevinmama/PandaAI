--- inspire by https://github.com/sony/sonyflake/blob/master/sonyflake.go

--- lua number has 52 bit

local BIT_LEN_SEQUENCE = 8
local BIT_LEN_TICK = 52 - BIT_LEN_SEQUENCE

local Snowflake = {
    tick = 0,
    sequence = 0,
}

local MASK_SEQUENCE = bit32.lshift(1, BIT_LEN_SEQUENCE) - 1
local TICK_BIT_OFFSET = bit32.lshift(1, BIT_LEN_SEQUENCE)
local TICK_LIMIT = math.pow(2, BIT_LEN_TICK)

function Snowflake:to_id()
    if self.tick >= TICK_LIMIT then
        error("over the time limit")
    end
    return self.tick * TICK_BIT_OFFSET + self.sequence
end

function Snowflake:next_id()
    if game and self.tick < game.tick then
        self.tick = game.tick
        self.sequence = 0
    else
        self.sequence = bit32.band((self.sequence + 1),  MASK_SEQUENCE)
        if self.sequence == 0 then
            self.tick = self.tick + 1
        end
    end

    --return 'k' .. self:to_id()
    return self:to_id()
end

return Snowflake

