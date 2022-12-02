local _M = {}

function _M.preread(ctx, plugin_data, matched_router)
    if not ctx.upstream_key then
        ctx.upstream_key = matched_router.upstream
    end
end

return _M
