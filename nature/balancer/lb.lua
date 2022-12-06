local hc = require('nature.core.healthcheck')
local get_status = hc.get_status
local report_failure = hc.report_failure

local _M = {}

local function crate_healthcheck(picker, length, upstream_key)
    local pick = picker.pick
    picker.pick = function(ctx)
        local server, err
        for i = 1, length do
            server, err = pick(ctx)
            if not server then
                return server, err
            end
            if get_status(upstream_key, server.pool) then
                return server
            end
        end
        return nil, 'no health node'
    end
    picker.report_failure = function(server)
        report_failure(upstream_key, server.pool)
    end
end

function _M.create(nodes, lb, has_healthcheck, upstream_key)
    local length = #nodes
    if length == 0 then
        return nil
    elseif length == 1 then
        lb = 'onlyyou'
    end

    if not lb then
        lb = 'roundrobin'
    end
    local picker = require('nature.balancer.' .. lb)(nodes)
    if has_healthcheck then
        crate_healthcheck(picker, length, upstream_key)
    end
    return picker
end

return _M
