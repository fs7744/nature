local ngp = require('nature.core.ngp')
local etcdlib = require("resty.etcd")
local log = require("nature.core.log")
local events = require("nature.core.events")
local str = require("nature.core.string")
local json = require("nature.core.json")
local table = require("nature.core.table")
local re_gsub = str.re_gsub

local _M = {}

local cache = { etcd_version = 0 }
local etcd

local function init_prefix(params)
    _M['config'] = function(key, data)
        events.publish_all(key, 'config_change', data)
    end
    _M['router_l7'] = function(key, data)
        events.publish_all(key, 'router_l7_change', data)
    end
    _M['upstream'] = function(key, data)
        events.publish_all(key, 'upstream_change', data)
    end
    _M['system'] = function(key, data)
        -- restart
    end
    _M['router_l4'] = function(key, data)
        -- restart
    end
end

local function update_etcd_version(res)
    if res then
        if res.result and res.result.header and res.result.header.revision then
            local new_etcd_version = tonumber(res.result.header.revision)
            if new_etcd_version > cache.etcd_version then
                cache.etcd_version = new_etcd_version
                log.notice('fetch etcd config data success with update etcd version: ', new_etcd_version)
            end

        end
    end
end

local function update_etcd_version_body(res)
    if res then
        if res.body and res.body.header and res.body.header.revision then
            cache.etcd_version = tonumber(res.body.header.revision)
        end
    end
end

function _M.get_all_config()
    local res, err = etcd:readdir('')
    if err ~= nil then
        return nil, err
    end
    update_etcd_version_body(res)
    log.info("get etcd all config data with version: ", cache.etcd_version)
    if res.body.kvs then
        for _, kv in ipairs(res.body.kvs) do
            local ks = str.split(kv.key, '/', nil, nil, 4)
            local s = cache[ks[3]]
            if not s then
                s = {}
                cache[ks[3]] = s
            end
            s[ks[4]] = kv.value
        end
    end
end

function _M.init(params)
    init_prefix(params)
    local err
    etcd, err = etcdlib.new(table.deepcopy(params))
    if err ~= nil then
        log.error(err)
        return nil, err
    end
    _M.get_all_config()
    if cache.system and cache.system.conf then
        cache.system.conf.init_params = params
    end
    return _M
end

local function config_change(data, event, source)
    cache[source] = data
end

function _M.init_worker()
    events.subscribe('*', 'config_change', config_change)
    if not ngp.is_privileged_agent() then
        return
    end

    -- local co = coroutine.create(function()

    -- end)
    -- coroutine.resume(co)
end

function _M.get(key, subkey)
    local r = cache[key]
    if subkey ~= nil and r ~= nil then
        return r[subkey]
    else
        return r
    end
end

return _M
