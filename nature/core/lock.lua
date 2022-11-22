local resty_lock = require("resty.lock")

local lock_shdict_name = "lrucache_lock"

local _M = {}

function _M.run(name, opts, func, ...)
    local lock, err = resty_lock:new(lock_shdict_name, opts)
    if not lock then
        return nil, err
    end
    local elapsed
    elapsed, err = lock:lock(name)
    if not elapsed then
        return nil, err
    end

    local r
    r, err = func(...)
    local ok, lock_err = lock:unlock()
    if not ok then
        return nil, lock_err
    end
    return r, err
end

return _M
