local log = require("nature.core.log")
local exit = require("nature.core.response").exit

local _M = {}

function _M.prepare(ctx)
    local server, err
    local up_key = ctx.upstream_key
    if not up_key then
        err = 'no upstream'
    end

    if not server then
        log.error("failed to pick server: ", err)
        return exit(404)
    end
    ctx.picked_server = server

end

function _M.run(ctx)

end

return _M
