use t::nature 'no_plan';

repeat_each(1);
log_level('info');
no_long_string();
no_root_location();
run_tests();

__DATA__

=== plugin load should right
--- config
location /t {
    content_by_lua_block {
        local context = require("nature.core.context")
        local ctx = context.new_api_context()
        local plugin = require("nature.core.plugin")
        plugin.load({'t.lua.plugin_test' })
        plugin.run('rewrite', {{ name ='t.lua.plugin_test'} }, ctx)
    }
}
--- request
GET /t
--- error_log
test

=== plugin load not exists should right
--- config
location /t {
    content_by_lua_block {
        local context = require("nature.core.context")
        local ctx = context.new_api_context()
        local plugin = require("nature.core.plugin")
        plugin.load({'t.lua.plugin_test1' })
    }
}
--- request
GET /t
--- error_log
load plugin [t.lua.plugin_test1] err

=== plugin run not exists method should right
--- config
location /t {
    content_by_lua_block {
        rawset(_G, 'lfs', false)
        local context = require("nature.core.context")
        local ctx = context.new_api_context()
        local plugin = require("nature.core.plugin")
        plugin.load({'t.lua.plugin_test' })
        plugin.run('rewrite1', {{ name ='t.lua.plugin_test'} }, ctx)
    }
}
--- request
GET /t
--- grep_error_log eval
qr/^.*?\[warn\].*/
--- grep_error_log_out eval
qr/t.lua.plugin_test no method rewrite1/

=== plugin run when stop method should right
--- config
location /t {
    content_by_lua_block {
        local context = require("nature.core.context")
        local ctx = context.new_api_context()
        local plugin = require("nature.core.plugin")
        plugin.load({'t.lua.plugin_error', 't.lua.plugin_test' })
        plugin.run('rewrite', {{ name ='t.lua.plugin_error'}, { name ='t.lua.plugin_test' }}, ctx)
    }
}
--- request
GET /t
--- no_error_log
[error]

=== plugin run when without stop method should right
--- config
location /t {
    content_by_lua_block {
        local context = require("nature.core.context")
        local ctx = context.new_api_context()
        local plugin = require("nature.core.plugin")
        plugin.load({'t.lua.plugin_error', 't.lua.plugin_test' })
        plugin.run_without_stop('rewrite', {{ name ='t.lua.plugin_error'}, { name ='t.lua.plugin_test' }}, ctx)
    }
}
--- request
GET /t
--- error_log
test

=== plugin load same twice should init right
--- config
location /t {
    content_by_lua_block {
        local context = require("nature.core.context")
        local ctx = context.new_api_context()
        local plugin = require("nature.core.plugin")
        plugin.load({'t.lua.plugin_init', 't.lua.plugin_init' })
    }
}
--- request
GET /t
--- error_log
destroy_true