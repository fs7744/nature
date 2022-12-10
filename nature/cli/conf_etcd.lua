local yaml = require("nature.config.yaml")
local json = require("nature.core.json")

local _M = {}

function _M.read_conf(env, args)
    local conf, err = yaml.read_conf(args.file)
    if conf then
        conf.init_params = json.encode({
            mode = args.mode,
            http_host = args.etcd_host,
            protocol = "v3",
            api_prefix = "/v3",
            key_prefix = args.etcd_prefix,
            timeout = args.etcd_timeout,
            user = args.etcd_user,
            password = args.etcd_password,
            ssl_verify = args.etcd_ssl_verify,
            use_grpc = args.etcd_use_grpc,
            ssl_cert_path = args.ssl_cert_path,
            ssl_key_path = args.ssl_key_path,
            conf = args.conf,
            check_conf = args.check_conf,
            home = env.home,
            events_sock = conf.events_sock
        })
    end

    return conf, err
end

return _M
