local ADDON, ns = ...
local BAGS = 4
local RETRY_SECONDS = 0.5
local RETRY_MAX = 20
local GOLD = "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t"
local SILVER = "|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t"
local items = {}
local majorOf = {}
for _, lists in pairs(ns.glyphItems or {}) do
    for _, id in ipairs(lists.major) do majorOf[id] = true end
    for _, id in ipairs(lists.minor) do majorOf[id] = false end
end
local scanTip
local function scanner()
    scanTip = scanTip or CreateFrame("GameTooltip", "HTP_TalentsGlyphItemScan", nil, "GameTooltipTemplate")
    scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTip:ClearLines()
    return scanTip
end
local function pattern(fmt)
    if not fmt then return nil end
    local p = fmt:gsub("([%(%)%.%+%-%*%?%[%]%^%$])", "%%%1"):gsub("%%%d?%$?[sd]", ".+")
    return "^" .. p .. "$"
end
local SKIP = {}
for _, fmt in ipairs({ ITEM_CLASSES_ALLOWED, ITEM_MIN_LEVEL, ITEM_UNIQUE, ITEM_SOULBOUND,
                       ITEM_BIND_ON_PICKUP, ITEM_BIND_ON_EQUIP, ITEM_BIND_ON_USE }) do
    local p = pattern(fmt)
    if p then SKIP[#SKIP + 1] = p end
end
local function longestLine(link)
    local tip = scanner()
    local ok = pcall(tip.SetHyperlink, tip, link)
    if not ok then tip:Hide(); return nil end
    local best
    for i = 2, tip:NumLines() or 0 do
        local fs = _G["HTP_TalentsGlyphItemScanTextLeft" .. i]
        local t = fs and fs:GetText()
        local skip = not t or t == "" or t == MAJOR_GLYPH or t == MINOR_GLYPH
        for _, p in ipairs(SKIP) do
            if not skip and t:match(p) then skip = true end
        end
        if not skip and (not best or #t > #best) then best = t end
    end
    tip:Hide()
    return best
end
local function effectText(id)
    local best = longestLine("item:" .. id)
    if best and ITEM_SPELL_TRIGGER_ONUSE then
        best = best:gsub("^" .. ITEM_SPELL_TRIGGER_ONUSE .. "%s*", "")
    end
    return best
end
local spellTexts = {}
function ns.SpellText(id)
    local t = spellTexts[id]
    if t == nil then
        t = longestLine("spell:" .. id) or false
        spellTexts[id] = t
    end
    return t or nil
end
local retry = CreateFrame("Frame")
retry:Hide()
local retryLeft, retryAt = 0, 0
local gaveUp = {}
local function askLater()
    if retryLeft > 0 then return end
    retryLeft, retryAt = RETRY_MAX, 0
    retry:Show()
end
function ns.GlyphItemGaveUp(id)
    return gaveUp[id] == true
end
function ns.GlyphRetrying()
    return retryLeft > 0
end
function ns.GlyphItem(id)
    local e = items[id]
    if e and e.name then return e end
    e = e or { item = id, major = majorOf[id] ~= false }
    items[id] = e
    local name, _, _, _, _, _, _, _, _, icon = GetItemInfo(id)
    if name then
        e.name, e.icon = name, icon
        e.text = effectText(id)
        gaveUp[id] = nil
    elseif not gaveUp[id] then
        scanner():SetHyperlink("item:" .. id)
        askLater()
    end
    return e
end
retry:SetScript("OnUpdate", function(self, elapsed)
    retryAt = retryAt + elapsed
    if retryAt < RETRY_SECONDS then return end
    retryAt = 0
    retryLeft = retryLeft - 1
    local last = retryLeft <= 0
    local missing, resolved = false, false
    for id, e in pairs(items) do
        if not e.name and not gaveUp[id] then
            ns.GlyphItem(id)
            if e.name then resolved = true else missing = true end
        end
    end
    if not missing or last then
        if missing then
            for id, e in pairs(items) do
                if not e.name then gaveUp[id] = true end
            end
        end
        retryLeft = 0
        self:Hide()
    end
    if not resolved then return end
    if ns.RefreshWindow then ns.RefreshWindow() end
    if ns.QuickRefresh then ns.QuickRefresh() end
end)
function ns.GlyphCatalog(class)
    local lists = ns.glyphItems and ns.glyphItems[class]
    local major, minor = {}, {}
    for _, id in ipairs(lists and lists.major or {}) do major[#major + 1] = ns.GlyphItem(id) end
    for _, id in ipairs(lists and lists.minor or {}) do minor[#minor + 1] = ns.GlyphItem(id) end
    return major, minor
end
local bags
function ns.GlyphBags()
    if bags then return bags end
    bags = {}
    for bag = 0, BAGS do
        for slot = 1, GetContainerNumSlots(bag) or 0 do
            local link = GetContainerItemLink(bag, slot)
            local id = link and tonumber(link:match("item:(%d+)"))
            if id and majorOf[id] ~= nil then
                local _, count = GetContainerItemInfo(bag, slot)
                local b = bags[id]
                if b then
                    b.count = b.count + (count or 1)
                else
                    bags[id] = { count = count or 1, bag = bag, slot = slot }
                end
            end
        end
    end
    return bags
end
function ns.GlyphPrice(id)
    if type(Atr_GetAuctionBuyout) == "function" then
        local ok, price = pcall(Atr_GetAuctionBuyout, id)
        if ok and type(price) == "number" and price > 0 then return price end
    end
    local db = type(AuctionScanDB) == "table" and AuctionScanDB.marketCache
    local market = db and db[(GetRealmName() or "") .. "|" .. (UnitFactionGroup("player") or "")]
    local quote = market and market.items and market.items[id] and market.items[id].quote
    if quote and type(quote.price) == "number" and quote.price > 0 then return quote.price end
    return nil
end
function ns.Money(copper)
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    if g > 0 then return g .. GOLD .. " " .. s .. SILVER end
    return s .. SILVER
end
local function spellName(spell)
    return spell and GetSpellInfo(spell) or nil
end
function ns.GlyphItemByName(class, name)
    if not name then return nil end
    local major, minor = ns.GlyphCatalog(class)
    for _, list in ipairs({ major, minor }) do
        for _, e in ipairs(list) do
            if e.name == name then return e end
        end
    end
    return nil
end
function ns.MarkSpells(text)
    if not text then return nil end
    local open = ns.Hex("spell")
    text = text:gsub("{s:(%d+)}", function(id)
        local name = GetSpellInfo(tonumber(id))
        return name and (open .. name .. "|r") or "?"
    end)
    return (text:gsub("{i:(%d+)}", function(id)
        local name = GetItemInfo(tonumber(id))
        return name and (open .. name .. "|r") or "?"
    end))
end
function ns.MarkQuoted(text)
    if not text then return nil end
    local open = ns.Hex("spell")
    return (text:gsub('"([^"|]+)"', function(name) return '"' .. open .. name .. '|r"' end))
end
function ns.InlineSpells(text, plain)
    if not text then return nil end
    local open, close = "", ""
    if not plain then open, close = ns.Hex("heading"), "|r" end
    text = text:gsub("{s:(%d+)}", function(id)
        local name, _, icon = GetSpellInfo(tonumber(id))
        if not name then return "?" end
        if plain then return name end
        return "|T" .. (icon or "") .. ":0|t " .. open .. name .. close
    end)
    return (text:gsub("{i:(%d+)}", function(id)
        local name = GetItemInfo(tonumber(id))
        return open .. (name or "?") .. close
    end))
end
local entryByName = {}
local function glyphEntry(class, name)
    if not name then return nil end
    local map = entryByName[class]
    if not map then
        map = {}
        for id, e in pairs(ns.glyphDB or {}) do
            local n = e.class == class and e.gives and spellName(id)
            if n then map[n] = e end
        end
        if next(map) then entryByName[class] = map end
    end
    return map[name]
end
function ns.GlyphGives(class, name)
    local e = glyphEntry(class, name)
    return e and ns.MarkSpells(ns.GlyphText(e.gives)) or nil
end
function ns.GlyphSpell(class, name)
    local e = glyphEntry(class, name)
    local id = e and e.gives:match("{s:(%d+)}")
    return id and tonumber(id) or nil
end
function ns.GlyphVariant(class, group)
    local grid = ns.ReadTalentGrid(group)
    local best, pts = 1, -1
    for i, t in ipairs(grid or {}) do
        if (t.points or 0) > pts then best, pts = i, t.points or 0 end
    end
    return ns.DefaultVariant(class, best)
end
function ns.GlyphAdvice(class, group)
    return ns.GlyphAdviceVariant(class, ns.GlyphVariant(class, group))
end
function ns.GlyphAdviceVariant(class, variant)
    local rec = variant and ns.SpecData(ns.glyphs, class, variant)
    local out = {}
    if not rec then return out, nil end
    for _, kind in ipairs({ "major", "minor" }) do
        for _, pick in ipairs(rec[kind] or {}) do
            local name = spellName(pick.glyph)
            if name then
                out[#out + 1] = {
                    name = name, item = ns.GlyphItemByName(class, name), major = kind == "major",
                    note = ns.MarkSpells(ns.GlyphText(pick.note)),
                    when = ns.MarkSpells(ns.GlyphText(pick.when)),
                }
            end
        end
    end
    return out, ns.SpecName(class, variant)
end
function ns.GlyphContext(group)
    local ctx = { bags = ns.GlyphBags(), sockets = {}, active = ns.IsActiveGroup(group), group = group }
    local major, minor = ns.GlyphSlots(group)
    for _, list in ipairs({ major, minor }) do
        for _, s in ipairs(list) do
            if s.name then ctx.sockets[s.name] = s.id end
        end
    end
    return ctx
end
function ns.GlyphRowItem(e, name, ctx)
    local id = e and e.item
    local it = { item = e, name = name, bag = id and ctx.bags[id] or nil, socket = ctx.sockets[name],
                 price = id and ns.GlyphPrice(id) or nil, group = ctx.group }
    if it.bag then
        if not ctx.active then
            it.why = ns.T("window.glyphs_inactive")
        elseif InCombatLockdown() then
            it.why = ns.T("glyph.in_combat")
        else
            it.secure = true
        end
    end
    return it
end
function ns.GlyphAdviceFor(class, group, name)
    local advice, spec = ns.GlyphAdvice(class, group)
    if not name then return nil, spec end
    for _, a in ipairs(advice) do
        if a.name == name then return a, spec end
    end
    return nil, spec
end
local TIP_DESC_CHARS = 220
local function cutText(text, limit)
    local out, n = {}, 0
    for word in text:gmatch("%S+") do
        local len = #word:gsub("[\128-\191]", "")
        if n > 0 and n + 1 + len > limit then return table.concat(out, " ") .. "..." end
        out[#out + 1] = word
        n = n + (n > 0 and 1 or 0) + len
    end
    return text
end
function ns.GlyphTooltip(owner, o)
    local C = ns.C
    local tip = GameTooltip
    local slot, it = o.slot, o.item
    local class = ns.PlayerClass()
    local name
    tip:SetOwner(owner, o.anchor or "ANCHOR_RIGHT")
    if o.title then
        tip:AddLine(o.title, 1, 1, 1, true)
        if o.body and o.body ~= "" then
            local c = o.good and C.positive or C.text
            tip:AddLine(o.body, c[1], c[2], c[3], true)
        end
    elseif slot and slot.spell then
        tip:SetGlyph(slot.id, o.group)
        name = slot.name
    elseif it then
        if it.bag then
            tip:SetBagItem(it.bag.bag, it.bag.slot)
        elseif it.item then
            tip:SetHyperlink("item:" .. it.item.item)
        else
            tip:AddLine(it.name or "?", 1, 1, 1)
        end
        name = it.name
    end
    if name then
        local spellId = ns.GlyphSpell(class, name)
        local spell = spellId and GetSpellInfo(spellId)
        if spell then
            local h, t = C.heading, C.text
            tip:AddLine(" ")
            tip:AddLine(ns.T("glyph.spell_of", ns.Hex("spell") .. spell .. "|r"), h[1], h[2], h[3], true)
            local desc = ns.SpellText(spellId)
            if desc then tip:AddLine(cutText(desc, TIP_DESC_CHARS), t[1], t[2], t[3], true) end
        end
        local a, spec = ns.GlyphAdviceFor(class, o.group, name)
        if a and spec then
            local p = C.positive
            tip:AddLine(" ")
            tip:AddLine(ns.T("glyph.in_advice", spec), p[1], p[2], p[3], true)
            if a.when then tip:AddLine(ns.T("glyph.alt") .. " " .. a.when, p[1], p[2], p[3], true) end
            if a.note then tip:AddLine(a.note, p[1], p[2], p[3], true) end
        end
    end
    if it and it.price then tip:AddLine(ns.T("glyph.price", ns.Money(it.price)), 1, 1, 1) end
    local warn = o.warn or (it and it.bag and not it.secure and it.why) or nil
    if warn then
        local a = C.alert
        tip:AddLine(warn, a[1], a[2], a[3], true)
    end
    ns.Kit.TipHints(tip, o.hints)
    tip:Show()
end
local cursorItem
function ns.SetCursorGlyph(id)
    cursorItem = id
end
function ns.CursorGlyph()
    if cursorItem and not SpellIsTargeting() then cursorItem = nil end
    return cursorItem
end
local watch = CreateFrame("Frame")
watch:RegisterEvent("BAG_UPDATE")
watch:SetScript("OnEvent", function()
    bags = nil
    if ns.GlyphsOnScreen and ns.GlyphsOnScreen() and ns.RefreshSoon then ns.RefreshSoon() end
end)
function ns.GlyphPlanNames(g, kind)
    local names = {}
    for i = 1, 3 do
        local id = g and g[kind] and g[kind][i]
        if id then names[#names + 1] = ns.GlyphItem(id).name or "..." end
    end
    return #names > 0 and table.concat(names, ", ") or nil
end
function ns.PlanTooltip(tip, plan)
    if not plan then return end
    local h, t, s = ns.C.heading, ns.C.text, ns.C.secondary
    local major = ns.GlyphPlanNames(plan.glyphs, "major")
    local minor = ns.GlyphPlanNames(plan.glyphs, "minor")
    if major or minor then
        tip:AddLine(" ")
        tip:AddLine(ns.T("tip.plan_glyphs"), h[1], h[2], h[3])
        if major then tip:AddLine(ns.T("tip.plan_major", major), t[1], t[2], t[3], true) end
        if minor then tip:AddLine(ns.T("tip.plan_minor", minor), t[1], t[2], t[3], true) end
        tip:AddLine(ns.T("tip.plan_only"), s[1], s[2], s[3], true)
    end
    if plan.note then
        tip:AddLine(" ")
        tip:AddLine(ns.T("tip.plan_note"), h[1], h[2], h[3])
        tip:AddLine(plan.note, t[1], t[2], t[3], true)
    end
end
