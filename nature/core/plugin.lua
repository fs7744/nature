local pkg_loaded = package.loaded
local log = require("nature.core.log")

local plugin_method = {
    "rewrite", "access", "header_filter", "body_filter", "log", "preread", "ssl_certificate"
}

local _M = {}

local plugins = {}

local function unload_plugin(plugin, name)
    if plugin and plugin.destroy then
        local ok, err = pcall(plugin.destroy)
        if not ok then
            log.error('unload plugin [', name, '] err:', err)
        end
    end
end

function _M.load(load_list, unload_load_list)
    if unload_load_list then
        for _, pkg_name in ipairs(unload_load_list) do
            plugins[pkg_name] = nil
            unload_plugin(pkg_loaded[pkg_name], pkg_name)
        end
    end
    if load_list then
        for _, pkg_name in ipairs(load_list) do
            local old = pkg_loaded[pkg_name]
            local ok, plugin = pcall(require, pkg_name)
            if ok then
                plugins[pkg_name] = plugin
                unload_plugin(old, pkg_name)
                if plugin and plugin.init then
                    local o, err = pcall(plugin.init)
                    if not o then
                        log.error('init plugin [', pkg_name, '] err:', err)
                    end
                end
                log.info('load plugin [', pkg_name, ']')
            else
                log.error('load plugin [', pkg_name, '] err:', plugin)
                return
            end
        end
    end
end

function _M.run(fnName, ctx)
    if ctx.stop then
        return
    end
    local fns = ctx.matched_router[fnName]
    if fns then
        for _, pkg in ipairs(fns) do
            local pkg_name = pkg.name
            local p = plugins[pkg_name]
            if p then
                p = p[fnName]
                if p then
                    local r, err = pcall(p, ctx, pkg)
                    if not r then
                        log.error(fnName, ' exec ', pkg_name, ' failed: ', err)
                    end
                    if ctx.stop then
                        return
                    end
                else
                    log.warn(pkg_name, ' no method ', fnName)
                end
            end
        end
    end
end

function _M.run_without_stop(fnName, ctx)
    local fns = ctx.matched_router[fnName]
    if fns then
        for _, pkg in ipairs(ctx.matched_router[fnName]) do
            local pkg_name = pkg.name
            local p = plugins[pkg_name]
            if p then
                p = p[fnName]
                if p then
                    local r, err = pcall(p, ctx, pkg)
                    if not r then
                        log.error(fnName, ' exec ', pkg_name, ' failed: ', err)
                    end
                else
                    log.warn(pkg_name, ' no method ', fnName)
                end
            end
        end
    end
end

return _M
