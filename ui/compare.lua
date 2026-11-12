local ADDON, ns = ...
local C = ns.C
local V = ns.View
local HEAD_H = 30
local SCROLL_W = 18
local ROW_H = 18
local COL_W = 54
local ICON = 16
local shown
local function hideTip() GameTooltip:Hide() end
local function rowEnter(self)
    local it = self.it
    if not it or not it.tal then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(it.tal.name or "?", 1, 1, 1)
    for k, col in ipairs(it.cols) do
        local r = it.ranks[k]
        GameTooltip:AddLine(ns.T("tip.cmp_rank", col.name, r, it.tal.max or 0), col.color[1], col.color[2], col.color[3])
    end
    GameTooltip:Show()
    ns.HighlightTalent(it.tal.tab, it.tal.index)
end
local function rowLeave()
    hideTip()
    ns.HighlightTalent(nil)
end
local function rowAt(t, i)
    local r = t.rows[i]
    if r then return r end
    r = CreateFrame("Button", nil, t.child)
    r:SetHeight(ROW_H)
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    r.bg:SetAllPoints(r)
    r.hl = r:CreateTexture(nil, "BORDER")
    r.hl:SetTexture("Interface\\Buttons\\WHITE8X8")
    r.hl:SetAllPoints(r)
    r.hl:SetVertexColor(C.rows.lit[1], C.rows.lit[2], C.rows.lit[3], C.rows.lit[4])
    r.hl:Hide()
    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetWidth(ICON); r.icon:SetHeight(ICON)
    r.icon:SetPoint("LEFT", r, "LEFT", 2, 0)
    r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.name:SetJustifyH("LEFT")
    r.name:SetHeight(ROW_H)
    r.cells = {}
    for k = 1, 3 do
        local fs = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        fs:SetWidth(COL_W)
        fs:SetJustifyH("CENTER")
        r.cells[k] = fs
    end
    r:SetScript("OnEnter", rowEnter)
    r:SetScript("OnLeave", rowLeave)
    t.rows[i] = r
    return r
end
local function placeRow(r, it, y, width, n)
    r.it = it
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", r:GetParent(), "TOPLEFT", 0, -y)
    r:SetWidth(width)
    local head = it.tal == nil
    if head then
        local h = C.rows.head
        r.bg:SetVertexColor(h[1], h[2], h[3], h[4])
        r.icon:Hide()
    else
        local o = C.rows.odd
        r.bg:SetVertexColor(o[1], o[2], o[3], it.odd and o[4] or 0)
        r.icon:SetTexture(it.tal.tex or "Interface\\Icons\\INV_Misc_QuestionMark")
        r.icon:Show()
    end
    r.name:ClearAllPoints()
    r.name:SetPoint("LEFT", r, "LEFT", head and 4 or (ICON + 6), 0)
    r.name:SetWidth(width - n * COL_W - (head and 8 or ICON + 10))
    r.name:SetText(head and (ns.Hex("heading") .. it.title .. "|r") or (it.tal.name or "?"))
    local base = it.ranks[1]
    for k = 1, 3 do
        local fs = r.cells[k]
        if k <= n then
            local v = it.ranks[k]
            fs:ClearAllPoints()
            fs:SetPoint("RIGHT", r, "RIGHT", -(n - k) * COL_W, 0)
            fs:SetText(head and tostring(v) or (v > 0 and tostring(v) or "–"))
            local c = (head or k == 1 or v == base) and C.text or (v > base and C.positive or C.negative)
            if not head and v == 0 then c = C.off end
            fs:SetTextColor(c[1], c[2], c[3])
            fs:Show()
        else
            fs:Hide()
        end
    end
    r.hl:Hide()
    r:Show()
end
local function rankOf(ranks, tal)
    return (ranks[tal.tab] and ranks[tal.tab][tal.index]) or 0
