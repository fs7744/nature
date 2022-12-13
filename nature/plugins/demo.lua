local log = require "nature.core.log"
local _M = {}

local function init(name)
    return function(ctx, plugin_data, matched_router)
        log.info(name)
    end
end

_M.preread = init('preread')
_M.access = init('access')
_M.header_filter = init('header_filter')
_M.body_filter = init('body_filter')
_M.log = init('log')
_M.header_filter = init('header_filter')

return _M
