local ADDON, ns = ...
local C = ns.C
local WHITE = "Interface\\Buttons\\WHITE8X8"
local COL_W = 256
local DIVIDER_X = COL_W + 8
local RIGHT_X = DIVIDER_X + 9
local HEAD_H = 26
local ROW_H = 58
local GROUP_GAP = 6
local ROW_INSET = 8
local ICON = 36
local TEXT_GAP = 10
local SEL_BAR = 2
local LINE_GAP = 2
local LIST_ROW_H = 36
local LIST_ICON = 26
local LIST_HEAD_H = 24
local SCROLL_W = 22
local NOTE_MAX = 600
local NOTE_PAD = 8
local EMPTY_ALPHA = 0.35
local view
local noteView
local sel = { kind = "major", i = 1 }
local function gives(class, id)
    local e = id and ns.GlyphItem(id)
    if not (e and e.name) then return nil end
    return ns.GlyphGives(class, e.name) or ns.MarkQuoted(e.text) or nil
end
local function put(plan, id)
    local list = plan.glyphs[sel.kind]
    for i = 1, 3 do
        if list[i] == id then list[i] = nil end
    end
    list[sel.i] = id
    for i = 1, 3 do
        if not list[i] then
            sel.i = i
            break
        end
    end
    if ns.RefreshWindow then ns.RefreshWindow() end
end
local function hideTip(self)
    self.hovered = false
    GameTooltip:Hide()
