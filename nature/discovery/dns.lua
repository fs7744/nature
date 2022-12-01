local dns = require("nature.core.dns")
local timers = require("nature.core.timers")

local _M = {}

function _M.init()
    dns.init()
end

function _M.init_worker()
    timers.register_timer('dns_upstream_check', dns.check, true)
end

function _M.check()

end

return _M
