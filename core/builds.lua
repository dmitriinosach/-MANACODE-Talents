local ADDON, ns = ...
ns.builds = ns.builds or {}
function ns.TalentPointsSpent(group)
    if not GetNumTalentTabs then return 0 end
    group = group or (GetActiveTalentGroup and GetActiveTalentGroup()) or 1
    local sum = 0
    for i = 1, GetNumTalentTabs() do
        local _, _, pts = GetTalentTabInfo(i, false, false, group)
        sum = sum + (pts or 0)
    end
    return sum
end
function ns.BuildFor(class, spec)
    return ns.SpecData(ns.builds, class, spec)
end
function ns.BuildsForClass(class)
    local out, seen = {}, {}
    local info = ns.specs and ns.specs[class]
    for _, variant in ipairs((info and info.order) or {}) do
        local recs = ns.BuildFor(class, variant)
        if recs and not seen[recs] then
            seen[recs] = true
            for _, r in ipairs(recs) do
                local locale = ns.locales[ns.CurrentLocale()] or ns.locales.enUS
                local names = locale and locale.buildNames
                local name = names and names[r.name] or r.name
                local own = ns.StandardName(class, r.name)
                out[#out + 1] = { variant = variant, name = own or name, ranks = r.ranks, key = r.name,
                                  renamed = own ~= nil }
            end
        end
    end
    return out
end
function ns.StandardName(class, key)
    local t = key and HTP_TalentsDB and HTP_TalentsDB.stdNames and HTP_TalentsDB.stdNames[class]
    return t and t[key] or nil
end
function ns.RenameStandardBuild(class, key, name)
    if not key then return false, ns.T("msg.no_slot") end
    name = name and strtrim(name) or ""
    HTP_TalentsDB.stdNames = HTP_TalentsDB.stdNames or {}
    local t = HTP_TalentsDB.stdNames[class] or {}
    t[key] = name ~= "" and name or nil
    HTP_TalentsDB.stdNames[class] = next(t) and t or nil
    if not next(HTP_TalentsDB.stdNames) then HTP_TalentsDB.stdNames = nil end
    return true, nil
end
function ns.BuildNameFor(ranks, class)
    if not (ranks and class) then return nil end
    local sig = ns.RanksSig(ranks)
    if sig == ns.RanksSig({}) then return nil end
    for i, b in ipairs(ns.CustomBuilds(class)) do
        if ns.RanksSig(b.ranks) == sig then return ns.BuildDisplayName(b, i) end
    end
    for _, r in ipairs(ns.BuildsForClass(class)) do
        if r.name and ns.RanksSig(r.ranks) == sig then return r.name end
    end
    return nil
end
function ns.SetBuildName(group, set)
    local _, class = UnitClass("player")
    local ranks
    if set and ns.CircleLoaded and ns.CircleLoaded() ~= set then
        local snap = ns.CircleSnap and ns.CircleSnap(set)
        ranks = snap and snap.ranks
    else
        local snap = ns.SnapshotTalents(group)
        ranks = snap and (snap.points or 0) > 0 and snap.ranks or nil
    end
    return ns.BuildNameFor(ranks, class)
end
local MAX_CUSTOM = 10
ns.MAX_CUSTOM_BUILDS = MAX_CUSTOM
function ns.CustomBuilds(class)
    HTP_TalentsDB.customBuilds = HTP_TalentsDB.customBuilds or {}
    HTP_TalentsDB.customBuilds[class] = HTP_TalentsDB.customBuilds[class] or {}
    return HTP_TalentsDB.customBuilds[class]
end
function ns.SnapshotTalents(group)
    local grid = ns.ReadTalentGrid(group)
    if not grid then return nil end
    local ranks, best, bestPts, total = {}, 1, -1, 0
    for ti, t in ipairs(grid) do
        local col, maxIdx, pts = {}, 0, 0
        for _, tal in ipairs(t.talents) do
            local r = tal.live or tal.rank or 0
            col[tal.index] = r
            pts = pts + r
            if tal.index > maxIdx then maxIdx = tal.index end
        end
        for i = 1, maxIdx do col[i] = col[i] or 0 end
        ranks[ti] = col
        total = total + pts
        if pts > bestPts then bestPts, best = pts, ti end
    end
    return { ranks = ranks, spec = best, points = total }
end
function ns.BuildDisplayName(bld, index)
    local name = bld and bld.name
    if name and name ~= "" then return name end
    return ns.T("msg.default_name", index)
end
local function cleanName(name)
    name = name and strtrim(name) or ""
    return (name ~= "") and name or nil
end
local function addSlot(class, entry)
    local list = ns.CustomBuilds(class)
    if #list >= MAX_CUSTOM then return false, ns.T("msg.slots_full", MAX_CUSTOM) end
    tinsert(list, entry)
    return true, nil
end
local function dominant(ranks)
    local best, bestPts, total = 1, -1, 0
    for tab, arr in pairs(ranks or {}) do
        local s = 0
        for _, v in pairs(arr) do s = s + (v or 0) end
        total = total + s
        if s > bestPts then bestPts, best = s, tab end
    end
    return best, total
end
function ns.SaveCustomBuild(name, group)
    local _, class = UnitClass("player")
    local snap = ns.SnapshotTalents(group)
    if not snap or snap.points == 0 then return false, ns.T("msg.nothing_to_save") end
    snap.name = cleanName(name)
    return addSlot(class, snap)
end
function ns.SaveBuilderBuild(ranks, name, class)
    local spec, pts = dominant(ranks)
    if pts == 0 then return false, ns.T("msg.builder_empty") end
    return addSlot(class, { ranks = ns.CopyRanks(ranks), spec = spec, points = pts,
                            name = cleanName(name) })
end
function ns.SaveCopiedBuild(data)
    local _, pts = dominant(data.ranks)
    return addSlot(data.class, { ranks = ns.CopyRanks(data.ranks), spec = data.spec,
                                 name = cleanName(ns.InspectName(data)), points = data.points or pts })
end
function ns.DeleteCustomBuild(class, i)
    local list = ns.CustomBuilds(class)
    if not list[i] then return false end
    tremove(list, i)
    return true
end
function ns.RenameCustomBuild(class, i, name)
    local list = ns.CustomBuilds(class)
    if not list[i] then return false, ns.T("msg.no_slot") end
    name = cleanName(name)
    if not name then return false, ns.T("msg.empty_name") end
    list[i].name = name
    return true, nil
end
local function deepCopy(src)
    local out = {}
    for k, v in pairs(src) do
        out[k] = (type(v) == "table") and deepCopy(v) or v
    end
    return out
end
function ns.ImportLegacyBuilds()
    if HTP_TalentsDB.importedFromHTP then return 0 end
    HTP_TalentsDB.importedFromHTP = true
    local old = type(htpDB) == "table" and type(htpDB.customBuilds) == "table" and htpDB.customBuilds
    if not old then return 0 end
    local n = 0
    for class, list in pairs(old) do
        if type(list) == "table" then
            local mine = ns.CustomBuilds(class)
            for _, b in ipairs(list) do
                if #mine >= MAX_CUSTOM then break end
                if type(b) == "table" and type(b.ranks) == "table" then
                    tinsert(mine, deepCopy(b))
                    n = n + 1
                end
            end
        end
    end
    return n
end
