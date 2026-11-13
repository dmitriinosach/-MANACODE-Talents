local ADDON, ns = ...
local SHARE_PREFIX = "htpBuild"
local PROTO = 1
local MAX_BODY = 254 - #SHARE_PREFIX
local MAX_TABS = 3
local MAX_TALENTS = 40
local MAX_RANK = 5
local MAX_NAME = 80
local RECV_THROTTLE = 5
local RECV_ALL_THROTTLE = 1
local PONG_THROTTLE = 5
local PING_EVERY = 10
local PONG_WAIT = 4
local PEER_YES_TTL = 600
local PEER_NO_TTL = 60
local OFFER_WAIT = 60
ns.SHARE_POPUP_TIME = 45
local function utf8Cut(s, max)
    if #s <= max then return s end
    s = s:sub(1, max)
    local i = #s
    while i > 0 and s:byte(i) >= 0x80 and s:byte(i) < 0xC0 do i = i - 1 end
    local lead = i > 0 and s:byte(i) or 0
    if lead >= 0xC0 then
        local need = (lead >= 0xF0 and 4) or (lead >= 0xE0 and 3) or 2
        if #s - i + 1 < need then s = s:sub(1, i - 1) end
    end
    return s
end
local function encodeBuild(class, spec, name, ranks)
    local parts = {}
    for tab = 1, MAX_TABS do
        local r, s, last = ranks[tab] or {}, {}, 0
        for i, v in pairs(r) do
            if type(i) == "number" and (v or 0) ~= 0 and i > last then last = i end
        end
        for i = 1, last do s[i] = tostring(r[i] or 0) end
        parts[tab] = table.concat(s)
    end
    name = utf8Cut((name or ""):gsub("[|;%c]", " "), MAX_NAME)
    return table.concat({ class, tostring(spec or 1), name, table.concat(parts, ";") }, "|")
