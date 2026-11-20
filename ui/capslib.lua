local ADDON, ns = ...
local C = ns.C
local Caps = ns.Caps
local WHITE = "Interface\\Buttons\\WHITE8X8"
local ICON_CROP = { 0.07, 0.93, 0.07, 0.93 }
local MARK_ON = "Interface\\RaidFrame\\ReadyCheck-Ready"
local MARK_OFF = "Interface\\RaidFrame\\ReadyCheck-NotReady"
local MARK_WAIT = "Interface\\RaidFrame\\ReadyCheck-Waiting"
local CHECK = "Interface\\Buttons\\UI-CheckBox-Check"
local TOP_H = 30
local SEC_H = 26
local ROW_H = 18
local BAR_H = 8
local PAD = 4
local ICON = 16
local BOX = 12
local MARK = 12
local GAP = 8
local CHIP_H = 18
local CHIP_PAD = 7
local CHIP_GAP = 4
local root, variantBtn, specIcon, raidSeg
local pool = { head = {}, row = {}, label = {}, para = {}, tex = {}, zone = {}, chip = {} }
local used = { head = 0, row = 0, label = 0, para = 0, tex = 0, zone = 0, chip = 0 }
local function tint(t, c)
    if t.SetVertexColor then
        t:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
    else
        t:SetTextColor(c[1], c[2], c[3])
    end
end
local function take(kind, make)
    local n = used[kind] + 1
    used[kind] = n
    local w = pool[kind][n]
    if not w then
        w = make()
        pool[kind][n] = w
    end
    w:Show()
    return w
end
local function texAt()
    return take("tex", function()
        local t = root:CreateTexture(nil, "ARTWORK")
        t:SetTexture(WHITE)
        return t
    end)
end
local function para(text, x, y, width, color, font)
    local fs = take("para", function()
        local f = root:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        f:SetJustifyH("LEFT")
        f:SetJustifyV("TOP")
        return f
    end)
    fs:SetFontObject(_G[font or "GameFontHighlightSmall"])
    fs:SetWidth(width)
    fs:SetText(text)
    tint(fs, color)
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", root, "TOPLEFT", x, -y)
    local h = fs:GetStringHeight() or 0
    return h > 1 and h or 10
end
local function showTip(self)
    if self.tipFn then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        self.tipFn(self)
        GameTooltip:Show()
    end
end
local function paint(self)
    local fill = (self.lit and C.selected) or (self.hovered and self.tipFn and C.hover) or nil
    if fill then
        tint(self.fill, fill)
        self.fill:Show()
    else
        self.fill:Hide()
    end
end
local function onEnter(self)
    self.hovered = true
    paint(self)
    showTip(self)
end
local function onLeave(self)
    self.hovered = false
    paint(self)
    GameTooltip:Hide()
end
local function onClick(self)
    if self.onClick then self.onClick() end
end
local function newStrip(h)
    local b = CreateFrame("Button", nil, root)
    b:SetHeight(h)
    b.fill = b:CreateTexture(nil, "BACKGROUND")
    b.fill:SetTexture(WHITE)
    b.fill:SetAllPoints(b)
    b:SetScript("OnEnter", onEnter)
    b:SetScript("OnLeave", onLeave)
    b:SetScript("OnClick", onClick)
    return b
end
local function head(y, width, title, status, statusColor, lit, tipFn)
    local b = take("head", function()
        local f = newStrip(SEC_H)
        f.bar = f:CreateTexture(nil, "BORDER")
        f.bar:SetTexture(WHITE)
        f.bar:SetWidth(2)
        f.bar:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
        f.bar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 1)
        f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f.title:SetJustifyH("LEFT")
        f.title:SetHeight(14)
        f.status = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        f.status:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, 7)
        f.line = f:CreateTexture(nil, "ARTWORK")
        f.line:SetTexture(WHITE)
        f.line:SetHeight(1)
        f.line:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
        f.line:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
        return f
    end)
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", root, "TOPLEFT", 0, -y)
    b:SetWidth(width)
    b.status:SetText(status or "")
    if statusColor then tint(b.status, statusColor) end
    b.title:ClearAllPoints()
    b.title:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", lit and PAD + 4 or PAD, 6)
    b.title:SetWidth(math.max(20, width - PAD * 3 - (b.status:GetStringWidth() or 0) - (lit and 4 or 0)))
    b.title:SetText(title)
    tint(b.title, lit and C.gold or C.heading)
    tint(b.line, C.line)
    if lit then
        tint(b.bar, C.gold)
        b.bar:Show()
    else
        b.bar:Hide()
    end
    b.lit, b.tipFn, b.onClick = lit, tipFn, nil
    b.hovered = tipFn ~= nil and b:IsMouseOver() and true or false
    paint(b)
    return SEC_H
