local ADDON, ns = ...
ns.Untrusted = ns.Untrusted or {}
local MAX_BODY = 254
local handlers = {}
local limits = {}
local buckets = {}
function ns.Untrusted.Text(s, max)
    if type(s) ~= "string" then return "" end
    s = s:gsub("%c", " "):gsub("|", " ")
    if max and #s > max then s = s:sub(1, max) end
    return s
end
function ns.Untrusted.Int(v, min, max, fallback)
    local n = tonumber(v)
    if not n then return fallback end
    n = math.floor(n)
    if n < min or n > max then return fallback end
    return n
end
function ns.Untrusted.Enum(v, registry)
    if type(v) ~= "string" or type(registry) ~= "table" then return nil end
    if registry[v] == nil then return nil end
    return v
end
function ns.Untrusted.Throttle(bucket, key, seconds)
    if type(key) ~= "string" or key == "" then return false end
    local b = buckets[bucket]
    if not b then b = {}; buckets[bucket] = b end
    local now = GetTime()
    local last = b[key]
    if last and now - last < seconds then return false end
    b[key] = now
    return true
end
function ns.Untrusted.OnMessage(prefix, handler, maxBody)
    handlers[prefix] = handler
    limits[prefix] = maxBody or MAX_BODY
end
local recv = CreateFrame("Frame")
recv:RegisterEvent("CHAT_MSG_ADDON")
recv:SetScript("OnEvent", function(_, _, prefix, message, _, sender)
    local handler = prefix and handlers[prefix]
    if not handler then return end
    if type(sender) ~= "string" or sender == "" then return end
    if type(message) ~= "string" or message == "" then return end
    if #message > (limits[prefix] or MAX_BODY) then return end
    handler(sender, message)
end)
ns.untrustedLoaded = true
