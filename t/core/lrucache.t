use t::nature 'no_plan';

repeat_each(1);
log_level('info');
no_long_string();
no_root_location();
run_tests();


__DATA__

=== lrucache without lock
--- config
location /t {
    content_by_lua_block {
        local log = require("nature.core.log")
        local cache = require("nature.core.lrucache")
        local c = cache.new()
        local data, err = c('o', function(b)
            return b
        end, 'vic')
        data, err = c('o', function(b)
            return b
        end, 'ok')
        ngx.say(data)
    }
}
--- request
GET /t
--- error_code: 200
--- no_error_log
[error]
--- response_body
vic

=== lrucache with lock
--- config
location /t {
    content_by_lua_block {
        local log = require("nature.core.log")
        local cache = require("nature.core.lrucache")
        local c = cache.new_with_lock()
        local data, err = c('o', function(b)
            return b
        end, 'vic1')
        data, err = c('o', function(b)
            return b
        end, 'ok1')
        ngx.say(data)
    }
}
--- request
GET /t
--- error_code: 200
--- no_error_log
[error]
--- response_body
vic1
