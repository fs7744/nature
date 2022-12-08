local _M = {}

function _M.preread(ctx, plugin_data, matched_router)
    if not ctx.upstream_key then
        ctx.upstream_key = matched_router.upstream
    end
end

function _M.access(ctx, plugin_data, matched_router)
    if not ctx.upstream_key then
        ctx.upstream_key = matched_router.upstream
    end
    local vars = ctx.var
    if vars.upstream_uri == '' then
        vars.upstream_uri = vars.request_uri
    end
    if vars.upstream_scheme == '' then
        vars.upstream_scheme = 'http'
    end
    if not vars.proxy_host then
        vars.proxy_host = vars.http_host
    end
end

return _M
