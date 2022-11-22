use t::nature 'no_plan';

repeat_each(1);
log_level('info');
no_long_string();
no_root_location();
run_tests();

__DATA__

=== file read_all and overwrite should has content
--- config
location /t {
    content_by_lua_block {
        local file = require("nature.core.file")
        local _, r, err = pcall(file.read_all, './t/servroot/conf/nginx.conf')
        if err ~= nil or #r == 0 then
            ngx.log(ngx.ERR, "read_all failed: ", err, r)
        end

        _, r, err = pcall(file.overwrite, './t/servroot/conf/ngddd.conf', 'ddd')
        _, r, err = pcall(file.read_all, './t/servroot/conf/ngddd.conf')
        if err ~= nil or r ~= 'ddd' then
            ngx.log(ngx.ERR, "overwrite failed: ", err, r)
        end

        file.remove('./t/servroot/conf/ngddd.conf')
        if file.exists('./t/servroot/conf/ngddd.conf') then
            ngx.log(ngx.ERR, "remove failed: ./t/servroot/conf/ngddd.conf")
        end
    }
}
--- request
GET /t
--- no_error_log
[error]

=== file exists should has content
--- config
location /t {
    content_by_lua_block {
        local file = require("nature.core.file")
        if not file.exists('./t/servroot/conf/nginx.conf') then
            ngx.log(ngx.ERR, "exists failed: ./t/servroot/conf/nginx.conf")
        end
        if file.exists('./t/servroot/conf/nginx22.conf') then
            ngx.log(ngx.ERR, "exists failed: ./t/servroot/conf/nginx22.conf")
        end
    }
}
--- request
GET /t
--- no_error_log
[error]
