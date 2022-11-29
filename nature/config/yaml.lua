local yaml = require("tinyyaml")
local lfs  = require("lfs")
local file = require("nature.core.file")

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

return _M
