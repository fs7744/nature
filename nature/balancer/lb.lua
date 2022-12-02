local _M = {}

function _M.create(nodes, lb)
    local length = #nodes
    if length == 0 then
        return nil
    elseif length == 1 then
        lb = 'onlyyou'
    end

    if not lb then
        lb = 'roundrobin'
    end
    return require('nature.balancer.' .. lb)(nodes)
end

return _M
