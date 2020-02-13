local function pkey(node)
    return tostring(node.position.x) .. "_" .. tostring(node.position.y)
end
return pkey
