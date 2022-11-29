local yaml = require("nature.config.yaml")

local _M = {}

function _M.read_conf(env, args)
    local conf, err = yaml.read_conf(args.file)

    return conf, err
end

return _M
