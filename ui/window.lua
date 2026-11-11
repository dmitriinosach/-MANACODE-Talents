local ADDON, ns = ...
local C = ns.C
local PAD = 18
local TITLE_Y = 12
local TITLE_H = 28
local TABS_Y = 48
local TAB_H = ns.Kit.H.ctrl
local BASE_Y = TABS_Y + TAB_H
local CTX_Y = BASE_Y + 8
local CTX_H = ns.Kit.H.ctrl
local TREE_Y = CTX_Y + CTX_H + 8
local CANVAS_H = 474
local WIN_BOTTOM = 12
local WIN_H = TREE_Y + CANVAS_H + WIN_BOTTOM
local TITLE_MID = -(TITLE_Y + TITLE_H / 2)
local CTX_MID = -(CTX_Y + CTX_H / 2)
local LIST_W = 300
local LIB_PAD = 14
local LIB_W = LIB_PAD + LIST_W + LIB_PAD
local LIB_SCROLL = 20
local LIB_SEC_H = 26
local LIB_SEC_GAP = 10
local LIB_ROW_H = 28
local LIB_OPEN_H = 30
local LIB_ICON = 22
local LIB_SAME = 12
local LIB_BAR = 2
local LIB_TEXT_X = 6 + LIB_ICON + 6
local GAP = 16
local CREST = 28
local ARROW = 12
local ORB = 20
local ORB_GAP = 3
local SEP_H = 18
local TITLE_GAP = 12
local CHIP_MIN = 60
local TAB_GAP = 4
local ACT_ORB = 20
local ACT_PILL_H = ns.Kit.H.ctrl
local BTN_GAP = 6
local WORD_GAP = 12
local SLOT_MAX = 170
local SLOT_MIN = 60
local ACT_SIZE = 18
local PICK_MAX = 220
local MIN_SCALE = 0.7
local SCALE_MIN, SCALE_MAX, SCALE_STEP = 0.7, 1.3, 0.05
local VIEW_ORB = 18
local VIEW_GAP = 3
local VIEW_W = 3 * (VIEW_ORB + VIEW_GAP)
local SCREEN_MARGIN = 16
local NORMAL_W = PAD + ns.TREE_WIDTH + PAD
local PALETTE_ORB = 24
local GRIP = 14
local PALETTE_COLS = 5
local MENU_ROW_H = 22
local CLASS_ORDER = {
    "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST",
    "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "DRUID",
}
local CLASS_TEX = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
local CLASS_CIRCLES = "Interface\\TargetingFrame\\UI-Classes-Circles"
local MARK_SELECTED = "Interface\\RaidFrame\\ReadyCheck-Ready"
local ICON_CROP = { 0.07, 0.93, 0.07, 0.93 }
local WHITE = "Interface\\Buttons\\WHITE8X8"
local TARGET_ICON = "Interface\\Icons\\INV_Misc_Spyglass_02"
local V = ns.View
local win
local ui = { rows = {}, secs = {}, notes = {}, actOrbs = {}, slots = {}, slotPts = {} }
local create
local playerClass = ns.PlayerClass
local isOwn = V.Own
local viewGroup = V.Group
local function onGlyphs()
    return V.OnGlyphs()
end
local function pointsStr(ranks)
    local p = { 0, 0, 0 }
    for tab = 1, 3 do
        for _, v in pairs((ranks and ranks[tab]) or {}) do p[tab] = p[tab] + (v or 0) end
    end
    return ns.T("panel.points", p[1], p[2], p[3])
end
local function treeIcon(class, tab)
    local g = ns.talentgrids and ns.talentgrids[class]
    return g and g[tab or 1] and g[tab or 1].icon
end
local function report(ok, msg)
    if msg and not ok then ns.warn(msg) end
end
local function miniMode()
    return HTP_TalentsDB.mode ~= "wide"
end
local function hideNative()
    if PlayerTalentFrame and PlayerTalentFrame:IsShown() then HideUIPanel(PlayerTalentFrame) end
end
function ns.RefreshWindow()
    if win and win:IsShown() then ui.render() end
    if ns.MiniRefresh then ns.MiniRefresh() end
end
local function applySub(id)
    V.SetPane(id == "glyphs" and "glyphs" or "tree")
end
local function openBuilder(ranks)
    V.OpenBuilder(ranks)
    ns.RefreshWindow()
end
local function toggleCompare(ranks, name)
    V.ToggleCompare(ranks, name)
    ns.RefreshWindow()
end
local myRanks = V.MyRanks
function ns.ShowInspected(data)
    if not data or not ns.specs[data.class] then return end
    hideNative()
    if not win then create() end
    V.ShowInspect(data)
    if win:IsShown() then ns.RefreshWindow() else win:Show() end
end
function ns.ShowClass(class, sub)
    if not ns.specs[class] then return end
    hideNative()
    if not win then create() end
    V.SetClass(class)
    if sub then applySub(sub) end
    if win:IsShown() then ns.RefreshWindow() else win:Show() end
end
local function pick(ranks, name)
    V.Pick(ranks, name, true)
    V.SetPane("tree")
    ns.RefreshWindow()
end
local function rowMenu(ranks, spec, name, mine, alt, std)
    local items = {}
    if isOwn() and ns.IsActiveGroup(viewGroup()) then
        items[#items + 1] = { label = ns.T("act.learn"), tip = ns.T("tip.learn"), off = ns.LearnBlock(),
                              onClick = function()
                                  V.Pick(ranks, name)
                                  ns.LearnBuild(ranks)
                                  ns.RefreshWindow()
                              end }
    end
    local st = ns.ShareTargetState(true)
    items[#items + 1] = { label = ns.T(st.name and "act.share_target" or "act.share"), tip = st.tip or ns.T("tip.share"),
                          off = st.off,
                          onClick = function() report(ns.ShareBuild(ranks, spec, name, V.class)) end }
    if mine then
        items[#items + 1] = { label = ns.T("act.rename"), tip = ns.T("tip.rename"), sep = true,
                              onClick = function()
                                  ns.Popup("HTP_TALENTS_RENAME", nil, nil,
                                           { class = mine.class, index = mine.index, name = mine.name })
                              end }
        items[#items + 1] = { label = ns.T("act.delete"), tip = ns.T("tip.delete"),
                              onClick = function()
                                  ns.Popup("HTP_TALENTS_DELETE", nil, nil, { class = mine.class, index = mine.index })
                              end }
    end
    if std then
        items[#items + 1] = { label = ns.T("act.rename"), tip = ns.T("tip.rename_std"), sep = true,
                              onClick = function()
                                  ns.Popup("HTP_TALENTS_RENAME", nil, nil, { name = std.name,
                                      apply = function(text) return ns.RenameStandardBuild(std.class, std.key, text) end })
                              end }
        if std.renamed then
            items[#items + 1] = { label = ns.T("act.rename_reset"), tip = ns.T("tip.rename_reset"),
                                  onClick = function()
                                      ns.RenameStandardBuild(std.class, std.key, nil)
                                      ns.RefreshWindow()
                                  end }
        end
    end
    if isOwn() and ns.BuildGear then
        local bound = ns.BuildGear(ranks)
        items[#items + 1] = { label = ns.T(bound and "act.gear_bound" or "act.gear", bound),
                              tip = ns.T("tip.gear"), sep = true,
                              off = #ns.GearSets() == 0 and ns.T("tip.gear_none") or nil,
                              onClick = function() ns.ShowGearMenu(ranks) end }
    end
    if alt then
        local class = V.class
        local full = #ns.CustomBuilds(class) >= ns.MAX_CUSTOM_BUILDS
        items[#items + 1] = { label = ns.T("act.save_mine"), tip = ns.T("tip.save_alt"), sep = true,
                              off = full and ns.T("msg.slots_full", ns.MAX_CUSTOM_BUILDS) or nil,
                              onClick = function()
                                  report(ns.SaveBuilderBuild(ranks, name, class))
                                  ns.RefreshWindow()
                              end }
        items[#items + 1] = { label = ns.T("act.alt_forget"), tip = ns.T("tip.alt_forget", alt.name),
                              onClick = function()
                                  if V.pick and V.pick.ranks == ranks then V.Pick(ranks, name, true) end
                                  local i = V.CompareFind(ranks, name)
                                  if i then V.CompareRemove(i) end
                                  ns.AltForget(alt.key)
                                  ns.RefreshWindow()
                              end }
    end
    return items
end
local function buildRow(ranks, liveSig, name, icon, spec, mine, alt, std)
    local cmp = V.Source() == "compare"
    local slot = V.CompareFind(ranks, name)
    local open = not cmp and V.Mode() == "pick" and V.pick.ranks == ranks
    local hints = {}
    if cmp then
        hints[1] = ns.Hint(slot and "cmp_remove_any" or "cmp_add")
    else
        hints[1] = ns.Hint(open and "pick_drop" or "row_pick")
        if slot then hints[2] = ns.Hint("cmp_remove") end
    end
    return {
        text = name, ranks = ranks, icon = icon, open = open, slot = slot,
        same = liveSig ~= nil and ns.RanksSig(ranks) == liveSig,
        gear = isOwn() and ns.BuildGear and ns.BuildGear(ranks) or nil,
        hints = hints,
        more = function() return rowMenu(ranks, spec, name, mine, alt, std) end,
        onClick = function(button)
            if button == "RightButton" then
                local i = V.CompareFind(ranks, name)
                if not i then return end
                V.CompareRemove(i)
                ns.RefreshWindow()
            elseif cmp then
                toggleCompare(ranks, name)
            else
                pick(ranks, name)
            end
        end,
    }
