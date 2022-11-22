use t::nature 'no_plan';

repeat_each(1);
log_level('info');
no_long_string();
no_root_location();
run_tests();

__DATA__

=== table keys_eq should match
--- config
location /t {
    content_by_lua_block {
        local json = require("nature.core.json")
        local table = require("nature.core.table")
        local cases = {
            { {a=1,b=3}, {a=1}, false},
            { {a=1}, {b=3}, false},
            { {a=1}, {b=3,a=1}, false},
            { {a=1,b=3}, {a=1,b=5}, true},
            { {}, {}, true},
            { nil, nil, false}
        }
        for _, case in ipairs(cases) do
            local ok, r, err = pcall(table.keys_eq,case[1], case[2])
            if not ok and case[3] then
                ngx.log(ngx.ERR, err)
            elseif ok and r ~= case[3] then
                ngx.log(ngx.ERR, "unexpected: ", r," ", json.encode(case))
            end
        end
    }
}
--- request
GET /t
--- no_error_log
[error]

=== table merge should match
--- config
location /t {
    content_by_lua_block {
        local json = require("nature.core.json")
        local table = require("nature.core.table")
        local cases = {
            { {a=1,b=3}, {c=1}, 1},
            { {a=1,c=2}, {}, 2}
        }
        for _, case in ipairs(cases) do
            local ok, r, err = pcall(table.merge,case[1], case[2])
            if not ok and case[3] then
                ngx.log(ngx.ERR, err)
            elseif ok and r.c ~= case[3] then
                ngx.log(ngx.ERR, "unexpected: ", json.encode(r)," ", json.encode(case))
            end
        end
        local cases = {
            { {a=1,b=3}, {d={c=1}}, 1},
            { {a=1,d={c=2}}, {d={}}, 2}
        }
        for _, case in ipairs(cases) do
            local ok, r, err = pcall(table.merge,case[1], case[2])
            if not ok and case[3] then
                ngx.log(ngx.ERR, err)
            elseif ok and r.d.c ~= case[3] then
                ngx.log(ngx.ERR, "unexpected: ", json.encode(r)," ", json.encode(case))
            end
        end
    }
}
--- request
GET /t
--- no_error_log
[error]

=== table deepcopy table should right
--- config
location /t {
    content_by_lua_block {
        local json = require("nature.core.json")
        local table = require("nature.core.table")
        local cases = {
            { {c=3}, {c=3}},
            { {c=3.123}, {c=3.123}},
            { {c="223"}, {c="223"}},
            { {c=true}, {c=true}},
            { {c=false}, {c=false}},
            { {c=nil}, {c=nil}}
        }
        for _, case in ipairs(cases) do
            local ok, r, err = pcall(table.deepcopy,case[1])
            if not ok then
                ngx.log(ngx.ERR, err)
            elseif ok and r.c ~= case[2].c then
                ngx.log(ngx.ERR, "unexpected: ", json.encode(r)," ", json.encode(case))
            end
        end
    }
}
--- request
GET /t
--- no_error_log
[error]

=== table deepcopy not table should right
--- config
location /t {
    content_by_lua_block {
        local json = require("nature.core.json")
        local table = require("nature.core.table")
        local cases = {
            { 3, 3},
            { 3.123, 3.123},
            { "223", "223"},
            { true, true},
            { false, false},
            { nil, nil}
        }
        for _, case in ipairs(cases) do
            local ok, r, err = pcall(table.deepcopy,case[1])
            if not ok then
                ngx.log(ngx.ERR, err)
            elseif ok and r ~= case[2] then
                ngx.log(ngx.ERR, "unexpected: ", json.encode(r)," ", json.encode(case))
            end
        end
    }
}
--- request
GET /t
--- no_error_log
[error]

=== table array_find should right
--- config
location /t {
    content_by_lua_block {
        local json = require("nature.core.json")
        local table = require("nature.core.table")
        local cases = {
            { {3}, 3, 1},
            { {3}, 2, nil},
            { {3,3.123}, 3.123, 2},
            { {"ss","d","223"}, "223", 3},
            { {true}, true, 1},
            { {false}, false, 1},
            { {d = 3}, 3, nil}
        }
        for _, case in ipairs(cases) do
            local ok, r, err = pcall(table.array_find,case[1],case[2])
            if not ok then
                ngx.log(ngx.ERR, err)
            elseif ok and (r ~= case[3]) then
                ngx.log(ngx.ERR, "unexpected: ", json.encode(r)," ", json.encode(case))
            end
        end
    }
}
--- request
GET /t
--- no_error_log
[error]