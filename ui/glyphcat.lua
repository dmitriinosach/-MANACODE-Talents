local ADDON, ns = ...
local C = ns.C
local ROW_H = ns.GLYPH_ROW_H
local SECTION_H = 24
local ICON = ns.GLYPH_ICON
local SIDE_W = 104
local ROW_INSET = 4
local ALT_INDENT = 14
local SCROLL_W = 20
local COMBAT_ALPHA = 0.45
local QMARK = "Interface\\Icons\\INV_Misc_QuestionMark"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local function refresh()
    if ns.RefreshWindow then ns.RefreshWindow() end
end
local function showTip(self, it)
    if not it then return end
    local hints = {}
    if it.bag and it.secure then
        if not it.target then
            hints[#hints + 1] = ns.Hint("glyph_take")
        elseif it.replace then
            hints[#hints + 1] = ns.Hint("glyph_bag_swap", it.target)
        else
            hints[#hints + 1] = ns.Hint("glyph_bag_put", it.target)
        end
    end
    if it.item and it.item.name then hints[#hints + 1] = ns.Hint("link") end
    ns.GlyphTooltip(self, { item = it, group = it.group or 1, hints = hints })
end
local function hideTip() GameTooltip:Hide() end
local function rowPostClick(self)
    local it = self.it
    if not it then return end
    if IsModifiedClick("CHATLINK") and it.item then
        local _, link = GetItemInfo(it.item.item)
        if link and ChatEdit_GetActiveWindow() then ChatEdit_InsertLink(link) end
        return
    end
end
local use
local function useWheel(self, delta)
    if not InCombatLockdown() then self:Hide() end
    local sc = self.row and self.row.scroll
    local h = sc and sc:GetScript("OnMouseWheel")
    if h then h(sc, delta) end
end
local function useButton()
    if use then return use end
    use = CreateFrame("Button", "HTP_TalentsGlyphUse", UIParent, "SecureActionButtonTemplate")
    use:SetFrameStrata("FULLSCREEN_DIALOG")
    use:RegisterForClicks("LeftButtonUp")
    use:SetAttribute("type", "item")
    use:SetAttribute("shift-type1", "htplink")
    use:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    use:EnableMouseWheel(true)
    use:SetScript("OnEnter", function(self) showTip(self, self.it) end)
    use:SetScript("OnLeave", function(self)
        hideTip()
        if not InCombatLockdown() then self:Hide() end
    end)
    use:SetScript("OnMouseWheel", useWheel)
    use:SetScript("PreClick", function() ns.GlyphSwapQuiet() end)
    use:SetScript("PostClick", function(self)
        local it = self.it
        if not (it and it.item) then return end
        if IsShiftKeyDown() then
            rowPostClick(self)
            return
        end
        ns.SetCursorGlyph(it.item.item)
        if it.target and SpellIsTargeting() and GlyphMatchesSocket(it.target) then
            ns.QuickPlaceGlyph(it.target)
        end
        refresh()
    end)
    use:Hide()
    return use
end
local function coverRow(r)
    local it = r.it
    if InCombatLockdown() then return end
    if not (it and it.secure and it.bag) then
        if use and use.row == r then
            use.it = nil
            use:Hide()
        end
        return
    end
    local b = useButton()
    local k = r:GetEffectiveScale() / UIParent:GetEffectiveScale()
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", r:GetLeft() * k, r:GetTop() * k)
    b:SetWidth(r:GetWidth() * k); b:SetHeight(r:GetHeight() * k)
    b:SetAttribute("item", it.bag.bag .. " " .. it.bag.slot)
    b.row, b.it = r, it
    b:Show()
end
local function recover(c)
    local b = use
    if not (b and b:IsShown()) or InCombatLockdown() then return end
    local r = b.row
    if not r or r.scroll ~= c.scroll then return end
    if r.it and r:IsShown() then
        coverRow(r)
    else
        b.it = nil
        b:Hide()
    end
    if b:IsShown() and GameTooltip:IsOwned(b) then showTip(b, b.it) end
end
local function rowEnter(self)
    showTip(self, self.it)
    coverRow(self)
end
ns.GlyphRowEnter = rowEnter
ns.GlyphRowLeave = hideTip
ns.GlyphRowClick = rowPostClick
function ns.GlyphRowSide(it)
    if it.socket then return ns.Hex("positive") .. ns.T("glyph.in_socket", it.socket) .. "|r" end
    if it.bag then return ns.Hex("positive") .. ns.T("glyph.in_bags", it.bag.count) .. "|r" end
    if it.price then return ns.Money(it.price) end
    return ns.Hex("secondary") .. "—|r"
end
function ns.GlyphRowNameColor(fs, it)
    local c = (it.socket and C.positive) or (not it.bag and C.secondary) or C.text
    fs:SetTextColor(c[1], c[2], c[3])
end
function ns.NewGlyphRow(parent)
    local r = CreateFrame("Button", nil, parent)
    r:SetHeight(ROW_H)
    r:RegisterForClicks("LeftButtonUp")
    r:SetHighlightTexture(WHITE)
    r.icon = ns.GlyphIcon(r, ICON)
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    r.name:SetJustifyH("LEFT")
    r.sub = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    r.sub:SetJustifyH("LEFT")
    r.side = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    r.side:SetPoint("RIGHT", r, "RIGHT", -ROW_INSET, 0)
    r.side:SetWidth(SIDE_W)
    r.side:SetJustifyH("RIGHT")
    r:SetScript("OnEnter", rowEnter)
    r:SetScript("OnLeave", hideTip)
    r:SetScript("PostClick", rowPostClick)
    return r
end
function ns.FillGlyphRow(r, it, width)
    r.it = it
    r:SetWidth(width)
    local hv = C.hover
    r:GetHighlightTexture():SetVertexColor(hv[1], hv[2], hv[3], hv[4] or 1)
    local x = ROW_INSET + (it.when and ALT_INDENT or 0)
    r.icon:ClearAllPoints()
    r.icon:SetPoint("LEFT", r, "LEFT", x, 0)
    r.icon:SetTexture((it.item and it.item.icon) or QMARK)
    r.icon:SetDesaturated(not (it.bag or it.socket) or (it.bag and not it.secure and not it.socket) or false)
    local textW = width - x - ICON - 6 - (SIDE_W + ROW_INSET * 2)
    r.name:SetWidth(textW); r.sub:SetWidth(textW)
    ns.GlyphRowNameColor(r.name, it)
    ns.FitText(r.name, it.name or "?", 1)
    local sub = ns.GlyphGives(ns.PlayerClass(), it.name) or ns.MarkQuoted(it.item and it.item.text) or it.note or ""
    if it.when then sub = ns.T("glyph.alt") .. " " .. it.when end
    r.sub:SetTextColor(C.text[1], C.text[2], C.text[3])
    ns.FitText(r.sub, sub, 1)
    r.name:ClearAllPoints()
    r.sub:ClearAllPoints()
    if sub ~= "" then
        r.name:SetPoint("BOTTOMLEFT", r.icon, "RIGHT", 6, 1)
        r.sub:SetPoint("TOPLEFT", r.icon, "RIGHT", 6, -1)
        r.sub:Show()
    else
        r.name:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
        r.sub:Hide()
    end
    r.side:SetText(ns.GlyphRowSide(it))
    r:Show()
end
local function rowAt(c, i)
    local r = c.rows[i]
    if r then return r end
    r = ns.NewGlyphRow(c.child)
    r.scroll = c.scroll
    c.rows[i] = r
    return r
end
local function sectionAt(c, i)
    local s = c.sections[i]
    if s then return s end
    s = c.child:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    s:SetJustifyH("LEFT")
    c.sections[i] = s
    return s
end
local function byPrice(a, b)
    if (a.price ~= nil) ~= (b.price ~= nil) then return a.price ~= nil end
    if a.price and b.price and a.price ~= b.price then return a.price < b.price end
    return a.name < b.name
end
local function byName(a, b)
    return a.name < b.name
end
function ns.GlyphListBagsOnly()
    return HTP_TalentsDB.glyphFilter == "bags"
end
function ns.GlyphListByPrice()
    return HTP_TalentsDB.glyphSort == "price"
end
function ns.GlyphListToggleBags()
    HTP_TalentsDB.glyphFilter = not ns.GlyphListBagsOnly() and "bags" or nil
    refresh()
end
function ns.GlyphListTogglePrice()
    HTP_TalentsDB.glyphSort = not ns.GlyphListByPrice() and "price" or nil
    refresh()
end
local function render(self, group, major, height, slot)
    local c = self
    c.frame:SetHeight(height)
    c.frame:SetAlpha(InCombatLockdown() and COMBAT_ALPHA or 1)
    local class = ns.PlayerClass()
    local ctx = ns.GlyphContext(group)
    local onlyBags = ns.GlyphListBagsOnly()
    local function aim(it)
        if not (slot and slot.enabled) then return it end
        it.target, it.replace = slot.id, slot.spell and true or nil
        if it.bag and it.secure and it.socket then
            it.secure, it.why = nil, ns.T("glyph.already_in", it.socket)
        end
        return it
    end
    local advice, spec = ns.GlyphAdvice(class, group)
    local advised, picks = {}, {}
    local pk = ns.View.pick
    local planned, planName = {}, nil
    local pg = pk and pk.plan and pk.plan.glyphs
    if pg and ns.View.Own() then
        planName = pk.name
        for i = 1, 3 do
            local id = pg[major and "major" or "minor"][i]
            local e = id and ns.GlyphItem(id)
            if e and e.name and not advised[e.name] then
                advised[e.name] = true
                local it = aim(ns.GlyphRowItem(e, e.name, ctx))
                if not onlyBags or it.bag then planned[#planned + 1] = it end
            end
        end
    end
    for _, a in ipairs(advice) do
        if a.major == major and not advised[a.name] then
            advised[a.name] = true
            local it = aim(ns.GlyphRowItem(a.item, a.name, ctx))
            it.note, it.when, it.advice = a.note, a.when, true
            if not onlyBags or it.bag then picks[#picks + 1] = it end
        end
    end
    local inBags, rest = {}, {}
    local majors, minors = ns.GlyphCatalog(class)
    for _, e in ipairs(major and majors or minors) do
        local name = e.name or "…"
        if not advised[name] then
            local it = aim(ns.GlyphRowItem(e, name, ctx))
            if it.bag then
                inBags[#inBags + 1] = it
            elseif not onlyBags then
                rest[#rest + 1] = it
            end
        end
    end
    table.sort(inBags, byName)
    table.sort(rest, ns.GlyphListByPrice() and byPrice or byName)
    local width = c.child:GetWidth()
    local y, ri, si = 0, 0, 0
    local function section(text, list)
        if #list == 0 then return end
        si = si + 1
        local s = sectionAt(c, si)
        local h = C.heading
        s:SetTextColor(h[1], h[2], h[3])
        s:ClearAllPoints()
        s:SetPoint("TOPLEFT", c.child, "TOPLEFT", ROW_INSET, -(y + 6))
        s:SetText(text)
        s:Show()
        y = y + SECTION_H
        for _, it in ipairs(list) do
            ri = ri + 1
            local r = rowAt(c, ri)
            r:ClearAllPoints()
            r:SetPoint("TOPLEFT", c.child, "TOPLEFT", 0, -y)
            ns.FillGlyphRow(r, it, width)
            y = y + ROW_H
        end
    end
    if planName then section(ns.T("glyph.sec_plan", planName), planned) end
    if spec then section(ns.T("glyph.sec_advice", spec), picks) end
    section(ns.T("glyph.sec_bags"), inBags)
    section(ns.T(major and "glyph.sec_rest_major" or "glyph.sec_rest_minor"), rest)
    for i = ri + 1, #c.rows do
        c.rows[i].it = nil
        c.rows[i]:Hide()
    end
    for i = si + 1, #c.sections do c.sections[i]:Hide() end
    if ri == 0 then
        local s = C.secondary
        c.empty:SetTextColor(s[1], s[2], s[3])
        c.empty:SetText(ns.T("glyph.none_to_put"))
        c.empty:Show()
    else
        c.empty:Hide()
    end
    c.child:SetHeight(math.max(y, 1))
    c.scroll:Sync(y)
    c.frame:Show()
    recover(c)
end
function ns.NewGlyphCatalog(parent, width)
    local c = { rows = {}, sections = {}, Render = render }
    local f = CreateFrame("Frame", nil, parent)
    f:SetWidth(width); f:SetHeight(1)
    c.frame = f
    c.scroll = ns.Kit.Scroll(f)
    c.scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    c.scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -SCROLL_W, 0)
    c.child = c.scroll.child
    c.child:SetWidth(width - SCROLL_W)
    c.empty = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    c.empty:SetPoint("TOPLEFT", f, "TOPLEFT", ROW_INSET, -6)
    c.empty:SetWidth(width - ROW_INSET * 2)
    c.empty:SetJustifyH("LEFT")
    c.empty:Hide()
    f:Hide()
    return c
end
local watch = CreateFrame("Frame")
watch:RegisterEvent("PLAYER_REGEN_ENABLED")
watch:RegisterEvent("PLAYER_REGEN_DISABLED")
watch:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" and use then use:Hide() end
    refresh()
end)
