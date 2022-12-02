local log    = require("nature.core.log")
local events = require("nature.core.events")
local config = require("nature.config.manager")
local lb     = require("nature.balancer.lb")

local _M = {}

local upstreams = {}

local function upstream_change(data)
    upstreams[data.key] = data.nodes and lb.create(data.nodes, data.lb) or nil
end

function _M.init()
    local conf = config.get('conf')
    conf = conf and conf.discovery or nil
    if conf then
        for _, k in pairs(conf) do
            local ok, p = pcall(require, "nature.discovery." .. k)
            if ok then
                local init = p['init']
                if init then
                    init()
                end
            else
                log.error('load discovery ', k, ' failed: ', p)
            end
        end
    end
end

function _M.init_worker()
    events.subscribe('upstream', 'upstream_change', upstream_change)
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