end
local function row(y, width, o)
    local b = take("row", function()
        local f = newStrip(ROW_H)
        f.swatch = f:CreateTexture(nil, "ARTWORK")
        f.swatch:SetTexture(WHITE)
        f.swatch:SetWidth(6); f.swatch:SetHeight(6)
        f.swatch:SetPoint("LEFT", f, "LEFT", PAD + 3, 0)
        f.box = f:CreateTexture(nil, "BORDER")
        f.box:SetTexture(WHITE)
        f.box:SetWidth(BOX); f.box:SetHeight(BOX)
        f.box:SetPoint("LEFT", f, "LEFT", PAD, 0)
        f.check = f:CreateTexture(nil, "ARTWORK")
        f.check:SetTexture(CHECK)
        f.check:SetWidth(BOX + 6); f.check:SetHeight(BOX + 6)
        f.check:SetPoint("CENTER", f.box, "CENTER", 0, 0)
        f.icon = f:CreateTexture(nil, "ARTWORK")
        f.icon:SetWidth(ICON); f.icon:SetHeight(ICON)
        f.icon:SetTexCoord(ICON_CROP[1], ICON_CROP[2], ICON_CROP[3], ICON_CROP[4])
        f.label = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        f.label:SetJustifyH("LEFT")
        f.label:SetHeight(14)
        f.mark = f:CreateTexture(nil, "OVERLAY")
        f.mark:SetWidth(MARK); f.mark:SetHeight(MARK)
        f.value = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        f.value:SetPoint("RIGHT", f, "RIGHT", -PAD, 0)
        return f
    end)
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", root, "TOPLEFT", 0, -y)
    b:SetWidth(width)
    local x = PAD
    if o.swatch then
        tint(b.swatch, o.swatch)
        b.swatch:Show()
    else
        b.swatch:Hide()
    end
    if o.box then
        tint(b.box, C.field)
        b.box:Show()
        if o.checked then b.check:Show() else b.check:Hide() end
    else
        b.box:Hide(); b.check:Hide()
    end
    if not o.flat then x = x + BOX + 6 end
    if o.icon then
        b.icon:SetTexture(o.icon)
        if b.icon.SetDesaturated then b.icon:SetDesaturated(o.dim and true or false) end
        b.icon:SetAlpha(o.dim and 0.6 or 1)
        b.icon:ClearAllPoints()
        b.icon:SetPoint("LEFT", b, "LEFT", x, 0)
        b.icon:Show()
        x = x + ICON + 5
    else
        b.icon:Hide()
    end
    b.value:SetText(o.value or "")
    tint(b.value, o.valueColor or C.text)
    local vw = b.value:GetStringWidth() or 0
    local room = width - x - PAD - vw - 8 - (o.mark and (MARK + 4) or 0)
    b.label:SetWidth(10000)
    b.label:SetText(o.label)
    local lw = b.label:GetStringWidth() or 0
    if lw > room then lw = room end
    b.label:SetWidth(math.max(10, lw + 1))
    tint(b.label, o.labelColor or C.secondary)
    b.label:ClearAllPoints()
    b.label:SetPoint("LEFT", b, "LEFT", x, 0)
    if o.mark then
        b.mark:SetTexture(o.mark)
        b.mark:ClearAllPoints()
        b.mark:SetPoint("LEFT", b.label, "RIGHT", 4, 0)
        b.mark:Show()
    else
        b.mark:Hide()
    end
    b.lit, b.tipFn, b.onClick = nil, o.tipFn, o.onClick
    b.hovered = o.tipFn ~= nil and b:IsMouseOver() and true or false
    paint(b)
    return ROW_H
