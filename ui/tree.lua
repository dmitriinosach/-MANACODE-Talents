local ADDON, ns = ...
local C = ns.C
local QMARK = "Interface\\Icons\\INV_Misc_QuestionMark"
local WIDE = { icon = 30, colw = 46, rowh = 39, x0 = 10, y0 = 30, pad = 10, gap = 12, panels = 3, framed = true }
WIDE.panelW = WIDE.x0 * 2 + 3 * WIDE.colw + WIDE.icon
local NATIVE = { icon = 37, colw = 63, rowh = 63, x0 = 35, y0 = 20, pad = 20, gap = 0, panels = 1, framed = false,
                 panelW = 320 }
ns.TREE_WIDTH = WIDE.panels * WIDE.panelW + (WIDE.panels - 1) * WIDE.gap
ns.TREE_GEOM = { wide = WIDE, native = NATIVE }
local T_BRANCH_TEX = "Interface\\TalentFrame\\UI-TalentBranches"
local T_ARROW_TEX  = "Interface\\TalentFrame\\UI-TalentArrows"
local T_BR = {
    v = { [1] = { 0, 0.125, 0, 0.484375 },        [0] = { 0, 0.125, 0.515625, 1 } },
    h = { [1] = { 0.2578125, 0.3828125, 0, 0.5 }, [0] = { 0.2578125, 0.3828125, 0.5, 1 } },
    topright    = { [1] = { 0.515625, 0.640625, 0, 0.5 },      [0] = { 0.515625, 0.640625, 0.5, 1 } },
    topleft     = { [1] = { 0.640625, 0.515625, 0, 0.5 },      [0] = { 0.640625, 0.515625, 0.5, 1 } },
    bottomright = { [1] = { 0.38671875, 0.51171875, 0, 0.5 },  [0] = { 0.38671875, 0.51171875, 0.5, 1 } },
    bottomleft  = { [1] = { 0.51171875, 0.38671875, 0, 0.5 },  [0] = { 0.51171875, 0.38671875, 0.5, 1 } },
    tdown       = { [1] = { 0.64453125, 0.76953125, 0, 0.5 },  [0] = { 0.64453125, 0.76953125, 0.5, 1 } },
    tup         = { [1] = { 0.7734375, 0.8984375, 0, 0.5 },    [0] = { 0.7734375, 0.8984375, 0.5, 1 } },
}
local T_AR = {
    down  = { [1] = { 0, 0.5, 0, 0.5 }, [0] = { 0, 0.5, 0.5, 1 } },
    right = { [1] = { 0.5, 1, 0, 0.5 }, [0] = { 0.5, 1, 0.5, 1 } },
    left  = { [1] = { 1, 0.5, 0, 0.5 }, [0] = { 1, 0.5, 0.5, 1 } },
}
local TREE_TINT = {
    PRIEST = { { 0.30, 0.25, 0.14 }, { 0.30, 0.27, 0.16 }, { 0.20, 0.16, 0.32 } },
}
local PANEL_BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}
local cellEnter
local rankLink
local function cellLink(self)
    local tab, index, r = self.talentTab, self.talentIdx, self.tipRank or 0
    if self.liveGroup then
        return GetTalentLink(tab, index, false, false, self.liveGroup, ns.PreviewEnabled())
    end
    if self.ownClass then return rankLink(tab, index, r) end
    local spells = self.tipSpells
    local id = spells and (spells[r > 0 and r or 1] or spells[1])
    return id and GetSpellLink(id) or nil
end
local function treeCellClick(self, mouse)
    if IsModifiedClick("CHATLINK") then
        local link = cellLink(self)
        if link then ChatEdit_InsertLink(link) end
        return
    end
    local e = self.edit
    if not e or e.locked then return end
    if mouse == "RightButton" then
        if e.onRemove then e.onRemove(self.talentTab, self.talentIdx) end
    elseif e.onAdd then
        e.onAdd(self.talentTab, self.talentIdx)
    end
    if self:IsMouseOver() then cellEnter(self) end
