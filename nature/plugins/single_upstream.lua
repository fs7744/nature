local _M = {}

local function preread(ctx, plugin_data, matched_router)
    if not ctx.upstream_key then
        ctx.upstream_key = matched_router.upstream
    end
end

_M.preread = preread
_M.access = preread

return _M
