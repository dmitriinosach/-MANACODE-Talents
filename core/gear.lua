local ADDON, ns = ...
local DELAY = 0.6
local TRY_EVERY, TRIES = 0.5, 10
function ns.GearSets()
    local out = {}
    for i = 1, (GetNumEquipmentSets and GetNumEquipmentSets() or 0) do
        local name = GetEquipmentSetInfo(i)
        if name then out[#out + 1] = name end
    end
    return out
end
function ns.GearExists(name)
    if not name then return false end
    if not GetEquipmentSetInfoByName then return true end
    return GetEquipmentSetInfoByName(name) ~= nil
end
local function buildGear()
    local ch = ns.CharDB()
    ch.buildGear = ch.buildGear or {}
    return ch.buildGear
end
function ns.BuildGear(ranks)
    local sig = ranks and ns.RanksSig(ranks)
    return sig and buildGear()[sig] or nil
end
function ns.SetBuildGear(ranks, name)
    local sig = ranks and ns.RanksSig(ranks)
    if not sig then return end
    buildGear()[sig] = name
end
local function busy(name)
    return (InCombatLockdown() or (UnitCastingInfo and UnitCastingInfo("player"))
        or (EquipmentSetContainsLockedItems and EquipmentSetContainsLockedItems(name))) and true or false
end
local runner = CreateFrame("Frame")
runner:Hide()
runner:SetScript("OnUpdate", function(self, dt)
    self.wait = self.wait - dt
    if self.wait > 0 then return end
    self.wait = TRY_EVERY
    self.tries = self.tries + 1
    local name = self.name
    local wait = busy(name)
    if wait and self.tries < TRIES then return end
    self:Hide()
    if wait then
        ns.warn(ns.T("msg.gear_busy", name))
    else
        UseEquipmentSet(name)
    end
end)
function ns.WearGear(name)
    if not (name and UseEquipmentSet) or not ns.GearExists(name) then return end
    if not busy(name) then
        runner:Hide()
        UseEquipmentSet(name)
        return
    end
    runner.name, runner.tries, runner.wait = name, 0, TRY_EVERY
    runner:Show()
end
local function setKey()
    local g = GetActiveTalentGroup(false, false) or 1
    if g == 2 and ns.CircleLoaded() == 3 then return "3" end
    return tostring(g)
end
local lastSig, lastKey
function ns.GearCheck()
    local snap = ns.SnapshotTalents(GetActiveTalentGroup(false, false) or 1)
    if not snap then return end
    if lastSig == nil and (snap.points or 0) == 0 then return end
    local sig, key = ns.RanksSig(snap.ranks), setKey()
    local first = lastSig == nil
    local sigChanged, keyChanged = sig ~= lastSig, key ~= lastKey
    lastSig, lastKey = sig, key
    if first or not (sigChanged or keyChanged) then return end
    local bound = buildGear()[sig]
    if bound and (sigChanged or keyChanged) then
        ns.WearGear(bound)
    elseif keyChanged then
        ns.WearGear(ns.QuickGear()[key])
    end
end
local watch = CreateFrame("Frame")
for _, ev in ipairs({ "PLAYER_ENTERING_WORLD", "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_TALENT_UPDATE" }) do
    watch:RegisterEvent(ev)
end
watch:SetScript("OnEvent", function(self)
    self.wait = DELAY
    self:Show()
end)
watch:SetScript("OnUpdate", function(self, dt)
    self.wait = (self.wait or 0) - dt
    if self.wait > 0 then return end
    self:Hide()
    ns.GearCheck()
end)
watch:Hide()
