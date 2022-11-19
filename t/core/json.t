use t::nature 'no_plan';

repeat_each(1);
log_level('info');
no_long_string();
no_root_location();
run_tests();

__DATA__

=== json encode and decode should match
--- config
location /t {
    content_by_lua_block {
        local json = require("nature.core.json")
        local _, r, err = pcall(json.encode, { a = 333 })
        local _, r2, err = pcall(json.decode, r)
        if err ~= nil or r2.a ~= 333 then
            ngx.log(ngx.ERR, "unexpected r: ", r2.a)
        end
    }
}
--- request
GET /t
--- no_error_log
[error]

=== json delay_encode and decode should match
--- config
location /t {
    content_by_lua_block {
        local json = require("nature.core.json")
        local _, r, err = pcall(json.delay_encode, { a = 333 })
        local _, r2, err = pcall(json.decode, tostring(r))
        if err ~= nil or r2.a ~= 333 then
            ngx.log(ngx.ERR, "unexpected r: ", r2.a)
        end
    }
}
--- request
GET /t
--- no_error_log
[error]

=== json checkSchema should match
--- config
location /t {
    content_by_lua_block {
        local schema = {
            type = "object",
            properties = {
                etcd = {
                    type = "integer"
                }
            },
            required = {"etcd"}
        }
        local json = require("nature.core.json")
        local cases = {
            { a = 'd', r = false},
            { etcd = 33, r = true},
            { etcd = 33.33, r = false}
        }
        for _, case in ipairs(cases) do
            local ok, r, err = pcall(json.checkSchema, 'test',schema, case)
            if not ok and case.r then
                ngx.log(ngx.ERR, err)
            elseif ok and r ~= case.r then
                ngx.log(ngx.ERR, "unexpected: ", err," ", json.encode(case))
            end
        end
    }
}
--- request
GET /t
--- no_error_log
[error]