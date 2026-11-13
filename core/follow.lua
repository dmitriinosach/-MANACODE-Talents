local ADDON, ns = ...
local DELAY = 0.3
local MIN_GAP = 1.5
local V = ns.View
local dueAt = 0
local lastSent = -MIN_GAP
local afterCombat = false
function ns.FollowEnabled()
    return HTP_TalentsDB.followTarget == true
end
local function refresh()
    if ns.RefreshWindow then ns.RefreshWindow() end
end
local function onGlyphs()
    return ns.ViewOnGlyphs and ns.ViewOnGlyphs() or false
end
local function autoShown()
    return V.Mode() == "inspect" and V.inspect ~= nil and V.inspect.auto == true
end
local function free()
    if onGlyphs() then return false end
    return (V.Mode() == "live" and V.Own()) or autoShown()
end
local function onReady(data)
    if not ns.FollowEnabled() then return end
    if free() and UnitName("target") == data.name then
        V.ShowInspect(data)
    else
        V.inspect = data
    end
    refresh()
end
local function goHome()
    if autoShown() and ns.Home then ns.Home() end
end
local function check()
    if not (ns.FollowEnabled() and ns.WindowShown and ns.WindowShown()) then return end
    if not ns.CanInspectTarget() then
        goHome()
        return
    end
    if InCombatLockdown() then
        afterCombat = true
        return
    end
    if ns.InspectFrameBusy() then
        ns.FollowTarget()
        dueAt = GetTime() + MIN_GAP
        return
    end
    lastSent = GetTime()
    ns.InspectTarget(onReady, true)
end
local timer = CreateFrame("Frame")
timer:Hide()
timer:SetScript("OnUpdate", function(self)
    local now = GetTime()
    if now < dueAt or ns.InspectPending() or now - lastSent < MIN_GAP then return end
    self:Hide()
    check()
end)
function ns.FollowTarget()
    if not ns.FollowEnabled() then return end
    dueAt = GetTime() + DELAY
    timer:Show()
end
local FRESH = 30
local function targetPlayer()
    return UnitExists("target") and UnitIsPlayer("target") and not UnitIsUnit("target", "player") and true or false
end
function ns.TargetTab()
    if targetPlayer() then
        local _, class = UnitClass("target")
        return { label = ns.T("mini.target_label", UnitName("target")), tip = ns.T("tip.target_tab"),
                 class = class, off = false }
    end
    local d = V.inspect
    if d then
        return { label = ns.T("mini.inspect_label", d.name), tip = ns.T("tip.target_last", d.name),
                 class = d.class, off = false }
    end
    return { label = ns.T("sub.target"), tip = ns.T("tip.target_none"), off = true }
end
function ns.ShowTarget()
    if targetPlayer() then
        local d = V.inspect
        if d and d.name == UnitName("target") and GetTime() - (d.at or 0) <= FRESH then
            V.ShowInspect(d)
            refresh()
            return
        end
        local _, msg = ns.InspectTarget(function(data)
            V.ShowInspect(data)
            refresh()
        end)
        if msg then ns.warn(msg) end
        return
    end
    if V.inspect then
        V.ShowInspect(V.inspect)
        refresh()
    end
end
local watch = CreateFrame("Frame")
watch:RegisterEvent("PLAYER_TARGET_CHANGED")
watch:RegisterEvent("PLAYER_REGEN_ENABLED")
watch:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" then
        if not afterCombat then return end
        afterCombat = false
    end
    ns.FollowTarget()
end)
