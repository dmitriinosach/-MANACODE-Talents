local ADDON, ns = ...
local WAIT_SECONDS = 6
local SLOT = 2
local GLYPH_MINOR = 2
local pending
local clock = CreateFrame("Frame")
clock:Hide()
local LATE_SECONDS = 20
local late
function ns.CircleThirdSet()
    return HTP_TalentsDB.circleSet3 == true and (GetNumTalentGroups() or 1) >= SLOT
end
local function slotSig()
    local snap = ns.SnapshotTalents(SLOT)
    return ns.RanksSig(snap and snap.ranks)
end
local function classCaps()
    local _, class = UnitClass("player")
    local grid = ns.talentgrids and ns.talentgrids[class]
    if not grid then return nil end
    local caps = {}
    for tab, t in ipairs(grid) do
        caps[tab] = {}
        for _, tal in ipairs(t.talents) do caps[tab][tal.index] = tal.max end
    end
    return caps
end
local function fits(old)
    local caps = classCaps()
    if not caps or type(old) ~= "table" then return false end
    if old.loaded ~= nil and old.loaded ~= SLOT and old.loaded ~= 3 then return false end
    local snaps = 0
    for _, snap in pairs(type(old.snap) == "table" and old.snap or {}) do
        snaps = snaps + 1
        local ranks = type(snap) == "table" and snap.ranks
        if type(ranks) ~= "table" then return false end
        for tab = 1, #caps do
            local col = ranks[tab]
            if type(col) ~= "table" or #col ~= #caps[tab] then return false end
            for i, r in ipairs(col) do
                if type(r) ~= "number" or r < 0 or r > caps[tab][i] then return false end
            end
        end
    end
    if snaps > 0 then return true end
    local any = false
    for _, s in pairs(type(old.sig) == "table" and old.sig or {}) do
        if type(s) ~= "string" then return false end
        local tab = 0
        for part in (s .. ";"):gmatch("([^;]*);") do
            tab = tab + 1
            local cap = caps[tab]
            if not cap or #part > #cap or part:find("%D") then return false end
            for i = 1, #part do
                if tonumber(part:sub(i, i)) > cap[i] then return false end
            end
            any = any or #part > 0
        end
    end
    return any
end
local function adoptLegacy()
    local old = HTP_TalentsDB.circle
    if old == nil then return nil end
    HTP_TalentsDB.circle = nil
    if not fits(old) then return nil end
    old.loaded = old.loaded or SLOT
    return old
end
local function state()
    local ch, stored = ns.CharDB()
    local c = ch.circle
    if not c then
        c = (stored and adoptLegacy()) or { loaded = SLOT, sig = { [SLOT] = slotSig() } }
        ch.circle = c
    end
    c.sig = c.sig or {}
    return c
end
local function capture(c)
    local snap = ns.SnapshotTalents(SLOT)
    if not snap or snap.points == 0 then return end
    local glyphs = {}
    for id = 1, NUM_GLYPH_SLOTS or 6 do
        local enabled, kind, spell, icon = GetGlyphSocketInfo(id, SLOT)
        glyphs[id] = { enabled = enabled and true or false, major = kind ~= GLYPH_MINOR, spell = spell, icon = icon }
    end
    c.snap = c.snap or {}
    c.snap[c.loaded or SLOT] = { ranks = ns.CopyRanks(snap.ranks), spec = snap.spec, points = snap.points, glyphs = glyphs }
end
function ns.CircleSnap(n)
    if not ns.CircleThirdSet() then return nil end
    local c = state()
    return c.snap and c.snap[n] or nil
end
function ns.CircleSnapSlots(n)
    local snap = ns.CircleSnap(n)
    if not (snap and snap.glyphs) then return nil, nil end
    local major, minor = {}, {}
    for id, g in ipairs(snap.glyphs) do
        local slot = { id = id, enabled = g.enabled, major = g.major, spell = g.spell, icon = g.icon,
                       name = g.spell and GetSpellInfo(g.spell) or nil, stored = true }
        if slot.major then major[#major + 1] = slot else minor[#minor + 1] = slot end
    end
    return major, minor
end
function ns.CircleLoaded()
    if not ns.CircleThirdSet() then return SLOT end
    return state().loaded or SLOT
end
function ns.CirclePending()
    return pending ~= nil
end
function ns.CircleInit()
    if ns.CircleThirdSet() then capture(state()) end
end
local function refresh()
    if ns.RefreshWindow then ns.RefreshWindow() end
end
function ns.CircleLoad(n)
    if not ns.CircleThirdSet() or pending or (n ~= 2 and n ~= 3) then return end
    local c = state()
    if c.loaded == n then return end
    late = nil
    if InCombatLockdown() then
        ns.warn(ns.T("msg.circle_combat"))
        return
    end
    if ns.LearnPending() then
        ns.warn(ns.T("msg.learn_busy"))
        return
    end
    local before = slotSig()
    c.sig[c.loaded] = before
    capture(c)
    pending = { want = n, before = before, seen = false, at = GetTime() }
    clock:Show()
    SendChatMessage(".spec " .. n, "WHISPER", nil, UnitName("player"))
    refresh()
end
local function finish(ok)
    local p = pending
    pending = nil
    if not p then return end
    if ok then
        local c = state()
        c.loaded = p.want
        c.sig[p.want] = slotSig()
        capture(c)
        ns.View.group = SLOT
        ns.View.Live()
        if ns.GearCheck then ns.GearCheck() end
    else
        ns.warn(ns.T("msg.circle_timeout", p.want))
        late = { want = p.want, before = p.before, till = GetTime() + LATE_SECONDS }
    end
    refresh()
end
local function recognize()
    local snap = ns.SnapshotTalents(SLOT)
    if not snap or snap.points == 0 then return end
    local c = state()
    local s = ns.RanksSig(snap.ranks)
    if late and GetTime() > late.till then late = nil end
    if late and s ~= late.before and not c.sig[late.want] and c.loaded ~= late.want then
        c.loaded = late.want
        c.sig[late.want] = s
        late = nil
        capture(c)
        if ns.GearCheck then ns.GearCheck() end
        return
    end
    if s == c.sig[c.loaded] then
        if not (c.snap and c.snap[c.loaded]) then capture(c) end
        return
    end
    local other = c.loaded == SLOT and 3 or SLOT
    if c.sig[other] and s == c.sig[other] then
        c.loaded = other
    else
        c.sig[c.loaded] = s
    end
    capture(c)
end
local watch = CreateFrame("Frame")
watch:RegisterEvent("PLAYER_TALENT_UPDATE")
watch:RegisterEvent("PLAYER_LEAVING_WORLD")
watch:RegisterEvent("GLYPH_ADDED")
watch:RegisterEvent("GLYPH_REMOVED")
watch:RegisterEvent("GLYPH_UPDATED")
watch:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LEAVING_WORLD" then
        pending, late = nil, nil
        return
    end
    if not ns.CircleThirdSet() then return end
    if event ~= "PLAYER_TALENT_UPDATE" then
        if not pending and (GetActiveTalentGroup() or 1) == SLOT then capture(state()) end
        return
    end
    if not pending then
        recognize()
        return
    end
    if slotSig() ~= pending.before then
        finish(true)
    else
        pending.seen = true
    end
end)
clock:SetScript("OnUpdate", function(self)
    local p = pending
    if not p then
        self:Hide()
        return
    end
    if GetTime() - p.at <= WAIT_SECONDS then return end
    finish(p.seen)
end)
