local config = require("nature.config.manager")
local log = require("nature.core.log")

local _M = {}

if require("nature.core.ngp").is_http_system() then

    local ev
    local function init()
        local conf = config.get('system', 'conf')
        local opts = {
            listening = conf.init_params.events_sock,
        }
        ev = require("resty.events").new(opts)
        if not ev then
            log.error("failed to init events")
        end
    end

    _M.init = init

    local function init_worker()
        local ok, err = ev:init_worker()
        if not ok then
            ngx.log(ngx.ERR, "failed to init events: ", err)
        end
    end

    _M.init_worker = init_worker

    function _M.run()
        ev:run()
    end

    local function publish_all(source, event, data)
        ev:publish('all', source, event, data)
    end

    _M.publish_all = publish_all

    local function publish_local(source, event, data)
        ev:publish('current', source, event, data)
    end

    _M.publish_local = publish_local

    local function subscribe(source, event, handler)
        ev:subscribe(source, event, handler)
    end

    _M.subscribe = subscribe

else
    local ev = require("resty.worker.events")

    _M.init = function()

    end
    local function init_worker()
        local ok, err = ev.configure({ interval = 0.5, shm = "stream_process_events" })
        if not ok then
            log.error("failed to init events", err)
        end
    end

    _M.init_worker = init_worker

    local function publish_all(source, event, data)
        ev.post(source, event, data)
    end

    _M.publish_all = publish_all

    local function publish_local(source, event, data)
        ev.post_local(source, event, data)
    end

    _M.publish_local = publish_local

    local function subscribe(source, event, handler)
        ev.register(handler, source, event)
    end

    _M.subscribe = subscribe
end
return _M