end
local function slotEnter(self)
    local id = self.plan.glyphs[self.kind][self.i]
    local e = id and ns.GlyphItem(id)
    local hints = {}
    if not (sel.kind == self.kind and sel.i == self.i) then hints[#hints + 1] = ns.Hint("plan_select") end
    if id then hints[#hints + 1] = ns.Hint("plan_clear") end
    if e then
        ns.GlyphTooltip(self, { item = { item = e, name = e.name }, group = ns.View.Group(), hints = hints })
    else
        ns.GlyphTooltip(self, { title = ns.T(self.kind == "major" and "glyph.plan_empty_major" or "glyph.plan_empty_minor"),
                                body = ns.T("glyph.plan_empty_tip"), hints = hints })
    end
end
local function slotClick(self, button)
    if button == "RightButton" then
        self.plan.glyphs[self.kind][self.i] = nil
    else
        sel.kind, sel.i = self.kind, self.i
    end
    if ns.RefreshWindow then ns.RefreshWindow() end
end
local function makeSlot(parent)
    local r = CreateFrame("Button", nil, parent)
    r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    r.fill = r:CreateTexture(nil, "BACKGROUND")
    r.fill:SetTexture(WHITE)
    r.fill:SetAllPoints(r)
    r.bar = r:CreateTexture(nil, "BORDER")
    r.bar:SetTexture(WHITE)
    r.bar:SetWidth(SEL_BAR)
    r.bar:SetPoint("TOPLEFT", r, "TOPLEFT", 0, 0)
    r.bar:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", 0, 0)
    r:SetHighlightTexture(WHITE)
    r.icon = ns.GlyphIcon(r, ICON)
    r.icon:SetPoint("LEFT", r, "LEFT", ROW_INSET + 4, 0)
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    r.name:SetJustifyH("LEFT")
    r.sub = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    r.sub:SetJustifyH("LEFT"); r.sub:SetJustifyV("TOP")
    r.sub:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -LINE_GAP)
    r:SetScript("OnEnter", slotEnter)
    r:SetScript("OnLeave", hideTip)
    r:SetScript("OnClick", slotClick)
    return r
end
local function fillSlot(r, class, plan, kind, i)
    r.plan, r.kind, r.i = plan, kind, i
    r:SetWidth(COL_W); r:SetHeight(ROW_H)
    local id = plan.glyphs[kind][i]
    local e = id and ns.GlyphItem(id)
    local x = ROW_INSET + 4 + ICON + TEXT_GAP
    local w = COL_W - x - ROW_INSET
    r.name:SetWidth(w); r.sub:SetWidth(w)
    local g = C.glyph
    if e then
        r.icon:SetTexture(e.icon or ns.QMARK)
        r.icon:SetAlpha(1)
        r.name:SetTextColor(g.name[1], g.name[2], g.name[3])
        ns.FitText(r.name, e.name or "...", 1)
        r.sub:SetTextColor(g.text[1], g.text[2], g.text[3])
        ns.FitText(r.sub, gives(class, id) or "", 2)
    else
        r.icon:SetTexture(ns.QMARK)
        r.icon:SetAlpha(EMPTY_ALPHA)
        r.name:SetTextColor(g.sub[1], g.sub[2], g.sub[3])
        r.name:SetText(ns.T("glyph.plan_empty"))
        r.sub:SetTextColor(g.text[1], g.text[2], g.text[3])
        ns.FitText(r.sub, ns.T("glyph.plan_empty_sub"), 2)
    end
    local block = r.name:GetStringHeight() + LINE_GAP + r.sub:GetStringHeight()
    r.name:ClearAllPoints()
    r.name:SetPoint("TOPLEFT", r, "TOPLEFT", x, -math.max(0, math.floor((ROW_H - block) / 2)))
    local sc, gold, hv = C.selected, C.gold, C.hover
    r.fill:SetVertexColor(sc[1], sc[2], sc[3], sc[4] or 1)
    r.bar:SetVertexColor(gold[1], gold[2], gold[3])
    r:GetHighlightTexture():SetVertexColor(hv[1], hv[2], hv[3], hv[4] or 1)
    if sel.kind == kind and sel.i == i then
        r.fill:Show(); r.bar:Show()
    else
        r.fill:Hide(); r.bar:Hide()
    end
    r:Show()
end
local function listEnter(self)
    local e = self.e
    if not e then return end
    local hints = { ns.Hint("plan_put", sel.i) }
    ns.GlyphTooltip(self, { item = { item = e, name = e.name }, group = ns.View.Group(), hints = hints })
end
local function listClick(self)
    if self.e and self.plan then put(self.plan, self.e.item) end
end
local function listRowAt(c, i)
    local r = c.rows[i]
    if r then return r end
    r = CreateFrame("Button", nil, c.child)
    r:SetHeight(LIST_ROW_H)
    r:SetHighlightTexture(WHITE)
    r.icon = ns.GlyphIcon(r, LIST_ICON)
    r.icon:SetPoint("LEFT", r, "LEFT", 6, 0)
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    r.name:SetJustifyH("LEFT")
    r.name:SetPoint("BOTTOMLEFT", r.icon, "RIGHT", 6, 1)
    r.sub = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.sub:SetJustifyH("LEFT")
    r.sub:SetPoint("TOPLEFT", r.icon, "RIGHT", 6, -1)
    r.side = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.side:SetJustifyH("RIGHT")
    r.side:SetPoint("RIGHT", r, "RIGHT", -6, 0)
    r:SetScript("OnEnter", listEnter)
    r:SetScript("OnLeave", hideTip)
    r:SetScript("OnClick", listClick)
    c.rows[i] = r
    return r
end
local function listHeadAt(c, i)
    local s = c.heads[i]
    if s then return s end
    s = c.child:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    s:SetJustifyH("LEFT")
    c.heads[i] = s
    return s
end
local function byName(a, b)
    return (a.name or "") < (b.name or "")
end
local function renderList(v, class, plan, ranks, width, height)
    local c = v.list
    c.frame:SetWidth(width); c.frame:SetHeight(height - v.listTop)
    c.child:SetWidth(width - SCROLL_W)
    local major = sel.kind == "major"
    local where = {}
    for kind, list in pairs(plan.glyphs) do
        for i = 1, 3 do
            if list[i] then where[list[i]] = { kind = kind, i = i } end
        end
    end
    local tab = ns.DominantTab and ns.RanksTotal(ranks) > 0 and ns.DominantTab(ranks) or nil
    local variant = tab and ns.DefaultVariant(class, tab)
    local advice, spec = {}, nil
    if variant then advice, spec = ns.GlyphAdviceVariant(class, variant) end
    local seen, picks, rest = {}, {}, {}
    for _, a in ipairs(advice) do
        local e = a.item
        if a.major == major and e and e.item and not seen[e.item] then
            seen[e.item] = true
            picks[#picks + 1] = e
        end
    end
    local majors, minors = ns.GlyphCatalog(class)
    for _, e in ipairs(major and majors or minors) do
        if not seen[e.item] then rest[#rest + 1] = e end
    end
    table.sort(rest, byName)
    local w = width - SCROLL_W
    local y, ri, hi = 0, 0, 0
    local h, t, s = C.heading, C.text, C.secondary
    local function section(title, list)
        if #list == 0 then return end
        hi = hi + 1
        local head = listHeadAt(c, hi)
        head:SetTextColor(h[1], h[2], h[3])
        head:ClearAllPoints()
        head:SetPoint("TOPLEFT", c.child, "TOPLEFT", 6, -(y + 6))
        head:SetText(title)
        head:Show()
        y = y + LIST_HEAD_H
        for _, e in ipairs(list) do
            ri = ri + 1
            local r = listRowAt(c, ri)
            r.e, r.plan = e, plan
            r:SetWidth(w)
            r:ClearAllPoints()
            r:SetPoint("TOPLEFT", c.child, "TOPLEFT", 0, -y)
            local hv = C.hover
            r:GetHighlightTexture():SetVertexColor(hv[1], hv[2], hv[3], hv[4] or 1)
            r.icon:SetTexture(e.icon or ns.QMARK)
            local at = where[e.item]
            local sideText = at and ns.T(at.kind == "major" and "glyph.plan_at_major" or "glyph.plan_at_minor", at.i) or ""
            r.side:SetText(sideText)
            local p = C.positive
            r.side:SetTextColor(p[1], p[2], p[3])
            local textW = w - 6 - LIST_ICON - 6 - (r.side:GetStringWidth() + 12)
            r.name:SetWidth(textW); r.sub:SetWidth(textW)
            local nc = at and C.positive or t
            r.name:SetTextColor(nc[1], nc[2], nc[3])
            ns.FitText(r.name, e.name or "...", 1)
            r.sub:SetTextColor(s[1], s[2], s[3])
            ns.FitText(r.sub, gives(class, e.item) or "", 1)
            r:Show()
            y = y + LIST_ROW_H
        end
    end
    if spec then section(ns.T("glyph.sec_advice", spec), picks) end
    section(ns.T(major and "glyph.plan_all_major" or "glyph.plan_all_minor"), rest)
    for i = ri + 1, #c.rows do c.rows[i]:Hide() end
    for i = hi + 1, #c.heads do c.heads[i]:Hide() end
    c.child:SetHeight(math.max(y, 1))
    c.scroll:Sync(y)
    c.frame:Show()
end
local function ensureView(host)
    if view then return view end
    local f = CreateFrame("Frame", nil, host)
    f:SetPoint("TOPLEFT", host, "TOPLEFT", 0, 0)
    view = { frame = f, rows = {}, heads = {} }
    for _, kind in ipairs({ "major", "minor" }) do
        for i = 1, 3 do view.rows[#view.rows + 1] = makeSlot(f) end
    end
    for i = 1, 2 do
        local h = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        h:SetJustifyH("LEFT")
        view.heads[i] = h
    end
    view.note = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    view.note:SetJustifyH("LEFT"); view.note:SetJustifyV("TOP")
    view.note:SetWidth(COL_W - ROW_INSET * 2)
    view.divider = f:CreateTexture(nil, "ARTWORK")
    view.divider:SetTexture(WHITE)
    view.divider:SetWidth(1)
    view.divider:SetPoint("TOPLEFT", f, "TOPLEFT", DIVIDER_X, 0)
    view.divider:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", DIVIDER_X, 0)
    view.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    view.title:SetJustifyH("LEFT")
    view.title:SetPoint("TOPLEFT", f, "TOPLEFT", RIGHT_X, -4)
    view.sub = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    view.sub:SetJustifyH("LEFT"); view.sub:SetJustifyV("TOP")
    view.sub:SetPoint("TOPLEFT", view.title, "BOTTOMLEFT", 0, -4)
    view.rule = f:CreateTexture(nil, "ARTWORK")
    view.rule:SetTexture(WHITE)
    view.rule:SetHeight(1)
    local c = { rows = {}, heads = {} }
    c.frame = CreateFrame("Frame", nil, f)
    c.scroll = ns.Kit.Scroll(c.frame)
    c.scroll:SetPoint("TOPLEFT", c.frame, "TOPLEFT", 0, 0)
    c.scroll:SetPoint("BOTTOMRIGHT", c.frame, "BOTTOMRIGHT", -SCROLL_W, 0)
    c.child = c.scroll.child
    view.list = c
    return view
end
local function ensureNote(host)
    if noteView then return noteView end
    local f = CreateFrame("Frame", nil, host)
    f:SetPoint("TOPLEFT", host, "TOPLEFT", 0, 0)
    noteView = { frame = f }
    noteView.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    noteView.title:SetJustifyH("LEFT")
    noteView.title:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -4)
    noteView.sub = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    noteView.sub:SetJustifyH("LEFT"); noteView.sub:SetJustifyV("TOP")
    noteView.sub:SetPoint("TOPLEFT", noteView.title, "BOTTOMLEFT", 0, -6)
    noteView.box = ns.NoteBox(f)
    return noteView
end
function ns.GlyphPlanRender(host, class, plan, pane, width, height, ranks)
    if pane == "note" then
        if view then view.frame:Hide() end
        local n = ensureNote(host)
        n.frame:SetWidth(width); n.frame:SetHeight(height)
        local h, s = C.heading, C.secondary
        n.title:SetTextColor(h[1], h[2], h[3])
        n.title:SetText(ns.T("glyph.plan_note_title"))
        n.sub:SetWidth(width)
        n.sub:SetTextColor(s[1], s[2], s[3])
        n.sub:SetText(ns.T("glyph.plan_note_sub"))
        local top = 4 + n.title:GetStringHeight() + 6 + n.sub:GetStringHeight() + 10
        n.box:Place(n.frame, 0, top, width, height - top)
        if n.plan ~= plan then
            n.box.edit:ClearFocus()
            n.plan = plan
        end
        n.box:Bind(plan.note, function(text)
            text = strtrim(text or "")
            plan.note = text ~= "" and text or nil
        end)
        n.frame:Show()
        return
    end
    if noteView then
        noteView.box:Unbind()
        noteView.frame:Hide()
    end
    local v = ensureView(host)
    v.frame:SetWidth(width); v.frame:SetHeight(height)
    local y = 0
    local titles = { ns.T("window.glyphs_major"), ns.T("window.glyphs_minor") }
    local n = 0
    for gi, kind in ipairs({ "major", "minor" }) do
        local h = v.heads[gi]
        local hc = gi == 1 and C.glyph.major or C.glyph.minor
        h:SetTextColor(hc[1], hc[2], hc[3])
        h:ClearAllPoints()
        h:SetPoint("LEFT", v.frame, "TOPLEFT", ROW_INSET, -(y + HEAD_H / 2))
        h:SetText(titles[gi])
        y = y + HEAD_H
        for i = 1, 3 do
            n = n + 1
            local r = v.rows[n]
            r:ClearAllPoints()
            r:SetPoint("TOPLEFT", v.frame, "TOPLEFT", 0, -y)
            fillSlot(r, class, plan, kind, i)
            y = y + ROW_H
        end
        y = y + GROUP_GAP
    end
    local s = C.secondary
    v.note:SetTextColor(s[1], s[2], s[3])
    v.note:ClearAllPoints()
    v.note:SetPoint("TOPLEFT", v.frame, "TOPLEFT", ROW_INSET, -(y + 4))
    ns.FitText(v.note, ns.T("glyph.plan_only_plan"), 4)
    local l = C.line
    v.divider:SetVertexColor(l[1], l[2], l[3], l[4] or 1)
    local rw = width - RIGHT_X
    local h, t = C.heading, C.text
    v.title:SetWidth(rw)
    v.title:SetTextColor(h[1], h[2], h[3])
    v.title:SetText(ns.T(sel.kind == "major" and "glyph.plan_pick_major" or "glyph.plan_pick_minor", sel.i))
    v.sub:SetWidth(rw)
    v.sub:SetTextColor(t[1], t[2], t[3])
    ns.FitText(v.sub, ns.T("glyph.plan_pick_sub"), 2)
    local top = 4 + v.title:GetStringHeight() + 4 + v.sub:GetStringHeight() + 8
    v.rule:SetVertexColor(l[1], l[2], l[3], l[4] or 1)
    v.rule:ClearAllPoints()
    v.rule:SetPoint("TOPLEFT", v.frame, "TOPLEFT", RIGHT_X, -top)
    v.rule:SetWidth(rw)
    v.listTop = top + 4
    v.list.frame:ClearAllPoints()
    v.list.frame:SetPoint("TOPLEFT", v.frame, "TOPLEFT", RIGHT_X, -v.listTop)
    renderList(v, class, plan, ranks or {}, rw, height)
    v.frame:Show()
end
function ns.GlyphPlanHide()
    if view then view.frame:Hide() end
    if noteView then
        noteView.box:Unbind()
        noteView.frame:Hide()
    end
end
function ns.NoteBox(parent)
    local box = {}
    local bg = CreateFrame("Frame", nil, parent)
    bg:SetBackdrop(ns.Kit.ROUND)
    ns.Kit.Track(bg, function(f) ns.Kit.PaintRound(f, C.field) end)
    ns.Kit.PaintRound(bg, C.field)
    local sc = CreateFrame("ScrollFrame", nil, bg)
    sc:SetPoint("TOPLEFT", bg, "TOPLEFT", NOTE_PAD, -NOTE_PAD)
    sc:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -NOTE_PAD, NOTE_PAD)
    local eb = CreateFrame("EditBox", nil, sc)
    eb:SetMultiLine(true)
    eb:SetAutoFocus(false)
    eb:SetMaxLetters(NOTE_MAX)
    eb:SetFontObject(GameFontHighlight)
    eb:SetWidth(100)
    eb:SetHeight(100)
    sc:SetScrollChild(eb)
    eb:SetScript("OnCursorChanged", function(self, _, y, _, h)
        local top = sc:GetVerticalScroll()
        local view = sc:GetHeight()
        y = -y
        if y < top then
            sc:SetVerticalScroll(y)
        elseif y + h > top + view then
            sc:SetVerticalScroll(y + h - view)
        end
    end)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    eb:SetScript("OnTextChanged", function(self, user)
        if user and box.onChange then box.onChange(self:GetText()) end
    end)
    bg:EnableMouse(true)
    bg:SetScript("OnMouseDown", function() eb:SetFocus() end)
    box.bg, box.scroll, box.edit = bg, sc, eb
    function box:Place(p, x, y, w, h)
        bg:SetParent(p)
        bg:ClearAllPoints()
        bg:SetPoint("TOPLEFT", p, "TOPLEFT", x, -y)
        bg:SetWidth(w); bg:SetHeight(math.max(40, h))
        eb:SetWidth(w - NOTE_PAD * 2)
        local t = C.text
        eb:SetTextColor(t[1], t[2], t[3])
        bg:Show()
    end
    function box:Bind(text, onChange)
        if not eb:HasFocus() then eb:SetText(text or "") end
        self.onChange = onChange
    end
    function box:Unbind()
        self.onChange = nil
        eb:ClearFocus()
    end
    return box
end
local noteWin
local NOTE_W, NOTE_H = 420, 260
function ns.OpenNoteWindow(o)
    if not noteWin then
        local w = CreateFrame("Frame", "HTP_TalentsNote", UIParent)
        w:SetWidth(NOTE_W); w:SetHeight(NOTE_H)
        w:SetFrameStrata("FULLSCREEN_DIALOG")
        w:SetToplevel(true)
        w:SetClampedToScreen(true)
        w:EnableMouse(true)
        w:SetMovable(true)
        w:RegisterForDrag("LeftButton")
        w:SetScript("OnDragStart", w.StartMoving)
        w:SetScript("OnDragStop", w.StopMovingOrSizing)
        tinsert(UISpecialFrames, "HTP_TalentsNote")
        ns.Kit.Window(w)
        w.title = w:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        w.title:SetJustifyH("LEFT")
        w.title:SetPoint("TOPLEFT", w, "TOPLEFT", 18, -16)
        w.title:SetWidth(NOTE_W - 36)
        w.box = ns.NoteBox(w)
        w.box:Place(w, 18, 44, NOTE_W - 36, NOTE_H - 44 - 50)
        w.ok = ns.Kit.Button(w, ns.Kit.H.ctrl)
        w.ok.kind = "main"
        w.ok:SetPoint("BOTTOMRIGHT", w, "BOTTOMRIGHT", -18, 16)
        w.cancel = ns.Kit.Button(w, ns.Kit.H.ctrl)
        w.cancel:SetPoint("RIGHT", w.ok, "LEFT", -6, 0)
        w:Hide()
        noteWin = w
    end
    local w = noteWin
    local text = o.text or ""
    local hc = C.heading
    w.title:SetTextColor(hc[1], hc[2], hc[3])
    w.title:SetText(ns.T("glyph.plan_note_window", o.title or ""))
    w.box:Place(w, 18, 44, NOTE_W - 36, NOTE_H - 44 - 50)
    w.box.edit:ClearFocus()
    w.box:Bind(text, function(t) text = t end)
    ns.Kit.SetButton(w.ok, ns.T("popup.save"), nil, function()
        w:Hide()
        o.apply(text)
    end)
    ns.Kit.SetButton(w.cancel, ns.T("popup.cancel"), nil, function() w:Hide() end)
    w:ClearAllPoints()
    w:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
    w:Show()
    w:Raise()
    w.box.edit:SetFocus()
end
