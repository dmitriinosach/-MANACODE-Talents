local ADDON, ns = ...
local SLOTS = 120
local MAX = 20
ns.BARS_MAX = MAX
ns.BARS_SLOTS = SLOTS
local MAX_ACCOUNT = MAX_ACCOUNT_MACROS or 36
local MAX_CHAR = MAX_CHARACTER_MACROS or 18
function ns.BarPresets()
    local ch = ns.CharDB()
    ch.bars = ch.bars or {}
    return ch.bars
end
function ns.BarEntry(slot)
    if not HasAction(slot) then return nil end
    local t, id, sub, spellID = GetActionInfo(slot)
    local tex = GetActionTexture(slot)
    if t == "spell" then
        local book = sub == BOOKTYPE_PET and BOOKTYPE_PET or BOOKTYPE_SPELL
        local name, rank
        if id and id > 0 then name, rank = GetSpellName(id, book) end
        if not name and spellID then name, rank = GetSpellInfo(spellID) end
        return name and { t = "spell", name = name, rank = rank, book = book ~= BOOKTYPE_SPELL and book or nil, tex = tex } or nil
    elseif t == "macro" then
        local name, icon, body = GetMacroInfo(id)
        return name and { t = "macro", name = name, body = body, char = id > MAX_ACCOUNT, tex = icon or tex } or nil
    elseif t == "item" then
        return { t = "item", id = id, tex = tex }
    elseif t == "companion" then
        local _, _, spell = GetCompanionInfo(sub, id)
        return spell and { t = "companion", kind = sub, spell = spell, tex = tex } or nil
    elseif t == "equipmentset" then
        return { t = "equipmentset", name = id, tex = tex }
    end
    return nil
end
function ns.BarKey(e)
    if not e then return nil end
    if e.t == "spell" then return "s:" .. e.name end
    if e.t == "macro" then return (e.char and "mc:" or "mg:") .. e.name end
    if e.t == "item" then return "i:" .. tostring(e.id) end
    if e.t == "companion" then return "c:" .. tostring(e.spell) end
    if e.t == "equipmentset" then return "e:" .. tostring(e.name) end
    return nil
end
local function snapshot()
    local slots, n = {}, 0
    for s = 1, SLOTS do
        local e = ns.BarEntry(s)
        if e then slots[s], n = e, n + 1 end
    end
    return slots, n
end
function ns.BarsCurrentBuild()
    return ns.SetBuildName(GetActiveTalentGroup(false, false) or 1)
end
function ns.BarsDefaultName()
    return ns.BarsCurrentBuild() or ns.T("bars.default_name", date("%d.%m %H:%M"))
end
function ns.BarsSave(name, index)
    local list = ns.BarPresets()
    if not index and #list >= MAX then return false, ns.T("msg.bars_full", MAX) end
    local slots, n = snapshot()
    if n == 0 then return false, ns.T("msg.bars_empty") end
    name = name and strtrim(name) or ""
    local p = index and list[index]
    if p then
        p.slots, p.count, p.at, p.group = slots, n, time(), GetActiveTalentGroup(false, false) or 1
        p.build = ns.BarsCurrentBuild()
        if name ~= "" then p.name = name end
    else
        if name == "" then name = ns.BarsDefaultName() end
        list[#list + 1] = { name = name, at = time(), count = n, slots = slots,
                            group = GetActiveTalentGroup(false, false) or 1, build = ns.BarsCurrentBuild() }
    end
    return true, nil
end
function ns.BarsRename(index, name)
    local p = ns.BarPresets()[index]
    if not p then return false, ns.T("msg.no_slot") end
    name = name and strtrim(name) or ""
    if name == "" then return false, ns.T("msg.empty_name") end
    p.name = name
    return true, nil
end
function ns.BarsDelete(index)
    table.remove(ns.BarPresets(), index)
end
function ns.BarsIcon(p)
    for s = 1, SLOTS do
        local e = p.slots[s]
        if e and e.tex then return e.tex end
    end
    return nil
end
function ns.BarsDiff(p)
    local n = 0
    for s = 1, SLOTS do
        if ns.BarKey(p.slots[s]) ~= ns.BarKey(ns.BarEntry(s)) then n = n + 1 end
    end
    return n
end
local function spellIndex(name, rank, book)
    local found
    local i = 1
    while true do
        local n, r = GetSpellName(i, book or BOOKTYPE_SPELL)
        if not n then break end
        if n == name then
            found = i
            if rank and r == rank then return i end
        end
        i = i + 1
    end
    return found
end
local function macroIcon(tex)
    if tex and GetNumMacroIcons then
        for i = 1, GetNumMacroIcons() do
            if GetMacroIconInfo(i) == tex then return i end
        end
    end
    return 1
end
local function macroIndex(e)
    local general, perCharN = GetNumMacros()
    local function scan(from, to)
        local hit
        for i = from, to do
            local n, _, body = GetMacroInfo(i)
            if n == e.name then
                if e.body == nil or body == e.body then return i end
                hit = hit or i
            end
        end
        return hit
    end
    local own = function() return scan(MAX_ACCOUNT + 1, MAX_ACCOUNT + (perCharN or 0)) end
    local shared = function() return scan(1, general or 0) end
    local idx
    if e.char then idx = own() or shared() else idx = shared() or own() end
    if idx then return idx end
    if not (e.body and CreateMacro) then return nil end
    local general, char = GetNumMacros()
    local perChar = e.char and true or false
    if perChar and char >= MAX_CHAR then perChar = false end
    if not perChar and general >= MAX_ACCOUNT then
        if char >= MAX_CHAR then return nil end
        perChar = true
    end
    idx = CreateMacro(e.name, macroIcon(e.tex), e.body, perChar and 1 or nil)
    return idx and idx > 0 and idx or nil
