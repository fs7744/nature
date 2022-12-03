local roundrobin = require("resty.roundrobin")

return function(nodes)
    local ns = {}
    local nodes_hash = {}
    for _, v in ipairs(nodes) do
        ns[v.pool] = v.weight
        nodes_hash[v.pool] = v
    end
    local picker = roundrobin:new(ns)
    return {
        pick = function(ctx)
            local node, err = picker:find()
            if not node then
                return nil, err
            end
            return nodes_hash[node]
        end
    }
end
