local events = require("nature.core.events")
local ngp = require("nature.core.ngp")
local log = require("nature.core.log")
local timers = require("nature.core.timers")
local re_match = require("nature.core.string").re_match
local re_find = require("nature.core.string").re_find
local config = require("nature.config.manager")
local lock = require("nature.core.lock")
local ngx_now = ngx.now
local shm_healthcheck
shm_healthcheck = ngx.shared[require('nature.core.ngp').sys_prefix() .. "healthcheck"]

local _M = {}

local active_checks = {}

function _M.get_status(id, pool)
    local status = shm_healthcheck:get(id .. '#' .. pool)
    return status == nil
end

function _M.report_failure(id, pool)
    local unhealthy_count, err = shm_healthcheck:incr(id .. '#' .. pool .. '#count', 1, 5)
    if err then
        log.warn("failed to incr unhealthy_key: ", id, '#', pool, '#count',
            " err: ", err)
    end
    if unhealthy_count < 20 then
        events.publish_all('healthcheck', 'node_status_change', { id = id, pool = pool, status = 'unhealthy' })
    end
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
        if not healthcheck.unhealthy_expire then
            healthcheck.unhealthy_expire = 30
        end
        if not healthcheck.unhealthy_failed then
            healthcheck.unhealthy_failed = 3
        end
        if not p then
            p = { failed = 1, expire = ngx_now() + healthcheck.unhealthy_expire }
            status[pool] = p
        elseif p.expire < ngx_now() then
            p.failed = 1
            p.expire = ngx_now() + healthcheck.unhealthy_expire
        else
            p.failed = p.failed + 1
        end

        if p.failed >= healthcheck.unhealthy_failed then
            log.warn(key, ' ', pool, ' unhealthy')
            shm_healthcheck:set(key .. '#' .. pool, 'unhealthy', healthcheck.unhealthy_expire)
            p.expire = ngx_now() + healthcheck.unhealthy_expire
        end
    end
end

local function report_failure(key, node, unhealthy_failed, expire)
    if not node._unhealthy_expire then
        node._unhealthy_expire = ngx_now() + expire
    end
    if node._unhealthy_expire < ngx_now() then
        node._failed = 1
        node._unhealthy_expire = ngx_now() + expire
    else
        node._failed = (node._failed or 0) + 1
    end
    log.debug(key, ' ', node.pool, ' unhealthy (', node._failed, '/', unhealthy_failed, ')')
    if node._failed >= unhealthy_failed then
        log.warn(key, ' ', node.pool, ' unhealthy')
        shm_healthcheck:set(key .. '#' .. node.pool, 'unhealthy', 0)
    end
end

local function report_success(key, node, healthy_success, expire)
    if not node._healthy_expire then
        node._healthy_expire = ngx_now() + expire
    end
    if node._healthy_expire < ngx_now() then
        node._success = 1
        node._healthy_expire = ngx_now() + expire
    else
        node._success = (node._success or 0) + 1
    end
    log.debug(key, ' ', node.pool, ' healthy (', node._success, '/', healthy_success, ')')
    if node._success >= healthy_success then
        log.warn(key, ' ', node.pool, ' healthy')
        shm_healthcheck:delete(key .. '#' .. node.pool)
    end
end

