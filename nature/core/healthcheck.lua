local events = require("nature.core.events")
local ngp = require("nature.core.ngp")
local log = require("nature.core.log")
local timers = require("nature.core.timers")
local config = require("nature.config.manager")
local lock = require("nature.core.lock")
local ngx_now = ngx.now
local shm_healthcheck
shm_healthcheck = ngx.shared[require('nature.core.ngp').sys_prefix() .. "healthcheck"]

local _M = {}

function _M.report_failure(id, pool, code)
    events.publish_all('healthcheck', 'node_status_change', { id = id, pool = pool, code = code })
end

function _M.get_status(id, pool)
    local status = shm_healthcheck:get(id .. '#' .. pool)
    return status == nil
end

local function node_status_changed(data)
    local upstreams = config.get('upstream')
    local key = data.id
    local up = upstreams[key]
    if not up or not up.healthcheck then
        return
    end
    local healthcheck = up.healthcheck
    local status = up.status
    if not status then
        status = {}
        up.status = status
    end
    local pool = data.pool
    local p = status[pool]
    if healthcheck.is_passive then
        if not healthcheck.unhealth_expire then
            healthcheck.unhealth_expire = 30
        end
        if not healthcheck.unhealth_failed then
            healthcheck.unhealth_failed = 3
        end
        if not p then
            p = { failed = 1, expire = ngx_now() + healthcheck.unhealth_expire }
            status[pool] = p
        elseif p.expire < ngx_now() then
            p.failed = 1
            p.expire = ngx_now() + healthcheck.unhealth_expire
        else
            p.failed = p.failed + 1
        end

        if p.failed >= healthcheck.unhealth_failed then
            log.warn(key, ' ', pool, ' unhealthy')
            shm_healthcheck:set(key .. '#' .. pool, 'unhealthy', healthcheck.unhealth_expire)
            p.expire = ngx_now() + healthcheck.unhealth_expire
        end
    end
end

local function node_status_change(data)
    local key = data.id .. '#' .. data.pool
    lock.run(key, nil, node_status_changed, data)
end

function _M.init_worker()
    if not ngp.is_privileged_agent() then
        return
    end
    events.subscribe('healthcheck', 'node_status_change', node_status_change)
    timers.register_timer('healthcheck', _M.check, true)
end

return _M
