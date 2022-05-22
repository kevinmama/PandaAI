local Position = require 'klib/gmo/position'

local results = {}
for i = 0, 64 do
    local pos = Position.from_spiral_index(i)
    results[i] = {
        index = i,
        pos = pos
    }
end

for i = 0, #results do
    local index = Position.to_spiral_index(results[i].pos)
    results[i].reindex = index
    results[i].error = results[i].reindex ~= results[i].index
end

log(serpent.line(results))
