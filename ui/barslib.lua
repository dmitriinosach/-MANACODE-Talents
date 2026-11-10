local ADDON, ns = ...
local C = ns.C
local WHITE = "Interface\\Buttons\\WHITE8X8"
local ICON_CROP = { 0.07, 0.93, 0.07, 0.93 }
local ROW_H, OPEN_H = 28, 30
local ICON = 22
local TEXT_X = 6 + ICON + 6
local TOP_H = 30
local SEC_H = 26
local ACT = 18
local PREVIEW_ICON, PREVIEW_GAP = 22, 2
local PREVIEW_LABEL = 96
local PREVIEW_PAD = 10
local PREVIEW_ROWS = {
    { "bars.row_main", 1 }, { "bars.row_page2", 13 }, { "bars.row_right", 25 }, { "bars.row_right2", 37 },
    { "bars.row_bottom_right", 49 }, { "bars.row_bottom_left", 61 }, { "bars.row_stance1", 73 },
    { "bars.row_stance2", 85 }, { "bars.row_stance3", 97 }, { "bars.row_stance4", 109 },
}
local rows, top, head, note, acts, preview = {}, nil, nil, nil, nil, nil
local openIdx
local function report(ok, msg)
    if msg then ns.warn(msg) end
    if ns.RefreshWindow then ns.RefreshWindow() end
end
local function apply(p)
    local ok, msg, ops = ns.BarsApply(p)
    report(ok, msg)
    if ok then ns.MurlocParade(ops) end
end
local function previewFrame()
    if preview then return preview end
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetFrameStrata("TOOLTIP")
    f:SetClampedToScreen(true)
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOPLEFT", f, "TOPLEFT", PREVIEW_PAD, -PREVIEW_PAD)
    f.title:SetJustifyH("LEFT")
    f.sub = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.sub:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -3)
    f.sub:SetJustifyH("LEFT")
    f.labels, f.cells = {}, {}
    for r = 1, #PREVIEW_ROWS do
        local l = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        l:SetJustifyH("LEFT")
        l:SetWidth(PREVIEW_LABEL - 4)
        f.labels[r] = l
        f.cells[r] = {}
        for c = 1, 12 do
            local cell = CreateFrame("Frame", nil, f)
            cell:SetWidth(PREVIEW_ICON); cell:SetHeight(PREVIEW_ICON)
            cell.edge = cell:CreateTexture(nil, "BACKGROUND")
            cell.edge:SetTexture(WHITE)
            cell.edge:SetAllPoints()
            cell.icon = cell:CreateTexture(nil, "ARTWORK")
            cell.icon:SetPoint("TOPLEFT", cell, "TOPLEFT", 1, -1)
            cell.icon:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", -1, 1)
            cell.icon:SetTexCoord(ICON_CROP[1], ICON_CROP[2], ICON_CROP[3], ICON_CROP[4])
            f.cells[r][c] = cell
        end
    end
    f.foot = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.foot:SetJustifyH("LEFT")
    ns.Kit.StylePanel(f)
    ns.Kit.Track(f, function(self) ns.Kit.StylePanel(self) end)
    f:Hide()
    preview = f
    return f
