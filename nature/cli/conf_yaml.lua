local yaml = require("nature.config.yaml")
local json = require("nature.core.json")

local _M = {}

function _M.read_conf(env, args)
    local conf, err = yaml.read_conf(args.file)
    conf.init_params = json.encode({
        mode = args.mode,
        file = args.file,
        conf = args.conf,
        check_conf = args.check_conf,
        home = env.home,
    })
    return conf, err
end

return _M
