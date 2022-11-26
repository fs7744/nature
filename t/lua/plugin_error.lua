local log = require("nature.core.log")

local _M = {}

function _M.rewrite(ctx)
    ctx.stop = true
end

return _M
