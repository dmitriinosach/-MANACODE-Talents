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