end
local function decodeBuild(msg)
    local class, spec, name, body = strmatch(msg or "", "^([^|]*)|([^|]*)|([^|]*)|(.*)$")
    if not class or not body then return nil end
    class = ns.Untrusted.Enum(class, ns.specs)
    if not class then return nil end
    local ranks, tab = {}, 0
    for chunk in string.gmatch(body .. ";", "([^;]*);") do
        tab = tab + 1
        if tab > MAX_TABS then break end
        local r = {}
        for i = 1, math.min(#chunk, MAX_TALENTS) do
            r[i] = ns.Untrusted.Int(strsub(chunk, i, i), 0, MAX_RANK, 0)
        end
        ranks[tab] = r
    end
    return { class = class, spec = ns.Untrusted.Int(spec, 1, MAX_TABS, 1),
             name = utf8Cut(ns.Untrusted.Text(name, MAX_NAME), MAX_NAME), ranks = ranks }
end
local function validRanks(class, ranks)
    local grid = ns.talentgrids and ns.talentgrids[class]
    if not grid or type(ranks) ~= "table" then return false end
    local total = 0
    for tab, r in pairs(ranks) do
        local t = grid[tab]
        if not t then return false end
        local caps = {}
        for _, tal in ipairs(t.talents) do caps[tal.index] = tal.max or 0 end
        for i, v in pairs(r) do
            if type(v) ~= "number" or v < 0 or v > (caps[i] or 0) then return false end
            total = total + v
        end
    end
    if total <= 0 or total > ns.MAX_TALENT_POINTS then return false end
    return ns.BuilderValid(grid, ranks)
end
local NOTE_CHUNK = MAX_BODY - #"!N|999|9|9|"
local NOTE_PARTS = 6
local GLYPH_ID_MAX = 99999
local function encodePlan(plan)
    plan = ns.PlanCopy and ns.PlanCopy(plan)
    local out = {}
    if not plan then return out end
    if plan.glyphs then
        local kinds = {}
        for k, kind in ipairs({ "major", "minor" }) do
            local ids = {}
            for i = 1, 3 do ids[i] = tostring(plan.glyphs[kind][i] or 0) end
            kinds[k] = table.concat(ids, ",")
        end
        out[#out + 1] = "G|" .. table.concat(kinds, ";")
    end
    if plan.note then
        local parts, rest = {}, plan.note:gsub("[|%c]", " ")
        while rest ~= "" and #parts < NOTE_PARTS do
            local piece = utf8Cut(rest, NOTE_CHUNK)
            if piece == "" then break end
            parts[#parts + 1] = piece
            rest = rest:sub(#piece + 1)
        end
        for k, piece in ipairs(parts) do
            out[#out + 1] = "N|" .. k .. "|" .. #parts .. "|" .. piece
        end
    end
    return out
end
local function decodeGlyphs(class, body)
    local lists = ns.glyphItems and ns.glyphItems[class]
    if not lists then return nil end
    local known = {}
    for _, kind in ipairs({ "major", "minor" }) do
        for _, id in ipairs(lists[kind] or {}) do known[id] = kind end
    end
    local g = { major = {}, minor = {} }
    local k = 0
    for chunk in string.gmatch((body or "") .. ";", "([^;]*);") do
        k = k + 1
        local kind = (k == 1 and "major") or (k == 2 and "minor") or nil
        if not kind then break end
        local i = 0
        for v in string.gmatch(chunk .. ",", "([^,]*),") do
            i = i + 1
            if i > 3 then break end
            local id = ns.Untrusted.Int(v, 0, GLYPH_ID_MAX, 0)
            if id > 0 and known[id] == kind then g[kind][i] = id end
        end
    end
    return ns.GlyphPlanCopy and ns.GlyphPlanCopy(g) or nil
end
local function send(body, target)
    SendAddonMessage(SHARE_PREFIX, body, "WHISPER", target)
end
local function ownVersion()
    local v = GetAddOnMetadata and GetAddOnMetadata(ADDON, "Version")
    return (type(v) == "string" and v ~= "") and v or "?"
end
local function changed()
    if ns.RefreshWindow then ns.RefreshWindow() end
end
local peers = {}
local outgoing = {}
local seq = 0
local function peerState(name)
    local p = peers[name]
    if not p then return "unknown" end
    if p.state == "asking" then return "asking" end
    local ttl = (p.state == "yes") and PEER_YES_TTL or PEER_NO_TTL
    if GetTime() - p.at >= ttl then return "unknown" end
    return p.state, p.ver
end
local function probe(name)
    local p = peers[name]
    local now = GetTime()
    if p and p.state == "asking" then return true end
    if p and p.askedAt and now - p.askedAt < PING_EVERY then return false end
    peers[name] = { state = "asking", at = p and p.at or now, askedAt = now, ver = p and p.ver }
    send("!P|" .. PROTO .. "|" .. ownVersion(), name)
    return true
end
local function sendOffer(name, o)
    seq = seq % 999 + 1
    o.phase, o.id, o.at = "offer", seq, GetTime()
    for _, extra in ipairs(o.extras or {}) do
        local kind, rest = extra:match("^(%u)|(.*)$")
        send("!" .. kind .. "|" .. seq .. "|" .. rest, name)
    end
    send("!O|" .. seq .. "|" .. o.payload, name)
end
local function sendLegacy(name, o)
    outgoing[name] = nil
    send(o.payload, name)
    ns.say(ns.T("msg.share_legacy", name, o.build))
end
function ns.ShareTargetState(doProbe)
    local st = { addon = "unknown", waiting = false }
    if not (UnitExists("target") and UnitIsPlayer("target")) then
        st.off = ns.T("msg.need_target_share")
    elseif UnitIsUnit("target", "player") then
        st.off = ns.T("msg.share_self")
    end
    if st.off then st.tip = st.off; return st end
    local name, realm = UnitName("target")
    local _, class = UnitClass("target")
    st.name, st.class = name, class
    if realm and realm ~= "" then
        st.off = ns.T("msg.share_realm", name)
    elseif UnitFactionGroup("target") ~= UnitFactionGroup("player") then
        st.off = ns.T("msg.share_faction", name)
    elseif outgoing[name] then
        st.waiting = true
        st.off = ns.T("msg.share_wait", name)
    end
    if doProbe and not st.off and not InCombatLockdown() and peerState(name) == "unknown" then
        probe(name)
    end
    st.addon, st.version = peerState(name)
    if st.off then st.tip = st.off
    elseif st.addon == "yes" then st.tip = ns.T("tip.share_has", name, st.version or "?")
    elseif st.addon == "no" then st.tip = ns.T("tip.share_none", name)
    elseif st.addon == "asking" then st.tip = ns.T("tip.share_asking", name)
    else st.tip = ns.T("tip.share_target") end
    return st
end
function ns.ShareToTarget(ranks, spec, name, class, plan)
    local st = ns.ShareTargetState(false)
    if st.off then return false, st.off end
    if not class then local _, c = UnitClass("player"); class = c end
    if not validRanks(class, ranks or {}) then return false, ns.T("msg.share_invalid") end
    local build = (name and name ~= "") and name or ns.T("msg.unknown_name")
    local payload = encodeBuild(class, spec, name, ranks)
    if #payload + #"!O|999|" > MAX_BODY then return false, ns.T("msg.too_big") end
    local target = st.name
    local o = { phase = "probe", payload = payload, build = build, at = GetTime(), extras = encodePlan(plan) }
    outgoing[target] = o
    if st.addon == "yes" then
        sendOffer(target, o)
    elseif st.addon == "no" or not probe(target) then
        sendLegacy(target, o)
    end
    changed(target)
    return true, nil
end
ns.ShareBuild = ns.ShareToTarget
local REPLY_MSG = {
    A = "msg.share_accepted", D = "msg.share_declined", T = "msg.share_expired",
    B = "msg.share_busy", C = "msg.share_combat", F = "msg.share_full", X = "msg.share_rejected",
}
local function tick(now)
    for name, p in pairs(peers) do
        if p.state == "asking" and now - p.askedAt >= PONG_WAIT then
            p.state, p.at = "no", now
            local o = outgoing[name]
            if o and o.phase == "probe" then sendLegacy(name, o) end
            changed(name)
        end
    end
    for name, o in pairs(outgoing) do
        if o.phase == "offer" and now - o.at >= OFFER_WAIT then
            outgoing[name] = nil
            ns.say(ns.T("msg.share_timeout", name, o.build))
            changed(name)
        end
    end
end
local ticker = CreateFrame("Frame")
local acc = 0
ticker:SetScript("OnUpdate", function(_, elapsed)
    acc = acc + (elapsed or 0)
    if acc < 0.5 then return end
    acc = 0
    if next(outgoing) or next(peers) then tick(GetTime()) end
end)
local pending
local deferred
function ns.PendingSharedBuild()
    return pending and pending.data
end
local function reply(p, code)
    if p.id then send("!R|" .. p.id .. "|" .. code, p.sender) end
end
local function slotsFull(class)
    return #ns.CustomBuilds(class) >= ns.MAX_CUSTOM_BUILDS
end
local function present(p)
    pending = p
    local shown = ns.OnBuildReceived and ns.OnBuildReceived(p.sender, p.data)
    if not shown then
        pending = nil
        reply(p, "B")
    end
end
function ns.SavePendingShared()
    local p = pending
    if not p then return false, ns.T("msg.nothing_to_save") end
    pending = nil
    local ok, msg = ns.SaveCopiedBuild(p.data)
    reply(p, ok and "A" or "F")
    return ok, msg
end
function ns.DeclinePendingShared(expired)
    local p = pending
    if not p then return end
    pending = nil
    reply(p, expired and "T" or "D")
end
local function receive(sender, data, id)
    local p = { sender = sender, data = data, id = id }
    local build = (data.name ~= "" and data.name) or ns.T("msg.unknown_name")
    if not validRanks(data.class, data.ranks) then
        reply(p, "X")
        return
    end
    if pending then reply(p, "B"); return end
    if InCombatLockdown() then
        if not id then deferred = p; return end
        reply(p, "C")
        ns.say(ns.T("msg.recv_combat", sender, build))
        return
    end
    if slotsFull(data.class) then
        reply(p, "F")
        ns.say(ns.T("msg.recv_full", sender, build, ns.MAX_CUSTOM_BUILDS, ns.ClassName(data.class)))
        return
    end
    present(p)
end
local extras = {}
local EXTRAS_MAX = 20
local function extraFor(sender, id)
    if not id then return nil end
    local e = extras[sender]
    if not (e and e.id == id) then
        local n = 0
        for _ in pairs(extras) do n = n + 1 end
        if n >= EXTRAS_MAX then wipe(extras) end
        e = { id = id, parts = {} }
        extras[sender] = e
    end
    return e
end
local function attachExtras(sender, id, data)
    local e = extras[sender]
    extras[sender] = nil
    if not (e and e.id == id) then return end
    if e.glyphs then data.glyphs = decodeGlyphs(data.class, e.glyphs) end
    if e.n then
        local text = {}
        for k = 1, e.n do
            if not e.parts[k] then return end
            text[k] = e.parts[k]
        end
        local note = strtrim(ns.Untrusted.Text(table.concat(text), NOTE_CHUNK * NOTE_PARTS))
        data.note = note ~= "" and note or nil
    end
end
local function handle(sender, message)
    sender = ns.Untrusted.Text(sender, 64)
    if sender == "" then return end
    local kind, rest = strmatch(message, "^!(%u)|(.*)$")
    if kind == "G" then
        local id, body = strmatch(rest, "^(%d+)|([%d,;]*)$")
        local e = extraFor(sender, ns.Untrusted.Int(id, 1, 999))
        if e then e.glyphs = body end
        return
    elseif kind == "N" then
        local id, k, n, text = strmatch(rest, "^(%d+)|(%d+)|(%d+)|(.*)$")
        k, n = ns.Untrusted.Int(k, 1, NOTE_PARTS), ns.Untrusted.Int(n, 1, NOTE_PARTS)
        local e = k and n and k <= n and extraFor(sender, ns.Untrusted.Int(id, 1, 999))
        if e then
            e.n = n
            e.parts[k] = ns.Untrusted.Text(text, NOTE_CHUNK)
        end
        return
    end
    if not kind then
        local data = decodeBuild(message)
        if not data then return end
        if not ns.Untrusted.Throttle("buildRecv", sender, RECV_THROTTLE) then return end
        receive(sender, data, nil)
    elseif kind == "P" then
        local p = peers[sender]
        if not (p and p.state == "asking") then
            peers[sender] = { state = "yes", at = GetTime(), askedAt = p and p.askedAt,
                              ver = ns.Untrusted.Text(strmatch(rest, "^%d+|([%w%.%-]*)$"), 16) }
        end
        if ns.Untrusted.Throttle("sharePong", sender, PONG_THROTTLE) then
            send("!H|" .. PROTO .. "|" .. ownVersion(), sender)
        end
    elseif kind == "H" then
        local p = peers[sender]
        if not (p and p.askedAt) then return end
        local proto, ver = strmatch(rest, "^(%d+)|([%w%.%-]*)$")
        if not ns.Untrusted.Int(proto, PROTO, 99) then return end
        p.state, p.at, p.ver = "yes", GetTime(), ns.Untrusted.Text(ver, 16)
        local o = outgoing[sender]
        if o and o.phase == "probe" then sendOffer(sender, o) end
        changed(sender)
    elseif kind == "O" then
        local id, body = strmatch(rest, "^(%d+)|(.*)$")
        id = ns.Untrusted.Int(id, 1, 999)
        local data = id and decodeBuild(body)
        if not data then return end
        attachExtras(sender, id, data)
        if not ns.Untrusted.Throttle("buildRecv", sender, RECV_THROTTLE) then return end
        if not ns.Untrusted.Throttle("buildRecvAll", "all", RECV_ALL_THROTTLE) then
            reply({ sender = sender, id = id }, "B")
            return
        end
        local p = peers[sender]
        if not (p and p.state == "asking") then
            peers[sender] = { state = "yes", at = GetTime(), askedAt = p and p.askedAt, ver = p and p.ver }
        end
        receive(sender, data, id)
    elseif kind == "R" then
        local id, code = strmatch(rest, "^(%d+)|(%u)$")
        local o = outgoing[sender]
        if not (o and o.phase == "offer" and tonumber(id) == o.id and REPLY_MSG[code]) then return end
        outgoing[sender] = nil
        ns.say(ns.T(REPLY_MSG[code], sender, o.build))
        changed(sender)
    end
end
ns.Untrusted.OnMessage(SHARE_PREFIX, handle)
local combat = CreateFrame("Frame")
combat:RegisterEvent("PLAYER_REGEN_ENABLED")
combat:SetScript("OnEvent", function()
    local p = deferred
    deferred = nil
    if p and not pending then receive(p.sender, p.data, p.id) end
end)
ns.ShareInternals = {
    encode = encodeBuild, decode = decodeBuild, valid = validRanks, encodePlan = encodePlan,
    handle = handle, tick = tick, maxBody = MAX_BODY, prefix = SHARE_PREFIX,
}
