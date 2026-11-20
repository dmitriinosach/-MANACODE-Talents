local ADDON, ns = ...
local SPELLS = { 63644, 63645 }
local TICK = 0.05
local EXPECT = 0.6
local DISMOUNT_WAIT = 1
local current
local names
local expectUntil = 0
local listeners = {}
local ticker = CreateFrame("Frame")
ticker:Hide()
local function specNames()
    if not names then
        names = {}
        for _, id in ipairs(SPELLS) do
            local n = GetSpellInfo(id)
            if n then names[n] = true end
        end
    end
    return names
end
function ns.OnSpecCast(fn)
    listeners[#listeners + 1] = fn
end
function ns.SpecCast()
    return current
end
function ns.SpecCastProgress(st)
    local span = st.finish - st.start
    if span <= 0 then return 1 end
    return math.min(1, math.max(0, (GetTime() - st.start) / span))
end
function ns.SpecCastLeft(st)
    return math.max(0, st.finish - GetTime())
end
function ns.SpecCastExpect()
    expectUntil = GetTime() + EXPECT
end
local function fire()
    for _, fn in ipairs(listeners) do fn(current) end
end
local function refresh()
    if ns.RefreshWindow then ns.RefreshWindow() end
    if ns.QuickRefresh then ns.QuickRefresh() end
end
local function poll()
    local was = current
    local name, _, _, _, startMs, endMs = UnitCastingInfo("player")
    if name and startMs and endMs and (specNames()[name] or GetTime() < expectUntil) then
        local start, finish = startMs / 1000, endMs / 1000
        if current then
            current.start, current.finish = start, finish
        else
            current = { to = 3 - (GetActiveTalentGroup() or 1), start = start, finish = finish, name = name }
        end
    else
        current = nil
    end
    if current then ticker:Show() else ticker:Hide() end
    if was ~= current then
        fire()
        refresh()
    end
end
local function drop()
    expectUntil = 0
    if not current then return end
    current = nil
    ticker:Hide()
    fire()
    refresh()
end
local afterDismount
local mountWait = CreateFrame("Frame")
local function cast(group)
    ns.SpecCastExpect()
    SetActiveTalentGroup(group)
end
local function mountStep(self)
    local w = afterDismount
    if not w then
        self:SetScript("OnUpdate", nil)
        return
    end
    local mounted = IsMounted and IsMounted()
    if mounted and GetTime() < w.till then return end
    afterDismount = nil
    self:SetScript("OnUpdate", nil)
    if mounted then
        ns.warn(ns.T("msg.spec_mounted"))
    elseif not InCombatLockdown() then
        cast(w.group)
    end
    refresh()
end
function ns.ActivateSpec(group)
    if afterDismount then
        if IsMounted and IsMounted() then return true end
        afterDismount = nil
    end
    if InCombatLockdown() then
        ns.warn(ns.T("msg.spec_combat"))
        return false
    end
    if IsFlying and IsFlying() then
        ns.warn(ns.T("msg.spec_flying"))
        return false
    end
    if UnitInVehicle and UnitInVehicle("player") then
        ns.warn(ns.T("msg.spec_vehicle"))
        return false
    end
    if IsMounted and IsMounted() and Dismount then
        Dismount()
        afterDismount = { group = group, till = GetTime() + DISMOUNT_WAIT }
        mountWait:SetScript("OnUpdate", mountStep)
        return true
    end
    cast(group)
    return true
end
local watch = CreateFrame("Frame")
for _, ev in ipairs({ "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_DELAYED", "UNIT_SPELLCAST_STOP",
                      "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_FAILED_QUIET", "UNIT_SPELLCAST_INTERRUPTED",
                      "UNIT_SPELLCAST_SUCCEEDED", "UI_ERROR_MESSAGE",
                      "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_LEAVING_WORLD" }) do
    watch:RegisterEvent(ev)
end
watch:SetScript("OnEvent", function(_, event, unit)
    if event:sub(1, 5) == "UNIT_" and unit ~= "player" then return end
    if event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_STOP" then
        drop()
        return
    end
    if event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_FAILED_QUIET" or event == "UI_ERROR_MESSAGE" then
        if event == "UI_ERROR_MESSAGE" and GetTime() >= expectUntil then return end
        expectUntil = 0
        poll()
        return
    end
    if event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "PLAYER_LEAVING_WORLD" then
        expectUntil = 0
        if current then
            current = nil
            ticker:Hide()
            fire()
            refresh()
        end
        return
    end
    poll()
end)
local acc = 0
ticker:SetScript("OnUpdate", function(_, elapsed)
    acc = acc + elapsed
    if acc < TICK then return end
    acc = 0
    poll()
    if current then fire() end
end)
