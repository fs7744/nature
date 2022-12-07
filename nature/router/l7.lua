local str_lower = require('nature.core.string').lower
local clear_table = require("nature.core.table").clear
local log = require("nature.core.log")

local _M = { current = {} }

function _M.init_router_metadata(r)
    return {
        paths = r.paths,
        hosts = r.host,
        remote_addrs = r.remote_addrs,
        methods = r.methods,
        priority = r.priority,
        metadata = r
    }
end

local router
local match_opts = {}
function _M.match_router(ctx)
    local r = router
    if r then
        clear_table(match_opts)
        match_opts.method = ctx.var.request_method
        match_opts.host = str_lower(ctx.var.host)
        match_opts.remote_addr = ctx.var.remote_addr
        local metadata, err = r:match(str_lower(ctx.var.uri), match_opts)
        if err then
            log.error(err)
        end
        return metadata
    end
end

function _M.set_router(r)
    router = r
end

function _M.get_router()
    return router
end

return _M
