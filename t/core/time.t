use t::nature 'no_plan';

repeat_each(1);
log_level('info');
no_long_string();
no_root_location();
run_tests();

__DATA__


=== current_time_millis should not nil
--- config
location /t {
    content_by_lua_block {
        local time = require("nature.core.time")
        local _, r, err = pcall(time.current_time_millis)
        if r == nil then
            ngx.log(ngx.ERR, "current_time_millis failed: ", err)
        end
        ngx.say(r)
    }
}
--- request
GET /t
--- no_error_log
[error]

=== sleep should not nil
--- config
location /t {
    content_by_lua_block {
        local time = require("nature.core.time")
        local a = ngx.now()
        time.sleep(2)
        ngx.update_time()
        local b = ngx.now()
        if b - a < 2 then
            ngx.log(ngx.ERR, "sleep failed: ", err)
        end
        ngx.say(b)
    }
}
--- request
GET /t
--- no_error_log
[error]