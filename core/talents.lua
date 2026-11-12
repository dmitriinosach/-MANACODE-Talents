local ADDON, ns = ...
function ns.ReadTalents()
    if not (GetNumTalentTabs and GetTalentInfo and GetNumTalents) then return nil end
    local group = GetActiveTalentGroup and GetActiveTalentGroup() or 1
    local out = {}
    for tab = 1, GetNumTalentTabs() do
        local name, _, points = GetTalentTabInfo(tab, false, false, group)
        local t = { name = name, points = points or 0, list = {} }
        for i = 1, GetNumTalents(tab) do
            local tname, icon, _, _, rank, maxRank = GetTalentInfo(tab, i, false, false, group)
            if rank and rank > 0 then
                tinsert(t.list, {
                    name = tname, rank = rank, max = maxRank,
                    icon = icon, tab = tab, index = i,
                })
            end
        end
        tinsert(out, t)
    end
    return out
end
function ns.TalentByName(name)
    if not (name and GetNumTalentTabs and GetTalentInfo and GetNumTalents) then return nil end
    local group = GetActiveTalentGroup and GetActiveTalentGroup() or 1
    for tab = 1, GetNumTalentTabs() do
        for i = 1, GetNumTalents(tab) do
            local tname, icon, _, _, rank, maxRank = GetTalentInfo(tab, i, false, false, group)
            if tname == name then
                return { tab = tab, index = i, icon = icon,
                         rank = rank or 0, max = maxRank or 0 }
            end
        end
    end
    return nil
end
function ns.ReadTalentGrid(group)
    if not (GetNumTalentTabs and GetTalentInfo and GetNumTalents) then return nil end
    group = group or (GetActiveTalentGroup and GetActiveTalentGroup()) or 1
    local preview = GetCVarBool("previewTalents")
    local out = {}
    for tab = 1, GetNumTalentTabs() do
        local name, iconTex, points, bg, previewPoints = GetTalentTabInfo(tab, false, false, group)
        points = points or 0
        if preview then points = points + (previewPoints or 0) end
        local t = { name = name, icon = iconTex, points = points, bg = bg, rows = 0, talents = {}, live = group }
        for i = 1, GetNumTalents(tab) do
            local tname, icon, tier, column, rank, maxRank, _, _, previewRank =
                GetTalentInfo(tab, i, false, false, group)
            if tname then
                tier, column = tier or 1, column or 1
                if tier > t.rows then t.rows = tier end
                local pr, pc
                if GetTalentPrereqs then pr, pc = GetTalentPrereqs(tab, i, false, false, group) end
                rank = rank or 0
                tinsert(t.talents, {
                    row = tier, col = column, tex = icon, name = tname,
                    rank = (preview and previewRank) or rank, live = rank, max = maxRank or 0,
                    tab = tab, index = i,
                    prereq = (pr and pc) and { row = pr, col = pc } or nil,
                })
            end
        end
        tinsert(out, t)
    end
    return out
end
function ns.PreviewGrid(ranks, group)
    local grid = ns.ReadTalentGrid(group)
    if not grid or not ranks then return grid end
    for _, t in ipairs(grid) do
        local pts = 0
        t.live = nil
        for _, tal in ipairs(t.talents) do
            local rr = (ranks[tal.tab] and ranks[tal.tab][tal.index]) or 0
            tal.rank = rr
            tal.live = nil
            pts = pts + rr
        end
        t.points = pts
    end
    return grid
end
function ns.TalentFace(tal)
    if not tal then return nil, nil end
    local id = tal.spells and tal.spells[1]
    if not (id and GetSpellInfo) then return tal.name, tal.tex end
    local name, _, icon = GetSpellInfo(id)
    return name or tal.name, icon or tal.tex
end
function ns.ApplyRanksToGrid(baked, ranks, class)
    if not baked then return nil end
    local out = {}
    for ti, t in ipairs(baked) do
        local tabName = (class and ns.T("names.talents." .. class .. "." .. ti)) or t.name
        local nt = { name = tabName, icon = t.icon, bg = t.bg, rows = t.rows, points = 0, talents = {} }
        for _, tal in ipairs(t.talents) do
            local r = (ranks and ranks[tal.tab] and ranks[tal.tab][tal.index]) or 0
            nt.points = nt.points + r
            local name, icon = ns.TalentFace(tal)
            tinsert(nt.talents, {
                row = tal.row, col = tal.col, tex = icon,
                name = name,
                spells = tal.spells,
                rank = r, max = tal.max, tab = tal.tab, index = tal.index,
                prereq = tal.prereq,
            })
        end
        tinsert(out, nt)
    end
    return out
