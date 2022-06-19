local String = require 'stdlib/utils/string'
local math = require 'stdlib/utils/math'

local exponent_multipliers = {
    ['y'] = 0.000000000000000000000001,
    ['z'] = 0.000000000000000000001,
    ['a'] = 0.000000000000000001,
    ['f'] = 0.000000000000001,
    ['p'] = 0.000000000001,
    ['n'] = 0.000000001,
    ['u'] = 0.000001,
    ['m'] = 0.001,
    ['c'] = 0.01,
    ['d'] = 0.1,
    [' '] = 1,
    ['h'] = 100,
    ['k'] = 1000,
    ['K'] = 1000,
    ['M'] = 1000000,
    ['G'] = 1000000000,
    ['T'] = 1000000000000,
    ['P'] = 1000000000000000,
    ['E'] = 1000000000000000000,
    ['Z'] = 1000000000000000000000,
    ['Y'] = 1000000000000000000000000
}

--- Convert a metric string prefix to a number value.
-- @tparam string str
-- @treturn float
function String.exponent_number(str)
    if type(str) == 'string' then
        local value, exp = str:match('([%-+]?[0-9]*%.?[0-9]+)([yzafpnumcdhkKMGTPEZY]?)')
        exp = exp or ' '
        value = (value or 0) * (exponent_multipliers[exp] or 1)
        return value
    elseif type(str) == 'number' then
        return str
    end
    return 0
end


local energy_postfix_list = { 'K', 'M', "G", "T", 'P', 'E', 'Z', 'Y' }
function String.exponent_string(number, p)
    local index = 0
    while number >= 1000 do
        number = number / 1000
        index = index + 1
    end
    if index > 0 then
        return math.round_to(number, p) .. energy_postfix_list[index]
    else
        return math.round_to(number, p)
    end
end

return String