local function do_active_check(key, healthcheck, node)
    if not healthcheck.period then
        healthcheck.period = 5
    end
    if not healthcheck.timeout then
        healthcheck.timeout = 1
    end
    if not healthcheck.unhealthy_failed then
        healthcheck.unhealthy_failed = 3
    end
    if not healthcheck.healthy_success then
        healthcheck.healthy_success = 3
    end
    if not healthcheck.unhealthy_expire then
        healthcheck.unhealthy_expire = 30
    end
    if not healthcheck.healthy_expire then
        healthcheck.healthy_expire = 30
    end
    if not healthcheck.unhealthy_http_status then
        healthcheck.unhealthy_http_status = { 429, 404,
            500, 501, 502, 503, 504, 505 }
    end
    if not healthcheck.healthy_http_status then
        healthcheck.healthy_http_status = { 200, 302 }
    end
    local expire = node._active_expire
    if expire and expire >= ngx_now() then
        return
    end
    node._active_expire = ngx_now() + healthcheck.period

    local sock, err = ngx.socket.tcp()
    if not sock then
        log.error("failed to create stream socket: ", err)
        return
    end

    sock:settimeout(healthcheck.timeout * 1000)
    local ok
    ok, err = sock:connect(node.host, node.port)
    if not ok then
        if err == "timeout" then
            sock:close() -- timeout errors do not close the socket.
        end
        return report_failure(key, node, healthcheck.unhealthy_failed, healthcheck.unhealthy_expire)
    end

    if healthcheck.type == "tcp" then
        sock:close()
        return report_success(key, node, healthcheck.healthy_success, healthcheck.healthy_expire)
    end

    if healthcheck.type == "https" then
        local session
        if healthcheck.ssl_cert and healthcheck.ssl_key then
            session, err = sock:tlshandshake({
                verify = healthcheck.https_verify_certificate,
                client_cert = healthcheck.ssl_cert,
                client_priv_key = healthcheck.ssl_key
            })
        else
            session, err = sock:sslhandshake(nil, node.hostname,
                healthcheck.https_verify_certificate)
        end
        if not session then
            sock:close()
            log.error("failed SSL handshake with '", node.hostname, " (", node.host, ":", node.port, ")': ", err)
            return report_failure(key, node, healthcheck.unhealthy_failed, healthcheck.unhealthy_expire)
        end
    end

    if healthcheck._no_host == nil then
        healthcheck._no_host = true
        if healthcheck.header then
            local h, err = re_match(healthcheck.header, 'host:', 'sijo')
            if h then
                healthcheck._no_host = false
            end
        end
    end
    local host = ''
    if healthcheck._no_host == true then
        host = "Host: " .. (node.hostname or node.host) .. "\r\n"
    end
    local request = "GET " .. (healthcheck.path or '/') .. " HTTP/1.0\r\n" .. host ..
        (healthcheck.header or '') .. "\r\n"
    log.debug("request head: ", request)
    local bytes
    bytes, err = sock:send(request)
    if not bytes then
        log.error("failed to send http request to '", node.hostname, " (", node.host, ":", node.port ")': ", err)
        if err == "timeout" then
            sock:close() -- timeout errors do not close the socket.
        end
        return report_failure(key, node, healthcheck.unhealthy_failed, healthcheck.unhealthy_expire)
    end

    local status_line
    status_line, err = sock:receive()
    if not status_line then
        log.error("failed to receive status line from '", node.hostname, " (", node.host, ":", node.port ")': ", err)
        if err == "timeout" then
            sock:close() -- timeout errors do not close the socket.
        end
        return report_failure(key, node, healthcheck.unhealthy_failed, healthcheck.unhealthy_expire)
    end

    local from, to = re_find(status_line,
        [[^HTTP/\d+\.\d+\s+(\d+)]],
        "joi", nil, 1)
    local status
    if from then
        status = tonumber(status_line:sub(from, to))
    else
        log.error("bad status line from '", node.hostname, " (", node.host, ":", node.port, ")': ", status_line)
        -- note: 'status' will be reported as 'nil'
    end
    local match_string = healthcheck.match_body
    if match_string and match_string ~= "" then
        local data, err = sock:receive('*a')
        if err then
            log.error("failed to parse body: ", err)
        end
        local m, err = re_match(data, match_string, "jo")
        if not m then
            status = 504
        end
    end
    sock:close()

    log.debug("Reporting '", node.hostname, " (", node.host, ":", node.port, ")' (got HTTP ", status, ")")

    if healthcheck.unhealthy_http_status[status] then
        return report_failure(key, node, healthcheck.unhealthy_failed, healthcheck.unhealthy_expire)
    elseif healthcheck.healthy_http_status[status] then
        return report_success(key, node, healthcheck.healthy_success, healthcheck.healthy_expire)
    end
end

function _M.active_check()
    local upstreams = config.get('upstream')
    for key, value in pairs(active_checks) do
        local up = upstreams[key]
        if up and up.healthcheck and up.healthcheck.is_passive == false then
            for index, node in ipairs(value) do
                local ok, err = pcall(do_active_check, key, up.healthcheck, node)
                if not ok then
                    log.error('do do_active_check failed : ', key, ' ', err)
                end
            end
        end
    end
end

function _M.add_active_target(key, nodes)
    active_checks[key] = nodes
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
    local opts = { each_ttl = 0, sleep_succ = 0.01, check_interval = 1 }
    local _, err = timers.new("healthcheck_active_check", _M.active_check, opts)
    if err then
        log.error("healthcheck_active_check err: ", err)
    end
end

return _M
