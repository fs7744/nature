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
        local mockredis = {
        }
        mockredis.new = function()
            return mockredis
        end
        mockredis.connect = function()
            return mockredis
        end
        mockredis.set_keepalive = function()
        end
        mockredis.get = function(self, key)
            return key
        end
        
        mockredis.set = function(self,  key, value, ttl)
            return  key..tostring(value)..tostring(ttl) 
        end
        mockredis.expire = function()
        end
        package.loaded['resty.redis.connector'] = mockredis
        package.loaded['resty.rediscluster'] = mockredis
        local redis = require("nature.core.redis")
        local log = require("nature.core.log")
        local r = redis.get({}, 'get_k')
        if r ~= 'get_k' then
            log.error('get error ', r)
        end
        r = redis.set({}, 'set_k', true)
        if r ~= 'set_ktruenil' then
            log.error('get error ', r)
        end
    }
}
--- request
GET /t
--- no_error_log
[error]