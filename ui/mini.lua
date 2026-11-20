local ADDON, ns = ...
local C = ns.C
local NATIVE_W, NATIVE_H = 384, 512
local TREE_X, TREE_TOP, TREE_W = 23, 77, 296
local RIGHT_W = NATIVE_W - TREE_X - TREE_W
local GLYPH_PAGE_W = 352
local POINTS_BOTTOM, POINTS_H = 81, 26
local PREVIEW_H = 26 + 4
local GAP = 10
local COL_STEP = TREE_W + GAP
local ART_L, ART_R = 258, 126
local ART_BAND = 256
local SLICE_U0, SLICE_W = 176 / 256, 80
local TOP_ART = "Interface\\PaperDollInfoFrame\\UI-Character-General-TopLeft"
local BOTTOM_ART = "Interface\\PaperDollInfoFrame\\UI-Character-General-BottomLeft"
local STRIP_W, STRIP_Y, STRIP_H = 264, -46, 20
local INPUT_BORDER = "Interface\\Common\\Common-Input-Border"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local SPREAD_X, SPREAD_Y = -92, -25
local BAR_X, BAR_TOP, BAR_BOTTOM = 6, -16, 16
local TROUGH_X, TROUGH_TOP, TROUGH_BOTTOM = -2, 5, -2
local SPEC_TAB_OVERHANG = 32
local MAX_COLS = 3
local GRIP = 16
local GRIP_X, GRIP_Y = -36, 78
local TICK = 0.2
local GLYPHS = "glyphs"
local ext
local top
local spreadText
local grip
local cols = {}
local glyphCol
local driver
local lastSig
local nat = {}
local saved = {}
local nativeW = NATIVE_W
local extended = false
local slices = { top = {}, bottom = {} }
local function remember(r)
    local pts = {}
    for i = 1, r:GetNumPoints() or 0 do pts[i] = { r:GetPoint(i) } end
    saved[r] = pts
end
local function restore(r)
    r:ClearAllPoints()
    for _, p in ipairs(saved[r] or {}) do r:SetPoint(unpack(p)) end
end
local function shown()
    return PlayerTalentFrame ~= nil and PlayerTalentFrame:IsShown() and not ns.NativeMode()
end
local function nativeState()
    local f = PlayerTalentFrame
    return f.talentGroup or GetActiveTalentGroup() or 1, PanelTemplates_GetSelectedTab(f) or 1, f.pet and true or false
end
local function dominantTab(grid)
    local best, bestPts = 1, -1
    for i, t in ipairs(grid) do
        if (t.points or 0) > bestPts then best, bestPts = i, t.points or 0 end
    end
    return best