end
local function bar(y, width, full, segs, ticks, tipFn)
    local x0, w = PAD, width - PAD * 2
    if tipFn then
        local z = take("zone", function() return newStrip(BAR_H + 6) end)
        z:ClearAllPoints()
        z:SetPoint("TOPLEFT", root, "TOPLEFT", 0, -(y - 3))
        z:SetWidth(width)
        z.tipFn = tipFn
        z.hovered = z:IsMouseOver() and true or false
        paint(z)
    end
    local track = texAt()
    tint(track, C.caps.track)
    track:ClearAllPoints()
    track:SetPoint("TOPLEFT", root, "TOPLEFT", x0, -y)
    track:SetWidth(w); track:SetHeight(BAR_H)
    if full <= 0 then return BAR_H end
    for _, s in ipairs(segs) do
        local a = math.max(0, math.min(s[1], full)) / full * w
        local b = math.max(0, math.min(s[2], full)) / full * w
        if b - a >= 1 then
            local t = texAt()
            tint(t, s[3])
            t:ClearAllPoints()
            t:SetPoint("TOPLEFT", root, "TOPLEFT", x0 + a, -y)
            t:SetWidth(b - a); t:SetHeight(BAR_H)
        end
    end
    for _, v in ipairs(ticks or {}) do
        if v > 0 and v <= full then
            local t = texAt()
            tint(t, C.caps.tick)
            t:ClearAllPoints()
            t:SetPoint("TOPLEFT", root, "TOPLEFT", x0 + math.min(v / full * w, w - 2), -(y - 2))
            t:SetWidth(2); t:SetHeight(BAR_H + 4)
        end
    end
    return BAR_H
end
local function amount(x, unit, exact)
    if unit ~= "%" then return ("%.0f"):format(x) end
    return exact and ("%.2f%%"):format(x) or ("%g%%"):format(x)
end
local function pair(rating, pct, unit, exact)
    return ("%.0f (%s)"):format(rating, amount(pct, unit, exact))
end
local function plain(it, v)
    return it.show == "pct" and ("%.2f%%"):format(v) or ("%.0f"):format(v)
end
local function text(key)
    return ns.L[key]
end
local function tipLine(s, c)
    c = c or C.text
    GameTooltip:AddLine(s, c[1], c[2], c[3], true)
end
local function statTip(it, extra)
    return function()
        tipLine(ns.T("caps.stat." .. it.label), C.heading)
        local desc = text(it.desc) or text("caps.desc." .. it.key)
        if desc then tipLine(desc) end
        for _, s in ipairs(extra or {}) do tipLine(s, C.secondary) end
    end
end
local function barTip(keys)
    return function()
        tipLine(ns.T("caps.bar_title"), C.heading)
        for _, k in ipairs(keys) do
            tipLine(ns.T("caps.bar_" .. k), C.caps[k == "have" and "gear" or k])
        end
    end
end
local function noteTip(title, body)
    return function()
        tipLine(title, C.heading)
        tipLine(body)
    end
