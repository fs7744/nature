local _M = {}

local function sort_by_key_host(a, b)
    return a.host < b.host
end

function _M.compare_node(old_t, new_t)
    if #new_t ~= #old_t then
        return false
    end

    table.sort(old_t, sort_by_key_host)
    table.sort(new_t, sort_by_key_host)

    for i = 1, #new_t do
        local new_node = new_t[i]
        local old_node = old_t[i]
        for _, name in ipairs({ "host", "port", "weight", "hostname" }) do
            if new_node[name] ~= old_node[name] then
                return false
            end
        end
    end

    return true
end

return _M
