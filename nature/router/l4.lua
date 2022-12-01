local str_split = require('nature.core.string').split
local log = require("nature.core.log")

local _M = { current = {} }

function _M.init_router_metadata(r)
    local p = str_split(r.listen, ':')
    return {
        paths = p[2],
        metadata = r
    }
end

local router
local match_opts = {}
function _M.match_router(ctx)
    local r = router
    if r then
        local metadata, err = r:match(ctx.var.server_port, match_opts)
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
