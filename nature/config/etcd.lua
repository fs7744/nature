local ngp = require('nature.core.ngp')
local etcdlib = require("resty.etcd")

local _M = {}

local cache = {}

function _M.init(params)
    cache.params = params
    local etcd, err = etcdlib.new(params)
    if err ~= nil then
        return nil, err
    end
    return _M
end

function _M.init_worker()
    if not ngp.is_privileged_agent() then
        return
    end

    local co = coroutine.create(function()

    end)
    coroutine.resume(co)
end

function _M.get(key)
    return cache[key]
end

return _M
