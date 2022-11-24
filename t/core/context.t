use t::nature 'no_plan';

repeat_each(1);
log_level('info');
no_long_string();
no_root_location();
run_tests();


__DATA__

=== context new_api_context
--- config
location /t {
    content_by_lua_block {
        local log = require("nature.core.log")
        local context = require("nature.core.context")
        local ctx = context.new_api_context()
        local c = context.get_api_context()
        if ctx == nil or c == nil or c ~= ctx then
            log.error('context should not be nil nut nil', ctx == nil, c == nil)
        end

        context.clear_api_context()
        if ngx.ctx.api_ctx ~= nil then
            log.error('api_ctx should be nil but not nil', ngx.ctx.api_ctx == nil)
        end
    }
}
--- request
GET /t
--- error_code: 200
--- no_error_log
[error]

=== context method GET
--- config
location /t {
    content_by_lua_block {
        local context = require("nature.core.context")
        local ctx = context.new_api_context()
        ngx.say(ctx.var.method)
    }
}
--- request
GET /t
--- error_code: 200
--- response_body
GET
--- no_error_log
[error]

=== context method POST
--- config
location /t {
    content_by_lua_block {
        local context = require("nature.core.context")
        local ctx = context.new_api_context()
        ngx.say(ctx.var.method)
    }
}
--- request
POST /t
--- error_code: 200
--- response_body
POST
--- no_error_log
[error]

=== context method POST
--- config
location /t {
    content_by_lua_block {
        local context = require("nature.core.context")
        local ctx = context.new_api_context()
        ngx.say(ctx.var.method)
    }
}
--- request
POST /t
--- error_code: 200
--- response_body
POST
--- no_error_log
[error]

=== context get var
--- config
set $o 'ok';
location /t {
    content_by_lua_block {
        local context = require("nature.core.context")
        local ctx = context.new_api_context()
        ngx.say(ctx.var.o)
    }
}
--- request
POST /t
--- error_code: 200
--- response_body
ok
--- no_error_log
[error]

=== context get var header
--- config
location /t {
    content_by_lua_block {
        local context = require("nature.core.context")
        local ctx = context.new_api_context()
        ngx.say(ctx.var['http_O-d']..ctx.var.http_O_d)
    }
}
--- request
GET /t
--- more_headers
o-d: isheader
--- error_code: 200
--- response_body
isheaderisheader
--- no_error_log
[error]

=== context set var cookie when no cookie
--- config
location /t {
    set $a 's';
    content_by_lua_block {
        local context = require("nature.core.context")
        context.register_var_name('a')
        local ctx = context.new_api_context()
        local d = ctx.var.a
        ctx.var.a = 'd1'
        ctx.var.a = 'd'
        ngx.say(ngx.var.a)
    }
}
--- request
GET /t
--- error_code: 200
--- response_body
d
--- no_error_log
[error]

=== context get var cookie
--- config
location /t {
    content_by_lua_block {
        local context = require("nature.core.context")
        local ctx = context.new_api_context()
        ngx.say(ctx.var['cookie_s']..ctx.var.cookie_b..ctx.var.cookie_c)
    }
}
--- request
GET /t
--- more_headers
Cookie: s=a; b=bb; c=ccc;
--- error_code: 200
--- response_body 
abbccc
--- no_error_log
[error]

=== context get var cookie when no cookie
--- config
location /t {
    content_by_lua_block {
        local context = require("nature.core.context")
        local ctx = context.new_api_context()
        ngx.say(ctx.var['cookie_s'] or 'd')
    }
}
--- request
GET /t
--- error_code: 200
--- response_body
d
--- no_error_log
[error]

=== context get arg
--- config
location /t {
    content_by_lua_block {
        local context = require("nature.core.context")
        local request = require("nature.core.request")
        local ctx = context.new_api_context()
        local old = ctx.var.arg_a
        request.set_uri_args(ctx, "a=155&b=31")
        ngx.say(old..' '..ctx.var.arg_a..request.get_uri_args(ctx)['a'])
    }
}
--- request
GET /t?a=3&b=4
--- error_code: 200
--- no_error_log
[error]
--- response_body
3 155155

=== context get arg
--- config
location /t {
    content_by_lua_block {
        local context = require("nature.core.context")
        local request = require("nature.core.request")
        local ctx = context.new_api_context()
        ctx.a = 'ssss'
        local old = ctx.var.ctx_a
        ctx.a = 'dd'
        ngx.say(old..' '..ctx.var.ctx_a)
    }
}
--- request
GET /t?a=3&b=4
--- error_code: 200
--- no_error_log
[error]
--- response_body
ssss dd

=== context get env
--- config
location /t {
    content_by_lua_block {
        local context = require("nature.core.context")
        local request = require("nature.core.request")
        local ctx = context.new_api_context()
        require("nature.core.os").set_env('aa', 'ssss')
        local old = ctx.var.env_aa
        require("nature.core.os").set_env('aa', 'dasdsad')
        ngx.say(old..' '..ctx.var.env_aa)
    }
}
--- request
GET /t?a=3&b=4
--- error_code: 200
--- no_error_log
[error]
--- response_body
ssss dasdsad
