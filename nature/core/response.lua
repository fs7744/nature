local ngx = ngx
local ngx_print = ngx.print
local ngx_exit = ngx.exit
local arg = ngx.arg

local _M = {}


local function print(content)
    if content then
        ngx_print(content)
    end
end

_M.print = print

if require('nature.core.ngp').is_http_system() then

    local header = ngx.header
    local ngx_add_header = require("ngx.resp").add_header
    local concat_tab = table.concat
    local str_sub = string.sub
    local handle_exit_content

    function _M.set_exit_contenthandler(func)
        handle_exit_content = func
    end

    local function exit(code, content)
        local ctx = ngx.ctx.api_ctx
        ctx.stop = true
        if code ~= nil then
            ngx.status = code
        end
        if not content and handle_exit_content then
            content = handle_exit_content(code, ctx)
        end
        print(content)
        if code then
            ngx_exit(code)
        end
    end

    _M.exit = exit

    local function set_headers(append, ...)
        if ngx.headers_sent then
            error("headers have already been sent", 2)
        end

        local count = select('#', ...)
        if count == 1 then
            local headers = select(1, ...)
            if type(headers) ~= "table" then
                error("should be a table if only one argument", 2)
            end

            for k, v in pairs(headers) do
                if append then
                    ngx_add_header(k, v)
                else
                    header[k] = v
                end
            end

            return
        end

        for i = 1, count, 2 do
            if append then
                ngx_add_header(select(i, ...), select(i + 1, ...))
            else
                header[select(i, ...)] = select(i + 1, ...)
            end
        end
    end

    function _M.set_header(k, v)
        header[k] = v
    end

    function _M.set_headers(...)
        set_headers(false, ...)
    end

    _M.add_header = ngx_add_header

    function _M.add_headers(...)
        set_headers(true, ...)
    end

    function _M.redirect(url, status, content)
        header['Location'] = url
        exit(status or 301, content)
    end

    function _M.clear_header_as_body_modified()
        header['content_length'] = nil
        -- in case of upstream content is compressed content
        header['content_encoding'] = nil

        -- clear cache identifier
        header['last_modified'] = nil
        header['etag'] = nil
    end

    function _M.hold_body_chunk(ctx, hold_the_copy)
        local body_buffer
        local chunk, eof = arg[1], arg[2]
        if eof then
            body_buffer = ctx._body_buffer
            if not body_buffer then
                return chunk
            end

            if type(chunk) == "string" and chunk ~= "" then
                local n = body_buffer.n + 1
                body_buffer.n = n
                body_buffer[n] = chunk
            end

            body_buffer = concat_tab(body_buffer, "", 1, body_buffer.n)
            ctx._body_buffer = nil
            return body_buffer
        end

        if type(chunk) == "string" and chunk ~= "" then
            body_buffer = ctx._body_buffer
            if not body_buffer then
                body_buffer = {
                    chunk,
                    n = 1
                }
                ctx._body_buffer = body_buffer
            else
                local n = body_buffer.n + 1
                body_buffer.n = n
                body_buffer[n] = chunk
            end
        end

        if not hold_the_copy then
            -- flush the origin body chunk
            arg[1] = nil
        end
        return nil
    end

    function _M.get_upstream_status(ctx)
        -- $upstream_status maybe including multiple status, only need the last one
        return tonumber(str_sub(ctx.var.upstream_status or "", -3))
    end
else
    function _M.exit(code, content)
        local ctx = ngx.ctx.api_ctx
        ctx.stop = true
        if code ~= nil then
            ngx.status = code
        end
        print(content)
        if code then
            ngx_exit(code)
        end
    end
end


return _M
