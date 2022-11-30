local config = require("nature.config.manager")
local log = require("nature.core.log")

local _M = {}

local ev
function _M.init()
    local params = config.get('params')
    local opts = {
        listening = params.events_sock,
    }
    ev = require("resty.events").new(opts)
    if not ev then
        log.error("failed to init events")
    end
end

function _M.init_worker()
    local ok, err = ev:init_worker()
    if not ok then
        ngx.log(ngx.ERR, "failed to init events: ", err)
    end
end

function _M.run()
    ev:run()
end

function _M.publish_all(source, event, data)
    ev:publish('all', source, event, data)
end

function _M.publish_local(source, event, data)
    ev:publish('current', source, event, data)
end

function _M.subscribe(source, event, handler)
    ev:subscribe(source, event, handler)
end

return _M
