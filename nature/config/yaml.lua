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

local cache
local yaml_change_time

local function load_file(params)
    local conf, err = _M.read_conf(params.file)
    if err then
        return nil, err
    end
    cache = conf or {}
    cache.init_params = params
end

function _M.init(params)
    local attributes, err = lfs.attributes(params.file)
    yaml_change_time = attributes.change

    load_file(params)
    return _M
end

local function watch_yaml()
    local params = cache.init_params
    local file = params.file
    local attributes, err = lfs.attributes(file)
    if not attributes then
        log.error("failed to fetch ", file, " attributes: ", err)
        return
    end
    local last_change_time = attributes.change
    if yaml_change_time == last_change_time then
        return
    end
    yaml_change_time = last_change_time
    os.execute('sh ' .. params.home .. '/nature.sh init -m yaml -f ' .. file .. ' -c ' .. params.conf)
    attributes, err = ngp.reload()
    if err then
        log.error(err)
    end
end

function _M.init_worker()
    timers.register_timer('watch_yaml', watch_yaml, true)
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
