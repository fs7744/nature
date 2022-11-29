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
if not worker_connections then
    worker_connections = 512
end    
if not worker_processes then
    worker_processes = 'auto'
end  
%}
error_log {* error_log *} {* error_log_level *};
{% if user and user ~= '' then %}
user {* user *};
{% end %}

worker_processes {* worker_processes *};
{% if worker_cpu_affinity and worker_cpu_affinity ~= '' then %}
worker_cpu_affinity {* worker_cpu_affinity *};
{% end %}
{% if worker_rlimit_nofile and worker_rlimit_nofile ~= '' then %}
worker_rlimit_nofile {* worker_rlimit_nofile *};
{% end %}
{% if worker_rlimit_core and worker_rlimit_core ~= '' then %}
worker_rlimit_core {* worker_rlimit_core *};
{% end %}
{% if worker_shutdown_timeout and worker_shutdown_timeout ~= '' then %}
worker_shutdown_timeout {* worker_shutdown_timeout *};
{% end %}

events {
    accept_mutex off;
    worker_connections {* worker_connections *};
}

{% if stream and stream.enable then %}
stream {
    lua_package_path  "{*lua_package_path*}$prefix/deps/share/lua/5.1/?.lua;$prefix/deps/share/lua/5.1/?/init.lua;$prefix/?.lua;$prefix/?/init.lua;;./?.lua;/usr/local/openresty/luajit/share/luajit-2.1.0-beta3/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua;/usr/local/openresty/luajit/share/lua/5.1/?.lua;/usr/local/openresty/luajit/share/lua/5.1/?/init.lua;";
    lua_package_cpath "{*lua_package_cpath*}$prefix/deps/lib64/lua/5.1/?.so;$prefix/deps/lib/lua/5.1/?.so;;./?.so;/usr/local/lib/lua/5.1/?.so;/usr/local/openresty/luajit/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so;";
    lua_socket_log_errors off;
    lua_code_cache on;

    lua_shared_dict stream_lrucache_lock 10m;

    {% if stream.config then %}
    {% for key, v in ipairs(stream.config) do %}
    {*v*};
    {% end %}
    {% end %}

    {% if dns then %}
    {% if dns.timeout_str then %}
    resolver_timeout {* dns.timeout_str *};
    {% end %}
    resolver {% for _, dns_addr in ipairs(dns.nameservers or {}) do %} {*dns_addr*} {% end %} {% if dns.validTtl_str then %} valid={*dns.validTtl_str*}{% end %} ipv6={% if dns.enable_ipv6 then %}on{% else %}off{% end %};
    {% end %}

    {% if stream.access_log then %}
    {% if stream.access_log.enable == false then %}
    access_log off;
    {% else %}
    {% if not stream.access_log.file then stream.access_log.file = 'logs/access.log' end %}
    log_format main '{* stream.access_log.format *}';
    access_log {* stream.access_log.file *} main buffer=16384 flush=3;
    {% end %}
    {% end %}

    upstream nature_upstream {
        server 0.0.0.1:80;

        balancer_by_lua_block {
            Nature.balancer()
        }
    }

    init_by_lua_block {
        Nature = require 'nature'
        Nature.init([[{* init_params *}]])
    }

    init_worker_by_lua_block {
        Nature.init_worker()
    }

    server {
        {% if router and router.l4 then %}
        {% for k, i in pairs(router.l4) do %}
        {% if i and i.listen then %}
        listen {* i.listen *} {% if i.ssl then %} ssl {% end %} {% if i.type == 'udp' then %} udp {% end %} {% if enable_reuseport then %} reuseport {% end %};
        {% end %}    
        {% end %}
        {% end %}
        
        {% if stream.server_config then %}
        {% for key, v in ipairs(stream.server_config) do %}
        {*v*};
        {% end %}
        {% end %}

        {% if not stream.ssl then stream.ssl = { enable = false} end %}
        {% if stream.ssl.enable then %}
        ssl_certificate      {* stream.ssl.cert *};
        ssl_certificate_key  {* stream.ssl.cert_key *};
        {% if not stream.ssl.session_cache then stream.ssl.session_cache = 'shared:SSL:20m' end %}
        ssl_session_cache   {* stream.ssl.session_cache *};
        {% if not stream.ssl.session_timeout then stream.ssl.session_timeout = '10m' end %}
        ssl_session_timeout {* stream.ssl.session_timeout *};
        {% if not stream.ssl.protocols then stream.ssl.protocols = 'TLSv1 TLSv1.1 TLSv1.2 TLSv1.3' end %}
        ssl_protocols {* stream.ssl.protocols *};
   
        {% if stream.ssl.session_tickets then %}
        ssl_session_tickets on;
        {% else %}
        ssl_session_tickets off;
        {% end %}

        ssl_certificate_by_lua_block {
            Nature.stream_ssl_certificate()
        }
        {% end %}

        preread_by_lua_block {
            Nature.stream_preread()
        }

        proxy_pass nature_upstream;

        log_by_lua_block {
            Nature.log()
        }
    }
}
{% end %}

http {
    lua_package_path  "{*lua_package_path*}$prefix/deps/share/lua/5.1/?.lua;$prefix/deps/share/lua/5.1/?/init.lua;$prefix/?.lua;$prefix/?/init.lua;;./?.lua;/usr/local/openresty/luajit/share/luajit-2.1.0-beta3/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua;/usr/local/openresty/luajit/share/lua/5.1/?.lua;/usr/local/openresty/luajit/share/lua/5.1/?/init.lua;";
    lua_package_cpath "{*lua_package_cpath*}$prefix/deps/lib64/lua/5.1/?.so;$prefix/deps/lib/lua/5.1/?.so;;./?.so;/usr/local/lib/lua/5.1/?.so;/usr/local/openresty/luajit/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so;";
    lua_socket_log_errors off;
    lua_code_cache on;

    lua_shared_dict lrucache_lock 10m;

    server {
        listen unix:/tmp/events.sock;
        location / {
            content_by_lua_block {
                require('nature.core.events').run()
            }
        }
    }
}
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
