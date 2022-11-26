use t::nature 'no_plan';

repeat_each(1);
log_level('info');
no_long_string();
no_root_location();
run_tests();

__DATA__

=== cli version
--- config
location /t {
    content_by_lua_block {
       local os = require("nature.core.os")
       local v, err = os.exec_cmd('sh nature.sh version')
       if err then
        ngx.log(ngx.ERR, err)
       end
       ngx.print(v)
    }
}
--- request
GET /t
--- response_body
0.1

--- no_error_log
[error]