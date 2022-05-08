local Table = require 'klib/utils/table'
local Time = require 'stdlib/utils/defines/time'
local KC = require 'klib/container/container'

local C = {}

C.RESET_TICKS_LIMIT = 15 * Time.minute

C.PLAYER_INIT_ITEMS = {
    ["submachine-gun"] = 1 ,
    ["firearm-magazine"] = 100,
    ["small-electric-pole"] = 50,
    ["iron-plate"] = 100,
    ["copper-plate"] = 100,
    ["coal"] = 100,
    ["stone"] = 100,
    ["spidertron-remote"] = 1,
}

C.TEST_INIT_ITEMS = {
    ["rocket-launcher"] = 1,
    ["atomic-bomb"] = 10,
}

--Table.merge(C.PLAYER_INIT_ITEMS, C.TEST_INIT_ITEMS)

local PLAYER_INIT_ITEMS = {
    --["tank"] = 1,
    --["spidertron"] = 1,
    --["solar-panel"] = 50,
    --["accumulator"] = 50,
    --["rocket"] = 100,
    --["nuclear-fuel"] = 2
}

C.MOBILE_BASE_MANAGER_CLASS_NAME = 'scenario.MobileFactory.MobileBaseManager'

function C.get_mobile_base_manager()
    local MobileBaseManager = KC.get_class(C.MOBILE_BASE_MANAGER_CLASS_NAME)
    return KC.get(MobileBaseManager)
end

return C