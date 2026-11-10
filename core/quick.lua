local ADDON, ns = ...
local waitCircle
local MINOR_IDS = { 2, 3, 5 }
local SOCKET_LEVEL = { 15, 15, 50, 30, 70, 80 }
local SCALE_MIN, SCALE_MAX, SCALE_STEP = 0.6, 1.6, 0.1
local CONFIRM_SECONDS = 3
ns.QUICK_SCALE_STEP, ns.QUICK_SCALE_MIN, ns.QUICK_SCALE_MAX = SCALE_STEP, SCALE_MIN, SCALE_MAX
function ns.QuickDB()
    HTP_TalentsDB.quick = HTP_TalentsDB.quick or {}
    local q = HTP_TalentsDB.quick
    if not q.show then
        q.show = {}
        local used = q.shown == true or q.pos or q.compact or (type(q.gear) == "table" and next(q.gear))
        if used and not q.minor then
            for _, id in ipairs(MINOR_IDS) do q.show[id] = false end
        end
    end
    q.compact, q.minor = nil, nil
    return q
end
function ns.QuickGear()
    local q = ns.QuickDB()
    local ch, stored = ns.CharDB()
    if not ch.gear then
        ch.gear = (stored and type(q.gear) == "table" and q.gear) or {}
        if stored then q.gear = nil end
    end
    return ch.gear
end
function ns.QuickGearExists(name)
    if not name then return false end
    if not GetEquipmentSetInfoByName then return true end
    return GetEquipmentSetInfoByName(name) ~= nil
end
function ns.QuickShown()
    return ns.QuickDB().shown ~= false
end
function ns.QuickSetShown(on)
    ns.QuickDB().shown = on and true or false
end
function ns.QuickShows(key)
    return ns.QuickDB().show[key] ~= false
end
function ns.QuickSetShow(key, on)
    if on then
        ns.QuickDB().show[key] = nil
    else
        ns.QuickDB().show[key] = false
    end
end
function ns.QuickLocked()
    return ns.QuickDB().locked == true
end
function ns.QuickSetLocked(on)
    ns.QuickDB().locked = on and true or nil
end
function ns.QuickScale()
    local v = tonumber(ns.QuickDB().scale) or 1
    return math.min(SCALE_MAX, math.max(SCALE_MIN, v))
end
function ns.QuickSetScale(v)
    v = math.min(SCALE_MAX, math.max(SCALE_MIN, math.floor((tonumber(v) or 1) * 100 + 0.5) / 100))
    ns.QuickDB().scale = v ~= 1 and v or nil
end
function ns.QuickSocketLevel(id)
    return SOCKET_LEVEL[id] or 80
