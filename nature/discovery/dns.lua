local dns     = require("nature.core.dns")
local timers  = require("nature.core.timers")
local log     = require("nature.core.log")
local ngp     = require("nature.core.ngp")
local config  = require("nature.config.manager")
local events  = require("nature.core.events")
local utils   = require("nature.core.utils")
local ngx_now = ngx.now

local _M = {}

function _M.init()
    dns.init()
end

local function get(node, nodes)
    log.info('query dns: ', node.host)
    local ns, err = dns.parse_domain(node.host, dns.RETURN_ALL)
    if err then
        log.error('dns query failed: ', node.host, ' ', err)
    elseif ns then
        for _, n in ipairs(ns) do
            table.insert(nodes, { host = n.address, port = node.port, weight = node.weight, hostname = node.host })
        end
    end
end

_M.get = get

local function compare_nodes(value)
    local expire = value._expire
    if expire and expire >= ngx_now() then
        return
    end

    value._expire = ngx_now() + (value.dns_expire or 60)
    log.info('upstream_meta dns compare_nodes: ', value.key)
    local old_dns = value.old_dns
    local new_dns = {}
    for _, node in ipairs(value.nodes) do
        if node.discovery == 'dns' then
            get(node, new_dns)
        end
    end
    if old_dns then
        if not utils.compare_node(old_dns, new_dns) then
            events.publish_local('upstream_meta', 'upstream_meta_change', value)
        end
    else

        value.old_dns = new_dns
    end

end

function _M.check()
    local upstream = config.get('upstream')
    if upstream then
        for key, value in pairs(upstream) do
            value.key = key
            local ok, err = pcall(compare_nodes, value)
            if not ok then
                log.error('dns compare upstream ', key, ' failed: ', err)
            end
        end
    end
end

function _M.init_worker()
    if not ngp.is_privileged_agent() then
        return
    end
    timers.register_timer('dns_upstream_check', _M.check, true)
end

return _M
