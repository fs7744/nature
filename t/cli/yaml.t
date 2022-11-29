use t::nature 'no_plan';


$ENV{TEST_NGINX_HTML_DIR} ||= html_dir();

repeat_each(1);
log_level('info');
no_long_string();
no_root_location();
run_tests();

__DATA__

=== cli yaml when no file
--- config
location /t {
    content_by_lua_block {
       local os = require("nature.core.os")
       local v, err = os.exec_cmd('sh nature.sh init -m yaml')
       if err then
        ngx.log(ngx.ERR, err)
       end
       ngx.print(v)
    }
}
--- request
GET /t
--- response_body_like
^not exists yaml.*$
--- no_error_log
[error]

=== cli yaml generate envs
--- config
location /t {
    content_by_lua_block {
       local os = require("nature.core.os")
       local f = require("nature.core.file")
       local fp = "$TEST_NGINX_HTML_DIR/envs.yaml"
       local c = "$TEST_NGINX_HTML_DIR/envs.conf"
       f.overwrite(fp, [=[
envs:
    - a
    - b
]=])
       local v, err = os.exec_cmd('sh nature.sh init -m yaml -f '..fp..' -c '..c)
       if err then
        ngx.log(ngx.ERR, err)
       end
       ngx.print(v)
       ngx.print(f.read_all(c))
    }
}
--- request eval
["GET /t","GET /t","GET /t"]
--- response_body_like eval
["syntax is ok", "env a;", "env b;"]
--- no_error_log
[error]

=== cli yaml generate default log
--- config
location /t {
    content_by_lua_block {
       local os = require("nature.core.os")
       local f = require("nature.core.file")
       local fp = "$TEST_NGINX_HTML_DIR/default_log.yaml"
       local c = "$TEST_NGINX_HTML_DIR/default_log.conf"
       f.overwrite(fp, [=[
ok: 1
]=])
       local v, err = os.exec_cmd('sh nature.sh init -m yaml -f '..fp..' -c '..c)
       if err then
        ngx.log(ngx.ERR, err)
       end
       ngx.print(v)
       ngx.print(f.read_all(c))
    }
}
--- request eval
["GET /t","GET /t"]
--- response_body_like eval
["syntax is ok","error_log logs/error.log warn;"]
--- response_body_unlike eval
["env","env"]
--- no_error_log
[error]

# === cli yaml generate user
# --- config
# location /t {
#     content_by_lua_block {
#        local os = require("nature.core.os")
#        local f = require("nature.core.file")
#        local fp = "$TEST_NGINX_HTML_DIR/user.yaml"
#        local c = "$TEST_NGINX_HTML_DIR/user.conf"
#        f.overwrite(fp, [=[
# user: root
# ]=])
#        local v, err = os.exec_cmd('sh nature.sh init -m yaml -f '..fp..' -c '..c)
#        if err then
#         ngx.log(ngx.ERR, err)
#        end
#        ngx.print(v)
#        ngx.print(f.read_all(c))
#     }
# }
# --- request eval
# ["GET /t","GET /t"]
# --- response_body_like eval
# ["syntax is ok","user root;"]
# --- no_error_log
# [error]

=== cli yaml generate worker config
--- config
location /t {
    content_by_lua_block {
       local os = require("nature.core.os")
       local f = require("nature.core.file")
       local fp = "$TEST_NGINX_HTML_DIR/worker_config.yaml"
       local c = "$TEST_NGINX_HTML_DIR/worker_config.conf"
       f.overwrite(fp, [=[
worker_rlimit_nofile: 1
worker_rlimit_core: 12
worker_shutdown_timeout: 10
worker_processes: 2
worker_cpu_affinity: 10
worker_connections: 6
]=])
       local v, err = os.exec_cmd('sh nature.sh init -m yaml -f '..fp..' -c '..c)
       if err then
        ngx.log(ngx.ERR, err)
       end
       ngx.print(v)
       ngx.print(f.read_all(c))
    }
}
--- request eval
["GET /t","GET /t","GET /t","GET /t","GET /t","GET /t","GET /t"]
--- response_body_like eval
["syntax is ok","worker_rlimit_nofile 1;","worker_rlimit_core 12;","worker_shutdown_timeout 10;","worker_processes 2;","worker_cpu_affinity 10;","worker_connections 6;"]
--- no_error_log
[error]