local pkg_loaded = package.loaded
local log = require("nature.core.log")
local config = require("nature.config.manager")
local events = require("nature.core.events")
local is_http = require('nature.core.ngp').is_http_system()

local plugin_method = {
    "rewrite", "access", "header_filter", "body_filter", "log", "preread", "ssl_certificate"
}

local _M = { global = {} }

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

local function run(fnList, fnName, ctx, matched_router)
    if ctx.stop then
        return
    end
    local fns = fnList[fnName]
    if fns then
        for _, pkg in ipairs(fns) do
            local pkg_name = pkg.name
            local p = plugins[pkg_name]
            if p then
                p = p[fnName]
                if p then
                    local r, err = pcall(p, ctx, pkg, matched_router)
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

function _M.run(fnName, ctx, matched_router)
    if not matched_router then
        matched_router = ctx.matched_router
    end
    run(_M.global, fnName, ctx, matched_router)
    run(matched_router, fnName, ctx, matched_router)
end

local function run_without_stop(fnList, fnName, ctx, matched_router)
    local fns = fnList[fnName]
    if fns then
        for _, pkg in ipairs(matched_router[fnName]) do
            local pkg_name = pkg.name
            local p = plugins[pkg_name]
            if p then
                p = p[fnName]
                if p then
                    local r, err = pcall(p, ctx, pkg, matched_router)
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

function _M.run_without_stop(fnName, ctx, matched_router)
    if not matched_router then
        matched_router = ctx.matched_router
    end
    run_without_stop(_M.global, fnName, ctx, matched_router)
    if matched_router then
        run_without_stop(matched_router, fnName, ctx, matched_router)
    end
end

local function plugin_meta_change(data)
    _M.load(data.load, data.unload)
end

local function global_plugins_change(data)
    if not data then
        data = {}
    end
    _M.global = {}
end

function _M.init()
    local lplugins = config.get("plugins")
    if lplugins then
        local ps
        local g
        local source
        if is_http then
            ps = lplugins.http
            g = "http_global_plugins"
            source = 'http'
        else
            ps = lplugins.stream
            source = 'stream'
            g = "stream_global_plugins"
        end
        if ps then
            _M.load(ps)
        end

        events.subscribe(source, 'plugin_meta_change', plugin_meta_change)
        events.subscribe(g, 'config_change', global_plugins_change)
        global_plugins_change(config.get(g))
    end
end

return _M
