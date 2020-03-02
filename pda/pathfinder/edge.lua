local Edge = {}

function Edge.midpoint(edge)
    return {
        x = (edge[1].x + edge[2].x) / 2,
        y = (edge[1].y + edge[2].y) / 2
    }
end

return Edge
