local ipmatcher = require("resty.ipmatcher")

local _M = {
    parse_ipv4 = ipmatcher.parse_ipv4,
    parse_ipv6 = ipmatcher.parse_ipv6
}

return _M
