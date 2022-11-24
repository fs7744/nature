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

=== string has_suffix should match
--- config
location /t {
    content_by_lua_block {
        local json = require("nature.core.json")
        local str = require("nature.core.string")
        local cases = {
            {'/ds/dsd/dd', '/dsd/dd', true},
            {'/ds/dsd/dd', nil, false},
            {nil, '', false},
            {nil, nil, false},
            {'/ds/dsd/dd', 'd', true},
            {"xx", "", true},
            {"xx", "x", true},
            {"", "x", false},
            {"", "", true},
            {"", 0, false},
            {0, "x", false},
            {"a[", "[", true},
            {"[a", "[", false},
            {"[a", "[b", false}
        }
        for _, case in ipairs(cases) do
            local ok, r = pcall(str.has_suffix, case[1], case[2])
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

=== string split should match
--- config
location /t {
    content_by_lua_block {
        local json = require("nature.core.json")
        local str = require("nature.core.string")
        local cases = {
            {'ada', 'd', 2, 2},
            {'ada', 'd', 3, 2},
            {'ada', 'a', 5, 3},
            {'ada', 'a', 2, 2}
        }
        for _, case in ipairs(cases) do
            local ok, r, err = pcall(str.split, case[1], case[2], nil, nil, case[3])
            if not ok then
                if case[4] then
                    ngx.log(ngx.ERR, "error: ", err)
                end
            elseif case[4] ~= #r then
                ngx.log(ngx.ERR, "unexpected r: ", json.encode(r)," ", case[4])
            end
        end
    }
}
--- request
GET /t
--- no_error_log
[error]

=== string re_gsub should match
--- config
location /t {
    content_by_lua_block {
        local json = require("nature.core.json")
        local str = require("nature.core.string")
        local cases = {
            {'ada', 'd', 'c', 'jx', 'aca'},
            {'ada', 'd', 'c', nil, 'aca'}
        }
        for _, case in ipairs(cases) do
            local ok, r, err = pcall(str.re_gsub, case[1], case[2], case[3], case[4])
            if not ok then
                if case[5] then
                    ngx.log(ngx.ERR, "error: ", err)
                end
            elseif case[5] ~= r then
                ngx.log(ngx.ERR, "unexpected r: ", r," ", case[5])
            end
        end
    }
}
--- request
GET /t
--- no_error_log
[error]

=== str re_match
--- config
location / {
    content_by_lua_block {
        local str = require("nature.core.string")
        local json = require("nature.core.json")
        local p = ngx.req.get_uri_args(0)
        local r = str.re_match(p['s'], p['r'])
        if r then
          ngx.say(#r > 0 and json.encode(r) or r[0])
        else
          ngx.say(nil)
        end
    }
}
--- pipelined_requests eval
["GET /t?s=a.sdds&r=sd","GET /t?s=a11d.gif&r=[a-zA-Z0-9]{4}","GET /t?r=a11","GET /t?s=hello1234&r=([0-9])(?<remaining>[0-9]+)"]
--- response_body eval
["sd\n","a11d\n","nil\n","nil\n"]
--- error_core eval
[200,200,200,200]
--- no_error_log
[error]

=== str re_match remaining
--- config
location / {
    content_by_lua_block {
        local str = require("nature.core.string")
        local json = require("nature.core.json")
        local r = str.re_match('hello1234', '([0-9])(?<remaining>[0-9]+)')
        if r then
          ngx.say(#r > 0 and json.encode(r) or r[0])
        else
          ngx.say(nil)
        end
    }
}
--- request
GET /t
--- response_body
{"0":"1234","1":"1","2":"234","remaining":"234"}
--- no_error_log
[error]

=== string re_find
--- config
location /t {
    content_by_lua_block {
        local json = require("nature.core.json")
        local str = require("nature.core.string")
        local cases = {
            {'/ds/dsd/dd', 'ds[&]{1,1}', false},
            {'/ds/dsd/dd', 'ds[/]{1,1}', true},
            {'/ds/dsd/dd', '.*', true},
            {'/ds/dsd/dd', 'xxx', false},
            {'/ds/dsd/dd', 'Ds', true},
            {'/ds/dsd/dd', '/ds', true},
            {'/ds/dsd/dd', 'dd', true},
            {'/ds/dsd/dd', 'dsd', true},
            {'ds/dsd/dd', 'd', true}
        }
        for _, case in ipairs(cases) do
            local ok, r, err = pcall(str.re_find, case[1], case[2], 'sijo')
            if not ok then
                ngx.log(ngx.ERR, "error: ", r, err)
            elseif case[3] ~= (r ~= nil) then
                ngx.log(ngx.ERR, "unexpected r: ", r," case: ", json.encode(case))
            end
        end
    }
}
--- request
GET /t
--- no_error_log
[error]

=== string to_hex and from_hex should match
--- config
location /t {
    content_by_lua_block {
        local str = require("nature.core.string")
        local cases = {
            '/ds/dsd/dd',
            '/ds/dsd/dd',
            '',
            nil
        }
        for _, case in ipairs(cases) do
            local ok, r, err1 = pcall(str.to_hex, case)
            local ok2, r2, err2 = pcall(str.from_hex, r)
            if not ok or not ok2 then
                ngx.log(ngx.ERR, "error", err1," ", err2)
            elseif case ~= r2 then
                ngx.log(ngx.ERR, "unexpected r2: ", r2," ", case)
            end
        end
    }
}
--- request
GET /t
--- no_error_log
[error]

=== string r_pad should match
--- config
location /t {
    content_by_lua_block {
        local json = require("nature.core.json")
        local str = require("nature.core.string")
        local cases = {
            {'4', 5, nil, '4    '},
            {'4', 5, '0', '40000'},
            {'444444', 5, nil, '444444'},
            {'444444', 5, '--', '444444'},
            {'4', 5, '--', '4--------'},
            {nil, 5, '--', false}
        }
        for _, case in ipairs(cases) do
            local ok, r, err = pcall(str.r_pad, case[1], case[2], case[3])
            if not ok then
                if case[4] then
                    ngx.log(ngx.ERR, "error: ", err)
                end
            elseif case[4] ~= r then
                ngx.log(ngx.ERR, "unexpected r: ", r," ", case[4])
            end
        end
    }
}
--- request
GET /t
--- no_error_log
[error]

=== string uri_safe_encode
--- config
location /t {
    content_by_lua_block {
        local json = require("nature.core.json")
        local str = require("nature.core.string")
        local cases = {
            {'/ds/dsd/dd', '%2Fds%2Fdsd%2Fdd' },
            {'/ds/dsd/dd?s=d', '%2Fds%2Fdsd%2Fdd%3Fs%3Dd' },
            {'/ds/dsd/dd?s=d&d=s', '%2Fds%2Fdsd%2Fdd%3Fs%3Dd%26d%3Ds' },
            {nil, nil }
        }
        for _, case in ipairs(cases) do
            local ok, r, err = pcall(str.uri_safe_encode, case[1])
            if not ok then
                ngx.log(ngx.ERR, "error: ", r, err)
            elseif case[2] ~= r then
                ngx.log(ngx.ERR, "unexpected r: ", r," case: ", json.encode(case))
            end
        end
    }
}
--- request
GET /t
--- no_error_log
[error]

=== str find_last
--- config
location / {
    content_by_lua_block {
        local str = require("nature.core.string")
        ngx.say(str.find_last(ngx.req.get_uri_args(0)['s'], '%.'))
    }
}
--- pipelined_requests eval
["GET /t?s=a.s","GET /t?s=a11.gif","GET /t?s=a11","GET /t"]
--- response_body eval
["3\n","5\n","nil\n","nil\n"]
--- error_core eval
[200,200,200,200]
--- no_error_log
[error]

=== str re_sub
--- config
location / {
    content_by_lua_block {
        local str = require("nature.core.string")
        local p = ngx.req.get_uri_args(0)
        ngx.say(str.re_sub(p['s'], p['r']))
    }
}
--- pipelined_requests eval
["GET /t?s=a.sdds&r=sd","GET /t?s=a11d.gif&r=[a-zA-Z0-9]{4}","GET /t?r=a11"]
--- response_body eval
["sd\n","a11d\n","nil\n"]
--- error_core eval
[200,200,200]
--- no_error_log
[error]

=== str get_file_ext
--- config
location / {
    content_by_lua_block {
        local str = require("nature.core.string")
        ngx.say(str.get_file_ext(ngx.var.uri))
    }
}
--- pipelined_requests eval
["GET /t?s=a.sdds&r=sd","GET /t","GET /t.txt/d","GET /t.txt","GET /t.txt/t.txt/d.html","GET /t.txt/t.txt/DDsdsd.HTML"]
--- response_body eval
["nil\n","nil\n","nil\n","txt\n","html\n","html\n"]
--- error_core eval
[200,200,200,200,200.200]
--- no_error_log
[error]

=== string encode_base64 and decode_base64 should match
--- config
location /t {
    content_by_lua_block {
        local str = require("nature.core.string")
        local cases = {
            '/ds/dsd/dd',
            '/ds/dsd/dd',
            '',
            nil
        }
        for i = 1, 10 do
            table.insert(cases, str.rand_bytes(i, true))
        end
        local function toBase64(source_str)
            local b64chars =
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
            local s64 = ""
            local str = source_str

            while #str > 0 do
                local bytes_num, buf = 0, 0
                for byte_cnt = 1, 3 do
                    buf = (buf * 256)
                    if #str > 0 then
                        buf = buf + string.byte(str, 1, 1)
                        str = string.sub(str, 2)
                        bytes_num = bytes_num + 1
                    end
                end

                for group_cnt = 1, (bytes_num + 1) do
                    local b64char = math.fmod(math.floor(buf / 262144), 64) + 1
                    s64 = s64 .. string.sub(b64chars, b64char, b64char)
                    buf = buf * 64
                end

                for fill_cnt = 1, (3 - bytes_num) do
                    s64 = s64 .. "="
                end
            end

            return s64
        end
        for _, case in ipairs(cases) do
            local ok, r, err1 = pcall(toBase64, case)
            local ok2, r2, err2 = pcall(str.decode_base64, r)
            if not ok or not ok2 then
                ngx.log(ngx.ERR, "error ", r, err1," ", r2, err2)
            elseif case ~= r2 then
                ngx.log(ngx.ERR, "unexpected r2: ", r2," ", case)
            end
        end
    }
}
--- request
GET /t
--- no_error_log
[error]



=== string encode_base64url and decode_base64url should match
--- config
location /t {
    content_by_lua_block {
        local str = require("nature.core.string")
        local cases = {
            '/ds/dsd/dd',
            '/ds/dsd/dd',
            '',
            nil
        }
        for _, case in ipairs(cases) do
            local ok, r, err1 = pcall(str.encode_base64url, case)
            local ok2, r2, err2 = pcall(str.decode_base64url, r)
            if not ok or not ok2 then
                ngx.log(ngx.ERR, "error", err1," ", err2)
            elseif case ~= r2 then
                ngx.log(ngx.ERR, "unexpected r2: ", r2," ", case)
            end
        end
    }
}
--- request
GET /t
--- no_error_log
[error]

=== string trim should match
--- config
location /t {
    content_by_lua_block {
        local str = require("nature.core.string")
        local json = require("nature.core.json")
        local cases = {
            {' /ds/dsd /dd ', '/ds/dsd /dd'},
            {' /ds/aa/dd','/ds/aa/dd'},
            {'/ds/aa/dd ','/ds/aa/dd'},
            {' ',''}
        }
        for _, case in ipairs(cases) do
            local ok, r, err1 = pcall(str.trim, case[1])
            if not ok or r ~= case[2] then
                ngx.log(ngx.ERR, "unexpected r: ", r, " ", json.encode(case))
            end
        end
    }
}
--- request
GET /t
--- no_error_log
[error]