end
local scanTip
local function scanner()
    scanTip = scanTip or CreateFrame("GameTooltip", "HTP_TalentsScanTip", nil, "GameTooltipTemplate")
    scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTip:ClearLines()
    return scanTip
end
local function scanLines(link, skipRankLine)
    local tip = scanner()
    local ok = pcall(tip.SetHyperlink, tip, link)
    if not ok then tip:Hide(); return nil end
    local out = {}
    for i = 2, tip:NumLines() or 0 do
        local fs = _G["HTP_TalentsScanTipTextLeft" .. i]
        local t = fs and fs:GetText()
        if t and t ~= "" and not (skipRankLine and strmatch(t, "^%D*%d+/%d+%s*$")) then
            out[#out + 1] = t
        end
    end
    tip:Hide()
    return #out > 0 and out or nil
end
rankLink = function(tab, index, rank)
    local link = GetTalentLink(tab, index)
    if not link then return nil end
    local enc = tonumber(strmatch(link, "|Htalent:%d+:(%-?%d+)"))
    if not enc then return nil end
    local live = select(5, GetTalentInfo(tab, index)) or 0
    return (link:gsub("(|Htalent:%d+):%-?%d+", "%1:" .. (enc - live + rank), 1))
end
local function rankDesc(tab, index, rank)
    local link = rankLink(tab, index, rank)
    return link and scanLines(link, true) or nil
end
local function spellDesc(spells, rank)
    if not spells then return nil end
    local id = spells[rank > 0 and rank or 1] or spells[1]
    if not id then return nil end
    return scanLines("spell:" .. id, false)
end
local function gateLines(self, r, m, e)
    local need, pre, preMax
    if e and e.gate then need, pre, preMax = e.gate(self.talentTab, self.talentIdx) end
    if need then
        local branch = e.branch and e.branch(self.talentTab) or "?"
        GameTooltip:AddLine(format(TOOLTIP_TALENT_TIER_POINTS, need, branch), 1, 0.12, 0.12, true)
    end
    if pre then
        GameTooltip:AddLine(format(TOOLTIP_TALENT_PREREQ, preMax or 1, pre), 1, 0.12, 0.12, true)
    end
    return need, pre
end
cellEnter = function(self)
    local r, m = self.tipRank or 0, self.tipMax or 0
    local e = self.edit
    if self.liveGroup then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetTalent(self.talentTab, self.talentIdx, false, false, self.liveGroup, ns.PreviewEnabled())
        if self.tipMark then
            GameTooltip:AddLine(ns.T("tip.mark_rank", self.tipMark, m), 1, 0.82, 0)
        end
        for _, c in ipairs(self.tipCmps or {}) do
            GameTooltip:AddLine(ns.T("tip.cmp_rank", c.name, c.rank, m), c.color[1], c.color[2], c.color[3])
        end
        if e and e.locked then
            GameTooltip:AddLine(ns.T("tip.learn_wait"), 1, 0.82, 0, true)
        end
        GameTooltip:Show()
        return
    end
    local desc
    if self.tipSpells then
        desc = spellDesc(self.tipSpells, r)
    else
        desc = rankDesc(self.talentTab, self.talentIdx, r)
    end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(self.tipName or "?", 1, 1, 1)
    GameTooltip:AddLine(format(TOOLTIP_TALENT_RANK, r, m), 1, 1, 1)
    if self.tipMark then
        GameTooltip:AddLine(ns.T("tip.mark_rank", self.tipMark, m), 1, 0.82, 0)
    end
    for _, c in ipairs(self.tipCmps or {}) do
        GameTooltip:AddLine(ns.T("tip.cmp_rank", c.name, c.rank, m), c.color[1], c.color[2], c.color[3])
    end
    local need, pre = gateLines(self, r, m, e)
    for _, ln in ipairs(desc or {}) do
        if ln == TOOLTIP_TALENT_NEXT_RANK then
            GameTooltip:AddLine(ln, 1, 1, 1)
        else
            GameTooltip:AddLine(ln, 1, 0.82, 0, true)
        end
    end
    if e and r < m and e.left and e.left <= 0 then
        GameTooltip:AddLine(ns.T("tip.builder_no_points"), 1, 0.12, 0.12, true)
    elseif e and not need and not pre and r < m and (e.left == nil or e.left > 0) then
        GameTooltip:AddLine(TOOLTIP_TALENT_LEARN, 0.1, 1, 0.1)
    end
    GameTooltip:Show()
end
local function hideTip() GameTooltip:Hide() end
local trees = setmetatable({}, { __mode = "k" })
function ns.HighlightTalent(tab, index)
    for tp in pairs(trees) do
        for _, panel in ipairs(tp.panels) do
            for _, c in ipairs(panel.cells) do
                if tab and c:IsShown() and c.talentTab == tab and c.talentIdx == index then c.hl:Show() else c.hl:Hide() end
            end
        end
    end
    if ns.OnTalentHighlight then ns.OnTalentHighlight(tab, index) end
end
local function cellOver(self)
    cellEnter(self)
    if self.tipCmps then ns.HighlightTalent(self.talentTab, self.talentIdx) end
end
local function cellOut(self)
    hideTip()
    if self.tipCmps then ns.HighlightTalent(nil) end
end
local CMP_CORNER = {
    { "TOPLEFT", -4, 4 }, { "TOPRIGHT", 4, 4 }, { "BOTTOMLEFT", -4, -4 },
}
local function makeTreeCell(parent, pool, i, g)
    local b = pool[i]
    if not b then
        local slot = math.floor(g.icon * 64 / 37 + 0.5)
        b = CreateFrame("Button", nil, parent)
        b.slot = b:CreateTexture(nil, "BACKGROUND")
        b.slot:SetTexture("Interface\\Buttons\\UI-EmptySlot-White")
        b.slot:SetPoint("CENTER", b, "CENTER", 0, -1)
        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetAllPoints(b)
        b.frame = b:CreateTexture(nil, "OVERLAY")
        b.frame:SetTexture("Interface\\Buttons\\UI-Quickslot2")
        b.frame:SetPoint("CENTER", b, "CENTER", 0, -1)
        b.rankBg = b:CreateTexture(nil, "OVERLAY")
        b.rankBg:SetTexture("Interface\\TalentFrame\\TalentFrame-RankBorder")
        b.rankBg:SetWidth(32); b.rankBg:SetHeight(32)
        b.rankBg:SetPoint("CENTER", b, "BOTTOMRIGHT", 0, 0)
        b.rank = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        b.rank:SetPoint("CENTER", b.rankBg, "CENTER", 0, 0)
        b.cmp = {}
        for k, pos in ipairs(CMP_CORNER) do
            local fs = b:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
            fs:SetPoint(pos[1], b, pos[1], pos[2], pos[3])
            b.cmp[k] = fs
        end
        b.hl = b:CreateTexture(nil, "OVERLAY")
        b.hl:SetTexture("Interface\\Buttons\\CheckButtonHilight")
        b.hl:SetBlendMode("ADD")
        b.hl:SetPoint("TOPLEFT", b, "TOPLEFT", -4, 4)
        b.hl:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 4, -4)
        b.hl:Hide()
        b.mark = b:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        b.mark:SetPoint("TOPLEFT", b, "TOPLEFT", -4, 4)
        b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        b:SetScript("OnEnter", cellOver)
        b:SetScript("OnLeave", cellOut)
        b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        b:SetScript("OnClick", treeCellClick)
        b:SetWidth(g.icon); b:SetHeight(g.icon)
        b.slot:SetWidth(slot); b.slot:SetHeight(slot)
        b.frame:SetWidth(slot); b.frame:SetHeight(slot)
        pool[i] = b
    end
    b.edit = nil
    b.tipCmps = nil
    b.tipMark = nil
    b.icon:SetDesaturated(false)
    b.slot:SetVertexColor(C.tree.slot[1], C.tree.slot[2], C.tree.slot[3])
    b.rank:Hide()
    b.rankBg:Hide()
    for _, fs in ipairs(b.cmp) do fs:Hide() end
    b.hl:Hide()
    b.mark:Hide()
    b:Show()
    return b