end
local function showPreview(p, anchor)
    local f = previewFrame()
    local h, s, t, g, sh = C.heading, C.secondary, C.text, C.gold, C.shade
    f.title:SetText(p.name)
    f.title:SetTextColor(h[1], h[2], h[3])
    local diff = ns.BarsDiff(p)
    f.sub:SetText(ns.T("bars.preview_sub", p.count, date("%d.%m.%Y %H:%M", p.at),
        diff > 0 and ns.T("bars.preview_diff", diff) or ns.T("bars.preview_same")))
    f.sub:SetTextColor(s[1], s[2], s[3])
    local y = PREVIEW_PAD + f.title:GetStringHeight() + 3 + f.sub:GetStringHeight() + 8
    local shown = 0
    for r, def in ipairs(PREVIEW_ROWS) do
        local base, any = def[2], false
        for c = 0, 11 do if p.slots[base + c] then any = true end end
        local l, cells = f.labels[r], f.cells[r]
        if any then
            shown = shown + 1
            l:ClearAllPoints()
            l:SetPoint("LEFT", f, "TOPLEFT", PREVIEW_PAD, -(y + PREVIEW_ICON / 2))
            l:SetText(ns.T(def[1]))
            l:SetTextColor(s[1], s[2], s[3])
            l:Show()
            for c = 1, 12 do
                local slot = base + c - 1
                local e = p.slots[slot]
                local cell = cells[c]
                cell:ClearAllPoints()
                cell:SetPoint("TOPLEFT", f, "TOPLEFT", PREVIEW_PAD + PREVIEW_LABEL + (c - 1) * (PREVIEW_ICON + PREVIEW_GAP), -y)
                if e then
                    cell.icon:SetTexture(e.tex or ns.QMARK)
                    cell.icon:Show()
                else
                    cell.icon:Hide()
                end
                local changed = ns.BarKey(e) ~= ns.BarKey(ns.BarEntry(slot))
                local edge = changed and g or sh
                cell.edge:SetVertexColor(edge[1], edge[2], edge[3], changed and 1 or 0.6)
                cell:Show()
            end
            y = y + PREVIEW_ICON + PREVIEW_GAP
        else
            l:Hide()
            for c = 1, 12 do cells[c]:Hide() end
        end
    end
    f.foot:ClearAllPoints()
    f.foot:SetPoint("TOPLEFT", f, "TOPLEFT", PREVIEW_PAD, -(y + 6))
    f.foot:SetWidth(PREVIEW_LABEL + 12 * (PREVIEW_ICON + PREVIEW_GAP))
    f.foot:SetText(ns.T("bars.preview_foot"))
    f.foot:SetTextColor(t[1], t[2], t[3])
    y = y + 6 + f.foot:GetStringHeight() + PREVIEW_PAD
    f:SetWidth(PREVIEW_PAD * 2 + PREVIEW_LABEL + 12 * (PREVIEW_ICON + PREVIEW_GAP))
    f:SetHeight(y)
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 12, 0)
    f:Show()
end
local function hidePreview()
    if preview then preview:Hide() end
end
local function paint(b)
    local fill = (b.open and C.selected) or (b.hovered and C.hover) or nil
    if fill then
        b.fill:SetVertexColor(fill[1], fill[2], fill[3], fill[4] or 1)
        b.fill:Show()
    else
        b.fill:Hide()
    end
end
local function rowEnter(self)
    self.hovered = true
    paint(self)
    local p = ns.BarPresets()[self.index]
    if p then showPreview(p, self) end
end
local function rowLeave(self)
    hidePreview()
    self.hovered = self:IsMouseOver() and true or false
    paint(self)
end
local function rowAt(parent, i)
    local b = rows[i]
    if b then return b end
    b = CreateFrame("Button", nil, parent)
    b.fill = b:CreateTexture(nil, "BACKGROUND")
    b.fill:SetTexture(WHITE)
    b.fill:SetAllPoints(b)
    b.bar = b:CreateTexture(nil, "BORDER")
    b.bar:SetTexture(WHITE)
    b.bar:SetWidth(2)
    b.bar:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
    b.bar:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 0, 0)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetWidth(ICON); b.icon:SetHeight(ICON)
    b.icon:SetTexCoord(ICON_CROP[1], ICON_CROP[2], ICON_CROP[3], ICON_CROP[4])
    b.icon:SetPoint("LEFT", b, "TOPLEFT", 6, -ROW_H / 2)
    b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    b.label:SetJustifyH("LEFT")
    b.label:SetHeight(14)
    b.label:SetPoint("LEFT", b, "TOPLEFT", TEXT_X, -ROW_H / 2)
    b.count = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.count:SetPoint("RIGHT", b, "TOPRIGHT", -6, -ROW_H / 2)
    b:SetScript("OnEnter", rowEnter)
    b:SetScript("OnLeave", rowLeave)
    b:SetScript("OnClick", function(self)
        openIdx = openIdx ~= self.index and self.index or nil
        ns.RefreshWindow()
    end)
    rows[i] = b
    return b
