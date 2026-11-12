local ADDON, ns = ...
ns.Caps = ns.Caps or {}
local Caps = ns.Caps
local STAT = {
    spellhit   = { rating = function() return GetCombatRating(8) end,
                   pct = function() return GetCombatRatingBonus(8) end },
    spellhaste = { rating = function() return GetCombatRating(20) end,
                   pct = function() return GetCombatRatingBonus(20) end },
    spellcrit  = { rating = function() return GetCombatRating(11) end,
                   pct = function() return GetSpellCritChance(6) end },
    meleehit   = { rating = function() return GetCombatRating(6) end,
                   pct = function() return GetCombatRatingBonus(6) end },
    meleehaste = { rating = function() return GetCombatRating(18) end,
                   pct = function() return GetCombatRatingBonus(18) end },
    meleecrit  = { rating = function() return GetCombatRating(9) end,
                   pct = function() return GetCritChance() end },
    rangedhit  = { rating = function() return GetCombatRating(7) end,
                   pct = function() return GetCombatRatingBonus(7) end },
    rangedhaste = { rating = function() return GetCombatRating(19) end,
                    pct = function() return GetCombatRatingBonus(19) end },
    rangedcrit = { rating = function() return GetCombatRating(10) end,
                   pct = function() return GetRangedCritChance() end },
    expertise  = { rating = function() return GetCombatRating(24) end,
                   pct = function() return GetCombatRatingBonus(24) end,
                   units = function() return (GetExpertise()) end },
    arp        = { rating = function() return GetCombatRating(25) end,
                   pct = function() return GetArmorPenetration() end },
    spellpower = { rating = function()
        local m = 0
        for s = 2, 7 do
            local v = GetSpellBonusDamage(s) or 0
            if v > m then m = v end
        end
        return m
    end },
    attackpower = { rating = function()
        local b, p, n = UnitAttackPower("player")
        return (b or 0) + (p or 0) + (n or 0)
    end },
    strength = { rating = function() return (UnitStat("player", 1)) end },
    agility  = { rating = function() return (UnitStat("player", 2)) end },
    stamina  = { rating = function() return (UnitStat("player", 3)) end },
    armor      = { rating = function() local b, e = UnitArmor("player"); return e or b or 0 end },
    defense    = { rating = function() local b, m = UnitDefense("player"); return (b or 0) + (m or 0) end },
    dodge      = { pct = function() return GetDodgeChance() end },
    parry      = { pct = function() return GetParryChance() end },
    block      = { pct = function() return GetBlockChance() end },
    resilience = { rating = function() return GetCombatRating(15) end },
    mp5        = { rating = function() local r = GetManaRegen(); return math.floor((r or 0) * 5) end },
}
function Caps.ReadStat(statKey, which)
    local s = STAT[statKey]
    local f = s and s[which]
    if not f then return nil end
    local ok, v = pcall(f)
    if ok and type(v) == "number" then return v end
    return nil
end
local function bestTab(grid)
    local best, pts, total = 1, -1, 0
    for i, t in ipairs(grid or {}) do
        local n = 0
        for _, tal in ipairs(t.talents or {}) do n = n + (tal.live or tal.rank or 0) end
        total = total + n
        if n > pts then best, pts = i, n end
    end
    return best, total