end
local function newPane(parent, g)
    local tp = { panels = {}, g = g }
    tp.frame = CreateFrame("Frame", nil, parent)
    local bd = CreateFrame("Frame", nil, tp.frame)
    bd:SetWidth(26); bd:SetHeight(26)
    bd:SetBackdrop(PANEL_BACKDROP)
    bd.num = bd:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bd.num:SetPoint("CENTER", bd, "CENTER", 0, 0)
    bd:SetPoint("TOPRIGHT", tp.frame, "TOPRIGHT", -4, -4)
    bd:EnableMouse(true)
    bd:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(format(UNSPENT_TALENT_POINTS, self.num:GetText() or "0"))
        GameTooltip:Show()
    end)
    bd:SetScript("OnLeave", hideTip)
    bd:Hide()
    tp.badge = bd
    for i = 1, g.panels do
        local p = CreateFrame("Frame", nil, tp.frame)
        p:SetWidth(g.panelW)
        if g.framed then
            p:SetBackdrop(PANEL_BACKDROP)
        end
        local function mkQuad(corner, cx, cy, inner)
            local q = p:CreateTexture(nil, "BORDER")
            q:SetPoint(corner, p, corner, cx, cy)
            q:SetPoint(inner, p, "CENTER", 0, 0)
            q:Hide()
            return q
        end
        p.quads = {
            TL = mkQuad("TOPLEFT",      3, -3, "BOTTOMRIGHT"),
            TR = mkQuad("TOPRIGHT",    -3, -3, "BOTTOMLEFT"),
            BL = mkQuad("BOTTOMLEFT",   3,  3, "TOPRIGHT"),
            BR = mkQuad("BOTTOMRIGHT", -3,  3, "TOPLEFT"),
        }
        p.title = p:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        p.title:SetPoint("TOP", p, "TOP", 0, -4)
        p.arrowLayer = CreateFrame("Frame", nil, p)
        p.arrowLayer:SetAllPoints(p)
        p.arrowLayer:SetFrameLevel(p:GetFrameLevel() + 5)
        tp.panels[i] = { bg = p, cells = {}, lines = {}, arrows = {} }
    end
    return tp
