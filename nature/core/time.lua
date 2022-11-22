local ngx_sleep = ngx.sleep
local exiting = ngx.worker.exiting
local max_sleep_interval = 1
local _M = {}
local ffi = require("ffi")
local C = ffi.C
ffi.cdef [[
    struct timeval {
        long int tv_sec;
        long int tv_usec;
    };
    int gettimeofday(struct timeval *tv, void *tz);
]];
local tm = ffi.new("struct timeval")

function _M.current_time_millis()
    C.gettimeofday(tm, nil);
    local sec = tonumber(tm.tv_sec)
    local usec = tonumber(tm.tv_usec)
    return sec + usec * 10 ^ -6
end

local function sleep(sec)
    if sec <= max_sleep_interval then
        return ngx_sleep(sec)
    end
    ngx_sleep(max_sleep_interval)
    if exiting() then
        return
    end
    sec = sec - max_sleep_interval
    return sleep(sec)
end

_M.sleep = sleep

return _M
