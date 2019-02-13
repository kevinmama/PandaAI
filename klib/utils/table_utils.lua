local U = {}

function U.merge_table(to, from)
    for k, v in pairs(from) do
        to[k] = v
    end
    return to
end

return U