end
function ns.QuickCircles(edit)
    local out = {}
    local spec = ns.QuickShows("spec")
    if edit or spec then out[#out + 1] = { key = "spec", on = spec } end
    local major, minor = ns.GlyphSlots(GetActiveTalentGroup() or 1)
    local any = false
    for _, list in ipairs({ major, minor }) do
        for _, s in ipairs(list) do any = any or s.enabled end
    end
    if not any then return out end
    for _, list in ipairs({ major, minor }) do
        for n, s in ipairs(list) do
            local on = s.enabled and ns.QuickShows(s.id)
            if edit or on then
                out[#out + 1] = { key = s.id, on = on, slot = s, n = n, locked = not s.enabled or nil }
            end
        end
    end
    return out
end
function ns.QuickCircleName(c)
    if c.key == "spec" then return ns.T("quick.orb_spec") end
    return ns.T(c.slot.major and "quick.orb_major" or "quick.orb_minor", c.n)
end
function ns.QuickUnlockText(id)
    local own = ns.GlyphLockText(id)
    if own and own ~= "" then return own end
    return ns.T("quick.unlock_at", ns.QuickSocketLevel(id))
end
function ns.QuickGlyphList(slot, group)
    local out = {}
    if not slot.enabled then return out end
    local ctx = ns.GlyphContext(group)
    local major, minor = ns.GlyphCatalog(ns.PlayerClass())
    for _, e in ipairs(slot.major and major or minor) do
        if e.name and ctx.bags[e.item] and not ctx.sockets[e.name] then
            local it = ns.GlyphRowItem(e, e.name, ctx)
            it.target, it.replace = slot.id, slot.spell ~= nil
            out[#out + 1] = it
        end
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end
local armed
function ns.QuickArm(item, socket)
    armed = { item = item, socket = socket, till = GetTime() + CONFIRM_SECONDS }
end
function ns.QuickDisarm()
    armed = nil
end
function ns.QuickArmed(item, socket)
    if armed and GetTime() > armed.till then armed = nil end
    if not armed then return false end
    return item == nil or (armed.item == item and armed.socket == socket)
end
function ns.QuickSets()
    local out = { { key = "1", group = 1 } }
    if (GetNumTalentGroups() or 1) < 2 then return out end
    if ns.CircleThirdSet() then
        out[2] = { key = "2", group = 2, set = 2 }
        out[3] = { key = "3", group = 2, set = 3 }
    else
        out[2] = { key = "2", group = 2 }
    end
    return out
end
function ns.QuickSetActive(s)
    if s.group ~= (GetActiveTalentGroup() or 1) then return false end
    return not s.set or ns.CircleLoaded() == s.set
end
function ns.QuickGearSets()
    local out = {}
    for i = 1, (GetNumEquipmentSets and GetNumEquipmentSets() or 0) do
        local name = GetEquipmentSetInfo(i)
        if name then out[#out + 1] = name end
    end
    return out
end
function ns.QuickCycleGear(key)
    local gear, sets = ns.QuickGear(), ns.QuickGearSets()
    local cur, nextName = gear[key], nil
    if not cur then
        nextName = sets[1]
    else
        for i, name in ipairs(sets) do
            if name == cur then nextName = sets[i + 1] end
        end
    end
    gear[key] = nextName
end
local function wear(name)
    if InCombatLockdown() then return end
    if ns.WearGear then ns.WearGear(name) elseif name and UseEquipmentSet then UseEquipmentSet(name) end
end
function ns.QuickBlock()
    if InCombatLockdown() then return ns.T("quick.off_combat") end
    if ns.SpecCast() then return ns.T("tip.off_casting") end
    if ns.LearnPending() or ns.CirclePending() or waitCircle then return ns.T("tip.off_wait") end
    return nil
end
function ns.QuickApplySet(s)
    if ns.QuickBlock() then return end
    local gear = ns.QuickGear()[s.key]
    if s.set and ns.CircleLoaded() ~= s.set then
        waitCircle = s
        ns.CircleLoad(s.set)
        return
    end
    if s.group ~= (GetActiveTalentGroup() or 1) then
        ns.ActivateSpec(s.group)
    else
        wear(gear)
    end
end
function ns.QuickPlaceGlyph(socket, confirmed)
    if not SpellIsTargeting() then return end
    local _, _, spell = GetGlyphSocketInfo(socket)
    if spell and not confirmed then
        ns.ShowGlyphPopup("HTP_TALENTS_REPLACE_GLYPH", CONFIRM_GLYPH_PLACEMENT, nil, socket)
    else
        PlaceGlyphInSocket(socket)
    end
end
local watch = CreateFrame("Frame")
watch:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
watch:RegisterEvent("PLAYER_TALENT_UPDATE")
watch:RegisterEvent("PLAYER_REGEN_DISABLED")
watch:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        waitCircle = nil
    end
    if ns.QuickRefresh then ns.QuickRefresh() end
end)
watch:SetScript("OnUpdate", function()
    if not waitCircle or ns.CirclePending() then return end
    local s = waitCircle
    waitCircle = nil
    if ns.CircleLoaded() == s.set then ns.QuickApplySet(s) end
    if ns.QuickRefresh then ns.QuickRefresh() end
end)
