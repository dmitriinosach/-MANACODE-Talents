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
function ns.PetCacheSave(grid)
    if not HTP_TalentsDB or not grid or #grid == 0 then return end
    local ch, stored = ns.CharDB()
    local key = petKey()
    if not stored or not key or (UnitLevel("pet") or 0) < PET_TALENT_LEVEL or ns.PetTalentsMissing(grid) then return end
    local ranks, points = {}, 0
    for tab, t in ipairs(grid) do
        local col = {}
        for _, tal in ipairs(t.talents) do
            col[tal.index] = tal.live or 0
            points = points + (tal.live or 0)
        end
        ranks[tab] = col
    end
    local sig = ns.RanksSig(ranks)
    ch.pets = ch.pets or {}
    local old = ch.pets[key]
    if old and old.sig == sig then return end
    ch.pets[key] = { ranks = ranks, points = points, sig = sig, at = time() }
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
    if stored then ch.pets = nil end
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
for _, ev in ipairs({ "PET_TALENT_UPDATE", "UNIT_PET", "PLAYER_ENTERING_WORLD", "PLAYER_TALENT_UPDATE" }) do
    petWatch:RegisterEvent(ev)
end
petWatch:SetScript("OnEvent", function(_, event, unit)
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
