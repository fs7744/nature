return function(nodes)
    local node = nodes[1]
    return {
        pick = function()
            return node
        end
    }
end
