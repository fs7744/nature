local yaml   = require("tinyyaml")
local lfs    = require("lfs")
local file   = require("nature.core.file")
local log    = require("nature.core.log")
local ngp    = require("nature.core.ngp")
local timers = require("nature.core.timers")

local _M = {}

function _M.read_conf(conf_path)
    if not file.exists(conf_path) then
        return nil, 'not exists yaml: ' .. conf_path
    end
    local content, err = file.read_all(conf_path)
    if err then
        return nil, err
    end

    local conf = yaml.parse(content)
    if not conf then
        return nil, "invalid yaml: " .. conf_path
    end
    return conf, nil
end

local cache = {}
local yaml_change_time

local function load_file()
    local conf, err = _M.read_conf(cache.params.file)
    if err then
        return nil, err
    end
    cache.conf = conf
    if conf then
        cache.router = conf.router
        cache.plugins = conf.plugins
        cache.upstream = conf.upstream
        conf.router = nil
        conf.plugins = nil
        conf.upstream = nil
        conf.upstream = nil
        if conf.config and type(conf.config) == "table" then
            for key, value in pairs(conf.config) do
                cache[key] = value
            end
        end
        conf.config = nil
    end
end

function _M.init(params)
    cache.params = params
    local attributes, err = lfs.attributes(params.file)
    yaml_change_time = attributes.change

    load_file()
    return _M
end

local function watch_yaml()
    local attributes, err = lfs.attributes(cache.params.file)
    if not attributes then
        log.error("failed to fetch ", cache.params.file, " attributes: ", err)
        return
    end
    local last_change_time = attributes.change
    if yaml_change_time == last_change_time then
        return
    end
    yaml_change_time = last_change_time
    os.execute('sh ' ..
        cache.params.home .. '/nature.sh init -m yaml -f ' .. cache.params.file .. ' -c ' .. cache.params.conf)
    attributes, err = ngp.reload()
    if err then
        log.error(err)
    end
end

function _M.init_worker()
    timers.register_timer('watch_yaml', watch_yaml, true)
end

function _M.get(key)
    return cache[key]
end

return _M
