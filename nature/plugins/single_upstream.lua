local _M = {}

function _M.preread(ctx, plugin_data, matched_router)
    require('nature.core.log').error(matched_router.upstream)

    if not ctx.upstream_key then
        ctx.upstream_key = matched_router.upstream
    end
end

return _M
