local binaryHeap = require("binaryheap")
local table = require("nature.core.table")
local table_pool_fetch = table.pool_fetch
local table_insert = table.insert
local table_pool_release = table.pool_release

local function least_score(a, b)
    return a.score < b.score
end

return function(nodes)
    local servers_heap = binaryHeap.minUnique(least_score)
    for _, v in ipairs(nodes) do
        local weight = v.weight or 1
        local score = 1 / weight
        servers_heap:insert({
            server = v,
            effect_weight = 1 / weight,
            score = score
        }, v)
    end
    return {
        pick = function(ctx)
            local least_conn_nodes = ctx._conn_nodes
            if not least_conn_nodes then
                least_conn_nodes = table_pool_fetch("conn_nodes", 0, 2)
                ctx._conn_nodes = least_conn_nodes
            end
            local server, info = servers_heap:peek()
            info.score = info.score + info.effect_weight
            servers_heap:update(server, info)
            table_insert(least_conn_nodes, server)
            return server
        end,
        after_balance = function(ctx)
            local least_conn_nodes = ctx._conn_nodes
            if least_conn_nodes then
                ctx._conn_nodes = nil
                for _, server in ipairs(least_conn_nodes) do
                    local info = servers_heap:valueByPayload(server)
                    info.score = info.score - info.effect_weight
                    servers_heap:update(server, info)
                end
                table_pool_release("conn_nodes", least_conn_nodes)
            end
        end
    }
end
