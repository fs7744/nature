local lru_new = require("resty.lrucache").new
local ngx = ngx
local get_phase = ngx.get_phase

local lock_shdict_name = "lrucache_lock"


local _M = {}

return _M
