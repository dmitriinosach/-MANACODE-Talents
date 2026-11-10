local ADDON, ns = ...
ns.Kit = {}
local WHITE = "Interface\\Buttons\\WHITE8X8"
local ART = "Interface\\AddOns\\" .. ADDON .. "\\art\\kit\\"
ns.Kit.ART = ART
local H_TAB, H_CTRL, H_SMALL = 26, 22, 18
ns.Kit.H = { tab = H_TAB, ctrl = H_CTRL, small = H_SMALL }
local BTN_PAD = 12
local SLIDER_W = 16
local C = ns.C
local ROUND_FILL = 0.8
local ROUND_BACKDROP = {
    bgFile = WHITE, edgeFile = ART .. "round.tga", tile = false, edgeSize = 5,
    insets = { left = 5, right = 5, top = 5, bottom = 5 },
}
ns.Kit.ROUND = ROUND_BACKDROP
local ACTIVE_MIX = 0.3
local styled = {}
local function buttonColors(b)
    local k = C.control
    if b.off then return k.off, k.edgeOff, k.textOff end
    if b.active then return k.bg, b.accent or C.tab.edge, b.accent or C.gold end
    if b.hovered then return k.hover, k.edgeLit, k.textLit end
    return k.bg, k.edge, k.text
end
local function mixed(b, bg, to)
    local m = b.mixBuf or {}
    b.mixBuf = m
    for i = 1, 3 do m[i] = bg[i] + (to[i] - bg[i]) * ACTIVE_MIX end
    m[4] = math.max(bg[4] or 1, 0.85)
    return m
end
local function roundColors(b)
    local k = C.control
    if b.off then return k.off, k.textOff end
    if b.kind == "main" then return b.hovered and C.main.hover or C.main.bg, C.main.text end
    if b.active then
        local a = b.accent or C.gold
        return mixed(b, b.hovered and k.hover or k.bg, a), a
    end
    if b.hovered then return k.hover, b.tint or k.textLit end
    return k.bg, b.tint or (b.kind == "quiet" and C.quiet.text) or k.text
end
local function paintRound(f, fill)
    local m, a = math.min, fill[4] or 1
    f:SetBackdropColor(fill[1], fill[2], fill[3], a)
    f:SetBackdropBorderColor(m(1, fill[1] / ROUND_FILL), m(1, fill[2] / ROUND_FILL), m(1, fill[3] / ROUND_FILL), a)
end
ns.Kit.PaintRound = paintRound
local function styleRound(b)
    local fill, t = roundColors(b)
    paintRound(b, fill)
    b.text:SetTextColor(t[1], t[2], t[3])
    if b.icon and b.tintIcon then b.icon:SetVertexColor(t[1], t[2], t[3]) end
end
local KEY_PAD, KEY_SIDE, KEY_MINW = 5, 2, 28
local SPACE_PROBE, SPACE_W = 20, 3
local KEY_ROLE = { face = "face", side = "side", text = "text" }
function ns.Hint(id, ...)
    return { key = ns.T("hint." .. id .. ".key"), text = ns.T("hint." .. id .. ".text", ...) }
end
function ns.Kit.HintText(h)
    return ns.T("key." .. h.key) .. ": " .. h.text
end
local function keyColor(role)
    local c = C.keycap[KEY_ROLE[role]]
    return c[1], c[2], c[3]
end
local function keyText(fs, text)
    fs:SetFontObject(GameFontNormalSmall)
    fs:SetText(text)
end
local tipKeys = setmetatable({}, { __mode = "k" })
local function keysClear(p)
    if #p.items == 0 then return end
    p.keys:HideFrom(1)
    for i = #p.items, 1, -1 do p.items[i] = nil end
    p.col = 0
