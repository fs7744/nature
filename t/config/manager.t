use t::nature 'no_plan';

$ENV{TEST_NGINX_HTML_DIR} ||= html_dir();

repeat_each(1);
log_level('info');
no_long_string();
no_root_location();
run_tests();


__DATA__

=== manager for yaml get config right
--- config
location /t {
    content_by_lua_block {
       local os = require("nature.core.os")
       local f = require("nature.core.file")
       local manager = require("nature.config.manager")
       local fp = "$TEST_NGINX_HTML_DIR/manager.yaml"
       f.overwrite(fp, [=[
config:
    a : v
    b : 3
]=])
       manager.init({mode = 'yaml', file = fp})
       ngx.print(manager.get('a')..' '.. manager.get('b')..' '.. (manager.get('c') and manager.get('c') or 'nil'))
    }
}
--- request
GET /t
--- response_body: v 3 nil
--- no_error_log
[error]