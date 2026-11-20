local ADDON, ns = ...
local WAIT_SECONDS = 6
local SETTLE_SECONDS = 1
local pending
local clock = CreateFrame("Frame")
clock:Hide()
local returnPreviewCVar
function ns.PreviewEnabled()
    return GetCVarBool("previewTalents") and true or false
end
function ns.PreviewSpent(group, pet)
    if not ns.PreviewEnabled() then return 0 end
    return GetGroupPreviewTalentPointsSpent(pet and true or false, group) or 0
end
function ns.UnspentPoints(group, pet)
    local n = GetUnspentTalentPoints(false, pet and true or false, group) or 0
    return n - ns.PreviewSpent(group, pet)
end
local function canTouch(group, pet)
    if pending then return false end
    if pet then return group == ns.PetGroup() end
    return group == (GetActiveTalentGroup(false, false) or 1)
        and not (ns.CirclePending and ns.CirclePending())
end
function ns.DisplayRanks(group, pet)
    pet = pet and true or false
    local preview = ns.PreviewEnabled()
    local out = {}
    for tab = 1, GetNumTalentTabs(false, pet) or 0 do
        local col = {}
        for i = 1, GetNumTalents(tab, false, pet) or 0 do
            local _, _, _, _, rank, _, _, _, previewRank = GetTalentInfo(tab, i, false, pet, group)
            col[i] = preview and math.max(previewRank or 0, rank or 0) or rank or 0
        end
        out[tab] = col
    end
    return out
end
local function liveRanks(group, pet)
    pet = pet and true or false
    local out = {}
    for tab = 1, GetNumTalentTabs(false, pet) or 0 do
        local col = {}
        for i = 1, GetNumTalents(tab, false, pet) or 0 do
            col[i] = select(5, GetTalentInfo(tab, i, false, pet, group)) or 0
        end
        out[tab] = col
    end
    return out
end
local function refresh()
    if ns.RefreshWindow then ns.RefreshWindow() end
end
local function startWait(group, expect, label, pet)
    pending = { group = group, pet = pet and true or false, expect = expect, label = label, at = GetTime() }
    clock:Show()
    refresh()
end
function ns.LearnPending()
    return pending ~= nil
end
local function shortfall(a, b)
    local missing, total = 0, 0
    for tab, col in pairs(a) do
        for i, want in pairs(col) do
            local have = (b[tab] and b[tab][i]) or 0
            total = total + want
            if have < want then missing = missing + (want - have) end
        end
    end
    return missing, total
end
local function finishWait(reason)
    local p = pending
    if not p then return end
    pending = nil
    if reason == "timeout" then
        ns.warn(ns.T("msg.learn_timeout"))
    else
        local missing, total = shortfall(p.expect, liveRanks(p.group, p.pet))
        if missing > 0 then ns.warn(ns.T("msg.learn_short", missing)) end
    end
    returnPreviewCVar()
    refresh()
end
function ns.LearnClick(tab, index, mouse, group, pet)
    pet = pet and true or false
    if IsModifiedClick("CHATLINK") then
        local link = GetTalentLink(tab, index, false, pet, group, ns.PreviewEnabled())
        if link and ChatEdit_GetActiveWindow() then ChatEdit_InsertLink(link) end
        return true
    end
    if not canTouch(group, pet) then return false end
    local preview = ns.PreviewEnabled()
    if mouse == "RightButton" then
        if preview then AddPreviewTalentPoints(tab, index, -1, pet, group) end
        return true
    end
    if preview then
        AddPreviewTalentPoints(tab, index, 1, pet, group)
        return true
    end
    local name, _, _, _, rank, maxRank = GetTalentInfo(tab, index, false, pet, group)
    if (rank or 0) >= (maxRank or 0) or (GetUnspentTalentPoints(false, pet, group) or 0) <= 0 then
        return false
    end
    local expect = liveRanks(group, pet)
    expect[tab][index] = (rank or 0) + 1
    LearnTalent(tab, index, pet, group)
    startWait(group, expect, name or "?", pet)
    return true
