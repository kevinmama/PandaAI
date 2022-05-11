local Table = require 'klib/utils/table'
local Chunk = require 'klib/gmo/chunk'
local Area = require 'klib/gmo/area'
local Dimension = require 'klib/gmo/dimension'
local Config = require 'scenario/mobile_factory/config'

local BASE_SIZE , CHUNK_SIZE = Config.BASE_SIZE, Config.CHUNK_SIZE

local U = {}

function U.for_each_chunk_of_base(base, func)
    Chunk.find_from_dimensions(Dimension.expand(BASE_SIZE, CHUNK_SIZE), base.center, func)
end

function U.find_entities_in_base(base, filter)
    return base.surface.find_entities_filtered(Table.merge({
        {area = Area.from_dimensions(Dimension.expand(BASE_SIZE, CHUNK_SIZE), base.center)}
    },filter))
end

return U