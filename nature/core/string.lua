local ngx_re = require("ngx.re")
local ffi = require("ffi")
local C = ffi.C
local ffi_cast = ffi.cast
local ffi_new = ffi.new
local ffi_str = ffi.string
local str_type = ffi.typeof("uint8_t[?]")
local base = require("resty.core.base")
local get_string_buf = base.get_string_buf
local ngx_escape_uri = ngx.escape_uri

ffi.cdef [[
    typedef unsigned char u_char;

    int memcmp(const void *s1, const void *s2, size_t n);

    u_char * ngx_hex_dump(u_char *dst, const u_char *src, size_t len);

    int RAND_bytes(unsigned char *buf, int num);

    int RAND_pseudo_bytes(unsigned char *buf, int num);
]]

local _M = {}

local c_memcmp = C.memcmp

setmetatable(_M, { __index = string })

function _M.has_prefix(s, prefix)
    if #s < #prefix then
        return false
    end
    local rc = c_memcmp(s, prefix, #prefix)
    return rc == 0
end

function _M.has_suffix(s, suffix)
    if #s < #suffix then
        return false
    end
    local rc = c_memcmp(ffi_cast("char *", s) + #s - #suffix, suffix, #suffix)
    return rc == 0
end

return _M
