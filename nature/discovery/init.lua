local log    = require("nature.core.log")
local events = require("nature.core.events")
local config = require("nature.config.manager")
local lb     = require("nature.balancer.lb")
local ngp    = require("nature.core.ngp")
local json   = require("nature.core.json")

local _M = {}

local upstreams = {}

local function upstream_change(data)
    local old = upstreams[data.key]
    upstreams[data.key] = data.nodes and lb.create(data.nodes, data.lb) or nil
    if old and old.destroy then
        old.destroy()
    end
end

local function build_upstream(data)
    log.info('build_upstream ', data.key)
    local nodes = {}
    for _, node in ipairs(data.nodes) do
        local discovery = _M[node.discovery]
        if discovery then
            discovery.get(node, nodes)
        end
    end

    for _, node in ipairs(nodes) do
        node.pool = node.host .. ':' .. node.port .. '#' .. (node.hostname or '')
    end
    log.info('build_upstream ', data.key, ' nodes: ', json.delay_encode(nodes))
    events.publish_all('upstream', 'upstream_change',
        { key = data.key, lb = data.lb, nodes = #nodes == 0 and nil or nodes })
end

function _M.init()
    local conf = config.get('conf')
    conf = conf and conf.discovery or nil
    if conf then
        for _, k in pairs(conf) do
            local ok, p = pcall(require, "nature.discovery." .. k)
            if ok then
                local init = p['init']
                _M[k] = p
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
    if not ngp.is_privileged_agent() then
        return
    end
    events.subscribe('upstream_meta', 'upstream_meta_change', build_upstream)
    ngx.timer.at(0, function()
        local upstream = config.get('upstream')
        if upstream then
            for key, value in pairs(upstream) do
                value.key = key
                local ok, err = pcall(build_upstream, value)
                if not ok then
                    log.error('build_upstream ', key, ' failed: ', err)
                end
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

function _M.after_balance(ctx)
    local up = ctx.picker
    up = up and up.after_balance or nil
    if up then
        up(ctx)
    end
end

return _M
