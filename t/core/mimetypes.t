use t::nature 'no_plan';

repeat_each(1);
log_level('info');
no_long_string();
no_root_location();
run_tests();


__DATA__

=== mimetypes
--- config
location / {
    content_by_lua_block {
        local mimetypes = require("nature.core.mimetypes")
        ngx.say(mimetypes.lookup(ngx.var.uri, ngx.var.http_content_type))
    }
}
--- pipelined_requests eval
["GET /t",
"GET /t",
"GET /t/sd",
"GET /t/sd/sdsds",
"GET /t",
"GET /t/sd",
"GET /t/sd",
"GET /t/sd.txt"]
--- more_headers eval
["Content-Type: application/octet-stream",
"Content-Type: application/octet-stream; charst: utf-8",
"Content-Type: application/Octet-stream",
"x-Content-Type: application/octet-stream; charst: utf-8",
"x-Content-Type: charst: utf-8",
"Content-Type: text/html",
"Content-Type: application/javascript",
"Content-Type: text/html"]
--- response_body eval
["bin\n",
"bin\n",
"bin\n",
"nil\n",
"nil\n",
"html\n",
"js\n",
"txt\n"]
--- error_core eval
[200, 200, 200, 200, 200, 200, 200, 200]
--- no_error_log
[error]