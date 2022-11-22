local open  = io.open
local close = io.close

local _M = {}

function _M.read_all(path)
    local file, data, err
    file, err = open(path, "rb")
    if not file then
        return nil, "open: " .. path .. " with error: " .. err
    end

    data, err = file:read("*all")
    if err ~= nil then
        file:close()
        return nil, "read: " .. path .. " with error: " .. err
    end

    file:close()
    return data
end

function _M.overwrite(path, content)
    local file, err
    file, err = open(path, "w")
    if not file then
        return nil, "open: " .. path .. " with error: " .. err
    end

    file:write(content)
    file:close()
end

function _M.exists(name)
    local f = open(name, "r")
    if f ~= nil then
        close(f)
        return true
    end
    return false
end

_M.remove = os.remove

return _M