end
local function whoOf(r)
    local out = {}
    for _, m in ipairs(r.members or {}) do
        out[#out + 1] = text("caps.who." .. m.key) or m.name
    end
    if #out == 0 then out[1] = text("caps.who." .. r.key) or r.name or "" end
    return table.concat(out, ", ")
end
local function whyText(r, who)
    if not r.why then return nil end
    local key = "caps.why." .. r.why
    if r.why == Caps.REASON.CLASS_HERE and not r.sure then key = "caps.why.class_unsure" end
    return ns.T(key, who or whoOf(r))
end
local function sourceTip(r, ctx, unit)
    return function()
        local native = false
        if r.talent and GameTooltip.SetTalent and not r.members then
            native = pcall(GameTooltip.SetTalent, GameTooltip, r.talent[1], r.talent[2], false, false, ctx.group)
        elseif r.spellId and not r.members then
            native = pcall(GameTooltip.SetHyperlink, GameTooltip, "spell:" .. r.spellId)
        end
        if not native or (GameTooltip:NumLines() or 0) == 0 then
            tipLine(r.name or ns.T("caps.group." .. r.key), C.heading)
        end
        GameTooltip:AddLine(" ")
        if r.members and #r.members > 1 then
            tipLine(ns.T("caps.tip_group"), C.secondary)
            for _, m in ipairs(r.members) do
                tipLine(m.detail and (m.name .. " " .. m.detail) or m.name, C.gold)
                tipLine(whyText(m, text("caps.who." .. m.key) or m.name) or "", m.on and C.positive or C.alert)
            end
        else
            tipLine(whyText(r) or "", r.on and C.positive or C.alert)
        end
        tipLine(ns.T("caps.tip_gives", "+" .. amount(r.pct, unit)), C.text)
        if not r.on then
            tipLine(ns.T((r.raid and r.picked) and "caps.tip_wait" or "caps.tip_cross"), C.secondary)
        end
        if r.raid then
            tipLine(ns.T(r.picked and "caps.tip_raid_picked" or "caps.tip_raid_skipped"), C.secondary)
            ns.Kit.TipHints(GameTooltip, { ns.Hint(r.picked and "caps_raid_no" or "caps_raid_yes") })
        else
            tipLine(ns.T(r.picked and "caps.tip_picked" or "caps.tip_skipped"), C.secondary)
            ns.Kit.TipHints(GameTooltip, { ns.Hint(r.picked and "caps_unpick" or "caps_pick") })
        end
    end
end
local STATUS_COLOR = { under = "negative", ok = "positive" }
local function statusColor(status)
    if status == "over" then return C.caps.over end
    return C[STATUS_COLOR[status] or "secondary"]
end
local function statusText(it)
    local r = it.r
    if not r then return nil end
    if r.haveMissing then return ns.T("caps.unread") end
    if it.kind == "hard" then
        if r.status == "under" then
            return ns.T("caps.st_under", pair(-r.deltaRating, -r.deltaPct, r.unit, true))
        elseif r.status == "over" then
            return ns.T("caps.st_over", "+" .. pair(r.deltaRating, r.deltaPct, r.unit, true))
        end
        return ns.T("caps.st_ok")
    elseif it.kind == "target" then
        if r.status == "under" then return ns.T("caps.st_under", plain(it, r.delta)) end
        if r.status == "all" then return ns.T("caps.st_all") end
        if r.status == "reached" then return ns.T("caps.st_goal") end
        return nil
    end
    return amount(r.pct, "%", true)
end
local function chips(m, y, width)
    local byLabel = {}
    for _, list in ipairs({ m.capped, m.more }) do
        for _, it in ipairs(list) do byLabel[it.label] = byLabel[it.label] or it end
    end
    local x, n = PAD, 0
    for _, label in ipairs(m.order) do
        local it = byLabel[label]
        if it and not it.chip then
            it.chip = true
            n = n + 1
            local b = take("chip", function() return ns.Kit.Button(root, CHIP_H) end)
            local status = statusText(it)
            local desc = text(it.desc) or text("caps.desc." .. it.key) or ""
            ns.Kit.SetButton(b, n .. " " .. ns.T("caps.short." .. label), status and (status .. "\n" .. desc) or desc)
            b.tipTitle = n .. ". " .. ns.T("caps.stat." .. label)
            local w = (b.text:GetStringWidth() or 0) + CHIP_PAD * 2
            b:SetWidth(w)
            b.active = it.status ~= nil
            b.accent = it.status and statusColor(it.status) or nil
            b.kind = it.status == nil and "quiet" or nil
            b:Restyle()
            if x + w > width - PAD and x > PAD then
                x, y = PAD, y + CHIP_H + CHIP_GAP
            end
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", root, "TOPLEFT", x, -y)
            x = x + w + CHIP_GAP
        end
    end
    return y + CHIP_H + GAP
end
local function hard(it, m, y, width)
    local r, unit = it.r, it.r.unit
    local extra = { ns.T("caps.tip_cap", pair(r.needRating, r.needPct, unit)), ns.T("caps.tip_level") }
    if unit ~= "%" then extra[#extra + 1] = ns.T("caps.note_units") end
    y = y + head(y, width, ns.T("caps.stat." .. it.label), statusText(it), statusColor(r.status), m.next == it.key,
        statTip(it, extra))
    y = y + 6
    if r.havePct then
        local cap = r.needPct
        local segs = { { 0, r.havePct, C.caps.gear }, { r.havePct, r.totalPct, C.caps.src } }
        if r.totalPct > cap then segs[#segs + 1] = { cap, r.totalPct, C.caps.over } end
        y = y + bar(y, width, math.max(cap, r.totalPct), segs, r.caps, barTip({ "gear", "src", "over", "tick" })) + 5
        y = y + row(y, width, { label = ns.T("caps.row_gear"), swatch = C.caps.gear,
            value = pair(r.haveRating, r.havePct, unit, true) })
    end
    for _, s in ipairs(r.rows) do
        local key, picked, auto = s.key, s.picked, s.auto
        local name = s.name or ns.T("caps.group." .. s.key)
        y = y + row(y, width, {
            label = s.detail and (name .. " " .. s.detail) or name,
            labelColor = picked and C.text or C.off,
            value = picked and ("+" .. amount(s.pct, unit)) or ns.T("caps.skipped"),
            valueColor = picked and C.caps.src or C.off,
            icon = s.icon or ns.QMARK, dim = not picked,
            box = true, checked = picked,
            mark = (not s.on) and ((s.raid and picked) and MARK_WAIT or MARK_OFF) or nil,
            tipFn = sourceTip(s, m.ctx, unit),
            onClick = function()
                local on = not picked
                if on == (auto and true or false) then on = nil end
                Caps.SetPick(m.ctx, key, on)
                ns.RefreshWindow()
            end,
        })
    end
    local ln = texAt()
    tint(ln, C.line)
    ln:ClearAllPoints()
    ln:SetPoint("TOPLEFT", root, "TOPLEFT", PAD, -(y + 2))
    ln:SetWidth(width - PAD * 2); ln:SetHeight(1)
    y = y + 5
    if r.havePct then
        y = y + row(y, width, { label = ns.T("caps.row_total"), labelColor = C.text,
            value = pair(r.totalRating, r.totalPct, unit, true), valueColor = statusColor(r.status) })
    end
    y = y + row(y, width, { label = ns.T("caps.row_cap"), value = pair(r.needRating, r.needPct, unit),
        valueColor = C.text })
    y = y + row(y, width, { label = ns.T("caps.row_need"),
        value = pair(r.gearRating, r.gearPct, unit), valueColor = C.gold })
    if r.status == "under" then
        local title = ns.T("caps.row_loss")
        y = y + row(y, width, { label = title, valueColor = C.negative,
            value = "~" .. (r.lossDps and ns.T("caps.dps", r.lossDps) or ("%.2f%%"):format(r.lossPct)),
            tipFn = noteTip(title, ns.T("caps.tip_loss")) })
    elseif r.status == "over" then
        local title = ns.T("caps.row_conv", ns.T("caps.main." .. (r.mainStat or "any")))
        y = y + row(y, width, { label = title, value = ("~%.0f"):format(r.conv), valueColor = C.caps.over,
            tipFn = noteTip(title, ns.T("caps.tip_conv")) })
        if r.convDps then
            title = ns.T("caps.row_dps")
            y = y + row(y, width, { label = title, value = "+" .. ns.T("caps.dps", r.convDps),
                valueColor = C.positive, tipFn = noteTip(title, ns.T("caps.tip_dps")) })
        end
    end
    return y + GAP
end
local function target(it, m, y, width)
    local r = it.r
    y = y + head(y, width, ns.T("caps.stat." .. it.label), statusText(it), statusColor(it.status), m.next == it.key,
        statTip(it))
    y = y + 6
    if r.have then
        local ticks = {}
        for _, st in ipairs(r.steps or {}) do ticks[#ticks + 1] = st.v end
        if not r.steps and r.need then ticks[1] = r.need end
        y = y + bar(y, width, math.max(r.top, r.have), { { 0, r.have, C.caps.gear } }, ticks,
            barTip({ "have", "tick" })) + 5
        y = y + row(y, width, { label = ns.T("caps.row_now"), swatch = C.caps.gear, value = plain(it, r.have),
            valueColor = C.text })
    end
    if r.steps then
        for _, st in ipairs(r.steps) do
            y = y + row(y, width, { label = ns.T("caps.target." .. st.t), value = plain(it, st.v),
                valueColor = st.taken and C.positive or C.text, mark = st.taken and MARK_ON or nil })
        end
    elseif r.need then
        y = y + row(y, width, { label = ns.T("caps.row_goal"), value = plain(it, r.need), valueColor = C.gold })
    end
    return y + GAP
end
local function arp(it, m, y, width)
    local r = it.r
    local steps = { ns.T("caps.arp_boss") }
    for _, st in ipairs(r.steps or {}) do steps[#steps + 1] = ns.T("caps.arp_step", st[1], st[2]) end
    y = y + head(y, width, ns.T("caps.stat." .. it.label), statusText(it), C.text, false, statTip(it, steps))
    y = y + 6
    if not r.haveMissing then
        local segs = { { 0, r.pct, C.caps.gear } }
        if r.pct > 100 then segs[2] = { 100, r.pct, C.caps.over } end
        y = y + bar(y, width, math.max(100, r.pct), segs, { 100 }, barTip({ "have", "over", "tick" })) + 5
        y = y + row(y, width, { label = ns.T("caps.row_now"), swatch = C.caps.gear,
            value = pair(r.rating, r.pct, "%", true), valueColor = C.text })
    end
    y = y + row(y, width, { label = ns.T("caps.row_cap"), value = pair(r.cap, 100, "%"), valueColor = C.gold })
    if r.gain then
        local title = ns.T("caps.row_arp_gain")
        local tipFn = noteTip(title, ns.T("caps.tip_arp_gain"))
        y = y + row(y, width, { label = title, value = ("+%.0f%%"):format(r.gain), valueColor = C.positive, tipFn = tipFn })
        if r.left and r.left > 0.5 then
            y = y + row(y, width, { label = ns.T("caps.row_arp_left"), value = ("+%.0f%%"):format(r.left),
                valueColor = C.secondary, tipFn = tipFn })
        end
    end
    return y + GAP
end
local DRAW = { hard = hard, target = target, arp = arp }
local function specLine(m, width)
    local ctx = m.ctx
    if not specIcon then
        specIcon = root:CreateTexture(nil, "ARTWORK")
        specIcon:SetTexCoord(ICON_CROP[1], ICON_CROP[2], ICON_CROP[3], ICON_CROP[4])
        specIcon:SetWidth(20); specIcon:SetHeight(20)
        specIcon:SetPoint("LEFT", root, "TOPLEFT", PAD, -TOP_H / 2)
    end
    specIcon:SetTexture((ns.SpecIcon and ns.SpecIcon(ctx.class, ctx.spec))
        or (ctx.grid and ctx.grid[ctx.tab] and ctx.grid[ctx.tab].icon) or ns.QMARK)
    specIcon:Show()
    local right = width - PAD
    local list = Caps.Variants(ctx.class, ctx.tab)
    if #list > 1 then
        if not variantBtn then variantBtn = ns.Kit.Button(root, ns.Kit.H and ns.Kit.H.small or 18) end
        local names = {}
        for i, key in ipairs(list) do names[i] = ns.SpecName(ctx.class, key) end
        ns.Kit.SetButton(variantBtn, ns.T("caps.variant"),
            ns.T("caps.variant_tip", ns.SpecName(ctx.class, ctx.spec), table.concat(names, ", ")), function()
                Caps.NextVariant(ctx)
                ns.RefreshWindow()
            end)
        variantBtn.hints = { ns.Hint("caps_variant") }
        variantBtn:ClearAllPoints()
        variantBtn:SetPoint("RIGHT", root, "TOPLEFT", right, -TOP_H / 2)
        variantBtn:Show()
        right = right - variantBtn:GetWidth() - 6
    elseif variantBtn then
        variantBtn:Hide()
    end
    local fs = take("label", function()
        local f = root:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f:SetJustifyH("LEFT")
        f:SetHeight(14)
        return f
    end)
    fs:SetWidth(math.max(20, right - (PAD + 26)))
    fs:SetText(ns.SpecName(ctx.class, ctx.spec) .. ns.Hex("secondary") .. " — " .. ns.View.SetName(ctx.group) .. "|r")
    tint(fs, C.heading)
    fs:ClearAllPoints()
    fs:SetPoint("LEFT", root, "TOPLEFT", PAD + 26, -TOP_H / 2)
end
local function raidLine(m, y)
    if not raidSeg then raidSeg = ns.Kit.Segment(root) end
    local raid = Caps.RaidMode()
    local function set(on)
        return function()
            Caps.SetRaidMode(m.ctx, on)
            ns.RefreshWindow()
        end
    end
    raidSeg:Set({
        { label = ns.T("caps.mode_raid"), tip = ns.T("caps.mode_raid_tip"), active = raid, onClick = set(true) },
        { label = ns.T("caps.mode_solo"), tip = ns.T("caps.mode_solo_tip"), active = not raid, onClick = set(false) },
    })
    raidSeg:ClearAllPoints()
    raidSeg:SetPoint("TOPLEFT", root, "TOPLEFT", PAD, -y)
    raidSeg:Show()
    return y + ns.Kit.H.ctrl + GAP
end
function ns.CapsLibRender(parent, width)
    if not root then root = CreateFrame("Frame", nil, parent) end
    for k in pairs(used) do used[k] = 0 end
    root:ClearAllPoints()
    root:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    root:SetWidth(width)
    root:Show()
    local m = Caps.Model()
    local y
    if not m then
        if variantBtn then variantBtn:Hide() end
        if specIcon then specIcon:Hide() end
        if raidSeg then raidSeg:Hide() end
        y = 6 + para(ns.T("caps.none"), PAD, 6, width - PAD * 2, C.secondary) + 6
    else
        specLine(m, width)
        y = chips(m, TOP_H, width)
        y = raidLine(m, y)
        if m.ctx.points == 0 then
            y = y + para(ns.T("caps.no_talents"), PAD, y, width - PAD * 2, C.secondary) + 4
        end
        for _, it in ipairs(m.capped) do
            y = DRAW[it.kind](it, m, y, width)
        end
        if #m.more > 0 then
            y = y + head(y, width, ns.T("caps.nocap"))
            y = y + 4
            for _, it in ipairs(m.more) do
                y = y + row(y, width, { label = ns.T("caps.stat." .. it.label), labelColor = C.text, flat = true,
                    value = it.value and plain(it, it.value) or ns.T("caps.unread"),
                    valueColor = it.value and C.text or C.off, tipFn = statTip(it) })
            end
            y = y + GAP
        end
    end
    for kind, list in pairs(pool) do
        for i = used[kind] + 1, #list do list[i]:Hide() end
    end
    root:SetHeight(math.max(y, 1))
    return y
end
function ns.CapsLibHide()
    if root then root:Hide() end
end
local watch = CreateFrame("Frame")
for _, ev in ipairs({ "UNIT_STATS", "COMBAT_RATING_UPDATE", "PLAYER_EQUIPMENT_CHANGED", "UNIT_AURA",
                      "PLAYER_TALENT_UPDATE", "ACTIVE_TALENT_GROUP_CHANGED", "GLYPH_ADDED", "GLYPH_REMOVED",
                      "GLYPH_UPDATED", "RAID_ROSTER_UPDATE", "PARTY_MEMBERS_CHANGED" }) do
    watch:RegisterEvent(ev)
end
watch:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_STATS" and unit ~= "player" then return end
    if event == "UNIT_AURA" and unit ~= "player" and unit ~= "target" then return end
    if not (HTP_TalentsDB.lib == true and ns.LibPane and ns.LibPane() == "caps"
            and ns.WindowShown and ns.WindowShown()) then return end
    if ns.RefreshSoon then ns.RefreshSoon() else ns.RefreshWindow() end
end)
