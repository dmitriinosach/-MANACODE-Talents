local ADDON, ns = ...
local DELAY = 0.5
function ns.AltCapture()
    if not HTP_TalentsDB then return end
    local ch, stored = ns.CharDB()
    if not stored then return end
    local sets, total = {}, 0
    for g = 1, GetNumTalentGroups(false, false) or 1 do
        local snap = ns.SnapshotTalents(g)
        if snap and (snap.points or 0) > 0 then
            sets[g] = { ranks = snap.ranks, spec = snap.spec, points = snap.points,
                        n = g == 2 and ns.CircleLoaded() or g }
            total = total + snap.points
        end
    end
    if total == 0 then return end
    ch.sets = sets
    ch.active = GetActiveTalentGroup(false, false) or 1
    ch.at = time()
end
local function shownName(key)
    local name, realm = key:match("^(.-)%-(.*)$")
    if not name then return key end
    local mine = GetRealmName and GetRealmName() or ""
    return (realm == "" or realm == mine) and name or (name .. " (" .. realm .. ")")
end
function ns.AltSets(class)
    local out = {}
    local me = ns.CharKey()
    for key, ch in pairs(HTP_TalentsDB.chars or {}) do
        if key ~= me and ch.class == class and ch.sets then
            local seen = {}
            local function add(set, n, active)
                if not (set and set.ranks and (set.points or 0) > 0) or seen[n] then return end
                seen[n] = true
                out[#out + 1] = { key = key, name = shownName(key), n = n, ranks = set.ranks,
                                  spec = set.spec or 1, points = set.points, active = active, at = ch.at }
            end
            for g = 1, 2 do
                local s = ch.sets[g]
                if s then add(s, s.n or g, ch.active == g) end
            end
            local snap = ch.circle and ch.circle.snap
            if snap then
                for n = 2, 3 do add(snap[n], n, false) end
            end
        end
    end
    table.sort(out, function(a, b)
        if a.name ~= b.name then return a.name < b.name end
        return a.n < b.n
    end)
    return out
end
function ns.AltForget(key)
    local ch = HTP_TalentsDB.chars and HTP_TalentsDB.chars[key]
    if ch then ch.sets, ch.active, ch.at = nil, nil, nil end
end
local PET_TALENT_LEVEL = 20
local SET_SETTLE = 3
local settleAt = 0
local function playerSetNo()
    local g = GetActiveTalentGroup(false, false) or 1
    return g == 2 and ns.CircleLoaded and ns.CircleLoaded() or g
end
local PET_KEEP = 12
local function petKey()
    local name = UnitName("pet")
    if not name or name == "" then return nil end
    return name .. "|" .. (UnitCreatureFamily and UnitCreatureFamily("pet") or "")
end
function ns.PetTalentsMissing(grid)
    if not grid or #grid == 0 or (UnitLevel("pet") or 0) < PET_TALENT_LEVEL then return false end
    local spent = 0
    for _, t in ipairs(grid) do
        for _, tal in ipairs(t.talents) do spent = spent + (tal.live or 0) end
    end
    return spent + (GetUnspentTalentPoints(false, true, ns.PetGroup()) or 0) <= 0
end
local function petLive(grid)
    local ranks, points = {}, 0
    for tab, t in ipairs(grid) do
        local col = {}
        for _, tal in ipairs(t.talents) do
            col[tal.index] = tal.live or 0
            points = points + (tal.live or 0)
        end
        ranks[tab] = col
    end
    return ranks, points
end
local PET_BUILDS_MAX = 8
ns.PET_BUILDS_MAX = PET_BUILDS_MAX
function ns.PetTreeKey(grid)
    local t = grid and grid[1]
    if not t then return nil end
    return t.bg or t.name, t.name
end
function ns.PetBuilds(key)
    local all = HTP_TalentsDB and HTP_TalentsDB.petBuilds
    return key and all and all[key] or {}
end
function ns.PetBuildDefaultName(grid)
    local _, tree = ns.PetTreeKey(grid)
    local _, points = petLive(grid or {})
    return (tree or "?") .. " " .. points
