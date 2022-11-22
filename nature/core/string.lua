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

_M.split = ngx_re.split
_M.re_gsub = ngx.re.gsub
local re_find = ngx.re.find
_M.re_find = re_find
_M.re_match = ngx.re.match

function _M.r_pad(s, l, c)
    return s .. string.rep(c or ' ', l - #s)
end

local string_char = string.char
local function from_hex_char(cc)
    return string_char(tonumber(cc, 16))
end

function _M.from_hex(str)
    return (str:gsub('..', from_hex_char))
end

_M.to_hex = require("resty.string").to_hex

function _M.uri_safe_encode(uri)
    if not uri then
        return uri
    end
    return ngx_escape_uri(uri)
end

local function find_last(s, needle)
    if not s then
        return nil
    end
    local i = s:match(".*" .. needle .. "()")
    return i
end

_M.find_last = find_last

local string_sub = string.sub
local function get_last_sub(path, regex)
    local i = find_last(path, regex)
    if i then
        return string_sub(path, i)
    end
    return nil
end

_M.get_last_sub = get_last_sub
local string_lower = string.lower
function _M.get_file_ext(path)
    local p = get_last_sub(path, '/')
    if not p then
        p = path
    end
    local r = get_last_sub(p, '%.')
    if r then
        return string_lower(r)
    end
    return r
end

local C_RAND_bytes = C.RAND_bytes
local C_RAND_pseudo_bytes = C.RAND_pseudo_bytes
function _M.rand_bytes(len, strong)
    local buf = ffi_new("char[?]", len)
    if strong then
        if C_RAND_bytes(buf, len) == 0 then
            return nil
        end
    else
        C_RAND_pseudo_bytes(buf, len)
    end

    return ffi_str(buf, len)
end

function _M.re_sub(subject, regex, options, ctx, nth)
    local from, to = re_find(subject, regex, options, ctx, nth)
    if from then
        return string_sub(subject, from, to)
    end
    return nil
end

_M.encode_base64 = ngx.encode_base64
_M.decode_base64 = ngx.decode_base64

function _M.trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

return _M
