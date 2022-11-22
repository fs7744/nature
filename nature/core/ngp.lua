local process = require("ngx.process")
local signal = require('resty.signal')
local process_type = process.type

local _M = {}

function _M.reload()
    return signal.kill(process.get_master_pid(), signal.signum("HUP"))
end

function _M.quit()
    return signal.kill(process.get_master_pid(), signal.signum("QUIT"))
end

function _M.reopen_log()
    return signal.kill(process.get_master_pid(), signal.signum("USR1"))
end

function _M.is_privileged_agent()
    return process_type() == "privileged agent"
end

local function subsystem()
    return ngx.config.subsystem
end

_M.subsystem = subsystem

function _M.is_http_system()
    return subsystem() == 'http'
end

return _M
