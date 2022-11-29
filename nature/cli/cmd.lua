local str = require('nature.core.string')
local exit = os.exit

local _M = { error_level = 0 }

local debug_opt = {
    name = "debug",
    description = "show deatil error info",
    flag = true
}

local function help(ops, showOptions, showHelp)
    print('Usage: nature.sh [action] <argument> \n')
    for _, o in ipairs(ops) do
        print(str.r_pad(o.name, 14) .. (o.description or ""))
        if showOptions and o.options then
            for _, t in ipairs(o.options) do
                local short_name = ''
                if t.short_name then
                    short_name = ' | -' .. t.short_name
                end
                local option = 'option'
                if t.required then
                    option = ''
                end
                local default = ''
                if not t.flag and t.default then
                    default = ' (default: ' .. tostring(t.default) .. ')'
                end
                print(str.r_pad('  --' .. t.name .. short_name, 18) ..
                    str.r_pad(option, 7) .. (t.description or "") ..
                    default)
            end
        end
    end
    if showHelp then
        print(str.r_pad('-h', 14) .. "help")
    end
end

local function parse_args(args, cmd)
    local r = {}
    local ops = cmd.options
    if not ops then
        return r
    end

    local i = 3
    local max = #args
    local n
    local temp = {}
    while i <= max do
        n = args[i]
        if n and str.has_prefix(n, '-') then
            local ps = str.split(n, '=', nil, nil, 2)
            local k = str.re_gsub(ps[1], '-', '', 'jo')
            local v = ps[2]
            if not v and args[i + 1] and not str.has_prefix(args[i + 1], '-') then
                i = i + 1
                v = args[i]
            end

            temp[k] = v
            if not temp[k] then
                temp[k] = '#no_args#'
            end
        end
        i = i + 1
    end

    table.insert(ops, debug_opt)
    for _, o in pairs(ops) do
        if temp[o.name] then
            r[o.name] = temp[o.name]
        elseif temp[o.short_name] then
            r[o.name] = temp[o.short_name]
        end
        if o.flag and r[o.name] then
            r[o.name] = o.flag
        end

        if o.default and (not r[o.name] or r[o.name] == '#no_args#') then
            r[o.name] = o.default
        end

        if o.type and r[o.name] then
            local t = o.type
            local v = r[o.name]
            if t == "boolean" then
                v = tostring(v) == 'true'
            end
            r[o.name] = v
        end

        if o.required and not r[o.name] then
            io.stderr:write("Not required parameter: --", o.name, "\n")
            help({ cmd }, true)
            return
        end
    end

    return r
end

function _M.execute(cmds, env, arg)
    local cmd = arg[2]
    if not cmd or cmd == '-h' then
        help(cmds, false, true)
        return
    end

    local o
    for _, i in ipairs(cmds) do
        if i.name == cmd then
            o = i
            break
        end
    end
    if not o then
        io.stderr:write("Not support: ", cmd, "\n")
        return help(cmds, false, true)
    end

    if arg[3] == '-h' then
        help({ o }, true)
        return
    end

    local args = parse_args(arg, o)
    if args then
        if args.debug then
            _M.error_level = 2
        end
        local _, out, err = pcall(o.fn, env, args)
        if err then
            io.stderr:write(err, '\n')
            exit(1)
            return
        end
        if out then
            io.stdout:write(out, '\n')
        end
    end
end

function _M.call(fn, ...)
    local r, err = fn(...)
    if err ~= nil then
        error(err, _M.error_level)
    end
    return r
end

function _M.execute_cmd(cmd)
    local code = os.execute(cmd)
    if code == nil then
        os.exit(1)
        return false
    end
    return true
end

return _M