end
local function render(self, cols, class)
    local t = self
    local n = #cols
    local width = t.child:GetWidth()
    for k = 1, 3 do
        local h = t.heads[k]
        if k <= n then
            local c = cols[k]
            h:ClearAllPoints()
            h:SetPoint("BOTTOMRIGHT", t.frame, "TOPLEFT", width - (n - k) * COL_W, -(HEAD_H - 6))
            h:SetText(ns.CMP_LETTERS[k])
            h:SetTextColor(c.color[1], c.color[2], c.color[3])
            h:Show()
        else
            h:Hide()
        end
    end
    local all = HTP_TalentsDB.cmpAll == true
    local function setAll(on)
        HTP_TalentsDB.cmpAll = on or nil
        if ns.RefreshWindow then ns.RefreshWindow() end
    end
    t.mode:Set({
        { label = ns.T("window.cmp_diff"), tip = ns.T("tip.cmp_diff"), active = not all,
          onClick = function() setAll(false) end },
        { label = ns.T("window.cmp_all"), tip = ns.T("tip.cmp_all"), active = all,
          onClick = function() setAll(true) end },
    }, C.mode.compare)
    local grid = V.RanksGrid(cols[1].ranks)
    local y, ri, odd = 0, 0, false
    for _, tree in ipairs(grid or {}) do
        local list, sums = {}, { 0, 0, 0 }
        local tals = {}
        for _, tal in ipairs(tree.talents or {}) do tals[#tals + 1] = tal end
        table.sort(tals, function(a, b)
            if (a.row or 0) ~= (b.row or 0) then return (a.row or 0) < (b.row or 0) end
            return (a.col or 0) < (b.col or 0)
        end)
        for _, tal in ipairs(tals) do
            local ranks, differ, any = {}, false, false
            for k, c in ipairs(cols) do
                ranks[k] = rankOf(c.ranks, tal)
                sums[k] = sums[k] + ranks[k]
                if ranks[k] ~= ranks[1] then differ = true end
                if ranks[k] > 0 then any = true end
            end
            if differ or (all and any) then list[#list + 1] = { tal = tal, ranks = ranks, cols = cols } end
        end
        ri = ri + 1
        placeRow(rowAt(t, ri), { title = tree.name or "?", ranks = sums, cols = cols }, y, width, n)
        y = y + ROW_H + 2
        for _, it in ipairs(list) do
            odd = not odd
            it.odd = odd
            ri = ri + 1
            placeRow(rowAt(t, ri), it, y, width, n)
            y = y + ROW_H
        end
        if #list == 0 then
            ri = ri + 1
            placeRow(rowAt(t, ri), { title = ns.Hex("off") .. ns.T("window.cmp_same") .. "|r", ranks = {}, cols = {} },
                     y, width, 0)
            y = y + ROW_H
        end
        y = y + 6
    end
    for i = ri + 1, #t.rows do t.rows[i]:Hide() end
    t.child:SetHeight(math.max(y, 1))
    t.scroll:Sync(y)
    t.frame:Show()
    shown = t
end
function ns.OnTalentHighlight(tab, index)
    if not (shown and shown.frame:IsShown()) then return end
    for _, r in ipairs(shown.rows) do
        local tal = r.it and r.it.tal
        if tab and tal and tal.tab == tab and tal.index == index then r.hl:Show() else r.hl:Hide() end
    end
end
function ns.NewCompareTable(parent, width, height)
    local t = { rows = {}, heads = {}, Render = render }
    local f = CreateFrame("Frame", nil, parent)
    f:SetWidth(width); f:SetHeight(height)
    t.frame = f
    t.mode = ns.Kit.Segment(f)
    t.mode:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    for k = 1, 3 do
        local h = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        h:SetWidth(COL_W)
        h:SetJustifyH("CENTER")
        t.heads[k] = h
    end
    t.scroll = ns.Kit.Scroll(f)
    t.scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -HEAD_H)
    t.scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -SCROLL_W, 0)
    t.child = t.scroll.child
    t.child:SetWidth(width - SCROLL_W)
    f:Hide()
    return t
end
