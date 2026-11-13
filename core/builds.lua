local ADDON, ns = ...
ns.builds = ns.builds or {}
local pass, passDepth = nil, 0
function ns.TalentPass(fn)
    passDepth = passDepth + 1
    if passDepth == 1 then pass = { grid = {}, builds = {}, names = {} } end
    local ok, err = pcall(fn)
    passDepth = passDepth - 1
    if passDepth == 0 then pass = nil end
    if not ok then error(err, 0) end
end
local function sharedGrid(group)
    if not pass then return ns.ReadTalentGrid(group) end
    group = group or (GetActiveTalentGroup and GetActiveTalentGroup()) or 1
    local g = pass.grid[group]
    if g == nil then
        g = ns.ReadTalentGrid(group) or false
        pass.grid[group] = g
    end
    return g or nil
end
ns.SharedTalentGrid = sharedGrid
function ns.BuildFor(class, spec)
    return ns.SpecData(ns.builds, class, spec)
end
function ns.GlyphPlanCopy(g)
    if type(g) ~= "table" then return nil end
    local out, any = { major = {}, minor = {} }, false
    for _, kind in ipairs({ "major", "minor" }) do
        for i = 1, 3 do
            local id = type(g[kind]) == "table" and tonumber(g[kind][i]) or nil
            if id and id > 0 then
                out[kind][i] = id
                any = true
            end
        end
    end
    return any and out or nil
end
function ns.GlyphPlanCount(g)
    local n = 0
    for _, kind in ipairs({ "major", "minor" }) do
        for i = 1, 3 do
            if g and g[kind] and g[kind][i] then n = n + 1 end
        end
    end
    return n
end
function ns.PlanCopy(p)
    if type(p) ~= "table" then return nil end
    local note = type(p.note) == "string" and strtrim(p.note) or ""
    local out = { glyphs = ns.GlyphPlanCopy(p.glyphs), note = note ~= "" and note or nil }
    return (out.glyphs or out.note) and out or nil
end
function ns.LiveGlyphPlan(group)
    if not (ns.GlyphSlots and ns.GlyphItemByName and GetGlyphSocketInfo) then return nil end
    local class = ns.PlayerClass()
    local major, minor = ns.GlyphSlots(group or GetActiveTalentGroup() or 1)
    local g = { major = {}, minor = {} }
    for kind, list in pairs({ major = major, minor = minor }) do
        for i, s in ipairs(list) do
            local e = s.name and ns.GlyphItemByName(class, s.name)
            if e and e.item and i <= 3 then g[kind][i] = e.item end
        end
    end
    return ns.GlyphPlanCopy(g)
end
function ns.BuildsForClass(class)
    if pass and pass.builds[class] then return pass.builds[class] end
    local out, seen = {}, {}
    local info = ns.specs and ns.specs[class]
    local locale = ns.locales[ns.CurrentLocale()] or ns.locales.enUS
    local names = locale and locale.buildNames
    local function add(variant, r)
        local name = names and names[r.name] or r.name
        local own = ns.StandardName(class, r.name)
        out[#out + 1] = { variant = variant, name = own or name, ranks = r.ranks, key = r.name,
                          renamed = own ~= nil, glyphs = ns.GlyphPlanCopy(r.glyphs), note = r.note }
    end
    for _, variant in ipairs((info and info.order) or {}) do
        local recs = ns.BuildFor(class, variant)
        if recs and not seen[recs] then
            seen[recs] = true
            for _, r in ipairs(recs) do add(variant, r) end
        end
    end
    for _, r in ipairs((ns.stdBuilds and ns.stdBuilds[class]) or {}) do
        local hit
        for _, o in ipairs(out) do
            if o.key == r.name then hit = o end
        end
        if hit then
            if r.ranks then hit.ranks = r.ranks end
            hit.glyphs = ns.GlyphPlanCopy(r.glyphs) or hit.glyphs
            hit.note = r.note or hit.note
        elseif r.ranks then
            add(r.variant or (ns.DominantTab and ns.DominantTab(r.ranks)) or 1, r)
        end
    end
    if pass then pass.builds[class] = out end
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
    local names = pass and pass.names[class]
    if not names then
        names = {}
        for i, bld in ipairs(ns.CustomBuilds(class)) do
            local k = ns.RanksSig(bld.ranks)
            if not names[k] then names[k] = ns.BuildDisplayName(bld, i) end
        end
        for _, r in ipairs(ns.BuildsForClass(class)) do
            local k = r.name and ns.RanksSig(r.ranks)
            if k and not names[k] then names[k] = r.name end
        end
        if pass then pass.names[class] = names end
    end
    return names[sig]
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
    local grid = sharedGrid(group)
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
    snap.glyphs = ns.LiveGlyphPlan(group)
    return addSlot(class, snap)
end
function ns.SaveBuilderBuild(ranks, name, class, plan)
    local spec, pts = dominant(ranks)
    if pts == 0 then return false, ns.T("msg.builder_empty") end
    plan = ns.PlanCopy(plan) or {}
    return addSlot(class, { ranks = ns.CopyRanks(ranks), spec = spec, points = pts,
                            name = cleanName(name), glyphs = plan.glyphs, note = plan.note })
end
function ns.SetBuildNote(class, i, note)
    local list = ns.CustomBuilds(class)
    if not list[i] then return false, ns.T("msg.no_slot") end
    note = note and strtrim(note) or ""
    list[i].note = note ~= "" and note or nil
    return true, nil
end
function ns.DominantTab(ranks)
    return (dominant(ranks))
end
function ns.SaveCopiedBuild(data)
    local _, pts = dominant(data.ranks)
    local plan = ns.PlanCopy(data) or {}
    return addSlot(data.class, { ranks = ns.CopyRanks(data.ranks), spec = data.spec,
                                 name = cleanName(ns.InspectName(data)), points = data.points or pts,
                                 glyphs = plan.glyphs, note = plan.note })
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
