local log = require("nature.core.log")
local events = require("nature.core.events")
local config = require("nature.config.manager")

local _M = {}

local upstreams = {}

local function upstream_change(data)
    local func = _M[data.type]
    if func then
        func(data)
    end
end

function _M.init()
    local conf = config.get('conf')
    conf = conf and conf.discovery or nil
    if conf then
        for _, k in pairs(conf) do
            local ok, p = pcall(require, "nature.discovery." .. k)
            if ok then
                p.upstreams = upstreams
                local init = p['init']
                if init then
                    init()
                end
                local up_change = p['upstream_change']
                if up_change then
                    _M[k] = up_change
                end
            else
                log.error('load discovery ', k, ' failed: ', p)
            end
        end
        events.subscribe('*', 'upstream_change', upstream_change)
    end
end

function _M.init_worker()
    local conf = config.get('conf')
    conf = conf and conf.discovery or nil
    if conf then
        for _, k in ipairs(conf) do
            local ok, p = pcall(require, "nature.discovery." .. k)
            if ok then
                local init = p['init_worker']
                if init then
                    init()
                end
            else
                log.error('load discovery ', k, ' failed: ', p)
            end
        end
    end
    ngx.timer.at(0, function()
        local upstream = config.get('upstream')
        if upstream then
            for key, value in pairs(upstream) do
                value.key = key
                upstream_change(value)
            end
        end
    end)

end

function _M.pick_server(ctx)
    local up = ctx.picker
    if not up then
        up = ctx.upstream_key
        up = up and upstreams[up] or nil
        ctx.picker = up
        if not up then
            return nil, 'no upstream'
        end
    end
    return up.pick(ctx)
end

return _M
