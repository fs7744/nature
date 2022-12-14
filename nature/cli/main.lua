rawset(_G, 'lfs', false)
local cmd = require("nature.cli.cmd")

local function env(home)
    local pkg_cpath_org = package.cpath
    local pkg_path_org = package.path
    local pkg_cpath = home .. "/deps/lib64/lua/5.1/?.so;" .. home ..
        "/deps/lib/lua/5.1/?.so;"

    local pkg_path = home .. "/src/?.lua;" .. home .. "/?/init.lua;" .. home ..
        "/deps/share/lua/5.1/?/init.lua;" .. home ..
        "/deps/share/lua/5.1/?.lua;;"

    package.cpath = pkg_cpath .. pkg_cpath_org
    package.path = pkg_path .. pkg_path_org

    return {
        home = home,
        openresty_args = [[openresty -p ]] .. home .. [[ -c ]],
        pkg_cpath = package.cpath,
        pkg_path = package.path
    }
end

local e = env(arg[1])

local conf_params = {
    {
        name = "conf",
        short_name = "c",
        description = "output generate nginx.conf",
        required = true,
        default = e.home .. '/nginx.conf'
    }
}

local cmds = {
    {
        name = "version",
        description = "show nature version",
        fn = function()
            print(require("nature").version)
        end
    },
    {
        name = "init",
        description = "init conf",
        options = {
            conf_params[1],
            {
                name = "mode",
                short_name = "m",
                description = "conf mode : yaml or etcd",
                required = true,
                default = 'yaml'
            },
            {
                name = "file",
                short_name = "f",
                description = "yaml conf path",
                required = false,
                default = e.home .. '/nature.yaml'
            },
            {
                name = "etcd_host",
                description = "etcd host",
                required = false,
                default = 'http://127.0.0.1:2379'
            },
            {
                name = "etcd_prefix",
                description = "etcd prefix",
                required = false,
                default = '/nature'
            },
            {
                name = "etcd_timeout",
                description = "etcd timeout",
                required = false,
                type = "number",
                default = 300
            },
            {
                name = "etcd_user",
                description = "etcd user",
                required = false
            },
            {
                name = "etcd_password",
                description = "etcd password",
                required = false
            },
            {
                name = "etcd_ssl_verify",
                description = "etcd ssl_verify",
                required = false,
                default = false,
                type = "boolean",
            },
            {
                name = "etcd_use_grpc",
                description = "etcd use_grpc",
                required = false,
                type = "boolean",
                default = false,
            },
            {
                name = "check_conf",
                description = "check conf",
                required = false,
                default = true,
                type = "boolean"
            },
        },
        fn = require('nature.cli.conf').generate
    },
    {
        name = "start",
        description = "start nature",
        options = conf_params,
        fn = function(env, args)
            if cmd.execute_cmd(env.openresty_args .. args.conf .. " -g 'daemon off;'") then
                return 'Started nature'
            else
                return 'Started failed '
            end
        end
    },
    {
        name = "reload",
        description = "reload nature",
        options = conf_params,
        fn = function(env, args)
            if cmd.execute_cmd(env.openresty_args .. args.output .. " -s reload") then
                return 'Reloaded nature'
            else
                return 'Reloaded failed'
            end
        end
    },
    {
        name = "stop",
        description = "stop nature",
        options = conf_params,
        fn = function(env, args)
            if cmd.execute_cmd(env.openresty_args .. args.output .. " -s stop") then
                return 'Stoped nature'
            else
                return 'Stoped failed'
            end
        end
    }
}

cmd.execute(cmds, e, arg)
