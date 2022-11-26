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
if error_log and error_log == '' then 
    error_log = 'logs/error.log'
end     
%}
error_log {* error_log *} {* error_log_level *};
{% if user and user ~= '' then %}
user {* user *};
{% end %}

]=]

local _M = {}

local function covnert_conf(env, args)

end

function _M.generate(env, args)

    local conf = covnert_conf(env, args)
    local _, err = file.overwrite(args.conf, require("resty.template").compile(tpl)(conf))
    if err then
        return nil, err
    end
    if cmd.execute_cmd(env.openresty_args .. args.conf .. ' -t') then
        return 'Generated success at: ' .. args.conf
    else
        return 'Generated failed'
    end
end

return _M
