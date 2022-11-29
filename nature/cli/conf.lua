local cmd = require("nature.cli.cmd")
local file = require("nature.core.file")

local tpl = [=[
{% if envs then %}
{% for _, name in ipairs(envs) do %}
env {*name*};
{% end %}
{% end %}
pid       logs/nginx.pid;
{% 
if not error_log or error_log == '' then 
    error_log = 'logs/error.log'
end
if not error_log_level then
    error_log_level = 'warn'
end     
%}
error_log {* error_log *} {* error_log_level *};
{% if user and user ~= '' then %}
user {* user *};
{% end %}

]=]

local _M = {}

local function covnert_conf(env, args)
    local conf, err = require('nature.cli.conf_' .. args.mode).read_conf(env, args)
    return conf, err
end

function _M.generate(env, args)
    local conf, err = covnert_conf(env, args)
    if err then
        return nil, err
    end
    conf, err = file.overwrite(args.conf, require("resty.template").compile(tpl)(conf))
    if err then
        return nil, err
    end
    if args.check_conf then
        if cmd.execute_cmd(env.openresty_args .. args.conf .. ' -t') then
            return 'Generated success at: ' .. args.conf
        else
            return 'Generated failed'
        end
    else
        return 'Generated success at: ' .. args.conf
    end
end

return _M
