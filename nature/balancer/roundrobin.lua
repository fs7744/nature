local roundrobin = require("resty.roundrobin")

return function(nodes)
    local ns = {}
    local nodes_hash = {}
    local safe_limit = #nodes
    for _, v in ipairs(nodes) do
        ns[v.pool] = v.weight
        nodes_hash[v.pool] = v
    end
    local picker = roundrobin:new(ns)
    return {
        pick = function(ctx)
            local node, err
            for i = (ctx._roundrobin_safe_limit or 1), safe_limit do
                ctx._roundrobin_safe_limit = i + 1
                node, err = picker:find()
                if not node then
                    return nil, err
                end
                return nodes_hash[node]
            end
            return nil, err
        end
    }
end