end
local function rowMenu(i)
    local p = ns.BarPresets()[i]
    local block = ns.BarsBlock()
    return {
        { label = ns.T("bars.overwrite"), tip = ns.T("bars.overwrite_tip"), off = block,
          onClick = function() report(ns.BarsSave(nil, i)) end },
        { label = ns.T("act.rename"), tip = ns.T("bars.rename_tip"),
          onClick = function()
              ns.Popup("HTP_TALENTS_RENAME", nil, nil, { name = p and p.name, textKey = "bars.rename_popup",
                  apply = function(text) return ns.BarsRename(i, text) end })
          end },
        { label = ns.T("act.delete"), tip = ns.T("bars.delete_tip"), sep = true,
          onClick = function() ns.Popup("HTP_TALENTS_BARS_DELETE", p and p.name, nil, { index = i }) end },
    }
end
local function actsFor(parent)
    if acts then return acts end
    acts = { apply = ns.Kit.Pill(parent),
             more = ns.Kit.Orb(parent, "more", ns.T("act.more"), ns.T("tip.more"), nil, ACT) }
    acts.apply.kind = "main"
    return acts
end
local function placeActs(parent, b, i)
    local a = actsFor(parent)
    local p = ns.BarPresets()[i]
    local block = ns.BarsBlock()
    ns.Kit.SetPill(a.apply, "bars", ns.T("bars.apply"), block or ns.T("bars.apply_tip"), function()
        if p then apply(p) end
    end)
    a.apply.off = block ~= nil
    a.apply:Restyle()
    a.more.tipTitle, a.more.tipBody = ns.T("act.more"), ns.T("tip.more")
    a.more.onClick = function() ns.WinMenu(a.more, rowMenu(i)) end
    local y = -(ROW_H + OPEN_H / 2 - 3)
    a.apply:SetParent(b); a.more:SetParent(b)
    a.apply:SetFrameLevel(b:GetFrameLevel() + 1); a.more:SetFrameLevel(b:GetFrameLevel() + 1)
    a.apply:ClearAllPoints()
    a.apply:SetPoint("LEFT", b, "TOPLEFT", TEXT_X, y)
    a.more:ClearAllPoints()
    a.more:SetPoint("LEFT", a.apply, "RIGHT", 6, 0)
    a.apply:Show(); a.more:Show()
