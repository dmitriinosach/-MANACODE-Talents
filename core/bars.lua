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
        local name, rank
        if spellID then name, rank = GetSpellInfo(spellID) end
        if not name and id then name, rank = GetSpellName(id, sub or BOOKTYPE_SPELL) end
        return name and { t = "spell", name = name, rank = rank, tex = tex } or nil
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
    if e.t == "macro" then return "m:" .. e.name end
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
function ns.BarsSave(name, index)
    local list = ns.BarPresets()
    if not index and #list >= MAX then return false, ns.T("msg.bars_full", MAX) end
    local slots, n = snapshot()
    if n == 0 then return false, ns.T("msg.bars_empty") end
    name = name and strtrim(name) or ""
    local p = index and list[index]
    if p then
        p.slots, p.count, p.at = slots, n, time()
        if name ~= "" then p.name = name end
    else
        if name == "" then name = ns.T("bars.default_name", date("%d.%m %H:%M")) end
        list[#list + 1] = { name = name, at = time(), count = n, slots = slots }
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
local function spellIndex(name, rank)
    local found
    local i = 1
    while true do
        local n, r = GetSpellName(i, BOOKTYPE_SPELL)
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
    local idx = GetMacroIndexByName(e.name)
    if idx and idx > 0 then return idx end
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
        local i = spellIndex(e.name, e.rank)
        if not i then return false end
        PickupSpell(i, BOOKTYPE_SPELL)
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
function ns.BarsApply(p)
    local block = ns.BarsBlock()
    if block then return false, block, {} end
    local ops, missing = {}, 0
    local want = {}
    for s = 1, SLOTS do want[s] = ns.BarKey(p.slots[s]) end
    local function settle(key, from, tex)
        local moved = false
        for _ = 1, SLOTS do
            if not (key and GetCursorInfo()) then break end
            local to
            for t = from + 1, SLOTS do
                if want[t] == key and ns.BarKey(ns.BarEntry(t)) ~= want[t] then to = t; break end
            end
            if not to then break end
            local nextKey, nextTex = ns.BarKey(ns.BarEntry(to)), GetActionTexture(to)
            PlaceAction(to)
            ops[#ops + 1] = { slot = to, kind = "move", from = from, tex = tex }
            moved = true
            key, tex = nextKey, nextTex
        end
        ClearCursor()
        return moved
    end
    for s = 1, SLOTS do
        local e = p.slots[s]
        local cur = ns.BarKey(ns.BarEntry(s))
        if cur ~= want[s] then
            local oldTex = GetActionTexture(s)
            if not e then
                PickupAction(s)
                if not settle(cur, s, oldTex) then ops[#ops + 1] = { slot = s, kind = "clear", tex = oldTex } end
            else
                local src
                for o = s + 1, SLOTS do
                    local k = ns.BarKey(ns.BarEntry(o))
                    if k == want[s] and k ~= want[o] then src = o; break end
                end
                if src then
                    PickupAction(src)
                    PlaceAction(s)
                    if GetCursorInfo() then PlaceAction(src) end
                    ClearCursor()
                    ops[#ops + 1] = { slot = s, kind = "move", from = src, tex = e.tex }
                elseif pickup(e) then
                    PlaceAction(s)
                    ops[#ops + 1] = { slot = s, kind = "put", tex = e.tex }
                    settle(cur, s, oldTex)
                else
                    ClearCursor()
                    missing = missing + 1
                end
            end
        end
    end
    if missing > 0 then return true, ns.T("msg.bars_missing", missing), ops end
    return true, nil, ops
end
