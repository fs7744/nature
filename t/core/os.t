use t::nature 'no_plan';

repeat_each(1);
log_level('info');
no_long_string();
no_root_location();
run_tests();

__DATA__

=== env should can set and get
--- config
location /t {
    content_by_lua_block {
       local os = require("nature.core.os")
       local v = os.get_env('a')
       if v then
        ngx.log(ngx.ERR, "unexpected env: ", v)
       end
       os.set_env('a', 'b')
       v = os.get_env('a')
       if v ~= 'b' then
        ngx.log(ngx.ERR, "unexpected env: ", v)
       end
    }
}
--- request
GET /t
--- no_error_log
[error]

=== os name should has value
--- config
location /t {
    content_by_lua_block {
       local os = require("nature.core.os")
       local v = os.os_name
       if v == nil then
        ngx.log(ngx.ERR, "unexpected env: ", v)
       end
    }
}
--- request
GET /t
--- no_error_log
[error]