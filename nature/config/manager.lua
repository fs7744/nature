local _M = {}

local loader
function _M.init(params)
    loader = require("nature.config." .. params.mode).init(params)
    _M.init_worker = loader.init_worker
    _M.get_config = loader.get_config
end

return _M
