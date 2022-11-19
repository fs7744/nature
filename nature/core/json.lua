local log = require('nature.core.log')
local jsonschema = require('jsonschema')
local lrucache = require("nature.core.lrucache")
local cached_validator = lrucache.new(1000, 0, true)

local _M = {
    decode = require('cjson.safe').decode,
    encode = require('cjson.safe').encode
}

local delay_tab = setmetatable({ data = "" }, {
    __tostring = function(self)
        local res, err = _M.encode(self.data)
        if not res then
            log.error("failed to encode: " .. err)
        end

        return res
    end
})

-- this is a non-thread safe implementation
-- it works well with log, eg: log.info(..., json.delay_encode({...}))
function _M.delay_encode(data)
    delay_tab.data = data
    return delay_tab
end

local function create_validator(schema)
    local ok, res = pcall(jsonschema.generate_validator, schema)
    if ok then
        return res
    end

    return nil, res
end

local function get_validator(key, schema)
    local validator, err = cached_validator(key, create_validator,
        schema)

    if not validator then
        return nil, err
    end

    return validator, nil
end

function _M.checkSchema(key, schema, json)
    local validator, err = get_validator(key, schema)

    if not validator then
        return false, err
    end

    return validator(json)
end

return _M
