local ADDON, ns = ...
local C = ns.C
local RUNE = "Interface\\Spellbook\\UI-Glyph-Rune1"
local LOCKED = "Interface\\Spellbook\\UI-GlyphFrame-Locked"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local GLYPH_MINOR = 2
local BREATH_RISE, BREATH_HOLD, BREATH_END = 2, 4, 6
local TINT_CYCLE = 1.5
local view
local natives = {}
local viewGroup = 1
local scanTip
local function glyphLines(id, group)
    scanTip = scanTip or CreateFrame("GameTooltip", "HTP_TalentsGlyphScan", nil, "GameTooltipTemplate")
    scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTip:ClearLines()
    scanTip:SetGlyph(id, group)
    local out = {}
    for i = 2, scanTip:NumLines() or 0 do
        local fs = _G["HTP_TalentsGlyphScanTextLeft" .. i]
        local t = fs and fs:GetText()
        if t and t ~= "" and t ~= GLYPH_SLOT_REMOVE_TOOLTIP and t ~= MAJOR_GLYPH and t ~= MINOR_GLYPH then
            out[#out + 1] = t
        end
    end
    scanTip:Hide()
    return out
end
local socketEnter
local selected
local function socketLeave(self)
    self.hovered = false
    GameTooltip:Hide()
end
local function socketClick(self, button)
    local slot = self.slot
    local id = slot.id
    if IsModifiedClick("CHATLINK") and ChatEdit_GetActiveWindow() then
        local link = GetGlyphLink(id, viewGroup)
        if link then ChatEdit_InsertLink(link) end
        return
    end
    if not ns.IsActiveGroup(viewGroup) then return end
    if button == "RightButton" then
        if IsShiftKeyDown() and slot.spell then
            ns.ShowGlyphPopup("HTP_TALENTS_REMOVE_GLYPH", CONFIRM_REMOVE_GLYPH, slot.name, id)
        end
    elseif slot.spell and SpellIsTargeting() and GlyphMatchesSocket(id) then
        ns.ShowGlyphPopup("HTP_TALENTS_REPLACE_GLYPH", CONFIRM_GLYPH_PLACEMENT, nil, id)
    else
        PlaceGlyphInSocket(id)
    end
end
local function breath(b, elapsed)
    if not (b.slot and b.slot.spell) then
        b.breath = 0
        return 0.6
    end
    local t = (b.breath or 0) + elapsed
    b.breath = t
    if t >= BREATH_END then
        b.breath = 0
        return 0.6
    elseif t <= BREATH_RISE then
        return 0.6 + 0.4 * t / BREATH_RISE
    elseif t >= BREATH_HOLD then
        return 1 - 0.4 * (t - BREATH_HOLD) / (BREATH_END - BREATH_HOLD)
    end
    return 1
end
local function pulse(self, elapsed)
    local targeting = SpellIsTargeting() and ns.IsActiveGroup(viewGroup)
    for _, b in ipairs(self.sockets) do
        b.rim:SetAlpha(breath(b, elapsed))
        local match = targeting and b.slot and b.slot.enabled and GlyphMatchesSocket(b.slot.id)
        if match then
            local t = ((b.tint or 0) + elapsed) % TINT_CYCLE
            local half = TINT_CYCLE / 2
            b.tint = t
            b.glow:SetAlpha(t <= half and t / half or (TINT_CYCLE - t) / half)
            b.glow:Show()
        else
            b.tint = 0
            b.glow:Hide()
        end
        if b.hovered and SpellIsTargeting() then
            SetCursor(match and "CAST_CURSOR" or "CAST_ERROR_CURSOR")
        end
    end
end
local ATLAS = "Interface\\Spellbook\\UI-GlyphFrame"
local ATLAS_PX = 512
local SLOT_EMPTY = { 0.78125, 0.91015625, 0.69921875, 0.828125 }
local SLOT_FILLED = {
    [1] = { 0, 0.12890625, 0.87109375, 1 },
    [2] = { 0.130859375, 0.259765625, 0.87109375, 1 },
    [3] = { 0.392578125, 0.521484375, 0.87109375, 1 },
    [4] = { 0.5234375, 0.65234375, 0.87109375, 1 },
    [5] = { 0.26171875, 0.390625, 0.87109375, 1 },
    [6] = { 0.654296875, 0.783203125, 0.87109375, 1 },
}
local RING_CX, RING_CY = 178, 238
local RING_OFF = {
    [1] = { -1, 122 }, [2] = { 0, -121 }, [3] = { -105, 60 },
    [4] = { 105, -61 }, [5] = { 105, 60 }, [6] = { -107, -61 },
}
local RING_W = 320
local TYPE_LOOK = {
    major = { tint = { 1, 0.25, 0 }, setting = 108, settingCoord = { 0.740234375, 0.953125, 0.484375, 0.697265625 },
              ring = 82, ringY = -1, ringCoord = { 0.767578125, 0.92578125, 0.32421875, 0.482421875 },
              shineCoord = { 0.9609375, 1, 0.9609375, 1 }, bg = 70 },
    minor = { tint = { 0, 0.25, 1 }, setting = 86, settingCoord = { 0.765625, 0.927734375, 0.15625, 0.31640625 },
              ring = 62, ringY = 1, ringCoord = { 0.787109375, 0.908203125, 0.033203125, 0.154296875 },
              shineCoord = { 0.9609375, 1, 0.921875, 0.9609375 }, bg = 64 },
}
local function coords(t, c)
    t:SetTexCoord(c[1], c[2], c[3], c[4])
end
local function makeNativeSocket(parent, id)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(90); b:SetHeight(90)
    b.setting = b:CreateTexture(nil, "BACKGROUND")
    b.setting:SetPoint("CENTER", b, "CENTER", 0, 0)
    b.rim = b.setting
    b.glow = b:CreateTexture(nil, "BORDER")
    b.glow:SetTexture(ATLAS)
    b.glow:SetBlendMode("ADD")
    b.glow:SetPoint("CENTER", b, "CENTER", 0, 0)
    b.glow:Hide()
    b.background = b:CreateTexture(nil, "BORDER")
    b.background:SetTexture(ATLAS)
    b.background:SetPoint("CENTER", b, "CENTER", 0, 0)
    b.glyph = b:CreateTexture(nil, "ARTWORK")
    b.glyph:SetWidth(53); b.glyph:SetHeight(53)
    b.glyph:SetPoint("CENTER", b, "CENTER", 0, 0)
    b.ring = b:CreateTexture(nil, "OVERLAY")
    b.ring:SetTexture(ATLAS)
    b.shine = b:CreateTexture(nil, "OVERLAY")
    b.shine:SetTexture(ATLAS)
    b.shine:SetWidth(16); b.shine:SetHeight(16)
    b.shine:SetPoint("CENTER", b, "CENTER", -9, 12)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:SetScript("OnEnter", function(self) socketEnter(self) end)
    b:SetScript("OnLeave", socketLeave)
    b:SetScript("OnClick", socketClick)
    return b
end
local function fillNativeSocket(b, slot, grey)
    b.slot = slot
    local look = slot.major and TYPE_LOOK.major or TYPE_LOOK.minor
    local dim = grey or (b.dims and not ns.IsActiveGroup(viewGroup)) or false
    for _, t in ipairs({ b.setting, b.glow, b.background, b.glyph, b.ring, b.shine }) do t:SetDesaturated(dim) end
    if not slot.enabled then
        b.setting:SetTexture(LOCKED)
        b.setting:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        b.setting:SetWidth(look.setting); b.setting:SetHeight(look.setting)
        b.background:Hide(); b.glyph:Hide(); b.ring:Hide(); b.shine:Hide()
        return
    end
    b.setting:SetTexture(ATLAS)
    coords(b.setting, look.settingCoord)
    b.setting:SetWidth(look.setting); b.setting:SetHeight(look.setting)
    b.glow:SetWidth(look.setting); b.glow:SetHeight(look.setting)
    coords(b.glow, look.settingCoord)
    b.ring:SetWidth(look.ring); b.ring:SetHeight(look.ring)
    b.ring:ClearAllPoints()
    b.ring:SetPoint("CENTER", b, "CENTER", 0, look.ringY)
    coords(b.ring, look.ringCoord)
    coords(b.shine, look.shineCoord)
    b.background:SetWidth(look.bg); b.background:SetHeight(look.bg)
    b.background:Show(); b.ring:Show(); b.shine:Show()
    if slot.spell then
        coords(b.background, SLOT_FILLED[slot.id] or SLOT_EMPTY)
        b.glyph:SetTexture(slot.icon or RUNE)
        b.glyph:SetVertexColor(look.tint[1], look.tint[2], look.tint[3])
        b.glyph:Show()
    else
        coords(b.background, SLOT_EMPTY)
        b.glyph:Hide()
    end
end
ns.NewGlyphSocket = makeNativeSocket
ns.FillGlyphSocket = fillNativeSocket
local function renderColumn(self, group, w, h)
    viewGroup = group
    local ring = self.frame
    local k = w / RING_W
    local ringH = h / k
    ring:SetScale(k)
    ring:SetWidth(RING_W); ring:SetHeight(ringH)
    local x0, y0 = RING_CX - RING_W / 2, RING_CY - ringH / 2
    ring.bg:SetTexCoord(x0 / ATLAS_PX, (x0 + RING_W) / ATLAS_PX, y0 / ATLAS_PX, (y0 + ringH) / ATLAS_PX)
    ring.bg:SetDesaturated(not ns.IsActiveGroup(group))
    local major, minor = ns.GlyphSlots(group)
    local byId = {}
    for _, s in ipairs(major) do byId[s.id] = s end
    for _, s in ipairs(minor) do byId[s.id] = s end
    for id, b in ipairs(ring.sockets) do
        if byId[id] then fillNativeSocket(b, byId[id]); b:Show() else b:Hide() end
    end
    ring:Show()
end
function ns.NewGlyphColumn(parent)
    local ring = CreateFrame("Frame", nil, parent)
    ring:SetWidth(RING_W); ring:SetHeight(RING_W)
    ring:SetPoint("CENTER", parent, "CENTER", 0, 0)
    local bg = ring:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(ATLAS)
    bg:SetAllPoints(ring)
    ring.bg = bg
    ring.sockets = {}
    for id = 1, 6 do
        local b = makeNativeSocket(ring, id)
        b.dims = true
        b:SetPoint("CENTER", ring, "CENTER", RING_OFF[id][1], RING_OFF[id][2])
        ring.sockets[id] = b
    end
    ring:SetScript("OnUpdate", pulse)
    ring:Hide()
    natives[#natives + 1] = ring
    return { frame = ring, Render = renderColumn }
end
local COL_W = 256
ns.GLYPH_COL_W = COL_W
ns.GLYPH_COL_H = 474
ns.GLYPH_ROW_H = 40
ns.GLYPH_ICON = 30
local DIVIDER_X = COL_W + 9
local RIGHT_X = COL_W + 18
local HEAD_H = 24
local ROW_H = 64
local GROUP_GAP = 14
local SOCKET_SCALE = 0.56
local SOCKET_BOX = 60
local BIG_SCALE = 0.6
local BIG_BOX = 64
local TEXT_GAP = 10
local SEL_BAR = 2
local ROW_INSET = 6
local BLOCK_GAP = 12
local LINE_GAP = 3
local ROW_LINES, GIVES_LINES, NOTE_LINES = 2, 3, 2
local CHIP_H = ns.Kit.H.small
local CHIP_GAP = 4
local PAPER_W = 200
local PAPER_H = PAPER_W * ns.GLYPH_COL_H / COL_W
local PAPER_COORD = {
    (RING_CX - PAPER_W / 2) / ATLAS_PX, (RING_CX + PAPER_W / 2) / ATLAS_PX,
    (RING_CY - PAPER_H / 2) / ATLAS_PX, (RING_CY + PAPER_H / 2) / ATLAS_PX,
}
local ELLIPSIS = "..."
function ns.FitText(fs, text, lines)
    fs:SetText("A")
    local limit = fs:GetStringHeight() * (lines + 0.5)
    fs:SetText(text)
    if fs:GetStringHeight() <= limit then return end
    local words = {}
    for w in text:gmatch("%S+") do words[#words + 1] = w end
    local lo, hi, best = 1, #words - 1, 1
    while lo <= hi do
        local mid = math.floor((lo + hi) / 2)
        fs:SetText(table.concat(words, " ", 1, mid) .. "|r" .. ELLIPSIS)
        if fs:GetStringHeight() <= limit then best, lo = mid, mid + 1 else hi = mid - 1 end
    end
    fs:SetText(table.concat(words, " ", 1, best) .. "|r" .. ELLIPSIS)
end
function ns.GlyphIcon(parent, size)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetWidth(size); t:SetHeight(size)
    t:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    local b = parent:CreateTexture(nil, "BORDER")
    b:SetTexture(WHITE)
    b:SetVertexColor(C.shade[1], C.shade[2], C.shade[3], C.shade[4])
    b:SetPoint("TOPLEFT", t, "TOPLEFT", -1, 1)
    b:SetPoint("BOTTOMRIGHT", t, "BOTTOMRIGHT", 1, -1)
    t.border = b
    return t
end
local function slotItem(slot)
    return slot.name and ns.GlyphItemByName(ns.PlayerClass(), slot.name) or nil
end
local function slotGives(slot)
    if not slot.spell then return nil end
    local gives = ns.GlyphGives(ns.PlayerClass(), slot.name)
    if gives then return gives end
    local e = slotItem(slot)
    if e and e.text then return ns.MarkQuoted(e.text) end
    return ns.MarkQuoted(table.concat(glyphLines(slot.id, viewGroup), " "))
end
local function bagCount(slot, ctx)
    local n, seen = 0, {}
    for id in pairs(ctx.bags) do
        local e = ns.GlyphItem(id)
        if e.name and e.major == slot.major and not ctx.sockets[e.name] and not seen[e.name] then
            seen[e.name] = true
            n = n + 1
        end
    end
    return n
end
local function slotText(slot, ctx)
    local g = C.glyph
    if not slot.enabled then
        return GLYPH_LOCKED, g.sub, ns.GlyphLockText(slot.id) or "", g.text
    elseif not slot.spell then
        local n = bagCount(slot, ctx)
        if n > 0 then return GLYPH_EMPTY, g.sub, ns.T("glyph.empty_bags", n), C.positive end
        return GLYPH_EMPTY, g.sub, ns.T("glyph.empty_sub"), g.text
    end
    return slot.name or "?", g.name, slotGives(slot) or "", g.text
end
local function socketTip(self, anchor)
    local slot = self.slot
    local group = self.group or viewGroup
    if slot.stored then
        ns.GlyphTooltip(self, { group = group, anchor = anchor, body = ns.T("glyph.stored"),
                                title = (not slot.enabled and GLYPH_LOCKED) or slot.name or GLYPH_EMPTY })
        return
    end
    local hints, warn = {}, nil
    local cur = ns.CursorGlyph()
    local c = cur and ns.GlyphItem(cur)
    if c and slot.enabled and ns.IsActiveGroup(group) and not self.opens then
        if c.major ~= slot.major then
            warn = ns.T("glyph.cursor_wrong", c.name or "?")
        elseif slot.spell then
            hints[#hints + 1] = ns.Hint("glyph_replace", slot.name or "?", c.name or "?")
        else
            hints[#hints + 1] = ns.Hint("glyph_put", c.name or "?")
        end
    elseif self.opens then
        hints[#hints + 1] = ns.Hint("glyph_open")
    elseif self.selects and slot.id ~= selected then
        hints[#hints + 1] = ns.Hint("glyph_select")
    end
    if slot.spell and not self.opens then hints[#hints + 1] = ns.Hint("link") end
    local o = { slot = slot, group = group, anchor = anchor, warn = warn, hints = hints }
    if not slot.enabled then
        o.title, o.body = GLYPH_LOCKED, ns.GlyphLockText(slot.id)
    elseif not slot.spell then
        local n = bagCount(slot, ns.GlyphContext(group))
        o.title = GLYPH_EMPTY
        o.body, o.good = n > 0 and ns.T("glyph.empty_bags", n) or ns.T("glyph.empty_sub"), n > 0
    end
    ns.GlyphTooltip(self, o)
end
socketEnter = function(self)
    self.hovered = true
    socketTip(self)
end
local STRIP_SCALE = 0.2
local STRIP_MAJOR = 18
local STRIP_MINOR = 14
local STRIP_GAP = 2
local STRIP_SPLIT = 6
local STRIP_OFF_ALPHA = 0.45
function ns.GlyphSelect(id)
    selected = id
end
local function stripEnter(b)
    b.hovered = true
    socketTip(b, "ANCHOR_BOTTOMRIGHT")
end
local function stripClick(b)
    if b.off or b.slot.stored then return end
    selected = b.slot.id
    ns.View.SetPane("glyphs")
    if ns.RefreshWindow then ns.RefreshWindow() end
end
local function renderStrip(self, group, shown, off, slots)
    local major, minor
    if slots then major, minor = slots[1], slots[2] else major, minor = ns.GlyphSlots(group) end
    local x, n = 0, 0
    for gi, list in ipairs({ major, minor }) do
        if gi == 2 and #major > 0 then x = x + STRIP_SPLIT - STRIP_GAP end
        local size = gi == 1 and STRIP_MAJOR or STRIP_MINOR
        for _, slot in ipairs(list) do
            n = n + 1
            local b = self.orbs[n]
            if not b then
                b = makeNativeSocket(self.frame, slot.id)
                b:SetScale(STRIP_SCALE)
                b.opens = true
                b:SetScript("OnEnter", stripEnter)
                b:SetScript("OnClick", stripClick)
                self.orbs[n] = b
            end
            b:SetWidth(size / STRIP_SCALE); b:SetHeight(size / STRIP_SCALE)
            b.group, b.off = group, off
            fillNativeSocket(b, slot, off)
            b:SetAlpha(off and STRIP_OFF_ALPHA or 1)
            b.rim:SetAlpha(slot.spell and 1 or 0.6)
            b.chosen = shown and slot.id == selected and slot.enabled and not slot.stored
            if b.chosen then
                b.glow:SetAlpha(1)
                b.glow:Show()
            else
                b.glow:Hide()
            end
            b:SetFrameLevel(self.frame:GetFrameLevel() + 1)
            b:ClearAllPoints()
            b:SetPoint("LEFT", self.frame, "LEFT", x / STRIP_SCALE, 0)
            b:Show()
            x = x + size + STRIP_GAP
        end
    end
    for i = n + 1, #self.orbs do self.orbs[i]:Hide() end
    self.frame:SetWidth(math.max(1, x - STRIP_GAP))
end
ns.GLYPH_STRIP_W = 3 * STRIP_MAJOR + 3 * STRIP_MINOR + 4 * STRIP_GAP + STRIP_SPLIT
function ns.GlyphStrip(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetHeight(STRIP_MAJOR)
    f:SetWidth(ns.GLYPH_STRIP_W)
    return { frame = f, orbs = {}, Render = renderStrip }
end
local function rowClick(self, button)
    if button == "LeftButton" and not SpellIsTargeting() and not IsModifiedClick("CHATLINK") then
        selected = self.slot.id
        if ns.RefreshWindow then ns.RefreshWindow() end
        return
    end
    socketClick(self, button)
    selected = self.slot.id
end
local function makeRow(parent, id)
    local r = CreateFrame("Button", nil, parent)
    r.sel = r:CreateTexture(nil, "BACKGROUND")
    r.sel:SetTexture(WHITE)
    r.sel:SetAllPoints(r)
    r.bar = r:CreateTexture(nil, "BORDER")
    r.bar:SetTexture(WHITE)
    r.bar:SetWidth(SEL_BAR)
    r.bar:SetPoint("TOPLEFT", r, "TOPLEFT", 0, 0)
    r.bar:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", 0, 0)
    r:SetHighlightTexture(WHITE)
    r.socket = makeNativeSocket(r, id)
    r.socket:EnableMouse(false)
    r.socket:SetScale(SOCKET_SCALE)
    r.socket:ClearAllPoints()
    r.socket:SetPoint("CENTER", r, "LEFT", (ROW_INSET + SOCKET_BOX / 2) / SOCKET_SCALE, 0)
    r.rim, r.glow = r.socket.setting, r.socket.glow
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    r.name:SetJustifyH("LEFT")
    r.sub = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    r.sub:SetJustifyH("LEFT"); r.sub:SetJustifyV("TOP")
    r.sub:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -LINE_GAP)
    r.selects = true
    r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    r:SetScript("OnEnter", function(self) socketEnter(self) end)
    r:SetScript("OnLeave", socketLeave)
    r:SetScript("OnClick", rowClick)
    return r
end
local function fillRow(r, slot, ctx, width, height)
    r.slot = slot
    r:SetWidth(width); r:SetHeight(height)
    fillNativeSocket(r.socket, slot)
    local x = ROW_INSET + SOCKET_BOX + TEXT_GAP
    local name, nameC, sub, subC = slotText(slot, ctx)
    r.name:SetWidth(width - x - ROW_INSET); r.sub:SetWidth(width - x - ROW_INSET)
    r.name:SetTextColor(nameC[1], nameC[2], nameC[3])
    ns.FitText(r.name, name, 1)
    r.sub:SetTextColor(subC[1], subC[2], subC[3])
    ns.FitText(r.sub, sub, ROW_LINES)
    local block = r.name:GetStringHeight() + LINE_GAP + r.sub:GetStringHeight()
    r.name:ClearAllPoints()
    r.name:SetPoint("TOPLEFT", r, "TOPLEFT", x, -math.max(0, math.floor((height - block) / 2)))
    local sc, g, hv = C.selected, C.gold, C.hover
    r.sel:SetVertexColor(sc[1], sc[2], sc[3], sc[4])
    r.bar:SetVertexColor(g[1], g[2], g[3])
    r:GetHighlightTexture():SetVertexColor(hv[1], hv[2], hv[3], hv[4] or 1)
    if slot.id == selected then
        r.sel:Show(); r.bar:Show()
    else
        r.sel:Hide(); r.bar:Hide()
    end
    r:Show()
end
local function noteText(ctx)
    if not ctx.active then
        return ns.T("glyph.note_idle"), C.glyph.sub
    elseif InCombatLockdown() then
        return ns.T("glyph.in_combat"), C.glyph.sub
    elseif SpellIsTargeting() then
        local cur = ns.CursorGlyph()
        local c = cur and ns.GlyphItem(cur)
        if c and c.name then return ns.T("glyph.note_cursor", c.name), C.glyph.name end
        return ns.T("window.glyphs_targeting"), C.glyph.name
    end
    return nil, C.glyph.text
end
local function adviceLine(slot)
    if not slot.spell then return "", C.text end
    local a, spec = ns.GlyphAdviceFor(ns.PlayerClass(), viewGroup, slot.name)
    if not spec then return "", C.text end
    if a then return ns.T("glyph.in_advice", spec), C.positive end
    return ns.T("glyph.not_advice", spec), C.secondary
end
local function setChip(b, label, tip, on)
    b.text:SetText(label)
    b.tipTitle, b.tipBody = label, tip
    b.active = on
    b:SetWidth(b.text:GetStringWidth() + 14)
    b:Restyle()
end
local function renderDetail(v, slot, ctx, width, height)
    local d = v.detail
    d:SetWidth(width); d:SetHeight(height)
    fillNativeSocket(v.big, slot)
    v.big.slot = slot
    local name, nameC = slotText(slot, ctx)
    local kind = slot.major and MAJOR_GLYPH or MINOR_GLYPH
    local textX = BIG_BOX + TEXT_GAP
    local textW = width - textX
    v.bigName:SetWidth(textW); v.bigSub:SetWidth(textW); v.bigAdvice:SetWidth(textW)
    v.bigName:SetTextColor(nameC[1], nameC[2], nameC[3])
    ns.FitText(v.bigName, name, 1)
    local s = C.secondary
    v.bigSub:SetTextColor(s[1], s[2], s[3])
    v.bigSub:SetText(ns.T("glyph.socket_title", slot.id, kind))
    local adv, advC = adviceLine(slot)
    if not slot.enabled then
        adv, advC = ns.GlyphLockText(slot.id) or "", C.text
    elseif not slot.spell then
        local n = bagCount(slot, ctx)
        adv, advC = n > 0 and ns.T("glyph.empty_bags", n) or ns.T("glyph.empty_sub"), n > 0 and C.positive or C.text
    end
    v.bigAdvice:SetTextColor(advC[1], advC[2], advC[3])
    ns.FitText(v.bigAdvice, adv, NOTE_LINES)
    local y = BIG_BOX + BLOCK_GAP
    local zone = v.gives
    if slot.spell then
        local h, t = C.heading, C.text
        zone.slot = slot
        zone:ClearAllPoints()
        zone:SetPoint("TOPLEFT", d, "TOPLEFT", 0, -y)
        zone:SetWidth(width)
        zone.head:SetTextColor(h[1], h[2], h[3])
        zone.head:SetText(ns.T("glyph.gives_head"))
        zone.text:SetWidth(width)
        zone.text:SetTextColor(t[1], t[2], t[3])
        ns.FitText(zone.text, slotGives(slot) or "", GIVES_LINES)
        local zh = zone.head:GetStringHeight() + LINE_GAP + zone.text:GetStringHeight()
        zone:SetHeight(zh)
        zone:Show()
        y = y + zh + BLOCK_GAP
    else
        zone:Hide()
    end
    if not slot.enabled then
        v.rule:Hide(); v.listHead:Hide(); v.listHow:Hide(); v.chipBags:Hide(); v.chipPrice:Hide()
        v.list.frame:Hide()
        return
    end
    local l = C.line
    v.rule:SetVertexColor(l[1], l[2], l[3], l[4] or 1)
    v.rule:ClearAllPoints()
    v.rule:SetPoint("TOPLEFT", d, "TOPLEFT", 0, -y)
    v.rule:SetPoint("TOPRIGHT", d, "TOPRIGHT", 0, -y)
    v.rule:Show()
    y = y + 1 + 8
    local h = C.heading
    v.listHead:SetTextColor(h[1], h[2], h[3])
    v.listHead:SetText(ns.T(slot.spell and "glyph.replace_head" or "glyph.put_head"))
    v.listHead:ClearAllPoints()
    v.listHead:SetPoint("LEFT", d, "TOPLEFT", 0, -(y + CHIP_H / 2))
    v.listHead:Show()
    setChip(v.chipPrice, ns.T("glyph.sort_price"), ns.T("glyph.sort_tip"), ns.GlyphListByPrice())
    setChip(v.chipBags, ns.T("glyph.filter_bags"), ns.T("glyph.bags_tip"), ns.GlyphListBagsOnly())
    v.chipPrice:ClearAllPoints()
    v.chipPrice:SetPoint("RIGHT", d, "TOPRIGHT", 0, -(y + CHIP_H / 2))
    v.chipBags:ClearAllPoints()
    v.chipBags:SetPoint("RIGHT", v.chipPrice, "LEFT", -CHIP_GAP, 0)
    v.chipPrice:Show(); v.chipBags:Show()
    y = y + CHIP_H + 6
    local how = v.listHow
    how:SetWidth(0)
    how:SetText(ns.T(slot.spell and "glyph.bag_click_swap" or "glyph.bag_click_put"))
    if ctx.active and not InCombatLockdown() and (how:GetStringWidth() or 0) <= width then
        local sc = C.secondary
        how:SetTextColor(sc[1], sc[2], sc[3])
        how:ClearAllPoints()
        how:SetPoint("TOPLEFT", d, "TOPLEFT", 0, -y)
        how:Show()
        y = y + (how:GetStringHeight() or 0) + 6
    else
        how:Hide()
    end
    v.list.frame:ClearAllPoints()
    v.list.frame:SetPoint("TOPLEFT", d, "TOPLEFT", 0, -y)
    v.list:Render(viewGroup, slot.major, math.max(ns.GLYPH_ROW_H, height - y), slot)
end
local function givesEnter(self)
    if not self.slot then return end
    local spell = ns.GlyphSpell(ns.PlayerClass(), self.slot.name)
    if spell and GetSpellInfo(spell) then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink("spell:" .. spell)
        GameTooltip:Show()
        return
    end
    ns.GlyphTooltip(self, { slot = self.slot, group = viewGroup })
end
local function rule(parent)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetTexture(WHITE)
    return t
end
local function ensureView(host)
    if view then return view end
    view = { frame = CreateFrame("Frame", nil, host), host = host, rows = {}, heads = {}, pulse = {} }
    local f = view.frame
    f:SetPoint("TOPLEFT", host, "TOPLEFT", 0, 0)
    view.paper = f:CreateTexture(nil, "BACKGROUND")
    view.paper:SetTexture(ATLAS)
    view.paper:SetTexCoord(PAPER_COORD[1], PAPER_COORD[2], PAPER_COORD[3], PAPER_COORD[4])
    view.paper:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    view.paper:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    view.paper:SetWidth(COL_W)
    f.sockets = view.pulse
    f:SetScript("OnUpdate", pulse)
    for id = 1, (NUM_GLYPH_SLOTS or 6) do
        view.rows[id] = makeRow(f, id)
        view.pulse[#view.pulse + 1] = view.rows[id]
    end
    for i = 1, 2 do
        local h = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        h:SetJustifyH("LEFT")
        view.heads[i] = h
    end
    view.note = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    view.note:SetJustifyH("LEFT"); view.note:SetJustifyV("BOTTOM")
    view.note:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", ROW_INSET, 0)
    view.note:SetWidth(COL_W - ROW_INSET * 2)
    view.divider = rule(f)
    view.divider:SetWidth(1)
    view.divider:SetPoint("TOPLEFT", f, "TOPLEFT", DIVIDER_X, 0)
    view.divider:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", DIVIDER_X, 0)
    local d = CreateFrame("Frame", nil, f)
    d:SetPoint("TOPLEFT", f, "TOPLEFT", RIGHT_X, 0)
    view.detail = d
    view.big = makeNativeSocket(d, 0)
    view.big:SetScale(BIG_SCALE)
    view.big:SetPoint("CENTER", d, "TOPLEFT", (BIG_BOX / 2) / BIG_SCALE, -(BIG_BOX / 2) / BIG_SCALE)
    view.pulse[#view.pulse + 1] = view.big
    view.bigName = d:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    view.bigName:SetJustifyH("LEFT")
    view.bigName:SetPoint("TOPLEFT", d, "TOPLEFT", BIG_BOX + TEXT_GAP, -4)
    view.bigSub = d:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    view.bigSub:SetJustifyH("LEFT")
    view.bigSub:SetPoint("TOPLEFT", view.bigName, "BOTTOMLEFT", 0, -LINE_GAP)
    view.bigAdvice = d:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    view.bigAdvice:SetJustifyH("LEFT"); view.bigAdvice:SetJustifyV("TOP")
    view.bigAdvice:SetPoint("TOPLEFT", view.bigSub, "BOTTOMLEFT", 0, -LINE_GAP)
    local zone = CreateFrame("Button", nil, d)
    zone.head = zone:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    zone.head:SetJustifyH("LEFT")
    zone.head:SetPoint("TOPLEFT", zone, "TOPLEFT", 0, 0)
    zone.text = zone:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    zone.text:SetJustifyH("LEFT"); zone.text:SetJustifyV("TOP")
    zone.text:SetPoint("TOPLEFT", zone.head, "BOTTOMLEFT", 0, -LINE_GAP)
    zone:SetScript("OnEnter", givesEnter)
    zone:SetScript("OnLeave", socketLeave)
    zone:Hide()
    view.gives = zone
    view.rule = rule(d)
    view.rule:SetHeight(1)
    view.listHead = d:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    view.listHead:SetJustifyH("LEFT")
    view.listHow = d:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    view.listHow:SetJustifyH("LEFT")
    view.listHow:Hide()
    view.chipBags = ns.Kit.Button(d, CHIP_H)
    view.chipBags.onClick = function() ns.GlyphListToggleBags() end
    view.chipPrice = ns.Kit.Button(d, CHIP_H)
    view.chipPrice.onClick = function() ns.GlyphListTogglePrice() end
    return view
end
function ns.GlyphRender(host, group, width, height, colOnly)
    viewGroup = group
    local v = ensureView(host)
    if v.host ~= host then
        v.frame:SetParent(host)
        v.frame:ClearAllPoints()
        v.frame:SetPoint("TOPLEFT", host, "TOPLEFT", 0, 0)
        v.host = host
    end
    v.frame:SetWidth(width); v.frame:SetHeight(height)
    local ctx = ns.GlyphContext(group)
    local major, minor = ns.GlyphSlots(group)
    local valid = false
    for _, list in ipairs({ major, minor }) do
        for _, s in ipairs(list) do
            if s.id == selected then valid = true end
        end
    end
    if not valid then selected = major[1] and major[1].id or 1 end
    local y, sel = 0, nil
    local titles = { ns.T("window.glyphs_major"), ns.T("window.glyphs_minor") }
    local pc = C.glyph.paper
    v.paper:SetVertexColor(pc[1], pc[2], pc[3], pc[4] or 1)
    for gi, list in ipairs({ major, minor }) do
        local h = v.heads[gi]
        local hc = gi == 1 and C.glyph.major or C.glyph.minor
        h:SetTextColor(hc[1], hc[2], hc[3])
        h:ClearAllPoints()
        h:SetPoint("LEFT", v.frame, "TOPLEFT", ROW_INSET, -(y + HEAD_H / 2))
        h:SetText(titles[gi])
        y = y + HEAD_H
        for _, s in ipairs(list) do
            local r = v.rows[s.id]
            r.selects = not colOnly
            r:ClearAllPoints()
            r:SetPoint("TOPLEFT", v.frame, "TOPLEFT", 0, -y)
            fillRow(r, s, ctx, COL_W, ROW_H)
            if colOnly then r.sel:Hide(); r.bar:Hide() end
            if s.id == selected then sel = s end
            y = y + ROW_H
        end
        y = y + GROUP_GAP
    end
    local note, noteC = noteText(ctx)
    if note then
        v.note:SetTextColor(noteC[1], noteC[2], noteC[3])
        ns.FitText(v.note, note, 2)
        v.note:Show()
    else
        v.note:Hide()
    end
    if colOnly or not sel then
        v.detail:Hide()
        v.divider:Hide()
        v.big.hovered = false
    else
        local l = C.line
        v.divider:SetVertexColor(l[1], l[2], l[3], l[4] or 1)
        v.divider:Show()
        v.detail:Show()
        if not v.list then
            v.list = ns.NewGlyphCatalog(v.detail, width - RIGHT_X)
        end
        renderDetail(v, sel, ctx, width - RIGHT_X, height)
    end
    v.frame:Show()
end
function ns.GlyphHide()
    if view then view.frame:Hide() end
end
local function anyShown()
    if view and view.frame:IsVisible() then return true end
    for _, f in ipairs(natives) do
        if f:IsVisible() then return true end
    end
    return false
end
local sfx = CreateFrame("Frame")
sfx:RegisterEvent("GLYPH_ADDED")
sfx:RegisterEvent("GLYPH_UPDATED")
sfx:RegisterEvent("GLYPH_REMOVED")
sfx:SetScript("OnEvent", function(_, event, index)
    if not anyShown() then return end
    local _, glyphType = GetGlyphSocketInfo(index or 1)
    local kind = glyphType == GLYPH_MINOR and "Minor" or "Major"
    PlaySound("Glyph_" .. kind .. (event == "GLYPH_REMOVED" and "Destroy" or "Create"))
end)
