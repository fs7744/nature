local ffi_lru_new = require("resty.lrucache.pureffi").new
local lru_new = require("resty.lrucache").new
local ngx = ngx
local resty_lock = require("resty.lock")
local get_phase = ngx.get_phase

local function new_lru_fun(max, ttl, read, flags)
    local max_count = max or 100
    local _ttl = ttl or 60
    local lru_obj = read and ffi_lru_new(max_count, flags) or lru_new(max_count, flags)
    return function(key, create_func, ...)
        local v = lru_obj:get(key)
        if not v then
            v = create_func(...)
            if v ~= nil then
                lru_obj:set(key, v, _ttl, flags)
            end
        end
        return v
    end
end

local lock_shdict_name = require('nature.core.ngp').sys_prefix() .. "lrucache_lock"
local can_yield_phases = {
    ssl_session_fetch = true,
    ssl_session_store = true,
    rewrite = true,
    access = true,
    content = true,
    timer = true
}

local function new_lock_lru_fun(max, ttl, read, flags)
    local max_count = max or 100
    local _ttl = ttl or 60
    local lru_obj = read and ffi_lru_new(max_count, flags) or lru_new(max_count, flags)
    return function(key, create_func, ...)
        local v = lru_obj:get(key)
        if v then
            return v
        end

        if not can_yield_phases[get_phase()] then
            v = create_func(...)
            if v ~= nil then
                lru_obj:set(key, v, _ttl, flags)
            end
            return v
        end

        local lock, err = resty_lock:new(lock_shdict_name)
        if not lock then
            return nil, "failed to create lock: " .. err
        end

        local elapsed
        elapsed, err = lock:lock(key)
        if not elapsed then
            return nil, "failed to acquire the lock: " .. err
        end
        v = create_func(...)
        if v ~= nil then
            lru_obj:set(key, v, _ttl, flags)
        end
        lock:unlock()
        return v
    end
end

local _M = { new = new_lru_fun, new_with_lock = new_lock_lru_fun }

return _M
