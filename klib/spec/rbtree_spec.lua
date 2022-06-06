local log = require ("stdlib/misc/logger").new("spec", DEBUG)
local Event = require("klib/event/event")
local rbtree = require "klib/vendor/rbtree"

Event.on_game_ready(function()

    local function log (message)
        game.print(message)
    end

    local data = {1412, 1245, 5632, 1235, 5633, 1235, 5667, 53, 563}
    local data1 = {
        {
            key = 1412,
            open = true
        },
        {
            key = 1245,
            open = false
        },
        {
            key = 5632,
            open = true
        }
    }

    local function insert(tree)
        for _, v in ipairs(data1) do
            log("insert " .. tostring(v) .. " to tree")
            tree:insert(v)
        end
    end

    local tree = rbtree.new()
    insert(tree)
    log("OK insert")

    local s = {}
    tree:travel(function(node)
        s[#s+1] = node.key
        log(serpent.block(node.key))
    end)
    log("OK travel")

    for _, v in ipairs(s) do
        print("OK delete", v)
        tree:delete(v)
    end

end)

local function get_root()
    local t = global.klib.objects['scenario.MobileFactory.ChunkKeeper'].active_chunk_queue.tree
    local ids = {}
    t:travel(function(node)
        if ids[node.id] then
            game.print("duplicate id: " .. node.id)
        else
            ids[node.id] = true
        end
    end)
    game.print(serpent.line(t.root.id))
    game.print(serpent.line(t.root.sentinel))
    game.print(serpent.line(t.sentinel.id))
    game.print(serpent.line(t.sentinel.sentinel))
end