end
local function keysValid(tip, p)
    local last = p.items[#p.items]
    if not last then return true end
    if (tip:NumLines() or 0) < last.line then return false end
    return not last.fs or last.fs:GetText() == last.shown
end
local function keysOf(tip)
    local p = tipKeys[tip]
    if p then return p end
    local holder = CreateFrame("Frame", nil, tip)
    holder:SetAllPoints(tip)
    p = { items = {}, col = 0, pad = "", space = {} }
    p.meter = holder:CreateFontString(nil, "ARTWORK", "GameTooltipText")
    p.meter:Hide()
    p.keys = ns.Keycap.New(holder, { color = keyColor, text = keyText, backdrop = ROUND_BACKDROP, edge = ROUND_FILL,
                                     pad = KEY_PAD, vpad = 0, side = KEY_SIDE, minW = KEY_MINW })
    tipKeys[tip] = p
    local function clear() keysClear(p) end
    tip:HookScript("OnHide", clear)
    tip:HookScript("OnTooltipCleared", clear)
    holder:SetScript("OnUpdate", function()
        if #p.items > 0 and not keysValid(tip, p) then keysClear(p) end
    end)
    return p
end
local function spaceWidth(p, fs)
    local src = fs or GameTooltipText
    local font, size, flags
    if src and src.GetFont then font, size, flags = src:GetFont() end
    local id = tostring(font) .. ":" .. tostring(size)
    local w = p.space[id]
    if w then return w end
    local m = p.meter
    if font and size then m:SetFont(font, size, flags) end
    m:SetText("x" .. string.rep(" ", SPACE_PROBE) .. "x")
    local wide = m:GetStringWidth()
    m:SetText("xx")
    local base = m:GetStringWidth()
    w = (type(wide) == "number" and type(base) == "number") and (wide - base) / SPACE_PROBE or 0
    if w < 1 then w = SPACE_W end
    p.space[id] = w
    return w
end
local function keyIndent(p, fs)
    return string.rep(" ", math.ceil((p.col + p.keys.gap) / spaceWidth(p, fs)))
end
local function keyLine(p, text)
    return p.pad .. text
end
function ns.Kit.TipHints(tip, hints)
    if not hints or #hints == 0 then return end
    local c = C.keycap.action
    local name = tip.GetName and tip:GetName()
    if type(name) ~= "string" or not ns.Keycap then
        for _, h in ipairs(hints) do tip:AddLine(ns.Kit.HintText(h), c[1], c[2], c[3]) end
        return
    end
    local p = keysOf(tip)
    if not keysValid(tip, p) then keysClear(p) end
    if #p.items == 0 and (tip:NumLines() or 0) > 0 then tip:AddLine(" ") end
    local from = #p.items
    for i, h in ipairs(hints) do
        local k = p.keys:Draw(from + i, ns.T("key." .. h.key))
        p.items[from + i] = { text = h.text, h = k.h }
    end
    local was = p.col
    p.col = p.keys:Column(#p.items)
    local first = p.items[1]
    p.pad = keyIndent(p, (first and first.fs) or _G[name .. "TextLeft" .. ((tip:NumLines() or 0) + 1)])
    for i, it in ipairs(p.items) do
        local k = p.keys.list[i]
        local text = keyLine(p, it.text)
        if i > from then
            tip:AddLine(text, c[1], c[2], c[3])
            it.line = tip:NumLines()
            it.fs = _G[name .. "TextLeft" .. it.line]
            it.shown = text
        elseif it.fs and p.col ~= was then
            it.fs:SetText(text)
            it.shown = text
        end
        if it.fs then
            k.box:ClearAllPoints()
            k.box:SetPoint("LEFT", it.fs, "LEFT", 0, 0)
        else
            p.keys:Hide(i)
        end
    end
end
local function showTip(self, anchor)
    if not self.tipTitle then return false end
    GameTooltip:SetOwner(self, anchor)
    GameTooltip:AddLine(self.tipTitle, 1, 1, 1, true)
    if self.tipBody then GameTooltip:AddLine(self.tipBody, nil, nil, nil, true) end
    if not self.off then ns.Kit.TipHints(GameTooltip, self.hints) end
    GameTooltip:Show()
    return true
end
local function onEnter(self)
    self.hovered = true
    self:Restyle()
    showTip(self, self.tipAnchor or "ANCHOR_RIGHT")
end
local function onLeave(self)
    self.hovered = false
    self:Restyle()
    GameTooltip:Hide()
end
local function onClick(self)
    if not self.off and self.onClick then self.onClick() end
end
function ns.Kit.Button(parent, height)
    local b = CreateFrame("Button", nil, parent)
    b:SetHeight(height or H_CTRL)
    b:SetBackdrop(ROUND_BACKDROP)
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
    b.Restyle = styleRound
    b:SetScript("OnEnter", onEnter)
    b:SetScript("OnLeave", onLeave)
    b:SetScript("OnClick", onClick)
    styled[#styled + 1] = b
    styleRound(b)
    return b
end
function ns.Kit.SetButton(b, label, tipBody, fn, width)
    b.text:SetText(label)
    b.tipTitle, b.tipBody = label, tipBody
    b.onClick = fn
    b:SetWidth(width or (b.text:GetStringWidth() + BTN_PAD * 2))
    b:Restyle()
end
local castFx = {}
local function castOn(b, st)
    local mode = b.castMode
    return st ~= nil and mode ~= nil and (mode == "any" or mode == st.to)
end
local function setLabel(b, s)
    if b.text then b.text:SetText(s) else b:SetText(s) end
end
local function paintFill(b, st)
    if not castOn(b, st) then
        b.castFill:Hide()
        return
    end
    local f = C.main.fill
    b.castFill:SetVertexColor(f[1], f[2], f[3], f[4])
    b.castFill:SetWidth(math.max(1, (b:GetWidth() - 4) * ns.SpecCastProgress(st)))
    b.castFill:Show()
    if b.castCount then setLabel(b, ns.T("act.switching", ns.SpecCastLeft(st))) end
end
function ns.Kit.CastFill(b)
    if b.castFill then return b end
    local t = b:CreateTexture(nil, "ARTWORK")
    t:SetTexture(WHITE)
    t:SetPoint("TOPLEFT", b, "TOPLEFT", 2, -2)
    t:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 2, 2)
    t:SetWidth(1)
    t:Hide()
    b.castFill = t
    castFx[#castFx + 1] = { b = b, paint = paintFill }
    return b
end
local function paintClock(b, st)
    local cd = b.castClock
    if not castOn(b, st) then
        if b.castStart then
            b.castStart = nil
            cd:Hide()
            b.castNum:SetText("")
        end
        return
    end
    if b.castStart ~= st.start then
        b.castStart = st.start
        cd:SetCooldown(st.start, st.finish - st.start)
    end
    b.castNum:SetTextColor(C.cast[1], C.cast[2], C.cast[3])
    b.castNum:SetText(format("%.1f", ns.SpecCastLeft(st)))
end
function ns.Kit.CastClock(b, region)
    if b.castClock then return b end
    local cd = CreateFrame("Cooldown", nil, b)
    cd:SetAllPoints(region or b)
    cd:Hide()
    local num = cd:CreateFontString(nil, "OVERLAY", "NumberFontNormalLarge")
    num:SetPoint("CENTER", cd, "CENTER", 0, 0)
    b.castClock, b.castNum = cd, num
    castFx[#castFx + 1] = { b = b, paint = paintClock }
    return b
end
ns.OnSpecCast(function(st)
    for _, fx in ipairs(castFx) do fx.paint(fx.b, st) end
end)
local ORB = 20
local function styleOrb(b)
    local bg, br, t = buttonColors(b)
    local r = (not b.off and b.ringTint) or br
    local g = (not b.off and b.tint) or t
    if b.image then
        g = (not b.off and b.tint) or C.plain
        b.icon:SetDesaturated((b.off or b.dim) and true or false)
    end
    b.plate:SetVertexColor(bg[1], bg[2], bg[3], bg[4])
    b.ring:SetVertexColor(r[1], r[2], r[3], r[4] or 1)
    b.icon:SetVertexColor(g[1], g[2], g[3])
end
local function orbEnter(self)
    self.hovered = true
    self:Restyle()
    if self.onHover and self.onHover(self) then return end
    showTip(self, self.tipAnchor or "ANCHOR_TOP")
end
local function orbClick(self, button)
    if not self.off and self.onClick then self.onClick(button) end
end
function ns.Kit.Orb(parent, key, title, body, fn, size)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(size or ORB); b:SetHeight(size or ORB)
    b.plate = b:CreateTexture(nil, "BACKGROUND")
    b.plate:SetAllPoints(b)
    b.plate:SetTexture(ART .. "plate.tga")
    b.ring = b:CreateTexture(nil, "BORDER")
    b.ring:SetAllPoints(b)
    b.ring:SetTexture(ART .. "ring.tga")
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints(b)
    b.tipTitle, b.tipBody, b.onClick = title, body, fn
    b.Restyle = styleOrb
    function b:SetKey(k)
        self.key = k
        if self.image then
            self.image = nil
            self.icon:ClearAllPoints()
            self.icon:SetAllPoints(self)
            self.icon:SetTexCoord(0, 1, 0, 1)
            self.icon:Show()
        end
        self.icon:SetTexture(ART .. k .. ".tga")
    end
    function b:SetImage(tex, crop)
        self.image = true
        self.icon:ClearAllPoints()
        self.icon:SetPoint("TOPLEFT", self, "TOPLEFT", 2, -2)
        self.icon:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -2, 2)
        if crop then
            self.icon:SetTexCoord(crop[1], crop[2], crop[3], crop[4])
        else
            self.icon:SetTexCoord(0, 1, 0, 1)
        end
        if tex then
            self.icon:SetTexture(tex)
            self.icon:Show()
        else
            self.icon:Hide()
        end
        styleOrb(self)
    end
    function b:SetOff(off)
        self.off = off and true or false
        styleOrb(self)
    end
    function b:SetOn(on)
        self.active = on and true or false
        styleOrb(self)
    end
    function b:SetTint(glyph, ring)
        self.tint, self.ringTint = glyph, ring
        styleOrb(self)
    end
    b:SetKey(key)
    b:SetScript("OnEnter", orbEnter)
    b:SetScript("OnLeave", onLeave)
    b:SetScript("OnClick", orbClick)
    styled[#styled + 1] = b
    styleOrb(b)
    return b
end
local PILL_ICON = 14
local PILL_PAD = 8
local PILL_GAP = 4
function ns.Kit.Pill(parent, height)
    local b = ns.Kit.Button(parent, height)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetWidth(PILL_ICON); b.icon:SetHeight(PILL_ICON)
    b.icon:SetPoint("LEFT", b, "LEFT", PILL_PAD - 2, 0)
    b.tintIcon = true
    b:Restyle()
    return b
end
function ns.Kit.SetPill(b, key, label, tipBody, fn, bare)
    b.text:SetText(bare and key and "" or label)
    b.text:ClearAllPoints()
    local w = b.text:GetStringWidth() + PILL_PAD * 2
    if bare and key then
        b.icon:SetTexture(ART .. key .. ".tga")
        b.icon:Show()
        b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
        w = PILL_ICON + (PILL_PAD - 2) * 2
    elseif key then
        b.icon:SetTexture(ART .. key .. ".tga")
        b.icon:Show()
        b.text:SetPoint("LEFT", b.icon, "RIGHT", PILL_GAP, 0)
        w = w + PILL_ICON + PILL_GAP - 2
    else
        b.icon:Hide()
        b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
    end
    b.tipTitle, b.tipBody = label, tipBody
    b.onClick = fn
    b:SetWidth(w)
    b:Restyle()
end
local SEG_INSET = 2
local SEG_PAD = 10
local SEG_CHECK = 12
local SEG_CHECK_TEX = "Interface\\RaidFrame\\ReadyCheck-Ready"
local function styleSeg(b)
    local k = C.control
    local fill, t = C.none, k.text
    if b.off then
        t = k.textOff
    elseif b.active then
        t = b.accent or C.gold
        fill = mixed(b, k.bg, t)
    elseif b.hovered then
        fill, t = k.hover, k.textLit
    end
    paintRound(b, fill)
    b.text:SetTextColor(t[1], t[2], t[3])
end
local function styleTrack(f)
    paintRound(f, C.field)
end
local function segAt(f, i)
    local b = f.buttons[i]
    if b then return b end
    b = CreateFrame("Button", nil, f)
    b:SetHeight(H_CTRL - SEG_INSET * 2)
    b:SetBackdrop(ROUND_BACKDROP)
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.text:SetPoint("LEFT", b, "LEFT", SEG_PAD, 0)
    b.mark = b:CreateTexture(nil, "OVERLAY")
    b.mark:SetTexture(SEG_CHECK_TEX)
    b.mark:SetWidth(SEG_CHECK); b.mark:SetHeight(SEG_CHECK)
    b.mark:SetPoint("LEFT", b.text, "RIGHT", 4, 0)
    b.mark:Hide()
    b.Restyle = styleSeg
    b:SetScript("OnEnter", onEnter)
    b:SetScript("OnLeave", onLeave)
    b:SetScript("OnClick", onClick)
    styled[#styled + 1] = b
    f.buttons[i] = b
    return b
end
function ns.Kit.Segment(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetHeight(H_CTRL)
    f:SetBackdrop(ROUND_BACKDROP)
    f.buttons = {}
    f.Restyle = styleTrack
    styled[#styled + 1] = f
    styleTrack(f)
    function f:Set(list, accent)
        local x = SEG_INSET
        local base = self:GetFrameLevel()
        for i, it in ipairs(list) do
            local b = segAt(self, i)
            b.text:SetText(it.label)
            b.tipTitle = it.label
            b.tipBody = it.off and ((it.tip and (it.tip .. "\n") or "") .. ns.Hex("alert") .. it.off .. "|r") or it.tip
            b.onClick = it.onClick
            b.hints = it.hints
            b.active, b.off, b.accent = it.active and true or false, it.off ~= nil, accent
            if it.check then b.mark:Show() else b.mark:Hide() end
            b:SetWidth(SEG_PAD + b.text:GetStringWidth() + (it.check and (4 + SEG_CHECK) or 0) + (it.extra or 0) + SEG_PAD)
            b:ClearAllPoints()
            b:SetPoint("LEFT", self, "LEFT", x, 0)
            b:SetFrameLevel(base + 1)
            b:Restyle()
            b:Show()
            x = x + b:GetWidth()
        end
        for i = #list + 1, #self.buttons do self.buttons[i]:Hide() end
        self:SetWidth(math.max(1, x + SEG_INSET))
    end
    return f
end
local TOGGLE_W, TOGGLE_KNOB = 34, 12
local function styleToggle(b)
    local k = C.control
    local fill, knob = k.off, k.textOff
    if b.on then
        fill, knob = b.hovered and C.main.hover or C.main.bg, C.main.text
    elseif b.hovered then
        fill, knob = k.hover, k.text
    end
    paintRound(b, fill)
    b.knob:SetVertexColor(knob[1], knob[2], knob[3])
    b.knob:ClearAllPoints()
    if b.on then
        b.knob:SetPoint("RIGHT", b, "RIGHT", -3, 0)
    else
        b.knob:SetPoint("LEFT", b, "LEFT", 3, 0)
    end
end
function ns.Kit.Toggle(parent)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(TOGGLE_W); b:SetHeight(H_SMALL)
    b:SetBackdrop(ROUND_BACKDROP)
    b.knob = b:CreateTexture(nil, "ARTWORK")
    b.knob:SetTexture(ART .. "plate.tga")
    b.knob:SetWidth(TOGGLE_KNOB); b.knob:SetHeight(TOGGLE_KNOB)
    b.Restyle = styleToggle
    function b:SetOn(on)
        self.on = on and true or false
        styleToggle(self)
    end
    b:SetScript("OnEnter", onEnter)
    b:SetScript("OnLeave", onLeave)
    b:SetScript("OnClick", function(self)
        if self.onClick then self.onClick(not self.on) end
    end)
    styled[#styled + 1] = b
    styleToggle(b)
    return b
end
local GRIP_TEX = ART .. "grip"
local GRIP_CURSOR = ART .. "grip_cursor"
local GRIP_BLANK = ART .. "blank"
local GRIP_BADGE = 24
local GRIP_ARROW = 25 / 32
local gripBadge
local gripBadgeOwner
local function gripBadgeFollow(self)
    local u = UIParent:GetEffectiveScale()
    local x, y = GetCursorPosition()
    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / u, y / u)
    SetCursor(GRIP_BLANK)
end
local function gripBadgeShow(g)
    if not gripBadge then
        gripBadge = CreateFrame("Frame", nil, UIParent)
        gripBadge:SetFrameStrata("TOOLTIP")
        gripBadge:SetWidth(GRIP_BADGE); gripBadge:SetHeight(GRIP_BADGE)
        local t = gripBadge:CreateTexture(nil, "OVERLAY")
        t:SetAllPoints(gripBadge)
        t:SetTexture(GRIP_CURSOR)
        t:SetTexCoord(0, GRIP_ARROW, 0, GRIP_ARROW)
        gripBadge:SetScript("OnUpdate", gripBadgeFollow)
        gripBadge:SetScript("OnHide", function() ResetCursor() end)
    end
    gripBadgeOwner = g
    gripBadgeFollow(gripBadge)
    gripBadge:Show()
end
local function gripBadgeHide(g)
    if gripBadgeOwner ~= g then return end
    gripBadgeOwner = nil
    gripBadge:Hide()
end
local function gripTint(g, state)
    g.state = state
    local c = C.grip[state]
    g.tex:SetVertexColor(c[1], c[2], c[3])
    local w = C.grip.glow
    g.hi:SetVertexColor(w[1], w[2], w[3], w[4])
end
local function styleGrip(g)
    gripTint(g, g.state or "idle")
end
function ns.Kit.Grip(parent, size)
    local g = CreateFrame("Button", nil, parent)
    g:SetWidth(size); g:SetHeight(size)
    g.tex = g:CreateTexture(nil, "ARTWORK")
    g.tex:SetTexture(GRIP_TEX)
    g.tex:SetAllPoints(g)
    local hi = g:CreateTexture(nil, "HIGHLIGHT")
    hi:SetTexture(GRIP_TEX)
    hi:SetAllPoints(g)
    hi:SetBlendMode("ADD")
    g.hi = hi
    g.Restyle = styleGrip
    styled[#styled + 1] = g
    gripTint(g, "idle")
    g:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self.held = true
            gripTint(self, "press")
        end
        if self.onDown then self.onDown(self, button) end
    end)
    g:SetScript("OnMouseUp", function(self, button)
        local over = self:IsMouseOver()
        self.held = nil
        gripTint(self, over and "lit" or "idle")
        if not over then gripBadgeHide(self) end
        if self.onUp then self.onUp(self, button) end
    end)
    g:SetScript("OnEnter", function(self)
        gripBadgeShow(self)
        if not self.held then gripTint(self, "lit") end
        showTip(self, "ANCHOR_RIGHT")
    end)
    g:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        if self.held then return end
        gripTint(self, "idle")
        gripBadgeHide(self)
    end)
    g:SetScript("OnHide", function(self)
        self.held = nil
        gripTint(self, "idle")
        gripBadgeHide(self)
    end)
    return g
end
local FLY_PAD = 6
local FLY_LIFT = 4
local FLY_REACH = 6
local FLY_STAY = 0.1
local fly
local flyAnchor
local flyContent
local flyAway = 0
local flyLift
local function styleFly(f)
    ns.Kit.StylePanel(f)
end
function ns.Kit.StylePanel(f, backdrop)
    local look, c = C.look.panel, C.panel
    local e = look.edge
    f:SetBackdrop(backdrop or look.backdrop)
    f:SetBackdropColor(c[1], c[2], c[3], math.max(c[4] or 1, look.alpha or 0))
    f:SetBackdropBorderColor(e[1], e[2], e[3], e[4] or 1)
end
local function screenBox(f)
    local l, r, b, t = f:GetLeft(), f:GetRight(), f:GetBottom(), f:GetTop()
    if not (l and r and b and t) or r <= l or t <= b then return nil, 0, 0, 0 end
    local s = f:GetEffectiveScale()
    return l * s, r * s, b * s, t * s
end
local function onBridge()
    local al, ar, ab, at = screenBox(flyAnchor)
    local fl, fr, fb, ft = screenBox(fly)
    if not (al and fl) then return false end
    local x, y = GetCursorPosition()
    local min, max = math.min, math.max
    if at <= fb or ft <= ab then
        return x >= min(al, fl) and x <= max(ar, fr) and y >= min(at, ft) and y <= max(ab, fb)
    end
    return y >= min(ab, fb) and y <= max(at, ft) and x >= min(ar, fr) and x <= max(al, fl)
end
local function flyUpdate(self, elapsed)
    if not flyAnchor or not flyAnchor:IsVisible() then
        ns.Kit.FlyHide()
        return
    end
    if self:IsMouseOver(FLY_REACH, -FLY_REACH, -FLY_REACH, FLY_REACH) or flyAnchor:IsMouseOver() or onBridge() then
        flyAway = 0
        return
    end
    flyAway = flyAway + elapsed
    if flyAway >= FLY_STAY then ns.Kit.FlyHide() end
end
local function flyPlace()
    local k = flyAnchor:GetEffectiveScale() / UIParent:GetEffectiveScale()
    fly:SetScale(k)
    fly:ClearAllPoints()
    local top, bottom, left = flyAnchor:GetTop(), flyAnchor:GetBottom(), flyAnchor:GetLeft()
    local h = fly:GetHeight()
    local lift = FLY_LIFT + (flyLift or 0)
    local up = true
    if top and bottom then
        local above = (UIParent:GetTop() or 0) / k - (top + lift)
        local under = bottom - FLY_LIFT
        up = above >= h or (under < h and above >= under)
    end
    local side = (not left or (left + fly:GetWidth()) * k <= UIParent:GetRight()) and "LEFT" or "RIGHT"
    if up then
        fly:SetPoint("BOTTOM" .. side, flyAnchor, "TOP" .. side, 0, lift)
    else
        fly:SetPoint("TOP" .. side, flyAnchor, "BOTTOM" .. side, 0, -FLY_LIFT)
    end
end
function ns.Kit.Fly(anchor, content, lift)
    if not fly then
        fly = CreateFrame("Frame", nil, UIParent)
        fly:SetFrameStrata("DIALOG")
        fly:SetClampedToScreen(true)
        fly:EnableMouse(true)
        fly:Hide()
        fly.Restyle = styleFly
        styled[#styled + 1] = fly
        styleFly(fly)
        fly:SetScript("OnUpdate", flyUpdate)
    end
    if flyContent and flyContent ~= content then flyContent:Hide() end
    flyAnchor, flyContent, flyAway, flyLift = anchor, content, 0, lift
    content:SetParent(fly)
    content:ClearAllPoints()
    content:SetPoint("TOPLEFT", fly, "TOPLEFT", FLY_PAD, -FLY_PAD)
    content:Show()
    fly:SetWidth(content:GetWidth() + FLY_PAD * 2)
    fly:SetHeight(content:GetHeight() + FLY_PAD * 2)
    flyPlace()
    fly:Show()
end
function ns.Kit.FlyHide()
    if not fly then return end
    fly:Hide()
    if flyContent then flyContent:Hide() end
    flyAnchor, flyContent = nil, nil
end
function ns.Kit.FlyAnchor()
    return fly and fly:IsShown() and flyAnchor or nil
end
local function styleSlider(sl)
    local bar = C.bar
    sl:SetBackdropColor(bar.bg[1], bar.bg[2], bar.bg[3], bar.bg[4])
    local c = bar.edge
    sl:SetBackdropBorderColor(c[1], c[2], c[3], c[4] or 1)
    local th = sl:GetThumbTexture()
    local u = C.tab.underline
    if th then th:SetVertexColor(u[1], u[2], u[3]) end
end
function ns.Kit.Scroll(parent)
    local sc = CreateFrame("ScrollFrame", nil, parent)
    local child = CreateFrame("Frame", nil, sc)
    child:SetHeight(1)
    sc:SetScrollChild(child)
    sc.child = child
    local sl = CreateFrame("Slider", nil, parent)
    sl:SetOrientation("VERTICAL")
    sl:SetWidth(SLIDER_W)
    sl:EnableMouse(true)
    sl:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Vertical")
    local th = sl:GetThumbTexture()
    if th then th:SetWidth(SLIDER_W); th:SetHeight(24) end
    sl:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 6, right = 6, top = 3, bottom = 3 },
    })
    sl:SetValueStep(1)
    sl:SetMinMaxValues(0, 0)
    sl:SetValue(0)
    sl:SetPoint("TOPLEFT", sc, "TOPRIGHT", 4, 0)
    sl:SetPoint("BOTTOMLEFT", sc, "BOTTOMRIGHT", 4, 0)
    sl:Hide()
    sl.Restyle = styleSlider
    styled[#styled + 1] = sl
    styleSlider(sl)
    sc.slider = sl
    function sc:ScrollTo(v)
        local maxv = self.maxScroll or 0
        if v < 0 then v = 0 elseif v > maxv then v = maxv end
        self:SetVerticalScroll(v)
        self.syncing = true
        sl:SetValue(v)
        self.syncing = false
    end
    sl:SetScript("OnValueChanged", function(_, v)
        if not sc.syncing then sc:ScrollTo(v) end
    end)
    sc:EnableMouseWheel(true)
    sc:SetScript("OnMouseWheel", function(self, delta)
        self:ScrollTo(self:GetVerticalScroll() - delta * 40)
    end)
    function sc:Sync(childH)
        local maxv = (childH or 0) - (self:GetHeight() or 0)
        if maxv < 0 then maxv = 0 end
        self.maxScroll = maxv
        sl:SetMinMaxValues(0, maxv)
        if maxv <= 0 then
            self:ScrollTo(0)
            sl:Hide()
        else
            sl:Show()
            if self:GetVerticalScroll() > maxv then self:ScrollTo(maxv) end
        end
    end
    return sc
end
local function styleWindow(f)
    local look, bg = C.look.window, C.background
    local e = look.edge
    f:SetBackdrop(look.backdrop)
    f:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
    f:SetBackdropBorderColor(e[1], e[2], e[3], e[4])
    ns.ApplyDecor(f)
end
function ns.Kit.Window(f)
    if not f.htpThemed then
        f.htpThemed = true
        f.Restyle = styleWindow
        styled[#styled + 1] = f
    end
    styleWindow(f)
end
function ns.Kit.Track(f, restyle)
    f.Restyle = restyle
    styled[#styled + 1] = f
    restyle(f)
end
local appliedTheme
function ns.Kit.Sync()
    ns.ApplyTheme()
    local id = ns.C.key
    if id == appliedTheme then return false end
    appliedTheme = id
    for _, w in ipairs(styled) do w:Restyle() end
    return true
end
