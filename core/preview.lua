local ADDON, ns = ...
local function makePlan(ranks, group)
    local plan, wanted, conflicts = {}, 0, 0
    for tab = 1, GetNumTalentTabs(false, false) do
        local r = ranks[tab] or {}
        for i = 1, GetNumTalents(tab, false, false) do
            local _, _, tier, col, rank, maxRank = GetTalentInfo(tab, i, false, false, group)
            rank = rank or 0
            local target = math.min(r[i] or 0, maxRank or 0)
            if rank > target then
                conflicts = conflicts + 1
            elseif target > rank then
                local preTier = GetTalentPrereqs(tab, i, false, false, group)
                tinsert(plan, { tab = tab, index = i, tier = tier or 1, col = col or 1,
                                add = target - rank, sameTier = (preTier ~= nil and preTier == tier) })
                wanted = wanted + (target - rank)
            end
        end
    end
    table.sort(plan, function(a, b)
        if a.tier ~= b.tier then return a.tier < b.tier end
        if a.sameTier ~= b.sameTier then return not a.sameTier end
        return a.col < b.col
    end)
    return plan, wanted, conflicts
end
function ns.FillPreview(ranks, group)
    if not ranks then return false, { ns.T("msg.no_pick") } end
    if group ~= (GetActiveTalentGroup(false, false) or 1) then return false, { ns.T("msg.inactive") } end
    if (GetUnspentTalentPoints(false, false, group) or 0) <= 0 then
        return false, { ns.T("msg.no_points") }
    end
    if (GetGroupPreviewTalentPointsSpent(false, group) or 0) > 0 then
        return false, { ns.T("msg.preview_busy") }
    end
    local out = {}
    local plan, wanted, conflicts = makePlan(ranks, group)
    if conflicts > 0 then tinsert(out, ns.T("msg.conflict", conflicts)) end
    if wanted == 0 then
        if conflicts == 0 then tinsert(out, ns.T("msg.learn_nothing")) end
        return false, out
    end
    if not GetCVarBool("previewTalents") then ns.BorrowPreviewCVar() end
    for _, p in ipairs(plan) do
        AddPreviewTalentPoints(p.tab, p.index, p.add, false, group)
    end
    return true, out
end