end
function Caps.Variants(class, tab)
    local out = {}
    local c = ns.specs and ns.specs[class]
    for _, key in ipairs((c and c.order) or {}) do
        if c.variants[key].tab == tab then out[#out + 1] = key end
    end
    return out
end
function Caps.Variant(class, tab)
    local saved = ns.CharDB and ns.CharDB().capsVariant
    local key = saved and saved[tab]
    local info = key and ns.SpecInfo(class, key)
    if info and info.tab == tab then return key end
    return ns.DefaultVariant and ns.DefaultVariant(class, tab) or nil
end
function Caps.NextVariant(ctx)
    local list = Caps.Variants(ctx.class, ctx.tab)
    if #list < 2 then return end
    local at = 1
    for i, key in ipairs(list) do if key == ctx.spec then at = i end end
    local key = list[at % #list + 1]
    local ch = ns.CharDB()
    ch.capsVariant = ch.capsVariant or {}
    ch.capsVariant[ctx.tab] = key ~= ns.DefaultVariant(ctx.class, ctx.tab) and key or nil
end
function Caps.Context()
    local _, class = UnitClass("player")
    local race = UnitRace and select(2, UnitRace("player")) or nil
    local faction = UnitFactionGroup and (UnitFactionGroup("player")) or nil
    local group = GetActiveTalentGroup and GetActiveTalentGroup() or 1
    local grid = ns.ReadTalentGrid and ns.ReadTalentGrid(group) or nil
    local tab, total = bestTab(grid)
    return { class = class, race = race, faction = faction, group = group, grid = grid,
             tab = tab, points = total, spec = Caps.Variant(class, tab) }
end
function Caps.Spec(ctx)
    return ns.SpecData(ns.capdata, ctx.class, ctx.spec)
end
local CAPS_BY_ARCHETYPE = {
    casterDps = { "spellhit", "spellhaste", "crit", "spellpower" },
    meleeDps  = { "meleehit", "expertise", "arp", "crit", "meleehaste", "mainstat" },
    ranged    = { "rangedhit", "arp", "crit", "rangedhaste", "mainstat" },
    tank      = { "defense", "meleehit", "expertise", "dodge", "parry", "block", "armor", "stamina", "resilience" },
    healer    = { "spellhaste", "crit", "spellpower", "mp5" },
}
local CASTER_DD = { MAGE = true, WARLOCK = true, PRIEST = true }
local CRIT_STAT = {
    casterDps = "spellcrit", healer = "spellcrit",
    meleeDps  = "meleecrit", tank = "meleecrit",
    ranged    = "rangedcrit",
}
local STR_CLASSES = { WARRIOR = true, DEATHKNIGHT = true, PALADIN = true }
function Caps.Archetype(ctx)
    local info = ns.SpecInfo and ns.SpecInfo(ctx.class, ctx.spec)
    local role, base = (info and info.role) or "dd", info and info.base
    if role == "tank" then return "tank" end
    if role == "heal" then return "healer" end
    if ctx.class == "HUNTER" then return "ranged" end
    if CASTER_DD[ctx.class] then return "casterDps" end
    if ctx.class == "SHAMAN" then return base == "ele" and "casterDps" or "meleeDps" end
    if ctx.class == "DRUID" then return base == "balance" and "casterDps" or "meleeDps" end
    return "meleeDps"
end
function Caps.CritStat(ctx)
    return CRIT_STAT[Caps.Archetype(ctx)] or "spellcrit"
end
function Caps.MainStat(ctx)
    return STR_CLASSES[ctx.class] and "strength" or "agility"
end
function Caps.For(ctx)
    local d = Caps.Spec(ctx)
    local set = CAPS_BY_ARCHETYPE[Caps.Archetype(ctx)] or {}
    local priority = d and d.priority
    if not priority then return set end
    local inSet, out, seen = {}, {}, {}
    for _, k in ipairs(set) do inSet[k] = true end
    for _, k in ipairs(priority) do
        if inSet[k] and not seen[k] then out[#out + 1] = k; seen[k] = true end
    end
    for _, k in ipairs(set) do
        if not seen[k] then out[#out + 1] = k end
    end
    return out
end
Caps.REASON = {
    OWN_RACE     = "own_race",
    IN_GROUP     = "in_group",
    RACE_FAR     = "race_far",
    NO_RACE      = "no_race",
    SELF         = "self_apply",
    ON_TARGET    = "on_target",
    CLASS_HERE   = "class_present",
    NO_CLASS     = "no_class",
    WRONG_WEAPON = "wrong_weapon",
    NO_RANK      = "no_rank",
    GLYPH        = "glyph",
    NO_GLYPH     = "no_glyph",
}
local REASON = Caps.REASON
local function picksFor(ctx)
    local ch = ns.CharDB()
    ch.capPicks = ch.capPicks or {}
    local key = tostring(ctx.spec)
    ch.capPicks[key] = ch.capPicks[key] or {}
    return ch.capPicks[key]
end
function Caps.SetPick(ctx, key, on)
    if key then picksFor(ctx)[key] = on end
end
function Caps.Pick(ctx, key)
    return picksFor(ctx)[key]
end
local function raidKey(key)
    if ns.capgroups and ns.capgroups[key] then return true end
    local src = ns.capsources and ns.capsources[key]
    return src ~= nil and not (src.personal or src.glyph or src.at or src.weapon)
end
function Caps.RaidMode()
    return ns.CharDB().capsSolo ~= true
end
function Caps.SetRaidMode(ctx, raid)
    ns.CharDB().capsSolo = (not raid) or nil
    local picks = picksFor(ctx)
    for key in pairs(picks) do
        if raidKey(key) then picks[key] = nil end
    end
end
local function talentAt(ctx, tab, row, col)
    local tree = ctx.grid and ctx.grid[tab]
    for _, t in ipairs((tree and tree.talents) or {}) do
        if t.row == row and t.col == col then return t end
    end
    return nil
end
local function talentBySpell(ctx, id)
    local name = id and GetSpellInfo(id)
    if not name then return nil end
    for _, tree in ipairs(ctx.grid or {}) do
        for _, t in ipairs(tree.talents or {}) do
            if t.name == name then return t end
        end
    end
    return nil
end
local function rankOf(t)
    if not t then return 0, 0 end
    return t.live or t.rank or 0, t.max or 0
end
local function hasAura(unit, id, fn)
    local name = id and GetSpellInfo(id)
    if not (name and fn and UnitExists and UnitExists(unit)) then return false end
    for i = 1, 40 do
        local n = fn(unit, i)
        if not n then break end
        if n == name then return true end
    end
    return false
end
local function roster()
    local out = {}
    local nr = GetNumRaidMembers and GetNumRaidMembers() or 0
    if nr > 0 then
        local me = UnitName("player")
        for i = 1, nr do
            local name, _, _, _, _, class = GetRaidRosterInfo(i)
            if class and name ~= me then
                local unit = "raid" .. i
                out[#out + 1] = { class = class, unit = unit, race = select(2, UnitRace(unit)) }
            end
        end
    else
        for i = 1, GetNumPartyMembers and GetNumPartyMembers() or 0 do
            local unit = "party" .. i
            local _, class = UnitClass(unit)
            if class then out[#out + 1] = { class = class, unit = unit, race = select(2, UnitRace(unit)) } end
        end
    end
    return out
end
local function groupHasRace(race)
    for _, m in ipairs(roster()) do
        if m.race == race then return true end
    end
    return false
end
local function groupHasClass(class, form)
    local present = false
    for _, m in ipairs(roster()) do
        if m.class == class then
            if form and hasAura(m.unit, form, UnitBuff) then return true, true end
            present = true
        end
    end
    return present, false
end
local weaponSubs
local function weaponSub(slot)
    local link = GetInventoryItemLink and GetInventoryItemLink("player", slot)
    if not link then return nil end
    local _, _, _, _, _, _, sub = GetItemInfo(link)
    if not weaponSubs then
        weaponSubs = {}
        if GetAuctionItemSubClasses then
            local list = { GetAuctionItemSubClasses(1) }
            for i = 1, #list do weaponSubs[list[i]] = i end
        end
    end
    return sub and weaponSubs[sub] or nil
end
local function weaponMatches(subs)
    local main, off = weaponSub(16), weaponSub(17)
    for _, s in ipairs(subs) do
        if s == main or s == off then return true end
    end
    return false
end
local function hasGlyph(id, group)
    if not GetGlyphSocketInfo then return false end
    local name = GetSpellInfo(id)
    for i = 1, NUM_GLYPH_SLOTS or 6 do
        local enabled, _, spell = GetGlyphSocketInfo(i, group)
        if enabled and spell and (spell == id or (name and GetSpellInfo(spell) == name)) then return true end
    end
    return false
end
local function availableTo(src, ctx)
    if src.faction and ctx.faction ~= src.faction then return false end
    if src.class and ctx.class ~= src.class then return false end
    if src.spec then
        local ok = false
        for _, s in ipairs(src.spec) do
            if s == ctx.spec then ok = true; break end
        end
        if not ok then return false end
    end
    if src.personal and src.race and ctx.race ~= src.race then return false end
    return true
end
function Caps.Registry(ctx, stat)
    local out = {}
    for key, src in pairs(ns.capsources or {}) do
        if availableTo(src, ctx) then
            for _, k in ipairs(src.stats or {}) do
                if k == stat then out[#out + 1] = { key = key, src = src }; break end
            end
        end
    end
    table.sort(out, function(a, b) return a.key < b.key end)
    return out
end
local function registryRow(entry, ctx)
    local src = entry.src
    local id = (src.byClass and src.byClass[ctx.class]) or src.spell
    local name, _, icon
    if id then name, _, icon = GetSpellInfo(id) end
    local row = { key = entry.key, name = name or entry.key, pct = src.pct or 0,
                  group = src.group, spellId = id, icon = icon, auto = true }
    local t
    if src.at then
        t = talentAt(ctx, src.at.tab, src.at.row, src.at.col)
    elseif src.talent and src.talent[ctx.class] then
        t = talentBySpell(ctx, src.talent[ctx.class])
    end
    if t or src.at then
        local rank, max = rankOf(t)
        if max == 0 then max = src.max or 0 end
        if max > 0 then row.detail = rank .. "/" .. max end
        row.rank, row.max = rank, max
        if t then
            row.talent = { t.tab, t.index }
            row.icon = t.tex or row.icon
            if src.at then row.name = t.name or row.name end
        end
    end
    if src.perRank then
        row.pct = ((row.rank or 0) > 0 and row.rank or (row.max or src.max or 0)) * src.perRank
    end
    if src.weapon and not weaponMatches(src.weapon) then
        row.on, row.why, row.auto = false, REASON.WRONG_WEAPON, false
    elseif (row.rank or 0) > 0 then
        row.on, row.why = true, REASON.SELF
    elseif src.glyph then
        row.on = hasGlyph(src.glyph, ctx.group)
        row.why = row.on and REASON.GLYPH or REASON.NO_GLYPH
        row.auto = row.on
    elseif src.onTarget and hasAura("target", src.debuff or id, UnitDebuff) then
        row.on, row.why = true, REASON.ON_TARGET
    elseif not src.onTarget and src.race and ctx.race == src.race then
        row.on, row.why = true, REASON.OWN_RACE
    elseif not src.onTarget and hasAura("player", id, UnitBuff) then
        row.on, row.why = true, REASON.IN_GROUP
    elseif src.at then
        row.on, row.why, row.auto = false, REASON.NO_RANK, false
    elseif src.race then
        row.on, row.why = false, groupHasRace(src.race) and REASON.RACE_FAR or REASON.NO_RACE
    else
        row.on, row.why = false, REASON.NO_CLASS
        for class in pairs(src.form or src.talent or {}) do
            local present, confirmed = groupHasClass(class, (src.form or {})[class])
            if present then
                row.why, row.sure = REASON.CLASS_HERE, confirmed
                break
            end
        end
    end
    row.raid = raidKey(entry.key) and row.why ~= REASON.SELF and row.why ~= REASON.OWN_RACE
    return row
end
local STATE_RANK = {
    [REASON.NO_CLASS]   = 1,
    [REASON.CLASS_HERE] = 2,
    [REASON.ON_TARGET]  = 3,
    [REASON.SELF]       = 4,
}
local function mergeGroups(rows)
    local out, byGroup = {}, {}
    local function take(m, r)
        m.on, m.why, m.sure, m.raid = r.on, r.why, r.sure, r.raid
        m.icon, m.spellId, m.detail, m.talent = r.icon, r.spellId, r.detail, r.talent
        m.name = (STATE_RANK[r.why] or 0) > 1 and r.name or nil
    end
    for _, r in ipairs(rows) do
        if not r.group then
            out[#out + 1] = r
        else
            local m = byGroup[r.group]
            if not m then
                m = { key = r.group, group = r.group, members = {}, pct = r.pct, auto = true }
                take(m, r)
                byGroup[r.group] = m
                out[#out + 1] = m
            elseif (STATE_RANK[r.why] or 0) > (STATE_RANK[m.why] or 0) then
                take(m, r)
            end
            if r.pct > m.pct then m.pct = r.pct end
            m.members[#m.members + 1] = r
        end
    end
    return out
end
function Caps.Sources(ctx, stat)
    local rows = {}
    local spec = Caps.Spec(ctx)
    for _, s in ipairs((spec and spec.sources) or {}) do
        if s.stat == stat then
            local t = talentAt(ctx, s.tab, s.row, s.col)
            local rank = rankOf(t)
            local max = s.max or rank
            local on = rank > 0
            local name, _, icon
            if s.spellId then name, _, icon = GetSpellInfo(s.spellId) end
            rows[#rows + 1] = {
                key = "talent:" .. tostring(s.spellId),
                name = (t and t.name) or name or tostring(s.spellId),
                pct = (on and rank or max) * (s.perRank or 0),
                on = on, why = on and REASON.SELF or REASON.NO_RANK, auto = on,
                detail = rank .. "/" .. max, rank = rank, max = max,
                icon = (t and t.tex) or icon, spellId = s.spellId,
                talent = t and { t.tab, t.index } or nil,
            }
        end
    end
    for _, entry in ipairs(Caps.Registry(ctx, stat)) do
        rows[#rows + 1] = registryRow(entry, ctx)
    end
    rows = mergeGroups(rows)
    local raidMode = Caps.RaidMode()
    local sum = 0
    for _, r in ipairs(rows) do
        if r.raid then r.auto = raidMode end
        local pick = Caps.Pick(ctx, r.key)
        if pick == nil then r.picked = r.auto and true or false else r.picked = pick end
        if r.picked then sum = sum + r.pct end
    end
    return sum, rows
end
function Caps.StatData(ctx, stat)
    local spec = Caps.Spec(ctx) or {}
    local out = {}
    if type(spec[stat]) == "table" then
        for k, v in pairs(spec[stat]) do out[k] = v end
    end
    out.avgDps, out.mainStat = spec.avgDps, spec.mainStat
    return out
end
function Caps.Weight(ctx)
    local byClass = ns.capweights and ns.capweights[ctx.class]
    return byClass and ns.SpecFrom(byClass, ctx.class, ctx.spec) or nil
end
function Caps.ArpGain(pct)
    local arp = ns.caparp
    if not (arp and arp.steps and pct) then return nil end
    local lo, hi
    for _, s in ipairs(arp.steps) do
        if s[1] <= pct and (not lo or s[1] > lo[1]) then lo = s end
        if s[1] >= pct and (not hi or s[1] < hi[1]) then hi = s end
    end
    if not lo then return 0 end
    if not hi or hi[1] == lo[1] then return lo[2] end
    return lo[2] + (hi[2] - lo[2]) * (pct - lo[1]) / (hi[1] - lo[1])
end
function Caps.ArpState()
    local arp = ns.caparp or {}
    local pct, rating = Caps.ReadStat("arp", "pct"), Caps.ReadStat("arp", "rating")
    local out = { pct = pct, rating = rating, cap = arp.cap or 1400, steps = arp.steps,
                  haveMissing = not (pct and rating) }
    out.gain = Caps.ArpGain(pct)
    if out.gain and arp.steps and arp.steps[1] then out.left = arp.steps[1][2] - out.gain end
    return out
end
function Caps.Target(meta, d)
    local have = Caps.ReadStat(meta.stat, meta.show or "rating")
    local steps, need, top
    if d.targets and #d.targets > 0 then
        steps = {}
        for _, t in ipairs(d.targets) do
            local taken = have ~= nil and have >= t.v
            steps[#steps + 1] = { v = t.v, t = t.t, taken = taken }
            if have and not taken and not need then need = t.v end
            top = t.v
        end
        if not have then need = d.targets[1].v end
    else
        need = d.need or meta.need
        top = need
    end
    local out = { have = have, need = need, top = top or 0, steps = steps, haveMissing = have == nil }
    if have and steps then
        if need then out.status, out.delta = "under", need - have else out.status = "all" end
    elseif have and need then
        if have < need then
            out.status, out.delta = "under", need - have
        else
            out.status, out.delta = "reached", have - need
        end
    end
    return out
end
local function thresholdsOf(ctx, meta)
    local t = meta.thresholds
    if not t then return { meta.basePct or 17 } end
    return t[Caps.Archetype(ctx)] or t.default or { meta.basePct or 17 }
end
function Caps.Hard(ctx, meta, d)
    local caps = thresholdsOf(ctx, meta)
    local base, perPct = caps[#caps], meta.perPct or 26.23
    local sumPct, rows = Caps.Sources(ctx, meta.stat)
    local gearPct = base - sumPct
    if gearPct < 0 then gearPct = 0 end
    local out = {
        rows = rows, sumPct = sumPct, unit = meta.unit or "%", caps = caps,
        needPct = base, needRating = base * perPct,
        gearPct = gearPct, gearRating = gearPct * perPct,
        haveMissing = false, mainStat = d.mainStat,
    }
    local rating = Caps.ReadStat(meta.stat, "rating")
    local havePct = meta.haveFromRating and rating and (rating / perPct)
        or Caps.ReadStat(meta.stat, meta.have or "pct")
    if rating == nil or havePct == nil then
        out.haveMissing = true
        return out
    end
    out.haveRating, out.havePct = rating, havePct
    local totalPct = havePct + sumPct
    out.totalPct, out.totalRating = totalPct, totalPct * perPct
    local delta = totalPct - base
    out.deltaPct, out.deltaRating = delta, delta * perPct
    if delta < -0.005 then
        out.status = "under"
        local loss = 0
        for _, cap in ipairs(caps) do
            local left = cap - totalPct
            if left > 0 then loss = loss + left * (meta.pctPerPoint or 1) end
        end
        out.lossPct = loss
        out.lossDps = d.avgDps and (loss / 100 * d.avgDps) or nil
    elseif delta > 0.005 then
        out.status = "over"
        out.conv = out.deltaRating * (meta.convRate or 23 / 20)
        local w = Caps.Weight(ctx)
        out.convDps = w and w.main and (out.conv * w.main) or nil
    else
        out.status = "ok"
    end
    return out
end
function Caps.Model()
    local ctx = Caps.Context()
    if not (ctx.class and ctx.spec) then return nil end
    local out = { ctx = ctx, order = {}, capped = {}, more = {} }
    for _, key in ipairs(Caps.For(ctx)) do
        local meta = ns.capstats and ns.capstats[key]
        if meta then
            local stat, label = meta.stat, meta.label
            if meta.virtual == "crit" then
                stat = Caps.CritStat(ctx)
            elseif meta.virtual == "mainstat" then
                stat = Caps.MainStat(ctx)
                label = stat
            end
            local d = Caps.StatData(ctx, key)
            local kind = (d.targets and "target") or meta.kind
            local it = { key = key, kind = kind, label = label, meta = meta, show = meta.show or "rating",
                         desc = d.desc and ("caps.spec." .. d.desc) or ("caps.desc." .. key) }
            local m = meta
            if stat ~= meta.stat then
                m = {}
                for k, v in pairs(meta) do m[k] = v end
                m.stat = stat
            end
            if kind == "hard" then
                it.r = Caps.Hard(ctx, m, d)
                it.status = it.r.status
            elseif kind == "target" then
                it.r = Caps.Target(m, d)
                it.status = it.r.status and (it.r.status == "under" and "under" or "ok") or nil
            elseif kind == "arp" then
                it.r = Caps.ArpState()
            else
                it.value = Caps.ReadStat(stat, it.show)
            end
            out.order[#out.order + 1] = label
            if kind == "more" then
                out.more[#out.more + 1] = it
            else
                out.capped[#out.capped + 1] = it
                if it.status == "under" and not out.next then out.next = key end
            end
        end
    end
    return out
end
