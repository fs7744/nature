if require("nature.core.os").os_name == "Linux" then
    require("ngx.re").opt("jit_stack_size", 200 * 1024)
end
require("jit.opt").start("minstitch=2", "maxtrace=4000", "maxrecord=8000",
    "sizemcode=64", "maxmcode=4000", "maxirconst=1000")
local ngx = ngx
local ngx_socket = ngx.socket
local original_tcp = ngx.socket.tcp
local original_udp = ngx.socket.udp
local str_has_prefix = require("nature.core.string").has_prefix
local parse_ipv4 = require("nature.core.ip").parse_ipv4
local parse_ipv6 = require("nature.core.ip").parse_ipv6
local parse_domain = require("nature.core.dns").parse_domain

local _M = {}

local patch_tcp_socket
do
    local old_tcp_sock_connect

    local function new_tcp_sock_connect(sock, host, port, opts)

        if host then
            if str_has_prefix(host, "unix:") then
                if not opts then
                    -- workaround for https://github.com/openresty/lua-nginx-module/issues/860
                    return old_tcp_sock_connect(sock, host)
                end

            elseif not parse_ipv4(host) and not parse_ipv6(host) then
                local err
                host, err = parse_domain(host)
                if not host then
                    return nil, "failed to parse domain: " .. err
                end
            end
        end

        return old_tcp_sock_connect(sock, host, port, opts)
    end

    function patch_tcp_socket(sock)
        if not old_tcp_sock_connect then
            old_tcp_sock_connect = sock.connect
        end

        sock.connect = new_tcp_sock_connect
        return sock
    end
end

local patch_udp_socket
do
    local old_udp_sock_setpeername

    local function new_udp_sock_setpeername(sock, host, port)
        if host then
            if str_has_prefix(host, "unix:") then
                return old_udp_sock_setpeername(sock, host)
            end

            if not parse_ipv4(host) and not parse_ipv6(host) then
                local err
                host, err = parse_domain(host)
                if not host then
                    return nil, "failed to parse domain: " .. err
                end
            end
        end

        return old_udp_sock_setpeername(sock, host, port)
    end

    function patch_udp_socket(sock)
        if not old_udp_sock_setpeername then
            old_udp_sock_setpeername = sock.setpeername
        end

        sock.setpeername = new_udp_sock_setpeername
        return sock
    end
end

function _M.patch()
    ngx_socket.tcp = function()
        return patch_tcp_socket(original_tcp())
        -- local phase = get_phase()
        -- if phase ~= "init" and phase ~= "init_worker" then
        --     return patch_tcp_socket(original_tcp())
        -- end

        -- return original_tcp()
    end

    ngx_socket.udp = function()
        return patch_udp_socket(original_udp())
    end
end

return _M
