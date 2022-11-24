local lfs = require('lfs')
local log = require('nature.core.log')
local file = require('nature.core.file')
local ngx = ngx
local get_headers = ngx.req.get_headers
local set_header = ngx.req.set_header
local req_read_body = ngx.req.read_body
local req_get_body_data = ngx.req.get_body_data
local req_get_body_file = ngx.req.get_body_file
local get_uri_args = ngx.req.get_uri_args
local set_uri_args = ngx.req.set_uri_args
local http_version = ngx.req.http_version
local clear_header = ngx.req.clear_header

local _M = {}

local function l_get_headers(ctx)
    local headers = ctx.headers
    if not headers then
        headers = get_headers(0)
        ctx.headers = headers
    end

    return headers
end

_M.headers = l_get_headers

function _M.get_header(ctx, name)
    return l_get_headers(ctx)[name]
end

function _M.set_header(ctx, name, value)
    if ctx.headers then
        ctx.headers[name] = value
    end

    set_header(name, value)
end

function _M.get_uri_args(ctx)
    if not ctx.req_uri_args then
        -- use 0 to avoid truncated result and keep the behavior as the
        local args = get_uri_args(0)
        ctx.req_uri_args = args
    end

    return ctx.req_uri_args
end

function _M.set_uri_args(ctx, args)
    ctx.req_uri_args = nil
    return set_uri_args(args)
end

function _M.get_host(ctx)
    return ctx.var.host or ''
end

function _M.get_http_version()
    return http_version()
end

function _M.set_var(ctx, k, v)
    ctx.var[k] = v
end

local function check_size(size, max_size)
    if max_size and size > max_size then
        return nil,
            "request size " .. size .. " is greater than the " ..
            "maximum size " .. max_size .. " allowed"
    end

    return true
end

function _M.get_body(ctx, max_size)
    local content_length = tonumber(ctx.var.http_content_length)
    if content_length then
        local ok, err = check_size(content_length, max_size)
        if not ok then
            -- When client_max_body_size is exceeded, Nginx will set r->expect_tested = 1 to
            -- avoid sending the 100 CONTINUE.
            -- We use trick below to imitate this behavior.
            local expect = ctx.var.http_expect
            if expect and string.lower(expect) == "100-continue" then
                clear_header("expect")
            end

            return nil, err
        end
    end

    req_read_body()

    local req_body = req_get_body_data()
    if req_body then
        local ok, err = check_size(#req_body, max_size)
        if not ok then
            return nil, err
        end

        return req_body
    end

    local file_name = req_get_body_file()
    if not file_name then
        return nil
    end
    log.info("Read req body file: ", file_name)
    if max_size then
        local size, err = lfs.attributes(file_name, "size")
        if not size then
            return nil, err
        end

        local ok, err = check_size(size, max_size)
        if not ok then
            return nil, err
        end
    end

    local req_body, err = file.read_all(file_name)
    return req_body, err
end

return _M