end
function ns.PetBuildSave(name)
    local grid = ns.PetTalentsOn() and ns.ReadTalentGrid(ns.PetGroup(), true) or nil
    local key = ns.PetTreeKey(grid)
    if not key or ns.PetTalentsMissing(grid) then return false, ns.T("tip.pet_save_empty") end
    local ranks, points = petLive(grid)
    if points <= 0 then return false, ns.T("tip.pet_save_empty") end
    name = name and strtrim(name) or ""
    if name == "" then name = ns.PetBuildDefaultName(grid) end
    HTP_TalentsDB.petBuilds = HTP_TalentsDB.petBuilds or {}
    local list = HTP_TalentsDB.petBuilds[key] or {}
    HTP_TalentsDB.petBuilds[key] = list
    for _, b in ipairs(list) do
        if b.name == name then
            b.ranks, b.points, b.at = ranks, points, time()
            return true
        end
    end
    if #list >= PET_BUILDS_MAX then return false, ns.T("msg.pet_builds_full", PET_BUILDS_MAX) end
    list[#list + 1] = { name = name, ranks = ranks, points = points, at = time() }
    return true
end
function ns.PetBuildForget(key, name)
    local list = ns.PetBuilds(key)
    for i, b in ipairs(list) do
        if b.name == name then
            tremove(list, i)
            return
        end
    end
end
function ns.PetSetBuilds()
    local key = petKey()
    local pets = ns.CharDB().pets
    local sets = key and pets and pets[key] and pets[key].sets
    local out = {}
    for n, set in pairs(sets or {}) do
        out[#out + 1] = { n = n, ranks = set.ranks, points = set.points or 0 }
    end
    table.sort(out, function(a, b) return a.n < b.n end)
    return out
end
function ns.PetCacheSave(grid)
    if not HTP_TalentsDB or not grid or #grid == 0 then return end
    local ch, stored = ns.CharDB()
    local key = petKey()
    if not stored or not key or (UnitLevel("pet") or 0) < PET_TALENT_LEVEL or ns.PetTalentsMissing(grid) then return end
    local ranks, points = petLive(grid)
    local sig = ns.RanksSig(ranks)
    ch.pets = ch.pets or {}
    local snap = ch.pets[key]
    if not snap then
        snap = { at = time() }
        ch.pets[key] = snap
    end
    if snap.sig ~= sig then snap.ranks, snap.points, snap.sig, snap.at = ranks, points, sig, time() end
    if points > 0 and GetTime() >= settleAt then
        local n = playerSetNo()
        snap.sets = snap.sets or {}
        local set = snap.sets[n]
        if not set or set.sig ~= sig then snap.sets[n] = { ranks = ranks, points = points, sig = sig } end
        snap.last = n
    end
    local n, oldest = 0, nil
    for k, snap in pairs(ch.pets) do
        n = n + 1
        if k ~= key and (not oldest or (snap.at or 0) < (ch.pets[oldest].at or 0)) then oldest = k end
    end
    if n > PET_KEEP and oldest then ch.pets[oldest] = nil end
end
function ns.PetCacheApply(grid)
    local key = petKey()
    local pets = ns.CharDB().pets
    local snap = key and pets and pets[key]
    if not (snap and grid) or (snap.points or 0) <= 0 then return false end
    for tab, t in ipairs(grid) do
        local col, pts = snap.ranks[tab] or {}, 0
        for _, tal in ipairs(t.talents) do
            local r = math.min(col[tal.index] or 0, tal.max or 0)
            tal.rank, tal.live = r, r
            pts = pts + r
        end
        t.points = pts
    end
    return true
end
function ns.PetCacheDrop()
    if not HTP_TalentsDB then return end
    local ch, stored = ns.CharDB()
    if not stored then return end
    for _, snap in pairs(ch.pets or {}) do snap.ranks, snap.points, snap.sig = nil, nil, nil end
end
function ns.PetSavedBuild()
    local key = petKey()
    local pets = ns.CharDB().pets
    local snap = key and pets and pets[key]
    local sets = snap and snap.sets
    if not sets then return nil end
    local set = sets[playerSetNo()]
    if set then return set.ranks, set.points, true end
    set = snap.last and sets[snap.last]
    if set then return set.ranks, set.points, false end
    return nil
end
local function playerSpent()
    if not (GetNumTalentTabs and GetTalentTabInfo) then return 0 end
    local g = GetActiveTalentGroup(false, false) or 1
    local n = 0
    for tab = 1, GetNumTalentTabs(false, false) or 0 do
        local _, _, points = GetTalentTabInfo(tab, false, false, g)
        n = n + (points or 0)
    end
    return n
end
local lastSpent, lastGroup
local petWatch = CreateFrame("Frame")
for _, ev in ipairs({ "PET_TALENT_UPDATE", "UNIT_PET", "PLAYER_ENTERING_WORLD", "PLAYER_TALENT_UPDATE",
                      "ACTIVE_TALENT_GROUP_CHANGED" }) do
    petWatch:RegisterEvent(ev)
end
petWatch:SetScript("OnEvent", function(_, event, unit)
    if event == "ACTIVE_TALENT_GROUP_CHANGED" then
        settleAt = GetTime() + SET_SETTLE
        return
    end
    if event == "PLAYER_TALENT_UPDATE" then
        local g, now = GetActiveTalentGroup(false, false) or 1, playerSpent()
        if g == lastGroup and (lastSpent or 0) > 0 and now == 0 then ns.PetCacheDrop() end
        lastGroup, lastSpent = g, now
        return
    end
    if event == "UNIT_PET" and unit ~= "player" then return end
    if ns.PetTalentsOn() then ns.PetCacheSave(ns.ReadTalentGrid(ns.PetGroup(), true)) end
end)
local watch = CreateFrame("Frame")
for _, ev in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_TALENT_UPDATE", "ACTIVE_TALENT_GROUP_CHANGED",
                      "CHARACTER_POINTS_CHANGED", "PLAYER_LOGOUT" }) do
    watch:RegisterEvent(ev)
end
local function later(self, elapsed)
    self.wait = self.wait - elapsed
    if self.wait > 0 then return end
    self:SetScript("OnUpdate", nil)
    ns.AltCapture()
end
watch:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGOUT" then
        ns.AltCapture()
        return
    end
    self.wait = DELAY
    self:SetScript("OnUpdate", later)
end)
