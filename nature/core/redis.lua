local log = require('nature.core.log')
local rclib = require("resty.redis.connector")
local rediscluster = require("resty.rediscluster")
local rclib_new = rclib.new

local _M = {}

local function get_con(config)
    local rc, err = rclib_new(config)
    if err then
        return nil, nil, "redis config error"
    end
    local redis
    redis, err = rc:connect(config)
    if err then
        log.error("redis connect error: ", err)
        return nil, nil, err
    end
    return rc, redis
end

local function get_cluster_con(config)
    local rc, redis, err
    if config.serv_list then
        redis, err = rediscluster:new(config)
        if err then
            log.error("redis config error: ", err)
            return nil, nil, err
        end
        return rc, redis
    else
        return get_con(config)
    end
end

function _M.subscribe(config, key, func)
    local co = coroutine.create(function()
        local rc, red, err
        while true do
            if not red then
                rc, red, err = get_con(config)
                if red then
                    local ok
                    ok, err = red:subscribe(key)
                    if not ok then
                        red = nil
                    end
                end
            end
            if red then
                local res
                res, err = red:read_reply()
                if err then
                    if err ~= 'timeout' then
                        log.error(err)
                        red = nil
                    end
                else
                    local ok
                    ok, err = pcall(func, res)
                    if ok == false then
                        log.error(err)
                    end
                end
                if red then
                    rc:set_keepalive(red)
                end
            end
            if err then
                ngx.sleep(5)
            else
                ngx.sleep(0.01)
            end
        end
    end)
    coroutine.resume(co)
end

local function exec(config, func, ...)
    local rc, redis, err = get_cluster_con(config)
    if not redis then
        return nil, err
    end
    -- if rc then
    --     redis:set_timeout(config.redis_timeout or 50)
    -- end
    if err then
        log.error("redis error: ", err)
        return nil, err
    end
    local r
    if redis then
        r, err = func(redis, ...)
    end
    if rc then
        rc:set_keepalive(redis)
    end
    return r, err
end

_M.exec = exec

local function r_get(r, key)
    return r:get(key)
end

function _M.get(config, key)
    return exec(config, r_get, key)
end

local function r_set(r, key, value, ttl)
    local ok, err = r:set(key, value)
    if ttl and not err then
        ok, err = r:expire(key, ttl)
    end
    return ok, err
end

function _M.set(config, key, value, ttl)
    return exec(config, r_set, key, value, ttl)
end

local function r_expire(r, key, ttl)
    return r:expire(key, ttl)
end

function _M.expire(config, key, ttl)
    return exec(config, r_expire, key, ttl)
end

local function r_ttl(r, key)
    return r:ttl(key)
end

function _M.ttl(config, key)
    return exec(config, r_ttl, key)
end

local function r_publish(r, key, value)
    return r:publish(key, value)
end

function _M.publish(config, key, value)
    return exec(config, r_publish, key, value)
end

local function r_script(r, cmd, value)
    return r:script(cmd, value)
end

function _M.script(config, cmd, value)
    return exec(config, r_script, cmd, value)
end

local function r_evalsha(r, ...)
    return r:evalsha(...)
end

function _M.evalsha(config, ...)
    return exec(config, r_evalsha, ...)
end

return _M
