local ngp = require('nature.core.ngp')
local etcdlib = require("resty.etcd")
local log = require("nature.core.log")
local events = require("nature.core.events")
local str = require("nature.core.string")
local json = require("nature.core.json")
local re_gsub = str.re_gsub

local _M = {}

local cache = { etcd_version = 0, router = { l7 = {}, l4 = {} } }
local etcd
local plugins_prefix
local router_prefix
local upstream_prefix
local config_prefix

local function init_prefix(params)
    local key_prefix = params.key_prefix
    plugins_prefix = key_prefix .. '_plugins'
    router_prefix = key_prefix .. '_router'
    upstream_prefix = key_prefix .. '_upstream'
    config_prefix = key_prefix .. '_config'
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
    log.info("get etcd all config data.")
    update_etcd_version_body(res)
    if res.body.kvs then
        --log.error(json.delay_encode(res.body.kvs))
        for _, kv in ipairs(res.body.kvs) do
            local ks = str.split(kv.key, '/', nil, nil, 3)
            log.error(json.delay_encode(ks))
            --cache[re_gsub(kv.key, key_prefix, '', 'jo')] = kv.value

        end
    end

end

function _M.init(params)
    cache.params = params
    init_prefix(params)
    local err
    etcd, err = etcdlib.new(params)
    if err ~= nil then
        log.error(err)
        return nil, err
    end
    _M.get_all_config()
    return _M
end

function _M.init_worker()
    if not ngp.is_privileged_agent() then
        return
    end

    -- local co = coroutine.create(function()

    -- end)
    -- coroutine.resume(co)
end

function _M.get(key)
    return cache[key]
end

return _M
