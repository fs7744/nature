use t::nature 'no_plan';

repeat_each(1);
log_level('info');
no_long_string();
no_root_location();
run_tests();


__DATA__

=== string has_prefix should match
--- config
location /t {
    content_by_lua_block {
        local json = require("nature.core.json")
        local str = require("nature.core.string")
        local cases = {
            {'/ds/dsd/dd', '/ds/dsd', true},
            {'/ds/dsd/dd', '/ds/d', true},
            {'/ds/dsd/dd', '/ds/:d', false},
            {'/ds/dsd/dd', '', true},
            {'/ds/dsd/dd', nil, false},
            {nil, '', false},
            {nil, nil, false},
            {'/ds/dsd/dd', 'd', false},
            {"xx", "", true},
            {"xx", "x", true},
            {"", "x", false},
            {"", "", true},
            {"", 0, false},
            {0, "x", false},
            {"a[", "[", false},
            {"[a", "[", true},
            {"[a", "[b", false}
        }
        for _, case in ipairs(cases) do
            local ok, r = pcall(str.has_prefix, case[1], case[2])
            if not ok and case[3] then
                ngx.log(ngx.ERR, "unexpected r: ", r," ", json.encode(case))
            elseif ok and r ~= case[3] then
                ngx.log(ngx.ERR, "unexpected r: ", r," ", json.encode(case))
            end
        end
    }
}
--- request
GET /t
--- no_error_log
[error]