end
local function applyPanelSkin(p, tint, bgFile, g, border)
    for _, q in pairs(p.quads) do q:Hide() end
    if not g.framed then
        p.title:Hide()
        return
    end
    p.title:Show()
    if border then
        p:SetBackdropBorderColor(border[1], border[2], border[3], 1)
    else
        local e = C.tree.border
        p:SetBackdropBorderColor(e[1], e[2], e[3], e[4])
    end
    if bgFile then
        local base = "Interface\\TalentFrame\\" .. bgFile
        if p.quads.TL:SetTexture(base .. "-TopLeft") ~= false then
            p.quads.TR:SetTexture(base .. "-TopRight")
            p.quads.BL:SetTexture(base .. "-BottomLeft")
            p.quads.BR:SetTexture(base .. "-BottomRight")
            local iw = (p:GetWidth() or g.panelW) - 6
            local ih = (p:GetHeight() or 1) - 6
            local a = (ih > 0) and (iw / ih) or 1
            if a > 1 then a = 1 end
            p.quads.TL:SetTexCoord(1 - a, 1, 0, 1)
            p.quads.TR:SetTexCoord(0, a, 0, 1)
            p.quads.BL:SetTexCoord(1 - a, 1, 0, 1)
            p.quads.BR:SetTexCoord(0, a, 0, 1)
            local art, bg = C.tree.art, C.tree.artBg
            for _, q in pairs(p.quads) do
                q:SetVertexColor(art[1], art[2], art[3], art[4])
                q:Show()
            end
            p:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
            return
        end
    end
    if tint then
        p:SetBackdropColor(tint[1], tint[2], tint[3], 0.9)
    else
        local bg = C.tree.bg
        p:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
    end
