local pkg_loaded = package.loaded
local log = require("nature.core.log")
local config = require("nature.config.manager")
local events = require("nature.core.events")

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

function _M.load(load_list)

    local loaded_hash = {}
    for _, pkg_name in ipairs(load_list) do
        local old = pkg_loaded[pkg_name]
        local ok, plugin = pcall(require, pkg_name)
        if ok then
            loaded_hash[pkg_name] = true
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

    for pkg_name, v in pairs(plugins) do
        if loaded_hash[pkg_name] ~= true then
            plugins[pkg_name] = nil
            unload_plugin(v, pkg_name)
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

local function load_plugins_change(data)
    if data then
        _M.load(data)
    end
end

local function global_plugins_change(data)
    if not data then
        data = {}
    end
    _M.global = data
end

function _M.init()
    local prefix = require('nature.core.ngp').sys_prefix()
    local ps = config.get('plugins')
    local load_key = prefix .. 'load'
    load_plugins_change(ps[load_key])
    local global_ps_key = prefix .. 'global'
    global_plugins_change(ps[global_ps_key])
    events.subscribe('plugins', load_key, load_plugins_change)
    events.subscribe('plugins', global_ps_key, global_plugins_change)
end

return _M