end
function ns.BarsLibRender(parent, width)
    local list = ns.BarPresets()
    if openIdx and not list[openIdx] then openIdx = nil end
    local h, s, l, t, g = C.heading, C.secondary, C.line, C.text, C.gold
    if not top then
        top = ns.Kit.Pill(parent)
        top.kind = "quiet"
        top.count = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        head = CreateFrame("Frame", nil, parent)
        head:SetHeight(SEC_H)
        head.title = head:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        head.title:SetPoint("BOTTOMLEFT", head, "BOTTOMLEFT", 4, 6)
        head.line = head:CreateTexture(nil, "ARTWORK")
        head.line:SetTexture(WHITE)
        head.line:SetHeight(1)
        head.line:SetPoint("BOTTOMLEFT", head, "BOTTOMLEFT", 0, 0)
        head.line:SetPoint("BOTTOMRIGHT", head, "BOTTOMRIGHT", 0, 0)
        note = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        note:SetJustifyH("LEFT")
    end
    local block = ns.BarsBlock()
    local full = #list >= ns.BARS_MAX
    ns.Kit.SetPill(top, "save", ns.T("bars.save"), (full and ns.T("msg.bars_full", ns.BARS_MAX)) or block
        or ns.T("bars.save_tip"), function()
        ns.Popup("HTP_TALENTS_RENAME", nil, nil, {
            name = ns.T("bars.default_name", date("%d.%m %H:%M")), textKey = "bars.save_popup", btnKey = "bars.save_btn",
            apply = function(text) return ns.BarsSave(text) end })
    end)
    top.off = (full or block) and true or false
    top:Restyle()
    top:ClearAllPoints()
    top:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -2)
    top:Show()
    top.count:SetText(ns.T("lib.count", #list, ns.BARS_MAX))
    top.count:SetTextColor(s[1], s[2], s[3])
    top.count:ClearAllPoints()
    top.count:SetPoint("RIGHT", parent, "TOPLEFT", width - 4, -2 - ns.Kit.H.ctrl / 2)
    top.count:Show()
    local y = TOP_H
    head.title:SetText(ns.T("bars.section"))
    head.title:SetTextColor(h[1], h[2], h[3])
    head.line:SetVertexColor(l[1], l[2], l[3], l[4] or 1)
    head:ClearAllPoints()
    head:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -y)
    head:SetWidth(width)
    head:Show()
    y = y + SEC_H + 2
    local opened = false
    for i, p in ipairs(list) do
        local b = rowAt(parent, i)
        b.index = i
        b.open = openIdx == i
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -y)
        b:SetWidth(width)
        b:SetHeight(b.open and (ROW_H + OPEN_H) or ROW_H)
        b.icon:SetTexture(ns.BarsIcon(p) or ns.QMARK)
        b.count:SetText(ns.T("bars.count", p.count))
        b.count:SetTextColor(s[1], s[2], s[3])
        b.label:SetWidth(width - TEXT_X - 10 - b.count:GetStringWidth())
        b.label:SetText(p.name)
        local lc = b.open and g or t
        b.label:SetTextColor(lc[1], lc[2], lc[3])
        if b.open then
            b.bar:SetVertexColor(g[1], g[2], g[3], 1)
            b.bar:Show()
            placeActs(parent, b, i)
            opened = true
        else
            b.bar:Hide()
        end
        b:Show()
        b.hovered = b:IsMouseOver() and true or false
        paint(b)
        y = y + b:GetHeight()
    end
    for i = #list + 1, #rows do rows[i]:Hide() end
    if not opened and acts then acts.apply:Hide(); acts.more:Hide() end
    if #list == 0 then
        note:ClearAllPoints()
        note:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, -(y + 4))
        note:SetWidth(width - 12)
        note:SetText(ns.T("bars.empty"))
        note:SetTextColor(s[1], s[2], s[3])
        note:Show()
        y = y + note:GetStringHeight() + 8
    else
        note:Hide()
    end
    return y
end
function ns.BarsLibHide()
    if not top then return end
    top:Hide(); top.count:Hide(); head:Hide(); note:Hide()
    for _, b in ipairs(rows) do b:Hide() end
    if acts then acts.apply:Hide(); acts.more:Hide() end
    hidePreview()
end
StaticPopupDialogs["HTP_TALENTS_BARS_DELETE"] = {
    htpKeys = { text = "bars.delete_popup", button1 = "popup.delete_btn", button2 = "popup.cancel" },
    OnAccept = function(_, data)
        if data and data.index then ns.BarsDelete(data.index) end
        openIdx = nil
        if ns.RefreshWindow then ns.RefreshWindow() end
    end,
    timeout = 0, whileDead = 1, hideOnEscape = 1,
}
local watch = CreateFrame("Frame")
for _, ev in ipairs({ "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "CURSOR_UPDATE", "ACTIONBAR_SLOT_CHANGED" }) do
    watch:RegisterEvent(ev)
end
watch:SetScript("OnEvent", function()
    if not (ns.LibPane and ns.LibPane() == "bars" and ns.WindowShown and ns.WindowShown()) then return end
    if ns.RefreshSoon then ns.RefreshSoon() else ns.RefreshWindow() end
end)