end
local function drawLinks(panel, p, t, g)
    local nLine, nArrow, half = 0, 0, g.icon / 2
    local function seg(x, y, w, h, tc)
        nLine = nLine + 1
        local ln = panel.lines[nLine]
        if not ln then
            ln = p:CreateTexture(nil, "ARTWORK")
            ln:SetTexture(T_BRANCH_TEX)
            panel.lines[nLine] = ln
        end
        ln:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
        ln:ClearAllPoints()
        ln:SetPoint("TOPLEFT", p, "TOPLEFT", x, -y)
        ln:SetWidth(w); ln:SetHeight(h)
        ln:Show()
    end
    local function arrow(cx, cy, tc)
        nArrow = nArrow + 1
        local ar = panel.arrows[nArrow]
        if not ar then
            ar = p.arrowLayer:CreateTexture(nil, "ARTWORK")
            ar:SetTexture(T_ARROW_TEX)
            ar:SetWidth(32); ar:SetHeight(32)
            panel.arrows[nArrow] = ar
        end
        ar:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
        ar:ClearAllPoints()
        ar:SetPoint("TOPLEFT", p.arrowLayer, "TOPLEFT", cx - 16, -(cy - 16))
        ar:Show()
    end
    local function centerOf(row, col)
        return g.x0 + (col - 1) * g.colw + half,
               g.y0 + (row - 1) * g.rowh + half
    end
    local occupied, vEdge, hEdge = {}, {}, {}
    local topArr, arrLeft, arrRight = {}, {}, {}
    local function at(store, row, col)
        return store[row] and store[row][col]
    end
    local function put(store, row, col, val)
        store[row] = store[row] or {}
        local was = store[row][col]
        if was == nil or val > was then store[row][col] = val end
    end
    for _, tal in ipairs(t.talents or {}) do
        occupied[tal.row or 1] = occupied[tal.row or 1] or {}
        occupied[tal.row or 1][tal.col or 1] = true
    end
    for _, tal in ipairs(t.talents or {}) do
        if tal.prereq then
            local k = (tal.rank or 0) > 0 and 1 or 0
            local pr, pc = tal.prereq.row or 1, tal.prereq.col or 1
            local tr, tc = tal.row or 1, tal.col or 1
            if pc == tc then
                for r = pr, tr - 1 do put(vEdge, r, pc, k) end
                put(topArr, tr, tc, k)
            elseif pr == tr then
                for c = math.min(pc, tc), math.max(pc, tc) - 1 do put(hEdge, pr, c, k) end
                put(pc < tc and arrLeft or arrRight, tr, tc, k)
            else
                local lo, hi = math.min(pc, tc), math.max(pc, tc)
                local scanLo = (lo == pc) and lo + 1 or lo
                local scanHi = (lo == pc) and hi or hi - 1
                local blocked = false
                for c = scanLo, scanHi do
                    if at(occupied, pr, c) then blocked = true end
                end
                if not blocked then
                    for c = lo, hi - 1 do put(hEdge, pr, c, k) end
                    for r = pr, tr - 1 do put(vEdge, r, tc, k) end
                    put(topArr, tr, tc, k)
                else
                    for r = pr, tr - 1 do put(vEdge, r, pc, k) end
                    put(pc < tc and arrLeft or arrRight, tr, tc, k)
                end
            end
        end
    end
    local ARROW_PAD = 4
    local CORNER = 32
    local OVER = 5
    local corner, chalf, corners = {}, CORNER / 2, {}
    for row = 1, (t.rows or 1) + 1 do
        for col = 1, 4 do
            if not at(occupied, row, col) then
                local l = at(hEdge, row, col - 1)
                local r = at(hEdge, row, col)
                local d = at(vEdge, row, col)
                local u = at(vEdge, row - 1, col)
                local k = d or u or l or r
                local kind
                if l and r and d then kind = "tdown"
                elseif l and r and u then kind = "tup"
                elseif l and d then kind = "topright"
                elseif r and d then kind = "topleft"
                elseif l and u then kind = "bottomright"
                elseif r and u then kind = "bottomleft"
                end
                if kind then
                    put(corner, row, col, k)
                    corners[#corners + 1] = { row = row, col = col, kind = kind, k = k }
                end
            end
        end
    end
    for row, cols in pairs(vEdge) do
        for col, k in pairs(cols) do
            local x, y = centerOf(row, col)
            local _, y2 = centerOf(row + 1, col)
            local from = at(corner, row, col) and (y + chalf - OVER) or y
            local stop = y2
            if at(corner, row + 1, col) then
                stop = y2 - chalf + OVER
            elseif at(topArr, row + 1, col) then
                stop = y2 - half - ARROW_PAD
            end
            if stop > from then seg(x - 16, from, 32, stop - from, T_BR.v[k]) end
        end
    end
    for row, cols in pairs(hEdge) do
        for col, k in pairs(cols) do
            local x, y = centerOf(row, col)
            local x2 = centerOf(row, col + 1)
            local from, stop = x, x2
            if at(corner, row, col) then
                from = x + chalf - OVER
            elseif at(arrRight, row, col) then
                from = x + half + ARROW_PAD
            end
            if at(corner, row, col + 1) then
                stop = x2 - chalf + OVER
            elseif at(arrLeft, row, col + 1) then
                stop = x2 - half - ARROW_PAD
            end
            if stop > from then seg(from, y - 16, stop - from, 32, T_BR.h[k]) end
        end
    end
    for _, c in ipairs(corners) do
        local x, y = centerOf(c.row, c.col)
        seg(x - chalf, y - chalf, CORNER, CORNER, T_BR[c.kind][c.k])
    end
    for row, cols in pairs(topArr) do
        for col, k in pairs(cols) do
            local x, y = centerOf(row, col)
            arrow(x, y - half - 5, T_AR.down[k])
        end
    end
    for row, cols in pairs(arrLeft) do
        for col, k in pairs(cols) do
            local x, y = centerOf(row, col)
            arrow(x - half - 5, y, T_AR.right[k])
        end
    end
    for row, cols in pairs(arrRight) do
        for col, k in pairs(cols) do
            local x, y = centerOf(row, col)
            arrow(x + half + 5, y, T_AR.left[k])
        end
    end
    for j = nLine + 1, #panel.lines do panel.lines[j]:Hide() end
    for j = nArrow + 1, #panel.arrows do panel.arrows[j]:Hide() end
end
local function showCmps(c, tal, cmps, quiet)
    local rank = tal.rank or 0
    c.tipCmps = {}
    for k, it in ipairs(cmps) do
        local r = (it.ranks[tal.tab] and it.ranks[tal.tab][tal.index]) or 0
        c.tipCmps[k] = { name = it.name, rank = r, color = it.color }
        local fs = c.cmp[k]
        if fs and r ~= rank and not quiet then
            fs:SetText(tostring(r))
            fs:SetTextColor(it.color[1], it.color[2], it.color[3])
            fs:Show()
        end
    end
end
local function showMark(c, shown, target)
    if target == 0 and shown == 0 then return end
    local m = C.marks
    local col = (shown > target and m.over) or (shown == target and m.done) or m.short
    c.mark:SetText(tostring(target))
    c.mark:SetTextColor(col[1], col[2], col[3])
    c.mark:Show()
    c.tipMark = target
end
local function drawCells(panel, p, t, edit, cmps, marks, g, quiet, own)
    local nUsed = 0
    for _, tal in ipairs(t.talents or {}) do
        nUsed = nUsed + 1
        local c = makeTreeCell(p, panel.cells, nUsed, g)
        c.edit = edit
        c.liveGroup = t.live
        c.ownClass = own
        if cmps then showCmps(c, tal, cmps, quiet) end
        if marks then showMark(c, tal.rank or 0, (marks[tal.tab] and marks[tal.tab][tal.index]) or 0) end
        c.icon:SetTexture(tal.tex or QMARK)
        c.talentTab, c.talentIdx = tal.tab, tal.index
        c.tipName = tal.name
        c.tipSpells = tal.spells
        c.tipRank, c.tipMax = tal.rank or 0, tal.max or 0
        local learned = (tal.rank or 0) > 0
        local previewed = tal.live ~= nil and (tal.rank or 0) > tal.live
        local avail = learned
        if edit and edit.gate and not avail then
            local need, pre = edit.gate(tal.tab, tal.index)
            avail = not need and not pre
        end
        if edit and not learned and edit.left and edit.left <= 0 then avail = false end
        if edit then c.icon:SetDesaturated(not avail) else c.icon:SetDesaturated(not learned) end
        if learned then
            c.rank:SetText(tostring(tal.rank))
            local rc = (previewed and C.tree.preview)
                or ((tal.max and tal.rank < tal.max) and C.tree.rank) or C.tree.rankMax
            c.slot:SetVertexColor(rc[1], rc[2], rc[3])
            c.rank:SetTextColor(rc[1], rc[2], rc[3])
            c.rank:Show()
            c.rankBg:Show()
        elseif edit and avail then
            local rc = C.tree.rank
            c.slot:SetVertexColor(rc[1], rc[2], rc[3])
            c.rank:SetText("0")
            c.rank:SetTextColor(rc[1], rc[2], rc[3])
            c.rank:Show()
            c.rankBg:Show()
        end
        c:ClearAllPoints()
        c:SetPoint("TOPLEFT", p, "TOPLEFT",
                   g.x0 + ((tal.col or 1) - 1) * g.colw,
                   -(g.y0 + ((tal.row or 1) - 1) * g.rowh))
    end
    return nUsed
end
local function marksTotal(marks, tab)
    local n = 0
    for _, v in pairs(marks[tab] or {}) do n = n + (v or 0) end
    return n
end
local function render(tp, trees, opts)
    opts = opts or {}
    local edit, class, cmps, only, marks = opts.edit, opts.class, opts.cmps, opts.only, opts.marks
    local g = tp.g
    local list = trees
    if only then list = { trees and trees[only] } end
    local maxRows = 1
    for _, t in pairs(list or {}) do
        if (t.rows or 0) > maxRows then maxRows = t.rows end
    end
    local panelH = g.y0 + maxRows * g.rowh + g.pad
    tp.frame:SetWidth(g.panels * g.panelW + (g.panels - 1) * g.gap)
    tp.frame:SetHeight(panelH)
    for i = 1, g.panels do
        local panel = tp.panels[i]
        local p = panel.bg
        local t = list and list[i]
        local treeIdx = only or i
        p:SetHeight(panelH)
        p:ClearAllPoints()
        p:SetPoint("TOPLEFT", tp.frame, "TOPLEFT", (i - 1) * (g.panelW + g.gap), 0)
        local tint = TREE_TINT[class or ""] and TREE_TINT[class][treeIdx]
        applyPanelSkin(p, tint, t and t.bg, g, opts.border)
        local nUsed = 0
        if t then
            p:Show()
            if marks then
                p.title:SetText(ns.T("tree.title_marks", t.name or "?", t.points or 0, marksTotal(marks, treeIdx)))
            else
                p.title:SetText(format("%s (%d)", t.name or "?", t.points or 0))
            end
            drawLinks(panel, p, t, g)
            nUsed = drawCells(panel, p, t, edit, cmps, marks, g, opts.quiet, (class or ns.PlayerClass()) == ns.PlayerClass())
        else
            p:Hide()
        end
        for j = nUsed + 1, #panel.cells do panel.cells[j]:Hide() end
    end
    if not g.framed then
        tp.badge:Hide()
    elseif edit and edit.left then
        local bd, sh, be = tp.badge, C.shade, C.tree.badgeEdge
        bd:SetBackdropColor(sh[1], sh[2], sh[3], sh[4])
        bd:SetBackdropBorderColor(be[1], be[2], be[3], be[4])
        bd.num:SetText(tostring(edit.left))
        local nc = edit.left > 0 and C.gold or C.text
        bd.num:SetTextColor(nc[1], nc[2], nc[3])
        tp.badge:SetFrameLevel(tp.frame:GetFrameLevel() + 10)
        tp.badge:Show()
    else
        tp.badge:Hide()
    end
    tp.frame:Show()
    return panelH
end
function ns.NewTree(parent, geom)
    local tp = newPane(parent, geom)
    tp.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    tp.Render = render
    trees[tp] = true
    return tp
end
local wide
function ns.TreeRender(parent, trees, opts)
    wide = wide or ns.NewTree(parent, WIDE)
    return wide:Render(trees, opts)
end
