local ngp = require('nature.core.ngp')
local etcdlib = require("resty.etcd")
local log = require("nature.core.log")
local events = require("nature.core.events")
local str = require("nature.core.string")
local json = require("nature.core.json")
local table = require("nature.core.table")
local str_split = str.split

local _M = {}

local cache = { etcd_version = 0 }
local etcd

local function publish_all(source, key, data)
    events.publish_all(source, key, data)
end

local function publish_local(source, key, data)
    events.publish_local(source, key, data)
end

local function init_prefix(params)
    _M['config'] = publish_all
    _M['router_l7'] = publish_all
    _M['upstream'] = publish_local
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
            local ks = str_split(kv.key, '/', nil, nil, 4)
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
    local s = cache[source]
    if not s then
        s = {}
        cache[source] = s
    end
    s[event] = data
end

local res_fn
local function watch_config()
    local res, err
    if res_fn == nil then
        local opts = {
            start_revision = cache.etcd_version + 1,
            timeout = cache.system.conf.init_params.timeout
        }
        res_fn, err = etcd:watchdir('', opts)
        if err then
            log.error('watch etcd failed: ', err)
            return
        end
    end

    while err == nil do
        res, err = res_fn()
        update_etcd_version(res)
        if not res or not res.result or not res.result.events then
            res, err = res_fn()
            if res and res.result and res.result.canceled then
                log.error('etcd compact revision ', res.result.compact_revision)
            end
        end
        if res and res.result and res.result.events then
            for _, event in ipairs(res.result.events) do
                if event.kv then
                    local ks = str_split(event.kv.key, '/', nil, nil, 4)
                    local source = ks[3]
                    local handler = _M[source]
                    if handler then
                        handler(source, ks[4], event.kv.type == 'DELETE' and nil or event.kv.value)
                    end
                end
            end
        end

    end
    res_fn = nil
    log.error('watch etcd failed: ', err)
end

function _M.init_worker()
    events.subscribe('config', '*', config_change)
    if not ngp.is_privileged_agent() then
        return
    end

    ngx.timer.at(0, function()
        local co = coroutine.create(function()
            local ok, err = pcall(watch_config)
            if err then
                log.error('watch etcd failed: ', err)
            end
            ngx.sleep(0.01)
        end)
        coroutine.resume(co)
    end)
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
