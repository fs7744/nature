use t::nature 'no_plan';

repeat_each(1);
log_level('debug');
no_long_string();
no_root_location();
run_tests();

__DATA__

=== log error should match
--- config
location /t {
    content_by_lua_block {
        local log = require("nature.core.log")
        log.error('dd is ', log.delay_exec(function(i) 
            return i
        end, 3))
    }
}
--- request
GET /t
--- error_log
dd is 3


=== log set_filter_level info should match
--- config
location /t {
    content_by_lua_block {
        local log = require("nature.core.log")
        log.set_filter_level(ngx.INFO)
        log.info('dd is ', log.delay_exec(function(i) 
            return i
        end, 4))
    }
}
--- request
GET /t
--- error_log
dd is 4

=== log set_filter_level Warn should no log
--- config
location /t {
    content_by_lua_block {
        local log = require("nature.core.log")
        log.set_filter_level(ngx.WARN)
        log.info('dd is ', log.delay_exec(function(i) 
            return i
        end, 4))
    }
}
--- request
GET /t
--- no_error_log
[error]