local rf = require('nature.core.string').re_find
local exit = require('nature.core.response').exit
local _M = {}

local function check_var(var, rules)
    if var ~= nil then
        for i, rule in ipairs(rules) do
            if rule ~= "" and rf(var, rule, "sijo") then
                exit(400)
                return true
            end
        end
    end
    return false
end

function _M.access(ctx, plugin_data, matched_router)
    local waf = plugin_data.waf
    if not waf then
        return
    end
    local rules = waf.rules
    if not rules then
        return
    end
    local var_names = waf.vars
    if not var_names then
        return
    end
    local vars = ctx.var
    for _, var_name in ipairs(var_names) do
        if check_var(vars[var_name], rules) then
            return
        end
    end
end

return _M