end
local function columnSeq(tab, grid)
    local seq = {}
    local first = tab ~= GLYPH_TALENT_TAB and tab or nil
    local start = first or dominantTab(grid)
    for k = 0, 2 do
        local t = (start - 1 + k) % 3 + 1
        if t ~= first and grid[t] then seq[#seq + 1] = t end
    end
    if first then seq[#seq + 1] = GLYPHS end
    return seq
end
local function currentSeq()
    local group, tab, pet = nativeState()
    local grid = not pet and ns.ReadTalentGrid(group) or nil
    return grid and columnSeq(tab, grid) or {}, grid, group, tab == GLYPH_TALENT_TAB
end
local function baseRight(glyphTab)
    return glyphTab and GLYPH_PAGE_W or TREE_X + TREE_W
end
local function widthFor(base, n)
    return base + n * COL_STEP + RIGHT_W
end
local function maxFit(base)
    local f = PlayerTalentFrame
    local room = (UIParent:GetWidth() or 0) - (f:GetLeft() or 0) - SPEC_TAB_OVERHANG
    local n = 0
    while n < MAX_COLS and widthFor(base, n + 1) <= room do n = n + 1 end
    return n
end
local function coords(t, c)
    t:SetTexCoord(c[1], c[2], c[3], c[4])
end
local function makeHead(parent, plain)
    local f = CreateFrame("Frame", nil, parent)
    f:SetWidth(STRIP_W); f:SetHeight(STRIP_H)
    f:SetPoint("TOP", parent, "TOP", 0, TREE_TOP + STRIP_Y)
    local l = f:CreateTexture(nil, "ARTWORK")
    l:SetTexture(INPUT_BORDER)
    l:SetWidth(8)
    l:SetPoint("TOPLEFT"); l:SetPoint("BOTTOMLEFT")
    coords(l, { 0, 0.0625, 0, 0.625 })
    local r = f:CreateTexture(nil, "ARTWORK")
    r:SetTexture(INPUT_BORDER)
    r:SetWidth(8)
    r:SetPoint("TOPRIGHT"); r:SetPoint("BOTTOMRIGHT")
    coords(r, { 0.9375, 1, 0, 0.625 })
    local m = f:CreateTexture(nil, "ARTWORK")
    m:SetTexture(INPUT_BORDER)
    m:SetPoint("TOPLEFT", l, "TOPRIGHT"); m:SetPoint("BOTTOMRIGHT", r, "BOTTOMLEFT")
    coords(m, { 0.0625, 0.9375, 0, 0.625 })
    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.text:SetPoint("CENTER", f, "CENTER", plain and 0 or 9, 0)
    if not plain then
        f.icon = f:CreateTexture(nil, "OVERLAY")
        f.icon:SetWidth(16); f.icon:SetHeight(16)
        f.icon:SetPoint("RIGHT", f.text, "LEFT", -4, 0)
    end
    return f
end
local function makeColFrame(plainHead)
    local f = PlayerTalentFrame
    local fr = CreateFrame("Frame", nil, f)
    fr:SetWidth(TREE_W); fr:SetHeight(TREE_W)
    fr:SetFrameLevel(f:GetFrameLevel() + 2)
    local dark = fr:CreateTexture(nil, "BORDER")
    dark:SetTexture(WHITE)
    dark:SetWidth(1)
    dark:SetPoint("TOPLEFT", fr, "TOPLEFT", -GAP / 2 - 1, 0)
    dark:SetPoint("BOTTOMLEFT", fr, "BOTTOMLEFT", -GAP / 2 - 1, 0)
    local nd = C.native.sepDark
    dark:SetVertexColor(nd[1], nd[2], nd[3], nd[4])
    local light = fr:CreateTexture(nil, "BORDER")
    light:SetTexture(WHITE)
    light:SetWidth(1)
    light:SetPoint("TOPLEFT", fr, "TOPLEFT", -GAP / 2, 0)
    light:SetPoint("BOTTOMLEFT", fr, "BOTTOMLEFT", -GAP / 2, 0)
    local nl = C.native.sepLight
    light:SetVertexColor(nl[1], nl[2], nl[3], nl[4])
    fr:Hide()
    return fr, makeHead(fr, plainHead)
end
local function wheel(_, delta)
    if ScrollFrameTemplate_OnMouseWheel then ScrollFrameTemplate_OnMouseWheel(nat.scroll, delta) end
end
local function treeColAt(i)
    if cols[i] then return cols[i] end
    local c = { quads = {} }
    local fr, head = makeColFrame()
    c.frame, c.head = fr, head
    local function quad(key, w, h)
        local t = fr:CreateTexture(nil, "BACKGROUND")
        t:SetWidth(w); t:SetHeight(h)
        c.quads[key] = t
        return t
    end
    local tl = quad("TopLeft", 256, 256)
    tl:SetPoint("TOPLEFT", fr, "TOPLEFT", 0, 0)
    tl:SetPoint("RIGHT", fr, "RIGHT", -40, 0)
    tl:SetPoint("BOTTOM", fr, "BOTTOM", 0, 76)
    local tr = quad("TopRight", 44, 256)
    tr:SetPoint("TOPRIGHT", fr, "TOPRIGHT", 0, 0)
    tr:SetPoint("BOTTOMLEFT", tl, "BOTTOMRIGHT", 0, 0)
    coords(tr, { 0, 0.6875, 0, 1 })
    local bl = quad("BottomLeft", 256, 75)
    bl:SetPoint("BOTTOMLEFT", fr, "BOTTOMLEFT", 0, 0)
    bl:SetPoint("TOPRIGHT", tl, "BOTTOMRIGHT", 0, 0)
    coords(bl, { 0, 1, 0, 0.5859375 })
    local br = quad("BottomRight", 44, 75)
    br:SetPoint("BOTTOMRIGHT", fr, "BOTTOMRIGHT", 0, 0)
    br:SetPoint("TOPLEFT", tl, "BOTTOMRIGHT", 0, 0)
    coords(br, { 0, 0.6875, 0, 0.5859375 })
    c.scroll = CreateFrame("ScrollFrame", nil, fr)
    c.scroll:SetAllPoints(fr)
    c.scroll:EnableMouseWheel(true)
    c.scroll:SetScript("OnMouseWheel", wheel)
    c.child = CreateFrame("Frame", nil, c.scroll)
    c.child:SetWidth(ns.TREE_GEOM.native.panelW); c.child:SetHeight(50)
    c.scroll:SetScrollChild(c.child)
    c.tree = ns.NewTree(c.child, ns.TREE_GEOM.native)
    c.pts = fr:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    c.pts:SetPoint("LEFT", fr, "BOTTOMLEFT", 5, -POINTS_H / 2 + 1)
    c.pts:SetJustifyH("LEFT")
    cols[i] = c
    return c
end
local function glyphColAt()
    if glyphCol then return glyphCol end
    local fr, head = makeColFrame(true)
    head.text:SetText(_G.GLYPHS)
    glyphCol = { frame = fr, head = head, page = ns.NewGlyphColumn(fr) }
    return glyphCol
end
local function paintTreeCol(c, t, group)
    local base = "Interface\\TalentFrame\\" .. (t.bg or "MageFire") .. "-"
    local desat = not ns.IsActiveGroup(group)
    for key, tex in pairs(c.quads) do
        tex:SetTexture(base .. key)
        SetDesaturation(tex, desat)
    end
    c.head.text:SetText(t.name or "?")
    c.head.icon:SetTexture(t.icon)
    c.head.icon:SetDesaturated(desat)
    c.pts:SetFormattedText(MASTERY_POINTS_SPENT, t.name or "?",
        HIGHLIGHT_FONT_COLOR_CODE .. (t.points or 0) .. FONT_COLOR_CODE_CLOSE)
end
local function spread(grid)
    local pts = {}
    for i, t in ipairs(grid) do pts[i] = t.points or 0 end
    return (grid[dominantTab(grid)].name or "") .. "  " .. table.concat(pts, " / ")
end
local function fill(gapW)
    local n = math.ceil(gapW / SLICE_W)
    for k = 1, n do
        local w = math.min(SLICE_W, gapW - (k - 1) * SLICE_W)
        for band, list in pairs(slices) do
            local t = list[k]
            if not t then
                t = ext:CreateTexture(nil, "BACKGROUND")
                t:SetTexture(band == "top" and TOP_ART or BOTTOM_ART)
                t:SetHeight(ART_BAND)
                list[k] = t
            end
            t:SetWidth(w)
            t:SetTexCoord(SLICE_U0, SLICE_U0 + w / 256, 0, 1)
            t:ClearAllPoints()
            t:SetPoint("TOPLEFT", ext, "TOPLEFT", ART_L + (k - 1) * SLICE_W, band == "top" and -1 or -1 - ART_BAND)
            t:Show()
        end
    end
    for k = n + 1, #slices.top do
        slices.top[k]:Hide()
        slices.bottom[k]:Hide()
    end
end
local function extend(width, last, glyphTab)
    local f = PlayerTalentFrame
    f:SetWidth(width)
    nat.scroll:ClearAllPoints()
    nat.scroll:SetPoint("TOPLEFT", f, "TOPLEFT", TREE_X, -TREE_TOP)
    nat.scroll:SetPoint("BOTTOM", nat.points, "TOP", 0, 0)
    nat.bar:ClearAllPoints()
    nat.bar:SetPoint("TOPLEFT", last, "TOPRIGHT", BAR_X, BAR_TOP)
    nat.bar:SetPoint("BOTTOMLEFT", last, "BOTTOMRIGHT", BAR_X, BAR_BOTTOM)
    nat.troughTop:ClearAllPoints()
    nat.troughTop:SetPoint("TOPLEFT", last, "TOPRIGHT", TROUGH_X, TROUGH_TOP)
    nat.troughBottom:ClearAllPoints()
    nat.troughBottom:SetPoint("BOTTOMLEFT", last, "BOTTOMRIGHT", TROUGH_X, TROUGH_BOTTOM)
    if glyphTab then nat.title:Hide() else nat.title:Show() end
    local g = _G.GlyphFrame
    if g and g:GetParent() == f then
        g:ClearAllPoints()
        g:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
        g:SetWidth(nativeW); g:SetHeight(f:GetHeight())
    end
    extended = true
    ext:Show()
    top:Show()
end
local function collapse()
    for _, c in ipairs(cols) do c.frame:Hide() end
    if glyphCol then glyphCol.frame:Hide() end
    if not extended then return end
    extended = false
    PlayerTalentFrame:SetWidth(nativeW)
    restore(nat.scroll)
    restore(nat.bar)
    restore(nat.troughTop)
    restore(nat.troughBottom)
    nat.title:Show()
    local g = _G.GlyphFrame
    if g and g:GetParent() == PlayerTalentFrame then
        g:ClearAllPoints()
        g:SetAllPoints(PlayerTalentFrame)
    end
    ext:Hide()
    top:Hide()
end
local function areaHeight()
    local h = NATIVE_H - TREE_TOP - POINTS_BOTTOM - POINTS_H
    if nat.preview and nat.preview:IsShown() then h = h - PREVIEW_H end
    return h
end
local function render()
    if not ext then return end
    if not shown() then
        collapse()
        return
    end
    local f = PlayerTalentFrame
    local seq, grid, group, glyphTab = currentSeq()
    local base = baseRight(glyphTab)
    local n = math.min(HTP_TalentsDB.miniCols or 0, #seq, maxFit(base))
    grip:ClearAllPoints()
    grip:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", GRIP_X, GRIP_Y)
    if n == 0 then
        collapse()
        return
    end
    local edit = ns.LiveEdit(grid, group)
    if edit and ns.CirclePending() then edit.locked = true end
    local strips = not (nat.activate and nat.activate:IsShown())
    local offset = nat.scroll:GetVerticalScroll() or 0
    local used, last, glyphs = 0, nil, false
    for i = 1, n do
        local what = seq[i]
        local c
        if what == GLYPHS then
            glyphs = true
            c = glyphColAt()
            c.page:Render(group, TREE_W, areaHeight())
        else
            used = used + 1
            c = treeColAt(used)
            paintTreeCol(c, grid[what], group)
            local h = c.tree:Render(grid, { edit = edit, class = ns.PlayerClass(), only = what })
            c.child:SetHeight(h)
            c.scroll:SetVerticalScroll(offset)
        end
        c.frame:ClearAllPoints()
        c.frame:SetPoint("TOPLEFT", f, "TOPLEFT", base + GAP + (i - 1) * COL_STEP, -TREE_TOP)
        c.frame:SetPoint("BOTTOM", nat.points, "TOP", 0, 0)
        c.frame:Show()
        if strips then c.head:Show() else c.head:Hide() end
        last = c.frame
    end
    for i = used + 1, #cols do cols[i].frame:Hide() end
    if glyphCol and not glyphs then glyphCol.frame:Hide() end
    local width = widthFor(base, n)
    extend(width, last, glyphTab)
    fill(width - ART_R - ART_L)
    spreadText:SetText(spread(grid))
end
ns.MiniRefresh = render
function ns.MiniGlyphsShown()
    return glyphCol ~= nil and glyphCol.frame:IsVisible() and true or false
end
local function gripDrag()
    if not grip.held then
        driver:Hide()
        return
    end
    local f = PlayerTalentFrame
    local cx = GetCursorPosition() / f:GetEffectiveScale()
    local seq, _, _, glyphTab = currentSeq()
    local edge = (f:GetLeft() or 0) + baseRight(glyphTab) + GAP
    local want = 0
    for i in ipairs(seq) do
        if cx < edge + TREE_W / 2 then break end
        want, edge = i, edge + COL_STEP
    end
    if want ~= (HTP_TalentsDB.miniCols or 0) then
        HTP_TalentsDB.miniCols = want > 0 and want or nil
        render()
    end
end
local function poll(self, elapsed)
    self.acc = (self.acc or 0) + elapsed
    if self.acc < TICK then return end
    self.acc = 0
    local group, tab, pet = nativeState()
    local sig = group .. ":" .. tab .. ":" .. tostring(pet) .. ":" .. (HTP_TalentsDB.miniCols or 0)
        .. ":" .. tostring(nat.activate and nat.activate:IsShown()) .. ":" .. tostring(nat.preview and nat.preview:IsShown())
    local g = _G.GlyphFrame
    if sig ~= lastSig or (extended and g and g:GetParent() == PlayerTalentFrame and g:GetWidth() ~= nativeW) then
        lastSig = sig
        render()
    end
end
local function onNativeScroll(_, offset)
    for _, c in ipairs(cols) do
        if c.frame:IsShown() then c.scroll:SetVerticalScroll(offset) end
    end
end
local function attach()
    if ext or not PlayerTalentFrame then return end
    local f = PlayerTalentFrame
    nat.scroll, nat.bar = PlayerTalentFrameScrollFrame, PlayerTalentFrameScrollFrameScrollBar
    nat.troughTop, nat.troughBottom = PlayerTalentFrameScrollFrameBackgroundTop, PlayerTalentFrameScrollFrameBackgroundBottom
    nat.points, nat.title = PlayerTalentFramePointsBar, PlayerTalentFrameTitleText
    nat.activate, nat.preview = PlayerTalentFrameActivateButton, PlayerTalentFramePreviewBar
    if not (nat.scroll and nat.bar and nat.troughTop and nat.troughBottom and nat.points and nat.title) then return end
    nativeW = f:GetWidth() or NATIVE_W
    remember(nat.scroll)
    remember(nat.bar)
    remember(nat.troughTop)
    remember(nat.troughBottom)
    nat.scroll:HookScript("OnVerticalScroll", onNativeScroll)
    ext = CreateFrame("Frame", nil, f)
    ext:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    ext:SetWidth(1); ext:SetHeight(1)
    ext:SetFrameLevel(math.max(0, f:GetFrameLevel() - 1))
    ext:Hide()
    top = CreateFrame("Frame", nil, f)
    top:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    top:SetWidth(1); top:SetHeight(1)
    top:SetFrameLevel(f:GetFrameLevel() + 2)
    top:Hide()
    spreadText = top:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    spreadText:SetPoint("RIGHT", f, "TOPRIGHT", SPREAD_X, SPREAD_Y)
    grip = ns.Kit.Grip(f, GRIP)
    local function label() grip.tipTitle, grip.tipBody = ns.T("act.mini_cols"), ns.T("tip.mini_cols") end
    label()
    ns.OnLocale(label)
    grip:SetFrameLevel(f:GetFrameLevel() + 20)
    driver = CreateFrame("Frame", nil, f)
    driver:Hide()
    driver:SetScript("OnUpdate", gripDrag)
    grip.onDown = function(_, button)
        if button == "LeftButton" then driver:Show() end
    end
    grip.onUp = function() driver:Hide() end
    local watch = CreateFrame("Frame", nil, f)
    watch:SetScript("OnUpdate", poll)
    watch:SetScript("OnShow", function()
        lastSig = nil
        if ns.NativeMode() then grip:Hide() else grip:Show() end
    end)
    watch:SetScript("OnHide", collapse)
end
local REFRESH_ON = {
    "PLAYER_TALENT_UPDATE", "CHARACTER_POINTS_CHANGED", "PREVIEW_TALENT_POINTS_CHANGED",
    "ACTIVE_TALENT_GROUP_CHANGED", "GLYPH_ADDED", "GLYPH_REMOVED", "GLYPH_UPDATED", "PLAYER_LEVEL_UP",
}
local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:RegisterEvent("PLAYER_LOGIN")
for _, ev in ipairs(REFRESH_ON) do boot:RegisterEvent(ev) end
boot:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name == "Blizzard_TalentUI" then attach()
        elseif name == "Blizzard_GlyphUI" then render() end
    elseif event == "PLAYER_LOGIN" then
        if IsAddOnLoaded("Blizzard_TalentUI") then attach() end
    else
        render()
    end
end)
