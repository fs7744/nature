local chash = require("resty.chash")

return function(nodes)
    local ns = {}
    local nodes_hash = {}
    for _, v in ipairs(nodes) do
        ns[v.pool] = v.weight
        nodes_hash[v.pool] = v
    end
    local picker = chash:new(ns)
    return {
        pick = function(ctx)
            local last_server_index = ctx._chash_last_server_index
            if last_server_index then
                local id
                id, last_server_index = picker:next(last_server_index)
                ctx._chash_last_server_index = last_server_index
                return nodes_hash[id]
            else
                local chash_key = ctx._chash_key
                if not chash_key then
                    return nil, 'no chash key'
                end
                local id
                id, last_server_index = picker:find(chash_key)
                ctx._chash_last_server_index = last_server_index
                return nodes_hash[id]
            end
        end
    }
end
