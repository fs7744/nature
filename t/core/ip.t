use t::nature 'no_plan';

repeat_each(1);
log_level('info');
no_long_string();
no_root_location();
run_tests();

__DATA__

=== ip should match
--- config
location /t {
    content_by_lua_block {
        local str = require("nature.core.string")
        local function ipv42long(ip)
            local ips = str.split(ip, "\\.")
            local num = 0
            for i = 1, #(ips) do
                num = num + (tonumber(ips[i]) or 0) % 256 * math.pow(256, (4 - i))
            end
            return num
        end
        local json = require("nature.core.json")
        local ip = require("nature.core.ip")
        local v4 = ip.parse_ipv4('2.3.4.5')
        if v4 ~= ipv42long('2.3.4.5') then
            ngx.log(ngx.ERR, "unexpected v4: ", v4, '-', ipv42long('2.3.4.5'))
        end
        local v6 = ip.parse_ipv6('2001:0db8:0000:0042:0000:8a2e:0370:7334')
        if v6[1] ~= 536939960 or v6[2] ~= 66 or v6[3] ~= 35374 or v6[4] ~= 57701172 then
            ngx.log(ngx.ERR, "unexpected v6: ", v6)
        end
    }
}
--- request
GET /t
--- no_error_log
[error]