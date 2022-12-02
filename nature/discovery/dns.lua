local dns    = require("nature.core.dns")
local timers = require("nature.core.timers")
local log    = require("nature.core.log")
local lb     = require("nature.balancer.lb")

local _M = {}

function _M.init()
    dns.init()
end

function _M.init_worker()
    timers.register_timer('dns_upstream_check', dns.check, true)
end

function _M.upstream_change(data)
    local nodes = {}
    for _, node in ipairs(data.nodes) do
        local ns, err = dns.parse_domain(node.host, dns.RETURN_ALL)
        if ns then
            for _, n in ipairs(ns) do
                table.insert(nodes, { host = n.address, port = node.port, weight = node.weight, hostname = node.host })
            end
        else
            log.error('dns query failed: ', node.host, ' ', err)
        end
    end
    _M.upstreams[data.key] = lb.create(nodes, data.lb)
end

function _M.check()

end

return _M
