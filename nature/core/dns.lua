local dns_utils = require("resty.dns.utils")
local table = require("nature.core.table")
local config = require("nature.config.manager")

local HOSTS_IP_MATCH_CACHE = {}

local _M = { RETURN_RANDOM = 1, RETURN_ALL = 2 }

local function gcd(a, b)
    if b == 0 then
        return a
    end

    return gcd(b, a % b)
end

local function resolve_srv(client, answers)
    if #answers == 0 then
        return nil, "empty SRV record"
    end

    local resolved_answers = {}
    local answer_to_count = {}
    for _, answer in ipairs(answers) do
        if answer.type ~= client.TYPE_SRV then
            return nil, "mess SRV with other record"
        end

        local resolved, err = client.resolve(answer.target)
        if not resolved then
            local msg =
            "failed to resolve SRV record " .. answer.target .. ": " .. err
            return nil, msg
        end

        local weight = answer.weight
        if weight == 0 then
            weight = 1
        end

        local count = #resolved
        answer_to_count[answer] = count
        -- one target may have multiple resolved results
        for _, res in ipairs(resolved) do
            local copy = table.deepcopy(res)
            copy.weight = weight / count
            copy.port = answer.port
            copy.priority = answer.priority
            table.insert(resolved_answers, copy)
        end
    end

    -- find the least common multiple of the counts
    local lcm = answer_to_count[answers[1]]
    for i = 2, #answers do
        local count = answer_to_count[answers[i]]
        lcm = count * lcm / gcd(count, lcm)
    end
    -- fix the weight as the weight should be integer
    for _, res in ipairs(resolved_answers) do
        res.weight = res.weight * lcm
    end

    return resolved_answers
end

local client
local function resolve(domain, selector)
    if not client then
        return nil, "no config dns server"
    end
    -- this function will dereference the CNAME records
    local answers, err = client.resolve(domain)
    if not answers then
        return nil, "failed to query the DNS server: " .. err
    end

    if answers.errcode then
        return nil, "server returned error code: " .. answers.errcode .. ": " ..
            answers.errstr
    end

    if selector == _M.RETURN_ALL then
        for _, answer in ipairs(answers) do
            if answer.type == client.TYPE_SRV then
                return resolve_srv(client, answers)
            end
        end
        return answers
    end

    local idx = math.random(1, #answers)
    local answer = answers[idx]
    local dns_type = answer.type
    if dns_type == client.TYPE_A or dns_type == client.TYPE_AAAA then
        return answer
    end

    return nil, "unsupport DNS answer"
end

_M.resolve = resolve

function _M.init()
    --  initialize /etc/hosts
    local hosts, err = dns_utils.parseHosts()
    if not hosts then
        return hosts, err
    end
    HOSTS_IP_MATCH_CACHE = hosts

    local c = config.get('conf')
    local dns_config = c and c.dns or nil
    if dns_config then
        package.loaded["resty.dns.client"] = nil
        local dns = require("resty.dns.client")

        local ok, err = dns.init(dns_config)
        if not ok then
            return nil, "failed to init the dns client: " .. err
        end
        client = dns
    end
end

function _M.parse_domain(host)
    local rev = HOSTS_IP_MATCH_CACHE[host]
    if rev then
        -- use ipv4 in high priority
        local ip = rev["ipv4"]
        if not ip then
            ip = rev["ipv6"]
        end
        if ip then
            return ip
        end
    end
    local ip_info, err = resolve(host)
    if not ip_info then
        return nil, err
    end
    if ip_info.address then
        return ip_info.address
    end

    return nil, "failed to parse domain"
end

return _M
