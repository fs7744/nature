local setmetatable = setmetatable
local pairs = pairs
local type = type
local tablepool = require("tablepool")
local ngx_null = ngx.null

local _M = {
    new = require("table.new"),
    clear = require("table.clear"),
    nkeys = require("table.nkeys"),
    insert = table.insert,
    concat = table.concat,
    sort = table.sort,
    clone = require("table.clone"),
    isarray = require("table.isarray"),
    empty_tab = {},
    pool_fetch = tablepool.fetch,
    pool_release = tablepool.release
}

setmetatable(_M, { __index = table })

function _M.keys_eq(i, j)
    if _M.nkeys(i) ~= _M.nkeys(j) then
        return false
    end

    for k in pairs(i) do
        if j[k] == nil then
            return false
        end
    end

    return true
end

local function merge(origin, extend)
    for k, v in pairs(extend) do
        if type(v) == "table" then
            if type(origin[k] or false) == "table" then
                if _M.nkeys(origin[k]) ~= #origin[k] then
                    merge(origin[k] or {}, extend[k] or {})
                else
                    origin[k] = v
                end
            else
                origin[k] = v
            end
        elseif v == ngx_null then
            origin[k] = nil
        else
            origin[k] = v
        end
    end

    return origin
end

_M.merge = merge

local deepcopy
do
    local function _deepcopy(orig, copied)
        -- prevent infinite loop when a field refers its parent
        copied[orig] = true
        -- If the array-like table contains nil in the middle,
        -- the len might be smaller than the expected.
        -- But it doesn't affect the correctness.
        local len = #orig
        local copy = _M.new(len, _M.nkeys(orig) - len)
        for orig_key, orig_value in pairs(orig) do
            if type(orig_value) == "table" and not copied[orig_value] then
                copy[orig_key] = _deepcopy(orig_value, copied)
            else
                copy[orig_key] = orig_value
            end
        end

        return copy
    end

    local copied_recorder = {}

    function deepcopy(orig)
        local orig_type = type(orig)
        if orig_type ~= 'table' then
            return orig
        end

        local res = _deepcopy(orig, copied_recorder)
        _M.clear(copied_recorder)
        return res
    end
end
_M.deepcopy = deepcopy

function _M.array_find(array, val)
    if type(array) ~= "table" then
        return nil
    end

    for i, v in ipairs(array) do
        if v == val then
            return i
        end
    end

    return nil
end

return _M
