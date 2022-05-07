local Table = require 'klib/utils/table'

local C = {}

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

return C