end
ns.MAX_TALENT_POINTS = 71
function ns.RanksTotal(ranks)
    local n = 0
    if ranks then
        for _, arr in pairs(ranks) do
            for _, v in pairs(arr) do n = n + (v or 0) end
        end
    end
    return n
end
function ns.CopyRanks(ranks)
    local out = {}
    if ranks then
        for tab, arr in pairs(ranks) do
            local a = {}
            for i, v in pairs(arr) do a[i] = v end
            out[tab] = a
        end
    end
    return out
end
local function pointsBelow(grid, ranks, tabIdx, tier)
    local t = grid[tabIdx]
    if not t then return 0 end
    local r = ranks[tabIdx] or {}
    local sum = 0
    for _, tal in ipairs(t.talents) do
        if (tal.row or 1) < tier then sum = sum + (r[tal.index] or 0) end
    end
    return sum
end
local function prereqTalent(grid, tabIdx, tal)
    if not tal.prereq then return nil end
    local t = grid[tabIdx]
    if not t then return nil end
    for _, x in ipairs(t.talents) do
        if x.row == tal.prereq.row and x.col == tal.prereq.col then return x end
    end
    return nil
end
local function findTal(grid, tab, index)
    local t = grid and grid[tab]
    if not t then return nil end
    for _, x in ipairs(t.talents) do
        if x.index == index then return x end
    end
    return nil
end
local function talSatisfied(grid, ranks, tabIdx, tal)
    local rank = (ranks[tabIdx] or {})[tal.index] or 0
    if rank <= 0 then return true end
    if pointsBelow(grid, ranks, tabIdx, tal.row or 1) < 5 * ((tal.row or 1) - 1) then return false end
    local pre = prereqTalent(grid, tabIdx, tal)
    if pre then
        local prank = (ranks[tabIdx] or {})[pre.index] or 0
        if prank < (pre.max or 0) then return false end
    end
    return true
end
function ns.BuilderValid(grid, ranks)
    if not grid then return false end
    for ti, t in ipairs(grid) do
        for _, tal in ipairs(t.talents) do
            if not talSatisfied(grid, ranks, ti, tal) then return false end
        end
    end
    return true
end
function ns.BuilderCanAdd(grid, ranks, tab, index)
    if ns.RanksTotal(ranks) >= ns.MAX_TALENT_POINTS then return false end
    local tal = findTal(grid, tab, index)
    if not tal then return false end
    local rank = (ranks[tab] or {})[index] or 0
    if rank >= (tal.max or 0) then return false end
    if pointsBelow(grid, ranks, tab, tal.row or 1) < 5 * ((tal.row or 1) - 1) then return false end
    local pre = prereqTalent(grid, tab, tal)
    if pre and ((ranks[tab] or {})[pre.index] or 0) < (pre.max or 0) then return false end
    return true
end
function ns.BuilderCanRemove(grid, ranks, tab, index)
    local rank = (ranks[tab] or {})[index] or 0
    if rank <= 0 then return false end
    local test = ns.CopyRanks(ranks)
    test[tab] = test[tab] or {}
    test[tab][index] = rank - 1
    return ns.BuilderValid(grid, test)
end
function ns.BuilderReachable(grid, ranks, tab, index)
    local tal = findTal(grid, tab, index)
    if not tal then return false end
    if pointsBelow(grid, ranks, tab, tal.row or 1) < 5 * ((tal.row or 1) - 1) then return false end
    local pre = prereqTalent(grid, tab, tal)
    if pre and ((ranks[tab] or {})[pre.index] or 0) < (pre.max or 0) then return false end
    return true
end
function ns.BuilderGate(grid, ranks, tab, index)
    local tal = findTal(grid, tab, index)
    if not tal then return nil, nil end
    local need
    local req = 5 * ((tal.row or 1) - 1)
    if req > 0 and pointsBelow(grid, ranks, tab, tal.row or 1) < req then need = req end
    local preName, preMax
    local pre = prereqTalent(grid, tab, tal)
    if pre and ((ranks[tab] or {})[pre.index] or 0) < (pre.max or 0) then
        preName, preMax = pre.name, pre.max
    end
    return need, preName, preMax
end
function ns.RanksSig(ranks)
    local parts = {}
    for tab = 1, 3 do
        local r = (ranks and ranks[tab]) or {}
        local last = 0
        for i, v in pairs(r) do
            if type(i) == "number" and (v or 0) ~= 0 and i > last then last = i end
        end
        local s = {}
        for i = 1, last do s[i] = string.format("%d", r[i] or 0) end
        parts[tab] = table.concat(s)
    end
    return table.concat(parts, ";")
end
ns.talentsLoaded = true
