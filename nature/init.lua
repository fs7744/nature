require("nature.core.patch")
local log                     = require("nature.core.log")
local json                    = require("nature.core.json")
local context                 = require("nature.core.context")
local balancer                = require("nature.balancer")
local plugin                  = require("nature.core.plugin")
local router                  = require("nature.router")
local l4                      = require("nature.router.l4")
local config                  = require("nature.config.manager")
local events                  = require("nature.core.events")
local discovery               = require("nature.discovery")
local after_balance           = discovery.after_balance
local get_api_context         = context.get_api_context
local new_api_context         = context.new_api_context
local clear_api_context       = context.clear_api_context
local exit                    = require("nature.core.response").exit
local balancer_prepare        = balancer.prepare
local balancer_run            = balancer.run
local plugin_run              = plugin.run
local plugin_run_without_stop = plugin.run_without_stop
local l4_match_router         = l4.match_router

local _M = { version = '0.1' }

function _M.init(params)
    local process = require("ngx.process")
    local ok, err = process.enable_privileged_agent()
    if not ok then
        log.error("failed to enable privileged_agent: ", err)
    end
    params = json.decode(params)
    ok, err = pcall(config.init, params)
    if not ok then
        log.error("failed to init config: ", err)
    end
    events.init()
    plugin.init()
    discovery.init()
    router.init()
end

function _M.init_worker()
    require("nature.core.timers").init_worker()
    config.init_worker()
    events.init_worker()
    discovery.init_worker()
end

function _M.stream_preread()
    local ctx = get_api_context()
    if not ctx then
        ctx = new_api_context()
    end
    local matched_router = ctx.matched_router
    if not matched_router then
        matched_router = l4_match_router(ctx)
        ctx.matched_router = matched_router
    end
    if matched_router then
        plugin_run("preread", ctx, matched_router)
        if not ctx.stop then
            balancer_prepare(ctx, matched_router)
        end
    else
        exit(404)
    end
end

function _M.balancer()
    balancer_run(get_api_context())
end

function _M.log()
    local ctx = get_api_context()
    if ctx then
        after_balance(ctx)
        plugin_run_without_stop("log", ctx)
        clear_api_context()
    end
end

return _M