end
function ns.BorrowPreviewCVar()
    HTP_TalentsDB.previewBorrowed = true
    SetCVar("previewTalents", "1")
end
returnPreviewCVar = function()
    if not (HTP_TalentsDB and HTP_TalentsDB.previewBorrowed) then return end
    local group = GetActiveTalentGroup(false, false) or 1
    if pending or (GetGroupPreviewTalentPointsSpent(false, group) or 0) > 0 then return end
    if (GetGroupPreviewTalentPointsSpent(true, ns.PetGroup()) or 0) > 0 then return end
    HTP_TalentsDB.previewBorrowed = nil
    SetCVar("previewTalents", "0")
end
function ns.LearnCommit(group, pet)
    if not canTouch(group, pet) or ns.PreviewSpent(group, pet) <= 0 then return end
    ns.ShowLearnPopup(group, pet)
end
function ns.LearnCommitNow(group, pet)
    pet = pet and true or false
    if not canTouch(group, pet) then
        if not pet and ns.CirclePending and ns.CirclePending() then ns.warn(ns.T("tip.circle_wait")) end
        return
    end
    local expect = ns.DisplayRanks(group, pet)
    LearnPreviewTalents(pet, group)
    startWait(group, expect, ns.T(pet and "sub.pet" or "sub.mine"), pet)
end
function ns.LearnReset(group, pet)
    pet = pet and true or false
    if group ~= (pet and ns.PetGroup() or GetActiveTalentGroup(false, false) or 1) then return end
    ResetGroupPreviewTalentPoints(pet, group)
    returnPreviewCVar()
    refresh()
end
function ns.LiveEdit(grid, group, pet)
    pet = pet and true or false
    if not grid or group ~= (pet and ns.PetGroup() or GetActiveTalentGroup(false, false) or 1) then return nil end
    local ranks = ns.DisplayRanks(group, pet)
    return {
        live = group,
        onAdd = function(t, i)
            if not ns.PreviewEnabled() then
                local need, pre = ns.BuilderGate(grid, ranks, t, i)
                if need or pre then return end
            end
            ns.LearnClick(t, i, "LeftButton", group, pet)
        end,
        onRemove = function(t, i) ns.LearnClick(t, i, "RightButton", group, pet) end,
        gate = function(t, i) return ns.BuilderGate(grid, ranks, t, i) end,
        branch = function(t) return grid[t] and grid[t].name end,
        left = ns.UnspentPoints(group, pet),
        locked = pending ~= nil,
    }
end
local watch = CreateFrame("Frame")
watch:RegisterEvent("PLAYER_TALENT_UPDATE")
watch:RegisterEvent("PET_TALENT_UPDATE")
watch:RegisterEvent("PLAYER_LEAVING_WORLD")
watch:RegisterEvent("PREVIEW_TALENT_POINTS_CHANGED")
watch:RegisterEvent("PREVIEW_PET_TALENT_POINTS_CHANGED")
watch:RegisterEvent("PLAYER_ENTERING_WORLD")
watch:SetScript("OnEvent", function(_, event)
    if event == "PREVIEW_TALENT_POINTS_CHANGED" or event == "PREVIEW_PET_TALENT_POINTS_CHANGED"
        or event == "PLAYER_ENTERING_WORLD" then
        returnPreviewCVar()
        return
    end
    if not pending then return end
    if event == "PLAYER_LEAVING_WORLD" then pending = nil; return end
    if shortfall(pending.expect, liveRanks(pending.group, pending.pet)) == 0 then
        finishWait("update")
    elseif not pending.seen and (event == "PET_TALENT_UPDATE") == pending.pet then
        pending.seen = GetTime()
    end
end)
clock:SetScript("OnUpdate", function(self)
    if not pending then
        self:Hide()
        return
    end
    local now = GetTime()
    if pending.seen and now - pending.seen > SETTLE_SECONDS then
        finishWait("update")
    elseif now - pending.at > WAIT_SECONDS then
        finishWait(pending.seen and "update" or "timeout")
    end
end)