end
local function buildMine(secs, liveSig)
    local class = V.class
    local mine = ns.CustomBuilds(class)
    local sec = { title = ns.T("sub.mine"), count = ns.T("lib.count", #mine, ns.MAX_CUSTOM_BUILDS), rows = {} }
    if #mine == 0 then
        sec.note = isOwn() and ns.T("window.mine_empty_own") or ns.T("window.mine_empty_foreign")
    end
    for i, b in ipairs(mine) do
        local shown = ns.BuildDisplayName(b, i)
        sec.rows[#sec.rows + 1] = buildRow(b.ranks, liveSig, shown, treeIcon(class, b.spec), b.spec,
                                           { class = class, index = i, name = b.name })
    end
    secs[#secs + 1] = sec
end
local function buildAlts(secs, liveSig)
    local class = V.class
    if not ns.AltSets then return end
    local list = ns.AltSets(class)
    if #list == 0 then return end
    local sec = { title = ns.T("lib.alts"), rows = {} }
    for _, a in ipairs(list) do
        local label = ns.T(a.active and "lib.alt_row_active" or "lib.alt_row", a.name, a.n)
        sec.rows[#sec.rows + 1] = buildRow(a.ranks, liveSig, label, treeIcon(class, a.spec), a.spec, nil, a)
    end
    secs[#secs + 1] = sec
end
local function buildStandard(secs, liveSig)
    local class = V.class
    local sec = { title = ns.T("panel.standard"), rows = {} }
    local recs = ns.BuildsForClass(class)
    if #recs == 0 then sec.note = ns.T("panel.standard_empty") end
    for i, rec in ipairs(recs) do
        local name = (rec.name and rec.name ~= "") and rec.name or ns.T("msg.default_name", i)
        local label = ns.T("panel.spec_named", ns.SpecName(class, rec.variant), name)
        sec.rows[#sec.rows + 1] = buildRow(rec.ranks, liveSig, label, ns.SpecIcon(class, rec.variant), nil, nil, nil,
                                           { class = class, key = rec.key, renamed = rec.renamed, name = rec.name })
    end
    secs[#secs + 1] = sec
end
local CMP_VIEWS = { "side", "marks", "table" }
local function cmpView()
    local v = HTP_TalentsDB.cmpView
    return (v == "table" or v == "marks") and v or "side"
end
local function hideTip() GameTooltip:Hide() end
local function capPill(b, maxW)
    if b:GetWidth() <= maxW then return end
    b.text:SetWidth(math.max(10, b.text:GetStringWidth() - (b:GetWidth() - maxW)))
    b.text:SetHeight(12)
    b:SetWidth(maxW)
end
local SWATCH = 8
local SWATCH_H = 12
local SWATCHES = { "background", "control.bg", "main.bg", "heading" }
local SWATCH_W = #SWATCHES * SWATCH + 6
local MENU_SEP = 7
local MENU_CHECK = 24
local MENU_PAD = 6
local function presetColor(preset, path)
    local node = preset
    for part in path:gmatch("[^%.]+") do
        if type(node) ~= "table" then return nil end
        node = node[part]
    end
    return type(node) == "table" and node or nil
end
local function menuRowEnter(self)
    local it = self.item
    if not (it.head or it.off) then ns.Kit.PaintRound(self, C.hover) end
    if it.tip or it.off then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(it.label, 1, 1, 1, true)
        if it.tip then GameTooltip:AddLine(it.tip, nil, nil, nil, true) end
        if it.off then
            local a = C.alert
            GameTooltip:AddLine(it.off, a[1], a[2], a[3], true)
        end
        GameTooltip:Show()
    end
end
local function menuRowLeave(self)
    ns.Kit.PaintRound(self, C.none)
    GameTooltip:Hide()
end
local function menuRowClick(self)
    local it = self.item
    if it.head or it.off or not it.onClick then return end
    ns.Kit.FlyHide()
    GameTooltip:Hide()
    it.onClick()
end
local function menuRowAt(f, i)
    local b = f.rows[i]
    if b then return b end
    b = CreateFrame("Button", nil, f)
    b:SetHeight(MENU_ROW_H)
    b:SetBackdrop(ns.Kit.ROUND)
    b.sep = b:CreateTexture(nil, "ARTWORK")
    b.sep:SetTexture(WHITE)
    b.sep:SetHeight(1)
    b.sep:SetPoint("BOTTOMLEFT", b, "TOPLEFT", 0, math.floor(MENU_SEP / 2))
    b.sep:SetPoint("BOTTOMRIGHT", b, "TOPRIGHT", 0, math.floor(MENU_SEP / 2))
    b.swatches = {}
    for k = 1, #SWATCHES do
        local t = b:CreateTexture(nil, "ARTWORK")
        t:SetTexture(WHITE)
        t:SetWidth(SWATCH); t:SetHeight(SWATCH_H)
        t:SetPoint("LEFT", b, "LEFT", MENU_PAD + (k - 1) * SWATCH, 0)
        b.swatches[k] = t
    end
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    b.text:SetJustifyH("LEFT")
    b.check = b:CreateTexture(nil, "OVERLAY")
    b.check:SetTexture(MARK_SELECTED)
    b.check:SetWidth(14); b.check:SetHeight(14)
    b.check:SetPoint("RIGHT", b, "RIGHT", -MENU_PAD, 0)
    b:SetScript("OnEnter", menuRowEnter)
    b:SetScript("OnLeave", menuRowLeave)
    b:SetScript("OnClick", menuRowClick)
    f.rows[i] = b
    return b
end
local function showMenu(anchor, items)
    if ns.Kit.FlyAnchor() == anchor then
        ns.Kit.FlyHide()
        return
    end
    GameTooltip:Hide()
    local f = ui.menuFly
    if not f then
        f = CreateFrame("Frame", nil, UIParent)
        f.rows = {}
        ui.menuFly = f
    end
    local w, y = 0, 0
    for i, it in ipairs(items) do
        local b = menuRowAt(f, i)
        b.item = it
        ns.Kit.PaintRound(b, C.none)
        if it.sep then
            y = y + MENU_SEP
            local l = C.line
            b.sep:SetVertexColor(l[1], l[2], l[3], l[4] or 1)
            b.sep:Show()
        else
            b.sep:Hide()
        end
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -y)
        b:SetPoint("RIGHT", f, "RIGHT", 0, 0)
        for k, t in ipairs(b.swatches) do
            local c = it.swatch and presetColor(it.swatch, SWATCHES[k])
            if c then
                t:SetVertexColor(c[1], c[2], c[3], 1)
                t:Show()
            else
                t:Hide()
            end
        end
        local x = MENU_PAD + (it.swatch and SWATCH_W or 0)
        b.text:ClearAllPoints()
        b.text:SetPoint("LEFT", b, "LEFT", x, 0)
        b.text:SetText(it.label)
        local c = (it.off and C.control.textOff) or ((it.head or it.check) and C.heading) or C.text
        b.text:SetTextColor(c[1], c[2], c[3])
        if it.check then b.check:Show() else b.check:Hide() end
        b:Show()
        w = math.max(w, x + b.text:GetStringWidth() + MENU_CHECK)
        y = y + MENU_ROW_H
    end
    for i = #items + 1, #f.rows do f.rows[i]:Hide() end
    f:SetWidth(w)
    f:SetHeight(y)
    ns.Kit.Fly(anchor, f)
end
ns.WinMenu = showMenu
function ns.ShowGearMenu(ranks)
    local bound = ns.BuildGear(ranks)
    local items = { { head = true, label = ns.T("menu.gear_head") },
                    { label = ns.T("menu.gear_none"), check = bound == nil, tip = ns.T("tip.gear_unbind"),
                      onClick = function() ns.SetBuildGear(ranks, nil); ns.RefreshWindow() end } }
    for _, name in ipairs(ns.GearSets()) do
        local n = name
        items[#items + 1] = { label = n, check = bound == n, tip = ns.T("tip.gear_bind", n),
                              onClick = function()
                                  ns.SetBuildGear(ranks, n)
                                  local snap = ns.SnapshotTalents(GetActiveTalentGroup(false, false) or 1)
                                  if snap and ns.RanksSig(snap.ranks) == ns.RanksSig(ranks) then ns.WearGear(n) end
                                  ns.RefreshWindow()
                              end }
    end
    local anchor = ui.rowActs and ui.rowActs.more
    if anchor and anchor:IsVisible() then showMenu(anchor, items) end
end
local function paintRow(b)
    local it = b.item
    local fill = (it.open and C.selected) or (b.hovered and C.hover) or nil
    if fill then
        b.fill:SetVertexColor(fill[1], fill[2], fill[3], fill[4] or 1)
        b.fill:Show()
    else
        b.fill:Hide()
    end
    if it.slot or b.hovered then b.cmp:Show() else b.cmp:Hide() end
end
local function rowEnter(self)
    local it = self.item
    self.hovered = true
    paintRow(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(it.text, 1, 1, 1, true)
    GameTooltip:AddLine(pointsStr(it.ranks), 1, 0.82, 0)
    if it.same then GameTooltip:AddLine(ns.T("tip.same"), 0.1, 1, 0.1, true) end
    if it.gear then GameTooltip:AddLine(ns.T("tip.row_gear", it.gear), 1, 1, 1, true) end
    ns.Kit.TipHints(GameTooltip, it.hints)
    GameTooltip:Show()
end
local function rowLeave(self)
    GameTooltip:Hide()
    self.hovered = self:IsMouseOver() and true or false
    paintRow(self)
end
local function rowClick(self, button)
    self.item.onClick(button)
end
local function inRow(child)
    local leave = child:GetScript("OnLeave")
    child:SetScript("OnLeave", function(self)
        if leave then leave(self) end
        if self.row then rowLeave(self.row) end
    end)
end
local function rowAt(i)
    local b = ui.rows[i]
    if b then return b end
    b = CreateFrame("Button", nil, ui.child)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b.fill = b:CreateTexture(nil, "BACKGROUND")
    b.fill:SetTexture(WHITE)
    b.fill:SetAllPoints(b)
    b.fill:Hide()
    b.bar = b:CreateTexture(nil, "BORDER")
    b.bar:SetTexture(WHITE)
    b.bar:SetWidth(LIB_BAR)
    b.bar:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
    b.bar:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 0, 0)
    b.bar:Hide()
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetWidth(LIB_ICON); b.icon:SetHeight(LIB_ICON)
    b.icon:SetTexCoord(ICON_CROP[1], ICON_CROP[2], ICON_CROP[3], ICON_CROP[4])
    b.icon:SetPoint("LEFT", b, "TOPLEFT", 6, -LIB_ROW_H / 2)
    b.same = b:CreateTexture(nil, "OVERLAY")
    b.same:SetTexture(MARK_SELECTED)
    b.same:SetWidth(LIB_SAME); b.same:SetHeight(LIB_SAME)
    b.same:SetPoint("BOTTOMRIGHT", b.icon, "BOTTOMRIGHT", 4, -3)
    b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    b.label:SetJustifyH("LEFT")
    b.label:SetHeight(14)
    b.label:SetPoint("LEFT", b, "TOPLEFT", LIB_TEXT_X, -LIB_ROW_H / 2)
    b.pts = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.pts:SetPoint("RIGHT", b, "TOPRIGHT", -(4 + ACT_SIZE + 4), -LIB_ROW_H / 2)
    b.cmp = ns.Kit.Orb(b, "compare", nil, nil, nil, ACT_SIZE)
    b.cmp:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b.cmp:SetPoint("RIGHT", b, "TOPRIGHT", -4, -LIB_ROW_H / 2)
    b.cmp.row = b
    inRow(b.cmp)
    b:SetScript("OnClick", rowClick)
    b:SetScript("OnEnter", rowEnter)
    b:SetScript("OnLeave", rowLeave)
    ui.rows[i] = b
    return b
end
local function rowActs()
    local a = ui.rowActs
    if a then return a end
    a = { builder = ns.Kit.Pill(ui.child), compare = ns.Kit.Pill(ui.child),
          more = ns.Kit.Orb(ui.child, "more", ns.T("act.more"), ns.T("tip.more"), nil, ACT_SIZE) }
    a.builder.kind, a.compare.kind = "quiet", "quiet"
    for _, w in pairs(a) do inRow(w) end
    ui.rowActs = a
    return a
end
local function placeRowActs(b, it)
    local a = rowActs()
    local y = -(LIB_ROW_H + LIB_OPEN_H / 2 - 3)
    ns.Kit.SetPill(a.builder, "builder", ns.T("act.builder_short"), ns.T("tip.builder"), function()
        openBuilder(it.ranks)
    end)
    local slot = it.slot
    ns.Kit.SetPill(a.compare, "compare", ns.T(slot and "act.compare_open" or "act.compare_add"),
        slot and ns.T("tip.compare_in", ns.CMP_LETTERS[slot]) or ns.T("tip.compare"),
        function()
            V.CompareClick(it.ranks, it.text)
            ns.RefreshWindow()
        end)
    a.compare.hints = { ns.Hint(slot and "cmp_open" or "cmp_add") }
    a.more.tipTitle, a.more.tipBody = ns.T("act.more"), ns.T("tip.more")
    a.more.onClick = function() showMenu(a.more, it.more()) end
    local prev
    for _, w in ipairs({ a.builder, a.compare, a.more }) do
        w.row = b
        w:SetParent(b)
        w:SetFrameLevel(b:GetFrameLevel() + 1)
        w:ClearAllPoints()
        if prev then
            w:SetPoint("LEFT", prev, "RIGHT", BTN_GAP, 0)
        else
            w:SetPoint("LEFT", b, "TOPLEFT", LIB_TEXT_X, y)
        end
        w:Show()
        prev = w
    end
end
local function placeRow(b, it, y, width)
    b.item = it
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", ui.child, "TOPLEFT", 0, -y)
    b:SetWidth(width)
    b:SetHeight(it.open and (LIB_ROW_H + LIB_OPEN_H) or LIB_ROW_H)
    if it.icon then
        b.icon:SetTexture(it.icon)
        b.icon:Show()
    else
        b.icon:Hide()
    end
    if it.same then b.same:Show() else b.same:Hide() end
    local s = C.secondary
    b.pts:SetText(pointsStr(it.ranks))
    b.pts:SetTextColor(s[1], s[2], s[3])
    b.label:SetWidth(width - LIB_TEXT_X - 6 - b.pts:GetStringWidth() - (4 + ACT_SIZE + 4))
    b.label:SetText(it.text)
    local lc = it.open and C.gold or C.text
    b.label:SetTextColor(lc[1], lc[2], lc[3])
    if it.open then
        local g = C.gold
        b.bar:SetVertexColor(g[1], g[2], g[3], 1)
        b.bar:Show()
    else
        b.bar:Hide()
    end
    local slot = it.slot
    local col = slot and V.compare[slot].color or nil
    local o = b.cmp
    o.tipTitle = ns.T(slot and "act.compare_open" or "act.compare_add")
    o.tipBody = slot and ns.T("tip.compare_in", ns.CMP_LETTERS[slot]) or ns.T("tip.compare")
    o.hints = slot and { ns.Hint("cmp_open"), ns.Hint("cmp_remove") } or { ns.Hint("cmp_add") }
    o:SetTint(col, col)
    o.onClick = function(button)
        V.CompareClick(it.ranks, it.text, button)
        ns.RefreshWindow()
    end
    b:Show()
    b.hovered = b:IsMouseOver() and true or false
    paintRow(b)
end
local function secAt(i)
    local f = ui.secs[i]
    if f then return f end
    f = CreateFrame("Frame", nil, ui.child)
    f:SetHeight(LIB_SEC_H)
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 4, 6)
    f.count = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.count:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -4, 6)
    f.line = f:CreateTexture(nil, "ARTWORK")
    f.line:SetTexture(WHITE)
    f.line:SetHeight(1)
    f.line:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    f.line:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    ui.secs[i] = f
    return f
end
local function noteAt(i)
    local t = ui.notes[i]
    if t then return t end
    t = ui.child:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    t:SetJustifyH("LEFT")
    ui.notes[i] = t
    return t
end
local function renderSections(secs)
    local width = ui.child:GetWidth()
    local head, sec2, line = C.heading, C.secondary, C.line
    local y, ri, ni = 0, 0, 0
    local opened = false
    for si, sec in ipairs(secs) do
        if si > 1 then y = y + LIB_SEC_GAP end
        local f = secAt(si)
        f.title:SetText(sec.title)
        f.title:SetTextColor(head[1], head[2], head[3])
        f.count:SetText(sec.count or "")
        f.count:SetTextColor(sec2[1], sec2[2], sec2[3])
        f.line:SetVertexColor(line[1], line[2], line[3], line[4] or 1)
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", ui.child, "TOPLEFT", 0, -y)
        f:SetWidth(width)
        f:Show()
        y = y + LIB_SEC_H + 2
        for _, it in ipairs(sec.rows) do
            ri = ri + 1
            local b = rowAt(ri)
            placeRow(b, it, y, width)
            if it.open then
                placeRowActs(b, it)
                opened = true
            end
            y = y + b:GetHeight()
        end
        if sec.note then
            ni = ni + 1
            local t = noteAt(ni)
            t:ClearAllPoints()
            t:SetPoint("TOPLEFT", ui.child, "TOPLEFT", 6, -(y + 4))
            t:SetWidth(width - 12)
            t:SetText(sec.note)
            t:SetTextColor(sec2[1], sec2[2], sec2[3])
            t:Show()
            y = y + t:GetStringHeight() + 8
        end
    end
    for i = ri + 1, #ui.rows do ui.rows[i]:Hide() end
    for i = #secs + 1, #ui.secs do ui.secs[i]:Hide() end
    for i = ni + 1, #ui.notes do ui.notes[i]:Hide() end
    if not opened and ui.rowActs then
        for _, w in pairs(ui.rowActs) do w:Hide() end
    end
    ui.child:SetHeight(math.max(y, 1))
    return y
end
local function actOrbAt(i)
    local b = ui.actOrbs[i]
    if b then return b end
    b = ns.Kit.Orb(ui.body, "learn", nil, nil, nil, ACT_ORB)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    ui.actOrbs[i] = b
    return b
end
local function actionTip(a)
    return a.off and (a.tip .. "\n" .. ns.Hex("alert") .. a.off .. "|r") or a.tip
end
local function slotAt(i)
    local b = ui.slots[i]
    if b then return b end
    b = ns.Kit.Pill(ui.body)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    ui.slots[i] = b
    return b
end
local function openLibrary()
    HTP_TalentsDB.lib = true
    ns.RefreshWindow()
end
local function slotPtsAt(i)
    local t = ui.slotPts[i]
    if t then return t end
    t = ui.body:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.slotPts[i] = t
    return t
end
local function renderCompareSlots(left, right, side)
    local items = V.compare or {}
    local each = math.max(SLOT_MIN, math.min(SLOT_MAX, math.floor((right - left - BTN_GAP) / 2)))
    if side then each = SLOT_MAX end
    local s = C.secondary
    local x = left
    for slot = 1, 2 do
        local b, it = slotAt(slot), items[slot]
        local idx, letter = slot, ns.CMP_LETTERS[slot]
        b.text:SetWidth(0); b.text:SetHeight(0)
        b.active = false
        if it then
            b.tint = it.color
            ns.Kit.SetPill(b, "compare", letter .. "  " .. it.name, pointsStr(it.ranks),
                function()
                    V.CompareRemove(idx)
                    ns.RefreshWindow()
                end)
            b.hints = { ns.Hint("cmp_remove_any") }
        else
            b.tint = nil
            ns.Kit.SetPill(b, "library", ns.T("status.cmp_empty", letter), ns.T("tip.cmp_slot_empty"), openLibrary)
            b.hints = { ns.Hint("library") }
        end
        capPill(b, each)
        if side and slot == 2 then x = math.max(x, PAD + ns.TREE_WIDTH + GAP) end
        b:ClearAllPoints()
        b:SetPoint("LEFT", ui.body, "TOPLEFT", x, CTX_MID)
        b:Show()
        x = x + b:GetWidth() + BTN_GAP
        local pts = slotPtsAt(slot)
        if side and it then
            pts:SetText(pointsStr(it.ranks))
            pts:SetTextColor(s[1], s[2], s[3])
            pts:ClearAllPoints()
            pts:SetPoint("LEFT", b, "RIGHT", BTN_GAP, 0)
            pts:Show()
            x = x + pts:GetStringWidth() + WORD_GAP
        else
            pts:Hide()
        end
    end
end
local function renderCompareControls()
    local clear = ui.cmpClear
    clear:SetOff(not V.compare)
    clear:ClearAllPoints()
    clear:SetPoint("RIGHT", ui.body, "TOPRIGHT", -PAD, CTX_MID)
    clear:Show()
    local list = {}
    for i, id in ipairs(CMP_VIEWS) do
        local view = id
        list[i] = { label = ns.T("act.cmp_" .. id), tip = ns.T("tip.cmp_" .. id), active = cmpView() == id,
                    onClick = function()
                        HTP_TalentsDB.cmpView = view ~= "side" and view or nil
                        ns.RefreshWindow()
                    end }
    end
    local seg = ui.cmpSeg
    seg:Set(list, C.mode.compare)
    seg:ClearAllPoints()
    seg:SetPoint("RIGHT", clear, "LEFT", -BTN_GAP, 0)
    seg:Show()
    local swap = ui.cmpSwap
    swap.off = not (V.compare and V.compare[2])
    ns.Kit.SetPill(swap, nil, ns.CMP_LETTERS[1] .. " <> " .. ns.CMP_LETTERS[2], ns.T("tip.cmp_swap"), function()
        V.CompareSwap()
        ns.RefreshWindow()
    end)
    swap.tipTitle = ns.T("act.cmp_swap")
    swap:ClearAllPoints()
    swap:SetPoint("RIGHT", seg, "LEFT", -BTN_GAP, 0)
    swap:Show()
    return ACT_ORB + BTN_GAP + seg:GetWidth() + BTN_GAP + swap:GetWidth()
end
local function renderTargetSwitch()
    local d = V.inspect
    local groups = d and d.groups
    if not (groups and groups[1] and groups[2]) then return 0 end
    local list = {}
    for g = 1, 2 do
        local n = g
        list[g] = { label = ns.T("window.set", g), active = d.shown == g, check = g == d.active,
                    tip = ns.T("tip.target_set") .. (g == d.active and ("\n" .. ns.T("tip.target_set_active")) or ""),
                    onClick = function()
                        V.InspectGroup(n)
                        ns.RefreshWindow()
                    end }
    end
    local seg = ui.tgtSeg
    seg:Set(list, C.mode.target)
    seg:ClearAllPoints()
    seg:SetPoint("RIGHT", ui.body, "TOPRIGHT", -PAD, CTX_MID)
    seg:Show()
    return seg:GetWidth()
end
local function renderPaneSwitch()
    local glyphs = onGlyphs()
    local need = SHOW_INSCRIPTION_LEVEL or 15
    local low = UnitLevel("player") < need
    local seg = ui.seg
    seg:Set({
        { label = ns.T("seg.talents"), tip = ns.T("tip.pane_tree"), active = not glyphs,
          onClick = function()
              V.SetPane("tree")
              ns.RefreshWindow()
          end },
        { label = ns.T("seg.glyphs"), tip = ns.T("tip.pane_glyphs"), active = glyphs,
          off = low and ns.T("tip.glyph_level", need) or nil, extra = ns.GLYPH_STRIP_W + 2,
          onClick = function()
              V.SetPane("glyphs")
              ns.RefreshWindow()
          end },
    })
    local host = seg.buttons[2]
    local strip = ui.strip
    if not strip then
        strip = ns.GlyphStrip(host)
        strip.frame:SetPoint("RIGHT", host, "RIGHT", -6, 0)
        ui.strip = strip
    end
    strip.frame:SetFrameLevel(host:GetFrameLevel() + 1)
    strip:Render(viewGroup(), glyphs, low)
    seg:ClearAllPoints()
    seg:SetPoint("RIGHT", ui.body, "TOPRIGHT", -PAD, CTX_MID)
    seg:Show()
    return seg:GetWidth()
end
local function renderStoredGlyphs()
    local major, minor = ns.CircleSnapSlots(V.stored)
    if not major then return 0 end
    local strip = ui.storedStrip
    if not strip then
        strip = ns.GlyphStrip(ui.body)
        strip.frame:SetPoint("RIGHT", ui.body, "TOPRIGHT", -PAD, CTX_MID)
        ui.storedStrip = strip
    end
    strip.frame:SetFrameLevel(ui.body:GetFrameLevel() + 2)
    strip:Render(viewGroup(), false, false, { major, minor })
    strip.frame:Show()
    return ns.GLYPH_STRIP_W
end
local function actionsMenu(icons)
    local items, tail = {}, {}
    for _, a in ipairs(icons) do
        if a.menu then
            tail[#tail + 1] = { head = true, sep = true, label = a.label }
            for _, m in ipairs(a.menu) do
                tail[#tail + 1] = { label = m.label, tip = m.tip, off = m.off, check = m.check, onClick = m.onClick }
            end
        else
            items[#items + 1] = { label = a.label, tip = a.tip, off = a.off, onClick = a.onClick }
        end
    end
    for _, it in ipairs(tail) do items[#items + 1] = it end
    return items
end
local function setActionPill(b, a, kind, bare)
    b.kind = kind
    b.off = a.off ~= nil
    b.hints = a.hints
    b.text:SetWidth(0); b.text:SetHeight(0)
    ns.Kit.SetPill(b, a.icon, a.label, actionTip(a), a.onClick, bare)
end
local function renderContext(list, st, winW, side)
    local body = ui.body
    local c = st.color
    local head = ui.status
    head:SetTextColor(c[1], c[2], c[3])
    local untitled = st.source == "set"
    head:SetText(untitled and "" or st.text)
    local x0 = untitled and (PAD - WORD_GAP) or nil
    local rightW = 0
    ui.seg:Hide(); ui.cmpSeg:Hide(); ui.cmpClear:Hide(); ui.cmpSwap:Hide(); ui.tgtSeg:Hide()
    if ui.storedStrip then ui.storedStrip.frame:Hide() end
    if st.source == "set" then
        rightW = renderPaneSwitch()
    elseif st.source == "stored" then
        rightW = renderStoredGlyphs()
    elseif st.source == "compare" then
        rightW = renderCompareControls()
    elseif st.source == "target" then
        rightW = renderTargetSwitch()
    end
    local limit = winW - PAD - (rightW > 0 and (rightW + WORD_GAP) or 0)
    local main, word
    local icons = {}
    for _, a in ipairs(list) do
        if a.kind == "main" and not main then
            main = a
        elseif a.kind == "word" and not word then
            word = a
        else
            icons[#icons + 1] = a
        end
    end
    local pill, wp, more = ui.mainPill, ui.wordPill, ui.actMore
    pill.castMode = main and main.cast and "any" or nil
    pill.castCount = main and main.cast or nil
    if main then setActionPill(pill, main, "main", false) end
    if word then setActionPill(wp, word, "quiet", false) end
    local function need(n)
        local x = x0 or (PAD + head:GetStringWidth())
        if main then x = x + WORD_GAP + pill:GetWidth() end
        if word then x = x + ((main and BTN_GAP) or WORD_GAP) + wp:GetWidth() end
        if n > 0 then x = x + WORD_GAP + n * ACT_ORB + (n - 1) * BTN_GAP end
        return x
    end
    local shown = #icons
    if need(shown) > limit and st.short and not untitled then head:SetText(st.short) end
    if need(shown) > limit and shown > 1 then shown = 1 end
    local folded = shown < #icons
    if need(shown) > limit and word then setActionPill(wp, word, "quiet", true) end
    if need(shown) > limit and main then
        setActionPill(pill, main, "main", true)
        pill.castCount = nil
    end
    local x = x0 or (PAD + head:GetStringWidth())
    if main then
        x = x + WORD_GAP
        pill:ClearAllPoints()
        pill:SetPoint("LEFT", body, "TOPLEFT", x, CTX_MID)
        pill:Show()
        x = x + pill:GetWidth()
    else
        pill:Hide()
    end
    if word then
        x = x + ((main and BTN_GAP) or WORD_GAP)
        wp:ClearAllPoints()
        wp:SetPoint("LEFT", body, "TOPLEFT", x, CTX_MID)
        wp:Show()
        x = x + wp:GetWidth()
    else
        wp:Hide()
    end
    local k = 0
    if folded then
        local menu = actionsMenu(icons)
        more.onClick = function() showMenu(more, menu) end
        more:ClearAllPoints()
        more:SetPoint("LEFT", body, "TOPLEFT", x + WORD_GAP, CTX_MID)
        more:Show()
        x = x + WORD_GAP + ACT_ORB
    else
        more:Hide()
        if #icons > 0 then x = x + WORD_GAP - BTN_GAP end
        for _, a in ipairs(icons) do
            k = k + 1
            local b = actOrbAt(k)
            b:SetKey(a.icon)
            b.tipTitle, b.tipBody, b.onHover, b.hints = a.label, actionTip(a), a.hover, a.hints
            local menu = a.menu
            b.onClick = menu and function() showMenu(b, menu) end or a.onClick
            b:SetOff(a.off ~= nil)
            b:SetTint(a.tint, a.tint)
            b:ClearAllPoints()
            b:SetPoint("LEFT", body, "TOPLEFT", x + BTN_GAP, CTX_MID)
            b:Show()
            x = x + BTN_GAP + ACT_ORB
        end
    end
    for i = k + 1, #ui.actOrbs do ui.actOrbs[i]:Hide() end
    if st.source == "compare" then
        renderCompareSlots(x + WORD_GAP, limit, side)
    else
        for _, b in ipairs(ui.slots) do b:Hide() end
        for _, t in ipairs(ui.slotPts) do t:Hide() end
    end
    local hint = ui.ctxHint
    local room = limit - x - WORD_GAP
    hint:Hide()
    if st.hint and rightW == 0 then
        local s = C.secondary
        hint:SetWidth(0)
        hint:SetText(st.hint)
        hint:SetTextColor(s[1], s[2], s[3])
        if hint:GetStringWidth() <= room then hint:Show() end
    end
end
local SLOT = 22
local SLOT_GAP = 4
local TITLE_LIB_GAP = 14
local CART_W = ORB + 4 + ORB + 4 + 1 + 4 + SLOT + SLOT_GAP + SLOT + 6
local SLOT_BLINK = 1.2
local SLOT_BLINK_STEP = 0.4
local function rankIcon(ranks)
    local best, bestPts = 1, -1
    for tab = 1, 3 do
        local sum = 0
        for _, v in pairs((ranks and ranks[tab]) or {}) do sum = sum + (v or 0) end
        if sum > bestPts then best, bestPts = tab, sum end
    end
    return treeIcon(V.class, best)
end
local function slotEnter(self)
    local it, letter = self.item, ns.CMP_LETTERS[self.idx]
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
    if it then
        local c = it.color
        GameTooltip:AddLine(letter .. "  " .. it.name, c[1], c[2], c[3], true)
        GameTooltip:AddLine(pointsStr(it.ranks), 1, 0.82, 0)
        ns.Kit.TipHints(GameTooltip, { ns.Hint("cmp_open"), ns.Hint("cmp_remove") })
    else
        GameTooltip:AddLine(ns.T("tip.slot_empty", letter), nil, nil, nil, true)
        ns.Kit.TipHints(GameTooltip, { ns.Hint("library") })
    end
    GameTooltip:Show()
end
local function slotClick(self, button)
    GameTooltip:Hide()
    if self.item then
        if button == "RightButton" then V.CompareRemove(self.idx) else V.OpenCompare() end
    elseif button ~= "RightButton" then
        HTP_TalentsDB.lib = true
    end
    ns.RefreshWindow()
end
local function slotEdge(b, col)
    ns.Kit.PaintRound(b, C.field)
    if col then b:SetBackdropBorderColor(col[1], col[2], col[3], 1) end
end
local function slotBlink(self)
    local left = (self.blinkUntil or 0) - GetTime()
    local col = C.cmp[self.idx]
    if left <= 0 or self.item then
        self:SetScript("OnUpdate", nil)
        slotEdge(self, self.item and col or nil)
        return
    end
    slotEdge(self, math.floor(left / SLOT_BLINK_STEP) % 2 == 0 and col or nil)
end
local function cmpSlotAt(i)
    local b = ui.cmpSlots[i]
    if b then return b end
    b = CreateFrame("Button", nil, ui.body)
    b:SetWidth(SLOT); b:SetHeight(SLOT)
    b:SetBackdrop(ns.Kit.ROUND)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b.idx = i
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetPoint("TOPLEFT", b, "TOPLEFT", 2, -2)
    b.icon:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 2)
    b.icon:SetTexCoord(ICON_CROP[1], ICON_CROP[2], ICON_CROP[3], ICON_CROP[4])
    b.badge = b:CreateTexture(nil, "OVERLAY")
    b.badge:SetTexture(WHITE)
    b.badge:SetWidth(10); b.badge:SetHeight(10)
    b.badge:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 1)
    b.letter = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b:SetScript("OnEnter", slotEnter)
    b:SetScript("OnLeave", hideTip)
    b:SetScript("OnClick", slotClick)
    ui.cmpSlots[i] = b
    return b
end
local function paintSlot(b, it)
    b.item = it
    local col = C.cmp[b.idx]
    slotEdge(b, it and col or nil)
    b.letter:SetText(ns.CMP_LETTERS[b.idx])
    b.letter:ClearAllPoints()
    if it then
        b.icon:SetTexture(rankIcon(it.ranks) or ns.QMARK)
        b.icon:Show()
        local sh = C.shade
        b.badge:SetVertexColor(sh[1], sh[2], sh[3], sh[4] or 1)
        b.badge:Show()
        b.letter:SetPoint("CENTER", b.badge, "CENTER", 0, 0)
        b.letter:SetTextColor(col[1], col[2], col[3])
    else
        b.icon:Hide()
        b.badge:Hide()
        b.letter:SetPoint("CENTER", b, "CENTER", 0, 0)
        local s = C.secondary
        b.letter:SetTextColor(s[1], s[2], s[3])
    end
end
local function renderCart()
    local items = V.compare or {}
    local cmp = V.Source() == "compare"
    for i = 2, 1, -1 do
        local s = cmpSlotAt(i)
        paintSlot(s, items[i])
        s:ClearAllPoints()
        if i == 2 then
            s:SetPoint("RIGHT", ui.titleSep, "LEFT", -4, 0)
        else
            s:SetPoint("RIGHT", ui.cmpSlots[2], "LEFT", -SLOT_GAP, 0)
        end
        s:Show()
    end
    local b = ui.cmpSlots[2]
    if items[1] and not items[2] and not cmp and V.compareAt and GetTime() - V.compareAt < SLOT_BLINK then
        b.blinkUntil = V.compareAt + SLOT_BLINK
        b:SetScript("OnUpdate", slotBlink)
    else
        b:SetScript("OnUpdate", nil)
    end
    local btn = ui.cmpBtn
    btn.tipBody = ns.T(cmp and "tip.compare_btn_on" or (#items == 0 and "tip.compare_btn_off" or "tip.compare_btn"))
    btn.active, btn.off = cmp, #items == 0 and not cmp
    btn.accent = C.mode.compare
    btn:Restyle()
    btn:ClearAllPoints()
    btn:SetPoint("RIGHT", ui.cmpSlots[1], "LEFT", -6, 0)
end
local function toggleCompareMode()
    if V.Source() == "compare" then V.CloseCompare() else V.OpenCompare() end
    ns.RefreshWindow()
end
local function libOpen()
    return HTP_TalentsDB.lib == true
end
function ns.LibPane()
    return HTP_TalentsDB.libPane == "bars" and "bars" or "builds"
end
local function toggleLib()
    HTP_TalentsDB.lib = not libOpen() or nil
    ns.RefreshWindow()
end
local function renderLibrary(secs, class)
    local hasBars = ns.BarsLibRender ~= nil
    if not libOpen() then
        if hasBars then ns.BarsLibHide() end
        ui.lib:Hide()
        return
    end
    ui.lib:Show()
    local h, l = C.heading, C.line
    local bars = hasBars and ns.LibPane() == "bars"
    ui.libSeg:Set({
        { label = ns.T("lib.pane_builds"), tip = ns.T("tip.lib_builds"), active = not bars,
          onClick = function() HTP_TalentsDB.libPane = nil; ns.RefreshWindow() end },
        { label = ns.T("lib.pane_bars"), tip = ns.T("tip.lib_bars"), active = bars,
          off = not hasBars and ns.T("msg.need_restart") or nil,
          onClick = function() HTP_TalentsDB.libPane = "bars"; ns.RefreshWindow() end },
    })
    ui.libSeg:ClearAllPoints()
    ui.libSeg:SetPoint("LEFT", ui.lib, "TOPLEFT", LIB_PAD, TITLE_MID)
    ui.libSeg:Show()
    ui.libTitle:SetText(bars and "" or ns.ClassName(class))
    ui.libTitle:SetTextColor(h[1], h[2], h[3])
    ui.libLine:SetVertexColor(l[1], l[2], l[3], l[4] or 1)
    if bars then
        renderSections({})
        local y = ns.BarsLibRender(ui.child, ui.child:GetWidth())
        ui.child:SetHeight(math.max(y, 1))
        ui.scroll:Sync(y)
    else
        if hasBars then ns.BarsLibHide() end
        ui.scroll:Sync(renderSections(secs))
    end
end
local function classIcon(b, class)
    b:SetImage(CLASS_CIRCLES, CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class])
end
local function titleButton(key, label)
    local b = ns.Kit.Pill(ui.body)
    ns.Kit.SetPill(b, key, label, nil, nil)
    return b
end
function ns.WindowScale()
    local v = tonumber(HTP_TalentsDB and HTP_TalentsDB.winScale) or 1
    return math.max(SCALE_MIN, math.min(SCALE_MAX, v))
end
function ns.WindowZoom(dir)
    local v = math.floor((ns.WindowScale() + dir * SCALE_STEP) * 100 + 0.5) / 100
    v = math.max(SCALE_MIN, math.min(SCALE_MAX, v))
    HTP_TalentsDB.winScale = v ~= 1 and v or nil
    ns.RefreshWindow()
    if ns.SettingsRefresh then ns.SettingsRefresh() end
end
local function paintZoom()
    local v = ns.WindowScale()
    local title = ns.T("tip.scale", math.floor(v * 100 + 0.5))
    for _, b in ipairs({ ui.zoomOut, ui.zoomIn }) do b.tipTitle = title end
    ui.zoomOut.tipBody, ui.zoomIn.tipBody = ns.T("tip.scale_less"), ns.T("tip.scale_more")
    ui.aboutOrb.tipTitle, ui.aboutOrb.tipBody = ns.T("act.about"), ns.T("tip.about")
    ui.zoomOut:SetOff(v <= SCALE_MIN + 0.001)
    ui.zoomIn:SetOff(v >= SCALE_MAX - 0.001)
    ui.zoomOut.hints = { ns.Hint("scale_less") }
    ui.zoomIn.hints = { ns.Hint("scale_more") }
end
local function renderTitle(class)
    local cc = ns.ClassColor(class)
    local name = ns.ClassName(class)
    classIcon(ui.crest, class)
    ui.crest:SetTint(nil, cc)
    ui.crest.tipTitle = name
    ui.classBtn.tipTitle = name
    ui.className:SetText(name)
    ui.className:SetTextColor(cc[1], cc[2], cc[3])
    local s = C.secondary
    ui.classArrow:SetVertexColor(s[1], s[2], s[3])
    ui.classBtn:SetWidth(CREST + 6 + ui.className:GetStringWidth() + 4 + ARROW)
    ui.libBtn.active = libOpen()
    ui.libBtn:Restyle()
    renderCart()
    paintZoom()
end
local function renderTitleInfo(st, winW)
    local left = PAD + ui.classBtn:GetWidth() + TITLE_LIB_GAP + ui.libBtn:GetWidth() + TITLE_GAP
    local right = winW - PAD - CART_W - VIEW_W - ui.cmpBtn:GetWidth() - TITLE_GAP
    local room = right - left
    local chip, info = ui.pickChip, ui.info
    ui.infoCasting, ui.infoRoom = st.casting, room
    if st.pick and room >= CHIP_MIN then
        chip.off = false
        chip.text:SetWidth(0); chip.text:SetHeight(0)
        ns.Kit.SetPill(chip, "library", ns.T("status.pick", st.pick),
            ns.T("tip.pick_chip") .. (st.pickInfo and ("\n" .. st.pickInfo) or ""),
            function()
                V.Live()
                ns.RefreshWindow()
            end)
        chip.hints = { ns.Hint("pick_drop") }
        capPill(chip, math.min(PICK_MAX, room))
        chip:Show()
        info:Hide()
        return
    end
    chip:Hide()
    info:Hide()
    if st.info then
        local c = st.infoColor or C.secondary
        info:SetText(st.info)
        info:SetTextColor(c[1], c[2], c[3])
        if info:GetStringWidth() <= room then info:Show() end
    end
end
local UNDER_H = 2
local UNDER_INSET = 6
local SET_BUILDER_ICON = "Interface\\Icons\\INV_Misc_Note_02"
local SET_QMARK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local SET_LOCK_ICON = "Interface\\LFGFrame\\UI-LFG-ICON-LOCK"
local SET_ACTIVE_MARK = "Interface\\RaidFrame\\ReadyCheck-Ready"
local function setDefs()
    local out = { { kind = "group", group = 1 } }
    if ns.CircleThirdSet() then
        out[#out + 1] = { kind = "circle", group = 2, set = 2 }
        out[#out + 1] = { kind = "circle", group = 2, set = 3 }
    else
        out[#out + 1] = { kind = "group", group = 2 }
    end
    out[#out + 1] = { kind = "builder" }
    out[#out + 1] = { kind = "target" }
    return out
end
local function dominantTree(grid)
    local best, bestPts
    for _, t in ipairs(grid or {}) do
        if not bestPts or (t.points or 0) > bestPts then best, bestPts = t, t.points or 0 end
    end
    return best
end
local SET_NAME_MAX = 200
local SET_NAME_MIN = 70
local TAB_PAD_L = 5
local TAB_ICON = 18
local TAB_ICON_GAP = 5
local function fitTab(b, w)
    local full = b.text:GetStringWidth()
    if w < full then
        b.text:SetWidth(math.max(1, w))
        b.text:SetHeight(14)
    else
        b.text:SetWidth(0); b.text:SetHeight(0)
        w = full
    end
    b:SetWidth(b.pad + w)
end
local function configureSet(b, d)
    local src = V.Source()
    local active = GetActiveTalentGroup() or 1
    local label, icon, body, pressed, checked
    local coords = ICON_CROP
    b.castMode = nil
    b.accent = nil
    b.hints = nil
    local off = d.kind ~= "builder" and d.kind ~= "target" and ns.CirclePending()
    b.build, b.num, b.unloaded = nil, nil, nil
    if d.kind == "builder" then
        label, icon, body = ns.T("sub.builder"), SET_BUILDER_ICON, ns.T("window.builder_help")
        pressed = src == "builder"
        b.accent = C.mode.builder
        b.hints = { ns.Hint("talent_add"), ns.Hint("talent_take") }
        b.onClick = function() ns.OpenBuilderTab() end
    elseif d.kind == "target" then
        local t = ns.TargetTab()
        label, body = ns.T("sub.target"), t.tip
        b.tipTitle = t.label
        local c = t.class and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[t.class]
        if c then icon, coords = CLASS_CIRCLES, c else icon = TARGET_ICON end
        pressed = src == "target"
        b.accent = C.mode.target
        b.onClick = function() ns.ShowTarget() end
        off = t.off
    elseif d.kind == "circle" and d.set ~= ns.CircleLoaded() then
        local n = d.set
        local snap = ns.CircleSnap(n)
        b.build = ns.SetBuildName(2, n)
        label = b.build or ns.T("window.set", n)
        b.num, b.unloaded = n, true
        icon = snap and treeIcon(playerClass(), snap.spec) or SET_QMARK_ICON
        body = ns.T("window.set_unloaded", n) .. "\n" .. (snap and ns.T("tip.set_stored", pointsStr(snap.ranks)) or ns.T("tip.set_stored_none"))
        pressed = src == "stored" and V.stored == n
        b.hints = { ns.Hint("set_stored") }
        b.onClick = function()
            V.ShowStored(n)
            ns.RefreshWindow()
        end
    elseif d.group > (GetNumTalentGroups() or 1) then
        label, icon, body = ns.T("window.set", d.group), SET_LOCK_ICON, ns.T("tip.not_bought")
        b.num = d.group
        b.onClick = nil
    else
        local g = d.group
        local dom = dominantTree(ns.ReadTalentGrid(g))
        local snap = ns.SnapshotTalents(g)
        b.build = ns.SetBuildName(g, d.set)
        label = b.build or ns.T("window.set", d.set or g)
        b.num = d.set or g
        icon = (dom and dom.icon) or SET_BUILDER_ICON
        body = ns.T("window.set_tip", (dom and dom.name) or "?", pointsStr(snap and snap.ranks))
        if g == active then body = body .. "\n" .. TALENT_ACTIVE_SPEC_STATUS end
        if d.set then body = body .. "\n" .. ns.T("tip.set_loaded", d.set) end
        pressed = src == "set" and viewGroup() == g
        b.hints = { ns.Hint((not isOwn() and "set_home") or (pressed and onGlyphs() and "set_tree")
                            or "set_show") }
        checked = g == active
        b.castMode = g
        b.onClick = function()
            V.ClickSet(g)
            ns.RefreshWindow()
        end
    end
    if off and d.kind ~= "target" then body = body .. "\n" .. ns.T("tip.circle_wait") end
    if b.build then body = ns.T("tip.set_build", b.build) .. "\n" .. body end
    b.text:SetWidth(0); b.text:SetHeight(0)
    b.text:SetText(label)
    if d.kind ~= "target" then
        b.tipTitle = (d.kind == "group" and V.GroupName(d.group)) or (b.build and ns.T("window.set", d.set)) or label
    end
    b.tipBody = body
    if coords == ICON_CROP and SetPortraitToTexture then
        SetPortraitToTexture(b.icon, icon)
        b.icon:SetTexCoord(0, 1, 0, 1)
    else
        b.icon:SetTexture(icon)
        b.icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    end
    if b.num then
        b.numText:SetText(b.num)
        b.numText:Show()
    else
        b.numText:Hide()
    end
    if checked then b.check:Show() else b.check:Hide() end
    b.active = pressed and true or false
    b.off = off and true or false
    b.icon:SetDesaturated((b.off or b.unloaded) and true or false)
    b.textW = math.min(b.text:GetStringWidth(), b.build and SET_NAME_MAX or math.huge)
    b.pad = TAB_PAD_L + TAB_ICON + TAB_ICON_GAP + (checked and 22 or 10)
    fitTab(b, b.textW)
    b:Restyle()
    b.under:Hide()
end
local function setButtonAt(i)
    local b = ui.setButtons[i]
    if b then return b end
    b = ns.Kit.Button(ui.body, TAB_H)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetWidth(TAB_ICON); b.icon:SetHeight(TAB_ICON)
    b.icon:SetPoint("LEFT", b, "LEFT", TAB_PAD_L, 0)
    b.numText = b:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    b.numText:SetPoint("BOTTOMRIGHT", b.icon, "BOTTOMRIGHT", 3, -2)
    b.text:ClearAllPoints()
    b.text:SetPoint("LEFT", b.icon, "RIGHT", TAB_ICON_GAP, 0)
    b.check = b:CreateTexture(nil, "OVERLAY")
    b.check:SetTexture(SET_ACTIVE_MARK)
    b.check:SetWidth(14); b.check:SetHeight(14)
    b.check:SetPoint("RIGHT", b, "RIGHT", -6, 0)
    b.under = b:CreateTexture(nil, "OVERLAY")
    b.under:SetTexture(WHITE)
    b.under:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", UNDER_INSET, 0)
    b.under:SetPoint("TOPRIGHT", b, "BOTTOMRIGHT", -UNDER_INSET, UNDER_H)
    b.under:Hide()
    ns.Kit.CastFill(b)
    ui.setButtons[i] = b
    return b
end
local function renderGroups()
    local defs = setDefs()
    local prev
    for i, d in ipairs(defs) do configureSet(setButtonAt(i), d) end
    local total, named = TAB_GAP * (#defs - 1), {}
    for i = 1, #defs do
        local b = ui.setButtons[i]
        total = total + b:GetWidth()
        if b.build then named[#named + 1] = b end
    end
    local over = total - (ui.body:GetWidth() - PAD * 2)
    if over > 0 and #named > 0 then
        local cut = math.ceil(over / #named)
        for _, b in ipairs(named) do fitTab(b, math.max(SET_NAME_MIN, b.textW - cut)) end
    end
    for i in ipairs(defs) do
        local b = ui.setButtons[i]
        b:ClearAllPoints()
        if prev then
            b:SetPoint("LEFT", prev, "RIGHT", TAB_GAP, 0)
        else
            b:SetPoint("TOPLEFT", ui.body, "TOPLEFT", PAD, -TABS_Y)
        end
        b:Show()
        prev = b
    end
    for i = #defs + 1, #ui.setButtons do ui.setButtons[i]:Hide() end
end
local function sideWidth(n)
    return PAD + n * ns.TREE_WIDTH + (n - 1) * GAP + PAD
end
local function sideLayout(cols, lib)
    local us = ns.WindowScale()
    if not cols or #cols < 2 or cmpView() ~= "side" then return false, us end
    local s = math.min(us, (UIParent:GetWidth() - SCREEN_MARGIN) / (lib + sideWidth(#cols)))
    if s >= MIN_SCALE then return true, s end
    return false, us
end
local function placeTrees(n, top)
    ui.treeHost:ClearAllPoints()
    ui.treeHost:SetPoint("TOPLEFT", ui.body, "TOPLEFT", PAD, -top)
    for k, h in ipairs(ui.cmpHosts) do
        h:ClearAllPoints()
        h:SetPoint("TOPLEFT", ui.body, "TOPLEFT", PAD + k * (ns.TREE_WIDTH + GAP), -top)
        if k + 1 > n then h:Hide() end
    end
end
local function resize(w, h, scale, lib)
    local total = lib + w
    local oldLib = ui.libW or 0
    ui.body:SetWidth(w)
    if win:GetWidth() == total and win:GetHeight() == h and win:GetScale() == scale and oldLib == lib then return end
    local left, top = win:GetLeft(), win:GetTop()
    local oldEff = win:GetEffectiveScale()
    ui.libW = lib
    win:SetScale(scale)
    win:SetWidth(total)
    win:SetHeight(h)
    if not (left and top) then return end
    local k = oldEff / win:GetEffectiveScale()
    left, top = (left + oldLib) * k - lib, top * k
    local screenW = UIParent:GetRight() * UIParent:GetEffectiveScale() / win:GetEffectiveScale()
    if left + total > screenW then left = screenW - total end
    if left < 0 then left = 0 end
    win:ClearAllPoints()
    win:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
end
function ui.render()
    ns.Kit.Sync()
    V.Ensure()
    local class = V.class
    local glyphs = onGlyphs()
    local view = V.Trees()
    local src = V.Source()
    local border = (src == "builder" or src == "target" or src == "compare") and ns.MODE_COLORS[src] or nil
    local secs = {}
    local lib = libOpen() and LIB_W or 0
    if lib > 0 then
        local liveSig
        if isOwn() then
            local mine = myRanks()
            liveSig = mine and ns.RanksSig(mine) or nil
        end
        buildMine(secs, liveSig)
        buildAlts(secs, liveSig)
        buildStandard(secs, liveSig)
    end
    local cols = src == "compare" and (V.compare or {}) or nil
    local side, scale = sideLayout(cols, lib)
    local tableOn = cols ~= nil and #cols > 0 and cmpView() == "table"
    local glyphCol = not (glyphs or tableOn or side) and HTP_TalentsDB.wideGlyphs and src == "set"
    local winW = (side and sideWidth(#cols)) or (glyphCol and NORMAL_W + GAP + ns.GLYPH_COL_W) or NORMAL_W
    local list, st = ns.SourceActions()
    renderTitle(class)
    renderGroups()
    renderTitleInfo(st, winW)
    renderContext(list, st, winW, side)
    local sep = C.line
    ui.titleSep:SetVertexColor(sep[1], sep[2], sep[3], sep[4] or 1)
    local top = TREE_Y
    renderLibrary(secs, class)
    ui.glyphCol:Hide()
    if glyphs or tableOn then
        ui.treeHost:Hide()
        placeTrees(0, top)
        resize(winW, WIN_H, scale, lib)
        if glyphs then
            ui.cmpTable.frame:Hide()
            ns.GlyphRender(ui.glyphHost, viewGroup(), ns.TREE_WIDTH, CANVAS_H)
        else
            ns.GlyphHide()
            ui.cmpTable.frame:ClearAllPoints()
            ui.cmpTable.frame:SetPoint("TOPLEFT", ui.body, "TOPLEFT", PAD, -top)
            ui.cmpTable:Render(cols, class)
        end
        return
    end
    ns.GlyphHide()
    ui.cmpTable.frame:Hide()
    placeTrees(side and #cols or 0, top)
    ui.treeHost:Show()
    if view.edit and ns.CirclePending() then view.edit.locked = true end
    local treeH
    if side then
        ui.treeNote:Hide()
        treeH = ns.TreeRender(ui.treeHost, V.RanksGrid(cols[1].ranks), { class = class, cmps = cols, quiet = true, border = border })
    elseif view.grid then
        ui.treeNote:Hide()
        treeH = ns.TreeRender(ui.treeHost, view.grid, {
            edit = view.edit, class = class, marks = view.marks,
            cmps = cols and cols[2] and { cols[2] } or nil, border = border,
        })
    else
        treeH = ns.TreeRender(ui.treeHost, nil, { class = class })
        ui.treeNote:SetText(isOwn() and ns.T("window.no_read") or ns.T("window.no_grid"))
        ui.treeNote:Show()
    end
    if not side then
        if glyphCol then
            ui.glyphCol:ClearAllPoints()
            ui.glyphCol:SetPoint("TOPLEFT", ui.body, "TOPLEFT", PAD + ns.TREE_WIDTH + GAP, -top)
            ui.glyphCol:Show()
            ns.GlyphRender(ui.glyphCol, viewGroup(), ns.GLYPH_COL_W, ns.GLYPH_COL_H, true)
        end
        resize(winW, WIN_H, scale, lib)
        return
    end
    for k, col in ipairs(cols) do
        if k > 1 then
            local host = ui.cmpHosts[k - 1]
            host:Show()
            treeH = math.max(treeH, ui.cmpTrees[k - 1]:Render(V.RanksGrid(col.ranks),
                                                              { class = class, cmps = cols, quiet = true }))
        end
    end
    resize(winW, WIN_H + math.max(0, treeH - CANVAS_H), scale, lib)
end
local function gripDrag()
    if not ui.grip.held then
        ui.gripDriver:Hide()
        return
    end
    local cx = GetCursorPosition() / win:GetEffectiveScale()
    local want = cx >= ui.body:GetLeft() + NORMAL_W + (GAP + ns.GLYPH_COL_W) / 2
    if want ~= (HTP_TalentsDB.wideGlyphs == true) then
        HTP_TalentsDB.wideGlyphs = want or nil
        ns.RefreshWindow()
    end
end
local function classClick(class)
    if V.mode == "inspect" then V.mode = "live" end
    ns.ShowClass(class)
end
local palette
local function classPalette()
    if palette then return palette end
    palette = CreateFrame("Frame", nil, UIParent)
    local rows = math.ceil(#CLASS_ORDER / PALETTE_COLS)
    palette:SetWidth(PALETTE_COLS * PALETTE_ORB + (PALETTE_COLS - 1) * ORB_GAP)
    palette:SetHeight(rows * PALETTE_ORB + (rows - 1) * ORB_GAP)
    palette.orbs = {}
    for i, class in ipairs(CLASS_ORDER) do
        local cls = class
        local own = cls == playerClass()
        local b = ns.Kit.Orb(palette, "plate", ns.ClassName(cls),
            (own and (ns.T("tip.own_class") .. "\n") or "") .. ns.T("tip.class"),
            function()
                ns.Kit.FlyHide()
                classClick(cls)
            end, PALETTE_ORB)
        classIcon(b, cls)
        b:SetPoint("TOPLEFT", palette, "TOPLEFT", ((i - 1) % PALETTE_COLS) * (PALETTE_ORB + ORB_GAP),
                   -math.floor((i - 1) / PALETTE_COLS) * (PALETTE_ORB + ORB_GAP))
        if own then
            local mark = b:CreateTexture(nil, "OVERLAY")
            mark:SetTexture(MARK_SELECTED)
            mark:SetWidth(12); mark:SetHeight(12)
            mark:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 3, -3)
        end
        b.class = cls
        palette.orbs[i] = b
    end
    return palette
end
local function togglePalette()
    if ns.Kit.FlyAnchor() == ui.classBtn then
        ns.Kit.FlyHide()
        return
    end
    local pal = classPalette()
    for _, b in ipairs(pal.orbs) do b:SetOn(b.class == V.class) end
    GameTooltip:Hide()
    ns.Kit.Fly(ui.classBtn, pal)
end
local function classClickAny(button)
    if button == "RightButton" then
        ns.Kit.FlyHide()
        GameTooltip:Hide()
        ns.Home()
        return
    end
    togglePalette()
end
local function windowMenu()
    local items = { { head = true, label = ns.T("menu.theme") } }
    local cur = ns.ThemeId()
    for _, key in ipairs(ns.THEME_ORDER) do
        local k = key
        items[#items + 1] = { label = ns.T("theme." .. k), tip = ns.T("theme." .. k .. "_tip"),
                              swatch = ns.THEMES[k], check = k == cur,
                              onClick = function() ns.SetTheme(k) end }
    end
    items[#items + 1] = { sep = true, label = ns.T("menu.native"), tip = ns.T("tip.native"),
                          onClick = function() ns.SetMode("mini") end }
    if (GetNumTalentGroups(false, true) or 0) > 0 then
        items[#items + 1] = { label = ns.T("menu.pet"), tip = ns.T("tip.menu_pet"),
                              onClick = function()
                                  if ns.OpenNativePet() then win:Hide() end
                              end }
    end
    items[#items + 1] = { label = ns.T("menu.swap_panel"), tip = ns.T("tip.menu_swap_panel"),
                          check = ns.QuickShown(), onClick = function() ns.QuickToggle() end }
    items[#items + 1] = { label = ns.T("menu.options"), tip = ns.T("tip.menu_options"), onClick = ns.OpenOptions }
    return items
end
local function toggleMenu()
    showMenu(ui.menuOrb, windowMenu())
end
function ns.Home()
    V.Home()
    ns.RefreshWindow()
end
function ns.WindowShown()
    return win ~= nil and win:IsShown()
end
function ns.GlyphsOnScreen()
    if win ~= nil and win:IsShown() and V.Source() == "set"
        and (onGlyphs() or HTP_TalentsDB.wideGlyphs == true) then
        return true
    end
    return ns.MiniGlyphsShown ~= nil and ns.MiniGlyphsShown()
end
function ns.ViewOnGlyphs()
    return win ~= nil and win:IsShown() and onGlyphs()
end
local function classBtnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
    GameTooltip:AddLine(self.tipTitle or "", 1, 1, 1, true)
    GameTooltip:AddLine(ns.T("tip.class_pick"), nil, nil, nil, true)
    ns.Kit.TipHints(GameTooltip, { ns.Hint("class_pick"), ns.Hint("class_home") })
    GameTooltip:Show()
end
local function rule(parent)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetTexture(WHITE)
    return t
end
create = function()
    win = CreateFrame("Frame", "HTP_TalentsFrame", UIParent)
    win:SetWidth(NORMAL_W)
    win:SetHeight(WIN_H)
    win:SetPoint("CENTER")
    win:SetFrameStrata("DIALOG")
    win:SetToplevel(true)
    win:SetClampedToScreen(true)
    win:EnableMouse(true)
    win:SetMovable(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop", win.StopMovingOrSizing)
    win:Hide()
    tinsert(UISpecialFrames, "HTP_TalentsFrame")
    local body = CreateFrame("Frame", nil, win)
    body:SetPoint("TOPRIGHT", win, "TOPRIGHT", 0, 0)
    body:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", 0, 0)
    body:SetWidth(NORMAL_W)
    ui.body = body
    ui.classBtn = CreateFrame("Button", nil, body)
    ui.classBtn:SetHeight(CREST)
    ui.classBtn:SetPoint("LEFT", body, "TOPLEFT", PAD, TITLE_MID)
    ui.classBtn:SetScript("OnEnter", classBtnEnter)
    ui.classBtn:SetScript("OnLeave", hideTip)
    ui.classBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    ui.classBtn:SetScript("OnClick", function(_, button) classClickAny(button) end)
    ui.crest = ns.Kit.Orb(ui.classBtn, "plate", "", ns.T("tip.class_pick"), classClickAny, CREST)
    ui.crest:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    ui.crest:SetPoint("LEFT", ui.classBtn, "LEFT", 0, 0)
    ui.crest.tipAnchor = "ANCHOR_BOTTOMRIGHT"
    ui.crest.hints = { ns.Hint("class_pick"), ns.Hint("class_home") }
    ui.className = ui.classBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    ui.className:SetPoint("LEFT", ui.crest, "RIGHT", 6, 0)
    ui.classArrow = ui.classBtn:CreateTexture(nil, "ARTWORK")
    ui.classArrow:SetTexture(ns.Kit.ART .. "right.tga")
    ui.classArrow:SetTexCoord(0, 1, 1, 1, 0, 0, 1, 0)
    ui.classArrow:SetWidth(ARROW); ui.classArrow:SetHeight(ARROW)
    ui.classArrow:SetPoint("LEFT", ui.className, "RIGHT", 4, -1)
    ui.libBtn = titleButton("library", ns.T("act.library"))
    ui.libBtn.tipBody = ns.T("tip.library")
    ui.libBtn.onClick = toggleLib
    ui.libBtn:SetPoint("LEFT", ui.classBtn, "RIGHT", TITLE_LIB_GAP, 0)
    local close = ns.Kit.Orb(body, "close", CLOSE, nil, function() win:Hide() end, ORB)
    close:SetPoint("RIGHT", body, "TOPRIGHT", -PAD, TITLE_MID)
    ui.menuOrb = ns.Kit.Orb(body, "more", ns.T("act.menu"), ns.T("tip.menu"), toggleMenu, ORB)
    ui.menuOrb:SetPoint("RIGHT", close, "LEFT", -4, 0)
    ui.menuOrb.tipAnchor = "ANCHOR_BOTTOMRIGHT"
    ui.titleSep = rule(body)
    ui.titleSep:SetWidth(1); ui.titleSep:SetHeight(SEP_H)
    ui.zoomIn = ns.Kit.Orb(body, "plus", "", ns.T("tip.scale_more"), function() ns.WindowZoom(1) end, VIEW_ORB)
    ui.zoomIn:SetPoint("RIGHT", ui.menuOrb, "LEFT", -VIEW_GAP - 1, 0)
    ui.zoomOut = ns.Kit.Orb(body, "minus", "", ns.T("tip.scale_less"), function() ns.WindowZoom(-1) end, VIEW_ORB)
    ui.zoomOut:SetPoint("RIGHT", ui.zoomIn, "LEFT", -VIEW_GAP, 0)
    ui.aboutOrb = ns.Kit.Orb(body, "info", ns.T("act.about"), ns.T("tip.about"), function()
        if ns.ShowAbout then ns.ShowAbout(ui.aboutOrb) else ns.warn(ns.T("msg.need_restart")) end
    end, VIEW_ORB)
    ui.aboutOrb:SetPoint("RIGHT", ui.zoomOut, "LEFT", -VIEW_GAP, 0)
    ui.aboutOrb.tipAnchor = "ANCHOR_BOTTOMRIGHT"
    ui.titleSep:SetPoint("RIGHT", ui.aboutOrb, "LEFT", -4, 0)
    ui.cmpSlots = {}
    ui.cmpBtn = titleButton("compare", ns.T("act.pane_compare"))
    ui.cmpBtn.onClick = toggleCompareMode
    ui.setButtons = {}
    ui.status = body:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    ui.status:SetJustifyH("LEFT")
    ui.status:SetPoint("LEFT", body, "TOPLEFT", PAD, CTX_MID)
    ui.ctxHint = body:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ui.ctxHint:SetJustifyH("RIGHT")
    ui.ctxHint:SetHeight(14)
    ui.ctxHint:SetPoint("RIGHT", body, "TOPRIGHT", -PAD, CTX_MID)
    ui.ctxHint:Hide()
    ui.seg = ns.Kit.Segment(body)
    ui.seg:Hide()
    ui.info = body:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.info:SetJustifyH("LEFT")
    ui.info:SetPoint("LEFT", ui.libBtn, "RIGHT", TITLE_GAP, 0)
    ui.info:Hide()
    ui.pickChip = ns.Kit.Pill(body)
    ui.pickChip:SetPoint("LEFT", ui.libBtn, "RIGHT", TITLE_GAP, 0)
    ui.pickChip:Hide()
    ui.mainPill = ns.Kit.CastFill(ns.Kit.Pill(body))
    ui.mainPill:SetHeight(ACT_PILL_H)
    ui.wordPill = ns.Kit.Pill(body)
    ui.wordPill:SetHeight(ACT_PILL_H)
    ui.wordPill:Hide()
    ui.actMore = ns.Kit.Orb(body, "more", ns.T("act.more"), ns.T("tip.more_acts"), nil, ACT_ORB)
    ui.actMore:Hide()
    ui.cmpSeg = ns.Kit.Segment(body)
    ui.cmpSeg:Hide()
    ui.cmpSwap = ns.Kit.Pill(body)
    ui.cmpSwap.kind = "quiet"
    ui.cmpSwap:SetHeight(ACT_PILL_H)
    ui.cmpSwap:Hide()
    ui.tgtSeg = ns.Kit.Segment(body)
    ui.tgtSeg:Hide()
    ui.cmpClear = ns.Kit.Orb(body, "close", ns.T("act.compare_off"), ns.T("tip.compare_off"), function()
        V.compare = nil
        V.CloseCompare()
        ns.RefreshWindow()
    end, ACT_ORB)
    ui.lib = CreateFrame("Frame", "HTP_TalentsLibrary", win)
    ui.lib:SetWidth(LIB_W)
    ui.lib:SetPoint("TOPLEFT", win, "TOPLEFT", 0, 0)
    ui.lib:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 0, 0)
    ui.lib:Hide()
    ui.libTitle = ui.lib:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    ui.libTitle:SetJustifyH("RIGHT")
    ui.libTitle:SetPoint("RIGHT", ui.lib, "TOPLEFT", LIB_PAD + LIST_W - 4, TITLE_MID)
    ui.libTitle:SetWidth(LIST_W / 2)
    ui.libSeg = ns.Kit.Segment(ui.lib)
    ui.libTitle:SetHeight(TITLE_H)
    ui.libLine = rule(ui.lib)
    ui.libLine:SetWidth(1)
    ui.libLine:SetPoint("TOPRIGHT", ui.lib, "TOPRIGHT", 0, -WIN_BOTTOM)
    ui.libLine:SetPoint("BOTTOMRIGHT", ui.lib, "BOTTOMRIGHT", 0, WIN_BOTTOM)
    ui.scroll = ns.Kit.Scroll(ui.lib)
    ui.scroll:SetPoint("TOPLEFT", ui.lib, "TOPLEFT", LIB_PAD, -TABS_Y)
    ui.scroll:SetPoint("BOTTOMRIGHT", ui.lib, "BOTTOMRIGHT", -(LIB_PAD + LIB_SCROLL), WIN_BOTTOM)
    ui.child = ui.scroll.child
    ui.child:SetWidth(LIST_W - LIB_SCROLL)
    ui.treeHost = CreateFrame("Frame", nil, body)
    ui.treeHost:SetPoint("TOPLEFT", body, "TOPLEFT", PAD, -TREE_Y)
    ui.treeHost:SetWidth(ns.TREE_WIDTH)
    ui.treeHost:SetHeight(1)
    ui.treeNote = ui.treeHost:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ui.treeNote:SetPoint("TOPLEFT", ui.treeHost, "TOPLEFT", 8, -40)
    ui.treeNote:SetWidth(ns.TREE_WIDTH - 16)
    ui.glyphHost = CreateFrame("Frame", nil, body)
    ui.glyphHost:SetPoint("TOPLEFT", body, "TOPLEFT", PAD, -TREE_Y)
    ui.glyphHost:SetWidth(ns.TREE_WIDTH)
    ui.glyphHost:SetHeight(1)
    ui.glyphCol = CreateFrame("Frame", nil, body)
    ui.glyphCol:SetWidth(ns.GLYPH_COL_W)
    ui.glyphCol:SetHeight(ns.GLYPH_COL_H)
    ui.glyphCol:Hide()
    ui.grip = ns.Kit.Grip(win, GRIP)
    ui.grip:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -4, 4)
    ui.grip:SetFrameLevel(win:GetFrameLevel() + 20)
    ui.grip.tipTitle, ui.grip.tipBody = ns.T("act.wide_glyphs"), ns.T("tip.wide_glyphs")
    ui.gripDriver = CreateFrame("Frame", nil, win)
    ui.gripDriver:Hide()
    ui.gripDriver:SetScript("OnUpdate", gripDrag)
    ui.grip.onDown = function(_, button)
        if button == "LeftButton" then ui.gripDriver:Show() end
    end
    ui.grip.onUp = function() ui.gripDriver:Hide() end
    ui.cmpHosts, ui.cmpTrees = {}, {}
    for k = 1, 2 do
        local host = CreateFrame("Frame", nil, body)
        host:SetWidth(ns.TREE_WIDTH)
        host:SetHeight(1)
        host:Hide()
        ui.cmpHosts[k] = host
        ui.cmpTrees[k] = ns.NewTree(host, ns.TREE_GEOM.wide)
    end
    ui.cmpTable = ns.NewCompareTable(body, ns.TREE_WIDTH, CANVAS_H)
    ui.cmpTable.frame:SetPoint("TOPLEFT", body, "TOPLEFT", PAD, -TREE_Y)
    ns.Kit.Sync()
    ns.Kit.Window(win)
    win:HookScript("OnHide", function()
        if ns.BarsLibHide then ns.BarsLibHide() end
    end)
    win:SetScript("OnShow", function()
        V.Ensure()
        ui.render()
        ns.FollowTarget()
    end)
end
ns.OnSpecCast(function(st)
    if st and ui.infoCasting and win and win:IsShown() and ui.info:IsShown() then
        ui.info:SetText(ns.T("foot.switching", ns.SpecCastLeft(st)))
    end
end)
function ns.ToggleWindow()
    if miniMode() then return ToggleTalentFrame() end
    if not win then create() end
    if win:IsShown() then win:Hide() else win:Show() end
end
function ns.OpenWindow(class)
    ns.ShowClass(class or playerClass())
end
function ns.SetMode(mode, class)
    HTP_TalentsDB.mode = (mode == "wide") and "wide" or nil
    ns.ApplyKeyBinding()
    if mode == "wide" then
        ns.ShowClass(class or playerClass())
    else
        if win then win:Hide() end
        if not (PlayerTalentFrame and PlayerTalentFrame:IsShown()) then ToggleTalentFrame() end
    end
end
function ns.OpenFromNative(glyphs, force)
    if not win then create() end
    local want = glyphs and "glyphs" or nil
    local shownGlyphs = win:IsShown() and onGlyphs()
    if win:IsShown() and not force and ((want and shownGlyphs) or (not want and not shownGlyphs)) then
        win:Hide()
        return
    end
    if want then
        V.group = nil
        ns.ShowClass(playerClass(), want)
    elseif shownGlyphs then
        V.SetPane("tree")
        ns.RefreshWindow()
    else
        win:Show()
    end
end
local REFRESH_ON = {
    PLAYER_TALENT_UPDATE = true, CHARACTER_POINTS_CHANGED = true, PREVIEW_TALENT_POINTS_CHANGED = true,
    GLYPH_ADDED = true, GLYPH_REMOVED = true, GLYPH_UPDATED = true, PLAYER_LEVEL_UP = true,
    PLAYER_TARGET_CHANGED = true,
}
local watch = CreateFrame("Frame")
for ev in pairs(REFRESH_ON) do watch:RegisterEvent(ev) end
watch:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
watch:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")
watch:SetScript("OnEvent", function(_, event)
    if event == "ACTIVE_TALENT_GROUP_CHANGED" then
        V.group = nil
    elseif event == "CURRENT_SPELL_CAST_CHANGED" then
        if not (win and win:IsShown() and onGlyphs()) then return end
    elseif event == "PLAYER_TARGET_CHANGED" then
        if win and win:IsShown() then ns.RefreshSoon() end
        return
    end
    ns.RefreshWindow()
end)
SLASH_HTPTALENTS1 = "/htpt"
SLASH_HTPTALENTS2 = "/htptalents"
SLASH_HTPTALENTS3 = "/mct"
SLASH_HTPTALENTS4 = "/mctalents"
SlashCmdList["HTPTALENTS"] = function(msg)
    local cmd, arg = strtrim(msg or ""):lower():match("^(%S*)%s*(.-)$")
    if cmd == "quick" then
        ns.QuickToggle()
    elseif cmd == "theme" then
        if arg ~= "" and ns.SetTheme(arg) then
            ns.say(ns.T("theme.set", ns.T("theme." .. arg)))
        else
            local keys = {}
            for _, k in ipairs(ns.THEME_ORDER) do
                keys[#keys + 1] = k .. " — " .. ns.T("theme." .. k) .. (k == ns.ThemeId() and " *" or "")
            end
            ns.say(ns.T("theme.list", table.concat(keys, ", ")))
        end
    elseif cmd == "lang" then
        local ok = arg ~= "" and ns.SetLang(arg)
        local id = ns.LangId()
        local name = ns.LangName(id) or (ns.T("options.lang_auto") .. " (" .. ns.T("msg.lang_auto") .. ")")
        ns.say(ns.T(ok and "msg.lang_set" or "msg.lang_list", name))
    elseif cmd == "show" then
        if not ns.ParadeTest then
            ns.say(ns.T("msg.need_restart"))
        else
            local msg = ns.ParadeTest(arg)
            if msg then ns.say(msg) end
        end
    elseif cmd == "model" then
        if not ns.ModelView then
            ns.say(ns.T("msg.need_restart"))
        else
            local msg = ns.ModelView(arg)
            if msg then ns.say(msg) end
        end
    elseif cmd == "voice" then
        if not ns.VoiceTest then
            ns.say(ns.T("msg.need_restart"))
        else
            for _, line in ipairs(ns.VoiceTest(arg)) do DEFAULT_CHAT_FRAME:AddMessage(line) end
        end
    elseif cmd == "actor" then
        ns.say(ns.ParadeActor and ns.ParadeActor(arg) or ns.T("msg.need_restart"))
    elseif cmd == "help" or cmd == "?" then
        ns.say(ns.T("msg.help_head"))
        for _, k in ipairs({ "open", "quick", "theme", "lang", "help" }) do
            DEFAULT_CHAT_FRAME:AddMessage("  " .. ns.T("msg.help_" .. k))
        end
    else
        ns.ToggleWindow()
    end
end
function HTP_TalentsBinding(id)
    if id == "quick" then
        ns.QuickToggle()
    elseif id == "settings" then
        ns.OpenSettings()
    else
        ns.ToggleWindow()
    end
end
