if require("nature.core.os").os_name == "Linux" then
    require("ngx.re").opt("jit_stack_size", 200 * 1024)
end
require("jit.opt").start("minstitch=2", "maxtrace=4000", "maxrecord=8000",
    "sizemcode=64", "maxmcode=4000", "maxirconst=1000")

local get_phase = ngx.get_phase
local ngx_socket = ngx.socket
local original_tcp = ngx.socket.tcp
local socket = require("socket")
local unix_socket = require("socket.unix")
local new_tab = require("table.new")
local concat_tab = table.concat

local function flatten(args)
    local buf = new_tab(#args, 0)
    for i, v in ipairs(args) do
        local ty = type(v)
        if ty == "table" then
            buf[i] = flatten(v)
        elseif ty == "boolean" then
            buf[i] = v and "true" or "false"
        elseif ty == "nil" then
            buf[i] = "nil"
        else
            buf[i] = v
        end
    end
    return concat_tab(buf)
end

local luasocket_wrapper = {
    connect = function(self, host, port)
        if not port then
            -- unix socket
            self.sock = unix_socket()
            if self.timeout then
                self.sock:settimeout(self.timeout)
            end

            local path = host:sub(#("unix:") + 1)
            return self.sock:connect(path)
        end

        if host:byte(1) == string.byte('[') then
            -- ipv6, form as '[::1]', remove '[' and ']'
            host = host:sub(2, -2)
            self.sock = self.tcp6
        else
            self.sock = self.tcp4
        end

        return self.sock:connect(host, port)
    end,

    send = function(self, ...)
        if select('#', ...) == 1 and type(select(1, ...)) == "string" then
            -- fast path
            return self.sock:send(...)
        end

        -- luasocket's send only accepts a single string
        return self.sock:send(flatten({ ... }))
    end,

    getreusedtimes = function()
        return 0
    end,
    setkeepalive = function(self)
        self.sock:close()
        return 1
    end,

    settimeout = function(self, time)
        if time then
            time = time / 1000
        end

        self.timeout = time

        return self.sock:settimeout(time)
    end,
    settimeouts = function(self, connect_time, read_time, write_time)
        connect_time = connect_time or 0
        read_time = read_time or 0
        write_time = write_time or 0

        -- set the max one as the timeout
        local time = connect_time
        if time < read_time then
            time = read_time
        end
        if time < write_time then
            time = write_time
        end

        if time > 0 then
            time = time / 1000
        else
            time = nil
        end

        self.timeout = time

        return self.sock:settimeout(time)
    end,

    sslhandshake = function(self, reused_session, server_name, verify, send_status_req)
        return self:tlshandshake({
            reused_session = reused_session,
            server_name = server_name,
            verify = verify,
            ocsp_status_req = send_status_req,
        })
    end
}


local mt = {
    __index = function(self, key)
        local sock = self.sock
        local fn = luasocket_wrapper[key]
        if fn then
            self[key] = fn
            return fn
        end

        local origin = sock[key]
        if type(origin) ~= "function" then
            return origin
        end

        fn = function(_, ...)
            return origin(sock, ...)
        end

        self[key] = fn
        return fn
    end
}

local function luasocket_tcp()
    local sock = socket.tcp()
    local tcp4 = socket.tcp4()
    local tcp6 = socket.tcp6()
    return setmetatable({ sock = sock, tcp4 = tcp4, tcp6 = tcp6 }, mt)
end

local http = require('resty.http')
local http_mt = { __index = http }
http.new = function(_)
    local phase = get_phase()
    local sock, err
    if phase ~= "init" then
        sock, err = original_tcp()
    else
        sock, err = luasocket_tcp()
    end
    if not sock then
        return nil, err
    end
    return setmetatable({ sock = sock, keepalive = true }, http_mt)
end
