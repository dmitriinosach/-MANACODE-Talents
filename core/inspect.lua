local ADDON, ns = ...
local WAIT_SECONDS = 5
local MAX_GROUPS = 2
local function snapGroup(g)
    local ranks, best, bestPts, total, learned = {}, 1, -1, 0, 0
    for tab = 1, GetNumTalentTabs(true) do
        local _, _, pts = GetTalentTabInfo(tab, true, false, g)
        local col, sum = {}, 0
        for i = 1, GetNumTalents(tab, true) do
            local rank = select(5, GetTalentInfo(tab, i, true, false, g)) or 0
            col[i] = rank
            sum = sum + rank
        end
        ranks[tab] = col
        learned = learned + sum
        pts = math.max(pts or 0, sum)
        total = total + pts
        if pts > bestPts then bestPts, best = pts, tab end
    end
    local free = GetUnspentTalentPoints(true, false, g) or 0
    return { ranks = ranks, spec = best, points = total, free = free }, learned
end
function ns.InspectShow(data, g)
    local grp = data.groups and data.groups[g]
    if not grp then return false end
    data.shown = g
    data.ranks, data.spec, data.points, data.free = grp.ranks, grp.spec, grp.points, grp.free
    return true
end
function ns.InspectGroups(data)
    local n = 0
    for _ in pairs((data and data.groups) or {}) do n = n + 1 end
    return n
end
function ns.InspectName(data)
    if ns.InspectGroups(data) > 1 and data.shown then
        return ns.T("status.target_set", data.name, data.shown)
    end
    return data.name
end
function ns.InspectSnapshot(name, class)
    local count = math.min(MAX_GROUPS, (GetNumTalentGroups and GetNumTalentGroups(true)) or 1)
    local active = GetActiveTalentGroup(true) or 1
    if active < 1 or active > MAX_GROUPS then active = 1 end
    local groups, first = {}, nil
    local grp = snapGroup(active)
    if grp.points > 0 then groups[active], first = grp, active end
    for g = 1, count do
        if g ~= active then
            local other, learned = snapGroup(g)
            if learned > 0 then
                groups[g] = other
                first = first or g
            end
        end
    end
    if not first then return nil end
    local data = { name = name, class = class, groups = groups, active = active, at = GetTime() }
    ns.InspectShow(data, groups[active] and active or first)
    return data
end
local pending
local clock = CreateFrame("Frame")
clock:Hide()
function ns.InspectPending()
    return pending ~= nil
end
function ns.InspectFrameBusy()
    local unit = InspectFrame and InspectFrame:IsShown() and InspectFrame.unit
    return unit and UnitExists(unit) and not UnitIsUnit(unit, "target") and true or false
end
function ns.CanInspectTarget()
    if not (UnitExists("target") and UnitIsPlayer("target")) or UnitIsUnit("target", "player") then
        return false, ns.T("msg.need_target_copy")
    end
    if CanInspect and not CanInspect("target") then return false, ns.T("msg.too_far") end
    return true
end
function ns.InspectTarget(onReady, auto)
    local ok, msg = ns.CanInspectTarget()
    if not ok then return false, msg end
    if ns.InspectFrameBusy() then return false, ns.T("msg.inspect_busy") end
    local _, class = UnitClass("target")
    pending = { name = UnitName("target"), class = class, cb = onReady, auto = auto and true or false, at = GetTime() }
    clock:Show()
    NotifyInspect("target")
    return true, nil
end
function ns.InspectMatches(p)
    if not (UnitExists("target") and UnitIsPlayer("target")) then return false end
    local _, class = UnitClass("target")
    return UnitName("target") == p.name and class == p.class
end
local recv = CreateFrame("Frame")
recv:RegisterEvent("INSPECT_TALENT_READY")
recv:RegisterEvent("PLAYER_TARGET_CHANGED")
recv:SetScript("OnEvent", function(_, event)
    local p = pending
    if event == "PLAYER_TARGET_CHANGED" then
        if p and p.auto and not ns.InspectMatches(p) then pending = nil end
        return
    end
    if not p then return end
    if not ns.InspectMatches(p) then return end
    pending = nil
    local data = ns.InspectSnapshot(p.name, p.class)
    if not data then
        if not p.auto then ns.warn(ns.T("msg.target_empty", p.name)) end
        return
    end
    data.auto = p.auto or nil
    p.cb(data)
end)
clock:SetScript("OnUpdate", function(self)
    local p = pending
    if not p then
        self:Hide()
        return
    end
    if GetTime() - p.at > WAIT_SECONDS then
        pending = nil
        if not p.auto then ns.warn(ns.T("msg.inspect_timeout", p.name)) end
    end
end)
