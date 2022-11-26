local _M = {}

_M.os_name = require("ffi").os

_M.set_env = require("resty.env").set
_M.get_env = require("resty.env").get

function _M.exec_cmd(cmd)
    local ngx_pipe = require "ngx.pipe"
    local proc, err = ngx_pipe.spawn(cmd, { merge_stderr = true })
    if not proc then
        return true, err
    end
    return proc:stdout_read_any(3800)
end

return _M
