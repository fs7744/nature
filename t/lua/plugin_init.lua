local log = require("nature.core.log")

local _M = {}

function _M.rewrite(ctx)
    ctx.stop = true
end

function _M.init()
    _M.inited = true
end

function _M.destroy()
    log.error("destroy_", _M.inited)
end

return _M
