local get_var = require("resty.ngxvar").fetch
local get_request = require("resty.ngxvar").request
local cookie = require("resty.cookie")
local str = require("nature.core.string")
local log = require("nature.core.log")
local table_clear = require("nature.core.table").clear
local table_pool_fetch = require("nature.core.table").pool_fetch
local table_pool_release = require("nature.core.table").pool_release
local ctxdump = require("resty.ctxdump")
local get_env = require("nature.core.os").get_env
local ngx = ngx
local ngx_var = ngx.var
local lower = string.lower
local has_prefix = str.has_prefix
local re_gsub = str.re_gsub
local str_sub = str.sub
local request_get_uri_args = require("nature.core.request").get_uri_args

local _M = {}

local ngx_var_names = {
    upstream_scheme     = true,
    upstream_host       = true,
    upstream_upgrade    = true,
    upstream_connection = true,
    upstream_uri        = true,

    upstream_mirror_host = true,

    upstream_cache_zone      = true,
    upstream_cache_zone_info = true,
    upstream_no_cache        = true,
    upstream_cache_key       = true,
    upstream_cache_bypass    = true,

    proxy_host   = true,
    proxy_server = true,
}

do
    local var_methods = {
        method = ngx.req.get_method,
        cookie = function()
            if ngx.var.http_cookie then
                return cookie:new()
            end
        end
    }

    local no_cacheable_var_methods = {
        args = request_get_uri_args
    }

    local mt = {
        __index = function(t, key)
            local cached = t._cache[key]
            if cached ~= nil then
                return cached
            end

            local val
            local method = var_methods[key]
            if method then
                val = method()
            else
                method = no_cacheable_var_methods[key]
                if method then
                    return method()
                elseif has_prefix(key, "http_") then
                    local k = lower(key)
                    k = re_gsub(k, "-", "_", "jo")
                    val = get_var(k, t._request)
                elseif has_prefix(key, "cookie_") then
                    local ck = t.cookie
                    if ck then
                        local err
                        val, err = ck:get(str_sub(key, 8))
                        if err then
                            log.warn("failed to fetch cookie value by key: ", key,
                                " error: ", err)
                        end
                    end
                elseif has_prefix(key, "arg_") then
                    local arg_key = str_sub(key, 5)
                    method = function()
                        local args = request_get_uri_args(ngx.ctx.api_ctx)[arg_key]
                        local v
                        if args then
                            if type(args) == "table" then
                                v = args[1]
                            else
                                v = args
                            end
                        end
                        return v
                    end
                    no_cacheable_var_methods[key] = method
                    return method()
                elseif has_prefix(key, "env_") then
                    local k = re_gsub(key, "env_", "", "jo")
                    method = function()
                        return get_env(k)
                    end
                    no_cacheable_var_methods[key] = method
                    return method()
                elseif has_prefix(key, "ctx_") then
                    local k = re_gsub(key, "ctx_", "", "jo")
                    method = function()
                        return ngx.ctx.api_ctx[k]
                    end
                    no_cacheable_var_methods[key] = method
                    return method()
                else
                    val = get_var(key, t._request)
                end
            end

            if val ~= nil then
                t._cache[key] = val
            end

            return val
        end,
        __newindex = function(t, key, val)
            t._cache[key] = val
            if ngx_var_names[key] then
                ngx_var[key] = val
            end
        end
    }

    function _M.set_vars_meta(ctx)
        local var = table_pool_fetch("ctx_var", 0, 32)
        if not var._cache then
            var._cache = {}
        end
        var._request = get_request()
        setmetatable(var, mt)
        ctx.var = var
    end

    function _M.release_vars(ctx)
        if ctx.var == nil then
            return
        end

        table_clear(ctx.var._cache)
        table_pool_release("ctx_var", ctx.var, true)
        ctx.var = nil
    end

end

function _M.new_api_context()
    local api_ctx = table_pool_fetch("api_ctx", 0, 32)
    ngx.ctx.api_ctx = api_ctx
    _M.set_vars_meta(api_ctx)
    return api_ctx
end

function _M.get_api_context()
    local ngx_ctx = ngx.ctx
    if ngx_ctx then
        return ngx_ctx.api_ctx
    else
        return nil
    end
end

function _M.clear_api_context()
    local ngx_ctx = ngx.ctx
    local api_ctx = ngx_ctx.api_ctx
    if api_ctx then
        _M.release_vars(api_ctx)
        table_pool_release("api_ctx", api_ctx)
        ngx_ctx.api_ctx = nil
    end
end

function _M.stash()
    local ref = ctxdump.stash_ngx_ctx()
    log.info("stash ngx ctx: ", ref)
    ngx_var.ctx_ref = ref
end

function _M.apply_ctx()
    local ref = ngx_var.ctx_ref
    log.info("apply ngx ctx: ", ref)
    local ctx = ctxdump.apply_ngx_ctx(ref)
    ngx_var.ctx_ref = ''
    ngx.ctx = ctx
    return ctx
end

function _M.register_var_name(key)
    ngx_var_names[key] = true
end

return _M
