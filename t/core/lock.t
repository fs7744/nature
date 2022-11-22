use t::nature 'no_plan';

repeat_each(1);
log_level('info');
no_long_string();
no_root_location();
run_tests();

__DATA__

=== lock should match
--- config
location /t {
    content_by_lua_block {
        local lock = require("nature.core.lock")
        local _, r, err = pcall(lock.run, 'testf',{}, function (i)
            return i
        end, '333')
        if err ~= nil or #r == 0 then
            ngx.log(ngx.ERR, "lock failed: ", err)
        end
        ngx.say(r)
    }
}
--- request
GET /t
--- no_error_log
[error]
--- response_body
333