end
local function pickup(e)
    if e.t == "spell" then
        local i = spellIndex(e.name, e.rank, e.book)
        if not i then return false end
        PickupSpell(i, e.book or BOOKTYPE_SPELL)
    elseif e.t == "macro" then
        local i = macroIndex(e)
        if not i then return false end
        PickupMacro(i)
    elseif e.t == "item" then
        PickupItem(e.id)
    elseif e.t == "companion" then
        local found
        for i = 1, (GetNumCompanions(e.kind) or 0) do
            local _, _, spell = GetCompanionInfo(e.kind, i)
            if spell == e.spell then found = i; break end
        end
        if not found then return false end
        PickupCompanion(e.kind, found)
    elseif e.t == "equipmentset" then
        if not (PickupEquipmentSetByName and ns.GearExists(e.name)) then return false end
        PickupEquipmentSetByName(e.name)
    else
        return false
    end
    return GetCursorInfo() ~= nil
end
function ns.BarsBlock()
    if InCombatLockdown() then return ns.T("msg.bars_combat") end
    if GetCursorInfo() then return ns.T("msg.bars_cursor") end
    return nil
end
local RETRY_T = 10
local RETRY_DELAY = 0.3
local retry
local verify = CreateFrame("Frame")
verify:Hide()
verify:SetScript("OnUpdate", function(self, dt)
    self.wait = self.wait - dt
    if self.wait > 0 then return end
    self:Hide()
    local bad = 0
    for s = 1, SLOTS do
        if not self.skip[s] and ns.BarKey(ns.BarEntry(s)) ~= self.want[s] then bad = bad + 1 end
    end
    if bad > 0 then ns.warn(ns.T("msg.bars_wrong", bad)) end
end)
function ns.BarsApply(p)
    local block = ns.BarsBlock()
    if block then return false, block, {} end
    local ops, missing, skip = {}, 0, {}
    local want, cur, tex = {}, {}, {}
    for s = 1, SLOTS do
        want[s] = ns.BarKey(p.slots[s])
        cur[s] = ns.BarKey(ns.BarEntry(s))
        tex[s] = GetActionTexture(s)
    end
    local before = {}
    for s = 1, SLOTS do before[s] = tex[s] end
    ops.before = before
    local hand, handTex
    local function take(s)
        PickupAction(s)
        hand, handTex = cur[s], tex[s]
        cur[s], tex[s] = nil, nil
    end
    local function place(s)
        PlaceAction(s)
        cur[s], hand = hand, cur[s]
        tex[s], handTex = handTex, tex[s]
    end
    local function drop()
        ClearCursor()
        hand, handTex = nil, nil
    end
    local function wanted(key, from)
        for t = from + 1, SLOTS do
            if want[t] == key and cur[t] ~= want[t] then return t end
        end
        return nil
    end
    local function settle(from)
        local moved = false
        for _ = 1, SLOTS do
            local to = hand and wanted(hand, from)
            if not to then break end
            local carried = handTex
            place(to)
            ops[#ops + 1] = { slot = to, kind = "move", from = from, tex = carried }
            moved = true
        end
        drop()
        return moved
    end
    for s = 1, SLOTS do
        if cur[s] ~= want[s] then
            local e = p.slots[s]
            local oldTex = tex[s]
            if not e then
                take(s)
                if not settle(s) then ops[#ops + 1] = { slot = s, kind = "clear", tex = oldTex } end
            else
                local src
                for o = s + 1, SLOTS do
                    if cur[o] == want[s] and cur[o] ~= want[o] then src = o; break end
                end
                if src then
                    take(src)
                    place(s)
                    if hand then place(src) end
                    drop()
                    ops[#ops + 1] = { slot = s, kind = "move", from = src, tex = e.tex }
                elseif pickup(e) then
                    hand, handTex = want[s], e.tex
                    place(s)
                    ops[#ops + 1] = { slot = s, kind = "put", tex = e.tex }
                    settle(s)
                else
                    ClearCursor()
                    missing, skip[s] = missing + 1, true
                end
            end
        end
    end
    verify.want, verify.skip, verify.wait = want, skip, 0.5
    verify:Show()
    if missing > 0 then
        if not (retry and retry.p == p) then retry = { p = p, untilT = GetTime() + RETRY_T } end
        return true, ns.T("msg.bars_missing", missing), ops
    end
    retry = nil
    return true, nil, ops
end
local retryWatch = CreateFrame("Frame")
for _, ev in ipairs({ "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB", "UPDATE_MACROS", "BAG_UPDATE", "COMPANION_LEARNED" }) do
    retryWatch:RegisterEvent(ev)
end
retryWatch:SetScript("OnEvent", function(self)
    if not retry then return end
    self.wait = RETRY_DELAY
    self:Show()
end)
retryWatch:SetScript("OnUpdate", function(self, dt)
    self.wait = (self.wait or 0) - dt
    if self.wait > 0 then return end
    self:Hide()
    local r = retry
    if not r then return end
    if GetTime() > r.untilT then retry = nil; return end
    if ns.BarsBlock() then return end
    ns.BarsApply(r.p)
end)
retryWatch:Hide()
