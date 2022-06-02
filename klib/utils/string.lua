local String = require 'stdlib/utils/string'

local energy_postfix_list = { 'K', 'M', "G", "T", 'P', 'E', 'Z', 'Y' }
function String.exponent_string(number)
    local index = 0
    while number >= 1000 do
        number = number / 1000
        index = index + 1
    end
    return math.floor(number) .. energy_postfix_list[index]
end

return String