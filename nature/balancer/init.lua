local log                       = require("nature.core.log")
local exit                      = require("nature.core.response").exit
local balancer                  = require("ngx.balancer")
local pick_server               = require("nature.discovery").pick_server
local enable_keepalive          = require('nature.core.ngp').is_http_system() and balancer.enable_keepalive or nil -- need patch
local balancer_set_current_peer = balancer.set_current_peer
local set_more_tries            = balancer.set_more_tries
local set_timeouts              = balancer.set_timeouts
local global_timeout            = { connect = 60, send = 60, read = 60 }
local global_keepalive          = {
    pool_size = 6,
    timeout = 60,
    requests = 10000
}

local _M = {}

local function set_balancer_opts(conf)
    local timeout = conf.timeout
    if not timeout then
        timeout = global_timeout
    end
    if timeout then
        local ok, err =
        set_timeouts(timeout.connect, timeout.send, timeout.read)
        if not ok then
            log.error("could not set upstream timeouts: ", err)
        end
    end
    local retries = conf.retries
    if retries and retries > 0 then
        local ok, err = set_more_tries(retries)
        if not ok then
            log.error("could not set upstream retries: ", err)
        end
    end
end

local set_current_peer
do
    local keepalive_opt = {}
    function set_current_peer(server, router_conf)
        if enable_keepalive then
            local keepalive = router_conf.keepalive
            if not keepalive then
                keepalive = global_keepalive
            end
            keepalive_opt.pool = server.pool
            keepalive_opt.pool_size = keepalive.pool_size
            local ok, err = balancer_set_current_peer(server.host, server.port, keepalive_opt)
            if not ok then
                return ok, err
            end

            return enable_keepalive(keepalive.timeout, keepalive.requests)
        end

        return balancer_set_current_peer(server.host, server.port)
    end
end

function _M.prepare(ctx, matched_router)
    local server, err = pick_server(ctx)
    if not server then
        log.error("failed to pick server: ", err)
        return exit(404)
    end

    ctx.first_server = server
end

function _M.run(ctx)
    local server, matched_router, err
    server = ctx.first_server
    matched_router = ctx.matched_router
    if server then
        ctx.first_server = nil
        set_balancer_opts(matched_router)
    else
        -- report_failure(ctx)
        server, err = pick_server(ctx)
        if not server then
            log.error("failed to pick server: ", err)
            return exit(502)
        end
    end
    ctx.proxy_server = server
    local ok
    ok, err = set_current_peer(server, matched_router)
    if not ok then
        log.error("failed to set the current peer: ", err)
        return exit(502)
    end
end

return _M
