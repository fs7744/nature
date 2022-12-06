local log = require("nature.core.log")
local table = require("nature.core.table")
local table_pool_fetch = table.pool_fetch
local table_insert = table.insert
local table_remove = table.remove
local table_pool_release = table.pool_release
local ngx_now = ngx.now
local math_max = math.max
local math_exp = math.exp
local math_random = math.random
local decay_time = 10
local shm_ewma = ngx.shared[require('nature.core.ngp').sys_prefix() .. "balancer-ewma"]
local shm_last_touched_at = ngx.shared[require('nature.core.ngp').sys_prefix() .. "balancer-ewma-last-touched-at"]

local function decay_ewma(ewma, last_touched_at, rtt, now)
    local td = now - last_touched_at
    td = math_max(td, 0)
    local weight = math_exp(-td / decay_time)

    ewma = ewma * weight + rtt * (1.0 - weight)
    return ewma
end

local function get_ewma(server, rtt)
    local ewma = shm_ewma:get(server) or 0
    local now = ngx_now()
    local last_touched_at = shm_last_touched_at:get(server) or 0
    return decay_ewma(ewma, last_touched_at, rtt, now)
end

local function p2c(nodes, ctx)
    local remaining_nodes = ctx._remaining_nodes
    if not remaining_nodes then
        remaining_nodes = table_pool_fetch("remaining_nodes", 0, 2)
        for _, v in ipairs(nodes) do
            table_insert(remaining_nodes, v)
        end
        ctx._remaining_nodes = remaining_nodes
    end
    local count = #remaining_nodes
    local node_i
    if count > 1 then
        local node_j
        local i, j = math_random(1, count), math_random(1, count - 1)
        if j >= i then
            j = j + 1
        end

        node_i, node_j = remaining_nodes[i], remaining_nodes[j]
        if get_ewma(node_i.pool, 0) > get_ewma(node_j.pool, 0) then
            node_i = node_j
            i = j
        end
        table_remove(remaining_nodes, i)
    elseif count == 1 then
        node_i = table_remove(remaining_nodes, 1)
    end

    return node_i
end

local function update_ewma(server, rtt)
    local now = ngx_now()
    local ewma = get_ewma(server, rtt)
    local success, err, forcible = shm_last_touched_at:set(server, now)
    if not success then
        log.error("shm_last_touched_at:set failed: ", err)
    end
    if forcible then
        log.warn("shm_last_touched_at:set valid items forcibly overwritten")
    end

    success, err, forcible = shm_ewma:set(server, ewma)
    if not success then
        log.error("shm_ewma:set failed: ", err)
    end
    if forcible then
        log.warn("shm_ewma:set valid items forcibly overwritten")
    end
end

local function after_balance(ctx)
    local remaining_nodes = ctx._remaining_nodes
    if remaining_nodes then
        ctx._remaining_nodes = nil
        table_pool_release("remaining_nodes", remaining_nodes)
    end
    local proxy_server = ctx.proxy_server
    if proxy_server then
        local rtt = ctx.var.upstream_response_time or 0
        local s = proxy_server.pool
        local ok, err = update_ewma(s, rtt)
        if err then
            log.error('update_ewma ', s, ' failed: ', err)
        end
    end
end

return function(nodes)
    return {
        after_balance = after_balance,
        pick = function(ctx)
            return p2c(nodes, ctx)
        end
    }
end
