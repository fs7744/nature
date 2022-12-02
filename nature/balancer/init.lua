local log                       = require("nature.core.log")
local exit                      = require("nature.core.response").exit
local balancer                  = require("ngx.balancer")
local pick_server               = require("nature.discovery").pick_server
local enable_keepalive          = balancer.enable_keepalive and require('nature.core.ngp').is_http_system() -- need patch
local balancer_set_current_peer = balancer.set_current_peer

local _M = {}

function _M.prepare(ctx, matched_router)
    ctx.upstream_key = matched_router.upstream
    local server, err = pick_server(ctx)
    if not server then
        log.error("failed to pick server: ", err)
        return exit(404)
    end

    ctx.first_server = server
end

local global_keepalive = {
    pool_size = 6,
    timeout = 60,
    requests = 10000
}
local set_current_peer
do
    local keepalive_opt = {}
    function set_current_peer(server, router_conf)
        -- if enable_keepalive then
        --     local keepalive
        --     if router_conf and router_conf.balancer then
        --         keepalive = router_conf.balancer.keepalive
        --     end
        --     if not keepalive then
        --         keepalive = global_keepalive
        --     end
        --     keepalive_opt.pool = server.pool
        --     keepalive_opt.pool_size = keepalive.pool_size
        --     local ok, err = balancer.set_current_peer(server.host, server.port, keepalive_opt)
        --     if not ok then
        --         return ok, err
        --     end

        --     return balancer.enable_keepalive(keepalive.timeout, keepalive.requests)
        -- end

        return balancer_set_current_peer(server.host, server.port)
    end
end

function _M.run(ctx)
    local server, err
    server = ctx.first_server
    if server then
        ctx.first_server = nil
        --set_balancer_opts(ctx.router_conf)
    else
        -- report_failure(ctx, ctx.proxy_server)
        server, err = pick_server(ctx)
        if not server then
            log.error("failed to pick server: ", err)
            return exit(502)
        end
    end
    ctx.proxy_server = server
    local ok
    ok, err = set_current_peer(server)
    if not ok then
        log.error("failed to set the current peer: ", err)
        return exit(502)
    end
end

return _M
