local dns     = require("nature.core.dns")
local timers  = require("nature.core.timers")
local log     = require("nature.core.log")
local ngp     = require("nature.core.ngp")
local config  = require("nature.config.manager")
local events  = require("nature.core.events")
local ngx_now = ngx.now

local _M = {}

function _M.init()
    dns.init()
end

local function upstream_change(data)
    local expire = data._expire
    if expire and expire >= ngx_now() then
        return
    end

    data._expire = ngx_now() + (data.expire or 60)
    local nodes = {}
    for _, node in ipairs(data.nodes) do
        log.info('query dns: ', node.host)
        local ns, err = dns.parse_domain(node.host, dns.RETURN_ALL)
        if ns then
            for _, n in ipairs(ns) do
                table.insert(nodes,
                    { host = n.address, port = node.port, weight = node.weight, hostname = node.host,
                        pool = n.address .. ':' .. node.port .. '#' .. node.host })
            end
        else
            log.error('dns query failed: ', node.host, ' ', err)
        end
    end
    events.publish_all('upstream', 'upstream_change',
        { key = data.key, lb = data.lb, nodes = #nodes == 0 and nil or nodes })
end

function _M.check()
    local upstream = config.get('upstream')
    if upstream then
        for key, value in pairs(upstream) do
            if value.type == 'dns' then
                value.key = key
                upstream_change(value)
            end
        end
    end
end

function _M.init_worker()
    if not ngp.is_privileged_agent() then
        return
    end
    timers.register_timer('dns_upstream_check', _M.check, true)
    ngx.timer.at(0, function()
        _M.check()
    end)
end

return _M
