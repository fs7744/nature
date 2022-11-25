use t::nature 'no_plan';

repeat_each(1);
log_level('info');
no_long_string();
no_root_location();
run_tests();


__DATA__

=== response exit when has content and code
--- config
location /t {
    content_by_lua_block {
        local context = require("nature.core.context")
        local ctx = context.new_api_context()
        local res = require("nature.core.response")
        res.exit(300, 'go\n')
    }
}
--- request
GET /t
--- error_code: 300
--- no_error_log
[error]
--- response_body
go

=== response get_upstream_status
--- config
location /t {
    content_by_lua_block {
        local context = require("nature.core.context")
        local ctx = context.new_api_context()
        local res = require("nature.core.response")
        ctx.var._cache['upstream_status'] = "502 ; 208"
        res.exit(300, res.get_upstream_status(ctx)..'\n')
    }
}
--- request
GET /t
--- error_code: 300
--- no_error_log
[error]
--- response_body
208

=== response exit when no content
--- config
location /t {
    content_by_lua_block {
        local context = require("nature.core.context")
        local ctx = context.new_api_context()
        local res = require("nature.core.response")
        res.exit(300)
    }
}
--- request
GET /t
--- error_code: 300
--- response_body

=== response exit when no code
--- config
location /t {
    content_by_lua_block {
        local context = require("nature.core.context")
        local ctx = context.new_api_context()
        local res = require("nature.core.response")
        res.exit()
    }
}
--- request
GET /t
--- error_code: 200
--- response_body

=== response exit when no code
--- config
location /t {
    content_by_lua_block {
        local res = require("nature.core.response")
        res.print('ddd\n')
    }
}
--- request
GET /t
--- error_code: 200
--- response_body
ddd

=== response headers
--- config
location /t {
    content_by_lua_block {
        local context = require("nature.core.context")
        local ctx = context.new_api_context()
        local res = require("nature.core.response")
        res.add_headers('a-h', 'bb','a-h', 'dd')
        res.set_headers('d-h', 'bb','d-h', 'ddd')
        res.exit(200, 'ddd\n')
    }
}
--- request
GET /t
--- error_code: 200
--- response_headers
a-h: bb, dd
d-h: ddd
--- response_body
ddd
--- no_error_log
[error]

=== response handle_exit_content
--- config
location /t {
    set $xlevel '';
    content_by_lua_block {
        local context = require("nature.core.context")
        local ctx = context.new_api_context()
        local res = require("nature.core.response")
        res.set_exit_contenthandler(function(code, c)
            return 'mew not found route\n'
        end)
        res.add_header('a-h', 'dd')
        res.set_header('d-h', 'sss')
        res.add_header('a-h', 'bb')
        res.set_header('d-h', 'bb')
        ctx.var.xlevel = 'xx'
        res.exit(200)
    }
}
--- request
GET /t
--- error_code: 200
--- response_headers
a-h: dd, bb
d-h: bb
--- response_body
mew not found route
--- no_error_log
[error]

=== response clear_header_as_body_modified
--- config
location /t {
    content_by_lua_block {
        local res = require("nature.core.response")
        ngx.header.content_length = 33
        ngx.header.content_encoding = 'utf-8'
        ngx.header.last_modified = 'a'
        ngx.header.etag = 'sdsd'
        res.clear_header_as_body_modified()
        ngx.say('ddd'..(ngx.header.content_length or '')..
        (ngx.header.content_encoding or '')..
        (ngx.header.last_modified or '')..
        (ngx.header.etag or ''))
    }
}
--- request
GET /t
--- error_code: 200
--- response_body
ddd
--- no_error_log
[error]

=== response hold_body_chunk
--- config
    location = /t {
        content_by_lua_block {
            local t = ngx.arg
            local metatable = getmetatable(t)
            local count = 0
            setmetatable(t, {__index = function(t, idx)
                if count == 0 then
                    if idx == 1 then
                        return "hello "
                    end
                    count = count + 1
                    return false
                end
                if count == 1 then
                    if idx == 1 then
                        return "world\n"
                    end
                    count = count + 1
                    return true
                end

                return metatable.__index(t, idx)
            end,
            __newindex = metatable.__newindex})

            -- trigger body_filter_by_lua_block
            ngx.print("A")
        }
        body_filter_by_lua_block {
            local response = require("nature.core.response")
            local final_body = response.hold_body_chunk(ngx.ctx)
            if not final_body then
                return
            end
            ngx.arg[1] = final_body
        }
    }
--- request
GET /t
--- response_body
hello world
--- no_error_log
[error]

=== stream response exit
--- stream_server_config
content_by_lua_block  {
    local sock, err = ngx.req.socket()
    if not sock then
        ngx.exit(500)
    end
    local data, err = sock:receive('*l')
    if not data then
        return ngx.exit(200)
    end
    local sent, err = sock:send(data)
    local context = require("nature.core.context")
    local ctx = context.new_api_context()
    local res = require("nature.core.response")
    res.exit(200, 'AAA\n')
}
--- stream_request
m
--- stream_response
mAAA
--- no_error_log
[error]