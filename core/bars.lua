local ADDON, ns = ...
local SLOTS = 120
local MAX = 40
ns.BARS_MAX = MAX
ns.BARS_SLOTS = SLOTS
local MAX_ACCOUNT = MAX_ACCOUNT_MACROS or 36
local MAX_CHAR = MAX_CHARACTER_MACROS or 18
local movedIn
local function moveCharPresets()
    local left = false
    for key, ch in pairs(HTP_TalentsDB.chars or {}) do
        if type(ch) == "table" and ch.bars and not ch.class then left = true end
        if type(ch) == "table" and ch.bars and ch.class then
            local list = HTP_TalentsDB.barsByClass[ch.class] or {}
            HTP_TalentsDB.barsByClass[ch.class] = list
            for _, p in ipairs(ch.bars) do
                p.who = p.who or key
                list[#list + 1] = p
            end
            ch.bars = nil
        end
    end
    movedIn = (not left) and HTP_TalentsDB.chars or nil
end
function ns.BarPresets(class)
    HTP_TalentsDB.barsByClass = HTP_TalentsDB.barsByClass or {}
    if movedIn == nil or movedIn ~= HTP_TalentsDB.chars then moveCharPresets() end
    if not class then
        local _, own = UnitClass("player")
        class = own or "?"
    end
    local list = HTP_TalentsDB.barsByClass[class]
    if not list then
        list = {}
        HTP_TalentsDB.barsByClass[class] = list
    end
    return list
end
function ns.BarsWho(p)
    local who = p and p.who
    if not who or who == ns.CharKey() then return nil end
    local name, realm = who:match("^(.-)%-(.*)$")
    if not name then return who end
    if realm == "" or realm == ((GetRealmName and GetRealmName()) or "") then return name end
    return name .. " (" .. realm .. ")"
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
local retry
function ns.BarsSetNo()
    local g = GetActiveTalentGroup(false, false) or 1
    if g == 2 and ns.CircleLoaded then return ns.CircleLoaded() end
    return g
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
        p.set = ns.BarsSetNo()
        p.who = ns.CharKey()
        p.build = ns.BarsCurrentBuild()
        if name ~= "" then p.name = name end
    else
        if name == "" then name = ns.BarsDefaultName() end
        list[#list + 1] = { name = name, at = time(), count = n, slots = slots,
                            group = GetActiveTalentGroup(false, false) or 1, set = ns.BarsSetNo(),
                            build = ns.BarsCurrentBuild(), who = ns.CharKey() }
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
    local list = ns.BarPresets()
    if retry and retry.p == list[index] then retry = nil end
    table.remove(list, index)
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
        if GetCursorInfo() then return true, ns.BarKey({ t = "macro", name = e.name, char = i > MAX_ACCOUNT }) end
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
    local want, cur, tex, entry = {}, {}, {}, {}
    for s = 1, SLOTS do
        want[s] = ns.BarKey(p.slots[s])
        entry[s] = ns.BarEntry(s)
        cur[s] = ns.BarKey(entry[s])
        tex[s] = GetActionTexture(s)
    end
    local before = {}
    for s = 1, SLOTS do before[s] = tex[s] end
    ops.before = before
    local function wasAt(key, s)
        for o = 1, SLOTS do
            if o ~= s and cur[o] == key and cur[o] ~= want[o] then return o end
        end
        return nil
    end
    local function stranded(o)
        local e = entry[o]
        if not (e and e.t == "item") then return false end
        return (GetItemCount and GetItemCount(e.id) or 0) == 0
    end
    local kept = {}
    for s = 1, SLOTS do
        if cur[s] and cur[s] ~= want[s] then
            if stranded(s) then
                kept[s] = true
            else
                PickupAction(s)
                ClearCursor()
                if not want[s] then ops[#ops + 1] = { slot = s, kind = "clear", tex = tex[s] } end
            end
        end
    end
    for s = 1, SLOTS do
        if want[s] and cur[s] ~= want[s] and not kept[s] then
            for o in pairs(kept) do
                if cur[o] == want[s] then
                    PickupAction(o)
                    PlaceAction(s)
                    ClearCursor()
                    kept[o] = nil
                    cur[o], cur[s] = nil, want[s]
                    ops[#ops + 1] = { slot = s, kind = "move", from = o, tex = tex[o] }
                    break
                end
            end
        end
    end
    for o in pairs(kept) do
        PickupAction(o)
        ClearCursor()
        if not want[o] then ops[#ops + 1] = { slot = o, kind = "clear", tex = tex[o] } end
    end
    for s = 1, SLOTS do
        local e = p.slots[s]
        if e and cur[s] ~= want[s] then
            local picked, realKey = pickup(e)
            if picked then
                PlaceAction(s)
                ClearCursor()
                if realKey then want[s] = realKey end
                local from = wasAt(want[s], s)
                ops[#ops + 1] = { slot = s, kind = from and "move" or "put", from = from, tex = e.tex }
            else
                ClearCursor()
                missing, skip[s] = missing + 1, true
            end
        end
    end
    verify.want, verify.skip, verify.wait = want, skip, 0.5
    verify:Show()
    if missing > 0 then
        local slots = {}
        for s in pairs(skip) do slots[s] = true end
        retry = { p = p, untilT = GetTime() + RETRY_T, set = ns.BarsSetNo(), slots = slots }
        return true, ns.T("msg.bars_missing", missing), ops
    end
    retry = nil
    return true, nil, ops
end
function ns.BarsClear()
    local block = ns.BarsBlock()
    if block then return false, block, {} end
    local ops, before = {}, {}
    for s = 1, SLOTS do
        before[s] = GetActionTexture(s)
        if HasAction(s) then
            PickupAction(s)
            ClearCursor()
            ops[#ops + 1] = { slot = s, kind = "clear", tex = before[s] }
        end
    end
    ops.before = before
    retry = nil
    return true, nil, ops
end
local retryWatch = CreateFrame("Frame")
for _, ev in ipairs({ "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB", "UPDATE_MACROS", "BAG_UPDATE", "COMPANION_LEARNED",
                      "ACTIVE_TALENT_GROUP_CHANGED" }) do
    retryWatch:RegisterEvent(ev)
end
retryWatch:SetScript("OnEvent", function(self, event)
    if event == "ACTIVE_TALENT_GROUP_CHANGED" then retry = nil; return end
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
    if GetTime() > r.untilT or ns.BarsSetNo() ~= r.set then retry = nil; return end
    if ns.BarsBlock() then return end
    for s in pairs(r.slots) do
        local e = r.p.slots[s]
        if HasAction(s) or not e then
            r.slots[s] = nil
        elseif pickup(e) then
            PlaceAction(s)
            ClearCursor()
            r.slots[s] = nil
        else
            ClearCursor()
        end
    end
    if not next(r.slots) then retry = nil end
end)
retryWatch:Hide()
