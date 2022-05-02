local U = {}
local table = require('__stdlib__/stdlib/utils/table')
local StdEntity = require('__stdlib__/stdlib/entity/entity')

--- build blueprint from blueprint string, blueprint string must be absolute aligned to grid
--- from: eradicator, url: https://forums.factorio.com/viewtopic.php?t=60584
--- @param bp_string string
--- @param surface LuaSurface
--- @param offset Position
--- @param force LuaForce
--- @param options table add to entity when created
function U.build_blueprint_from_string(bp_string,surface,offset,force, options)
    local bp_entity = surface.create_entity{name='item-on-ground',position=offset,stack='blueprint'}
    bp_entity.stack.import_stack(bp_string)
    local bp_entities = bp_entity.stack.get_blueprint_entities()
    bp_entity.destroy()
    for _,entity in pairs(table.deepcopy(bp_entities)) do
        entity.position = {entity.position.x + offset.x, entity.position.y + offset.y}
        entity.force = force
        local created_entity = surface.create_entity(entity)
        table.merge(created_entity, options)
    end
end

U.has = StdEntity.has
U.get_data = StdEntity.get_data
U.set_data = StdEntity.set_data


return U