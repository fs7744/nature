local _M = {}

_M.os_name = require("ffi").os

_M.set_env = require("resty.env").set
_M.get_env = require("resty.env").get

return _M
