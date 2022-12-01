local radix = require("resty.radixtree")
local config = require("nature.config.manager")
local tb = require('nature.core.table')
local l4 = require("nature.router.l4")
local events = require("nature.core.events")
--local l7 = require("nature.router.l7")

local _M = {}


local function update(routers, m, unload)
    local old_router = m.get_router()
    local old = tb.new(32, 0)
    for key, value in pairs(unload or {}) do
        if m.current[key] then
            tb.insert(old, m.current[key])
            m.current[key] = nil
        end
    end
    for key, value in pairs(routers or {}) do
        if m.current[key] then
            tb.insert(old, m.current[key])
            m.current[key] = nil
        end
        value.id = key
        _, m.current[key] = pcall(m.init_router_metadata, value)
    end
    local rs = tb.new(#m.current, 0)
    for _, rc in pairs(m.current) do
        table.insert(rs, rc)
    end
    m.set_router(radix.new(rs))
    tb.clear(old)
    if old_router then
        old_router:free()
    end
end

function _M.init()
    local routers = config.get('router')
    if require('nature.core.ngp').is_http_system() then
        --update(routers.l7, l7)
    else
        update(routers.l4, l4)
        events.subscribe('stream', 'router_l4_change', function(data)
            update(data.load, l4, data.unload)
        end)
    end
end

return _M
