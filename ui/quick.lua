local ADDON, ns = ...
local C = ns.C
local Kit = ns.Kit
local CELL = 34
local GAP = 6
local PAD = 6
local BOX = 16
local BOX_GAP = 4
local CTRL = 16
local CTRL_GAP = 3
local CTRL_LIFT = 3
local CTRL_KEYS = { "less", "more", "lock", "settings" }
local SOCKET_SCALE = 0.34
local SPEC_ICON = 20
local ICON_CROP = { 0.07, 0.93, 0.07, 0.93 }
local OFF_ALPHA = 0.4
local FLY_W = 300
local HEAD_H = 22
local SET_ROW_H = 22
local ROW_INSET = 4
local HOVER_STEP = 0.1
local EVENT_DELAY = 0.2
local QMARK = "Interface\\Icons\\INV_Misc_QuestionMark"
local CHECK = "Interface\\RaidFrame\\ReadyCheck-Ready"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local CHECK_MARK = "|T" .. CHECK .. ":14:14|t "
local panel
local list
local use
local cells = {}
local inCombat = false
local function hideTip() GameTooltip:Hide() end
local function active()
    return GetActiveTalentGroup() or 1
end
local function combat()
    return inCombat or InCombatLockdown() and true or false
end
local function dominant(group)
    local best
    for _, t in ipairs(ns.ReadTalentGrid(group) or {}) do
        if not best or (t.points or 0) > (best.points or 0) then best = t end
    end
    return best
end
local function settingsRefresh()
    if ns.SettingsRefresh then ns.SettingsRefresh() end
end
local function hideUse()
    if use and not InCombatLockdown() then use:Hide() end
end
local function closeList()
    ns.QuickDisarm()
    hideUse()
    if list and list:IsShown() then Kit.FlyHide() end
end
local function savePlace()
    local l, b = panel:GetLeft(), panel:GetBottom()
    if not (l and b) then return end
    ns.QuickDB().pos = { "BOTTOMLEFT", "BOTTOMLEFT", l, b }
    panel:ClearAllPoints()
    panel:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", l, b)
end
local function dragStart()
    if not panel or ns.QuickLocked() then return end
    closeList()
    panel:StartMoving()
end
local function dragStop()
    if not panel then return end
    panel:StopMovingOrSizing()
    savePlace()
end
local function draggable(b)
    b:RegisterForDrag("LeftButton")
    b:SetScript("OnDragStart", dragStart)
    b:SetScript("OnDragStop", dragStop)
end
local function rowArmed(r)
    local it = r.it
    return it ~= nil and it.item ~= nil and ns.QuickArmed(it.item.item, it.target)
end
local function paintGlyphRow(r)
    local it = r.it
    if not it then return end
    if rowArmed(r) then
        local s = C.selected
        r.armBg:SetVertexColor(s[1], s[2], s[3], s[4] or 1)
        r.armBg:Show()
        r.side:SetText(CHECK_MARK .. ns.Hex("positive") .. ns.T(it.replace and "quick.replace" or "quick.insert") .. "|r")
    else
        r.armBg:Hide()
        r.side:SetText(ns.GlyphRowSide(it))
    end
end
local function paintGlyphRows()
    if not list then return end
    for _, r in ipairs(list.glyphs) do
        if r:IsShown() then paintGlyphRow(r) end
    end
end
local function glyphRowTip(owner, r)
    local it = r and r.it
    if not it then return end
    local h
    if not rowArmed(r) then
        h = ns.Hint("swap_pick")
    elseif it.replace then
        h = ns.Hint("swap_swap", r.slotName or "?")
    else
        h = ns.Hint("swap_put", it.target)
    end
    ns.GlyphTooltip(owner, { item = it, group = active(), hints = { h } })
end
local function cover(r)
    local it = r.it
    if InCombatLockdown() or not (it and it.bag) then return end
    if not use then
        use = CreateFrame("Button", "HTP_TalentsQuickUse", UIParent, "SecureActionButtonTemplate")
        use:SetFrameStrata("TOOLTIP")
        use:RegisterForClicks("LeftButtonUp")
        use:SetAttribute("type", "item")
        use:SetScript("OnEnter", function(self) glyphRowTip(self, self.row) end)
        use:SetScript("OnLeave", function(self)
            hideTip()
            if not InCombatLockdown() then self:Hide() end
        end)
        use:SetScript("PreClick", function() ns.GlyphSwapQuiet() end)
        use:SetScript("PostClick", function(self)
            local row = self.row
            local item = row and row.it
            if item and rowArmed(row) then
                ns.QuickDisarm()
                ns.QuickPlaceGlyph(item.target, true)
            end
            closeList()
        end)
    end
    local k = r:GetEffectiveScale() / UIParent:GetEffectiveScale()
    use:ClearAllPoints()
    use:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", r:GetLeft() * k, r:GetTop() * k)
    use:SetWidth(r:GetWidth() * k); use:SetHeight(r:GetHeight() * k)
    use:SetAttribute("item", it.bag.bag .. " " .. it.bag.slot)
    use.row = r
    use:Show()
end
local function glyphRowEnter(self)
    glyphRowTip(self, self)
    if rowArmed(self) then cover(self) end
end
local function glyphRowClick(self)
    local it = self.it
    if combat() or not (it and it.item and it.bag) then return end
    if IsModifiedClick("CHATLINK") then
        ns.GlyphRowClick(self)
        return
    end
    ns.QuickArm(it.item.item, it.target)
    list.armed = true
    paintGlyphRows()
    cover(self)
    glyphRowTip(self, self)
end
local function glyphRowAt(i)
    local r = list.glyphs[i]
    if r then return r end
    r = ns.NewGlyphRow(list)
    r.armBg = r:CreateTexture(nil, "BACKGROUND")
    r.armBg:SetTexture(WHITE)
    r.armBg:SetAllPoints(r)
    r.armBg:Hide()
    r:SetScript("OnEnter", glyphRowEnter)
    r:SetScript("OnLeave", hideTip)
    r:SetScript("OnClick", glyphRowClick)
    r:SetScript("PostClick", nil)
    list.glyphs[i] = r
    return r
end
local function setRowEnter(self)
    local it = self.item
    if not it then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(it.name, C.plain[1], C.plain[2], C.plain[3])
    local why = ns.QuickBlock()
    if why then
        local a = C.alert
        GameTooltip:AddLine(why, a[1], a[2], a[3], true)
    else
        Kit.TipHints(GameTooltip, { ns.Hint("quick_set") })
    end
    Kit.TipHints(GameTooltip, { ns.Hint("quick_gear") })
    GameTooltip:Show()
end
local function setRowClick(self, button)
    local it = self.item
    if not it or combat() then return end
    if button == "RightButton" then
        ns.QuickCycleGear(it.set.key)
        ns.QuickRefresh()
        return
    end
    ns.QuickApplySet(it.set)
    closeList()
end
local function setRowAt(i)
    local r = list.sets[i]
    if r then return r end
    r = CreateFrame("Button", nil, list)
    r:SetHeight(SET_ROW_H)
    r:SetWidth(FLY_W)
    r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    r:SetHighlightTexture(WHITE)
    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetWidth(18); r.icon:SetHeight(18)
    r.icon:SetPoint("LEFT", r, "LEFT", ROW_INSET, 0)
    r.icon:SetTexCoord(ICON_CROP[1], ICON_CROP[2], ICON_CROP[3], ICON_CROP[4])
    r.check = r:CreateTexture(nil, "OVERLAY")
    r.check:SetTexture(CHECK)
    r.check:SetWidth(12); r.check:SetHeight(12)
    r.check:SetPoint("BOTTOMRIGHT", r.icon, "BOTTOMRIGHT", 3, -3)
    r.right = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.right:SetPoint("RIGHT", r, "RIGHT", -ROW_INSET, 0)
    r.right:SetJustifyH("RIGHT")
    r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    r.text:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
    r.text:SetJustifyH("LEFT")
    r:SetScript("OnEnter", setRowEnter)
    r:SetScript("OnLeave", hideTip)
    r:SetScript("OnClick", setRowClick)
    list.sets[i] = r
    return r
end
local function ensureList()
    if list then return list end
    list = CreateFrame("Frame", nil, UIParent)
    list:SetWidth(FLY_W)
    list.sets, list.glyphs = {}, {}
    list.head = list:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    list.head:SetJustifyH("LEFT")
    list.head:SetPoint("TOPLEFT", list, "TOPLEFT", ROW_INSET, -2)
    list.head:SetWidth(FLY_W - ROW_INSET * 2)
    list.note = list:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    list.note:SetJustifyH("LEFT")
    list.note:SetWidth(FLY_W - ROW_INSET * 2)
    list:Hide()
    list:SetScript("OnHide", function()
        ns.QuickDisarm()
        hideUse()
    end)
    list:SetScript("OnUpdate", function(self)
        if self.armed and not ns.QuickArmed() then
            self.armed = nil
            hideUse()
            paintGlyphRows()
        end
    end)
    return list
end
local function placeNote(text, y)
    local c = C.secondary
    list.note:SetText(text)
    list.note:SetTextColor(c[1], c[2], c[3])
    list.note:ClearAllPoints()
    list.note:SetPoint("TOPLEFT", list, "TOPLEFT", ROW_INSET, -(y + 4))
    list.note:Show()
    return y + 4 + list.note:GetStringHeight() + 2
end
local function openList(b, text)
    local h = C.heading
    list.head:SetTextColor(h[1], h[2], h[3])
    ns.FitText(list.head, text, 1)
    list.owner = b
    GameTooltip:Hide()
    local top, cellTop = panel:GetTop(), b:GetTop()
    Kit.Fly(b, list, math.max(0, (top or 0) - (cellTop or top or 0)) + CTRL_LIFT + CTRL)
end
local function showSets(b)
    ensureList()
    for _, r in ipairs(list.glyphs) do r:Hide() end
    local gear = ns.QuickGear()
    local y, n = HEAD_H, 0
    for _, s in ipairs(ns.QuickSets()) do
        n = n + 1
        local r = setRowAt(n)
        local loaded = not s.set or ns.CircleLoaded() == s.set
        local dom = loaded and dominant(s.group) or nil
        local snap = not loaded and ns.CircleSnap(s.set) or nil
        if snap and snap.spec then
            local tree, icon = GetTalentTabInfo(snap.spec)
            if tree then dom = { name = tree, icon = icon } end
        end
        local name = ns.T("window.set", s.set or s.group)
        if dom then name = name .. " — " .. (dom.name or "?") end
        r.item = { set = s, name = name }
        local hv, tc = C.hover, C.text
        r:GetHighlightTexture():SetVertexColor(hv[1], hv[2], hv[3], hv[4] or 1)
        r.icon:SetTexture(dom and dom.icon or QMARK)
        if ns.QuickSetActive(s) then r.check:Show() else r.check:Hide() end
        local bound = ns.QuickGearExists(gear[s.key]) and gear[s.key] or nil
        r.right:SetText(bound or (ns.Hex("off") .. ns.T("quick.no_gear") .. "|r"))
        r.text:SetText(name)
        r.text:SetTextColor(tc[1], tc[2], tc[3])
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -y)
        r:Show()
        y = y + SET_ROW_H
    end
    for i = n + 1, #list.sets do list.sets[i]:Hide() end
    y = placeNote(Kit.HintText(ns.Hint("quick_gear")), y)
    list:SetHeight(y)
    openList(b, ns.T("quick.sets_head"))
end
local function showGlyphs(b)
    ensureList()
    for _, r in ipairs(list.sets) do r:Hide() end
    local slot = b.slot
    local y, n = HEAD_H, 0
    for _, it in ipairs(ns.QuickGlyphList(slot, active())) do
        n = n + 1
        local r = glyphRowAt(n)
        r.slotName = slot.name
        ns.FillGlyphRow(r, it, FLY_W)
        paintGlyphRow(r)
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -y)
        y = y + ns.GLYPH_ROW_H
    end
    for i = n + 1, #list.glyphs do list.glyphs[i]:Hide() end
    if n == 0 then
        y = placeNote(ns.T("quick.no_bag_glyphs"), y)
    else
        list.note:Hide()
    end
    if use and use:IsShown() and not (use.row and use.row:IsShown() and rowArmed(use.row)) then hideUse() end
    list:SetHeight(y)
    openList(b, ns.T("quick.socket_head", slot.id, slot.name or GLYPH_EMPTY))
end
local function cellEnter(b)
    if combat() then
        local a = C.alert
        GameTooltip:SetOwner(b, "ANCHOR_TOP")
        GameTooltip:AddLine(ns.T("quick.off_combat"), a[1], a[2], a[3], true)
        GameTooltip:Show()
    elseif b.key == "spec" then
        showSets(b)
    elseif b.locked then
        local t = C.text
        GameTooltip:SetOwner(b, "ANCHOR_TOP")
        GameTooltip:AddLine(GLYPH_LOCKED, C.plain[1], C.plain[2], C.plain[3])
        GameTooltip:AddLine(ns.QuickUnlockText(b.key), t[1], t[2], t[3], true)
        GameTooltip:Show()
    elseif b.slot then
        showGlyphs(b)
    end
    return true
end
local function glyphClick(self, button)
    local slot = self.slot
    if not slot or self.locked or combat() then return end
    if button == "RightButton" then
        if IsShiftKeyDown() and slot.spell then
            ns.ShowGlyphPopup("HTP_TALENTS_REMOVE_GLYPH", CONFIRM_REMOVE_GLYPH, slot.name, slot.id)
        end
    elseif SpellIsTargeting() and GlyphMatchesSocket(slot.id) then
        if slot.spell then
            ns.ShowGlyphPopup("HTP_TALENTS_REPLACE_GLYPH", CONFIRM_GLYPH_PLACEMENT, nil, slot.id)
        else
            PlaceGlyphInSocket(slot.id)
        end
    end
end
local function cellFor(key)
    local b = cells[key]
    if b then return b end
    if key == "spec" then
        b = Kit.Orb(panel, "tree", nil, nil, function() ns.ToggleWindow() end, CELL)
        b.onHover = cellEnter
        Kit.CastClock(b, b.icon)
        b.castMode = "any"
    else
        b = CreateFrame("Button", nil, panel)
        b:SetWidth(CELL); b:SetHeight(CELL)
        b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        b.socket = ns.NewGlyphSocket(b, key)
        b.socket:SetScale(SOCKET_SCALE)
        b.socket:ClearAllPoints()
        b.socket:SetPoint("CENTER", b, "CENTER", 0, 0)
        b.socket:EnableMouse(false)
        b:SetScript("OnEnter", cellEnter)
        b:SetScript("OnLeave", hideTip)
        b:SetScript("OnClick", glyphClick)
    end
    b.key = key
    draggable(b)
    cells[key] = b
    return b
end
local function boxFor(cell)
    local b = cell.box
    if b then return b end
    b = Kit.Button(panel, BOX)
    b:SetWidth(BOX)
    b.mark = b:CreateTexture(nil, "OVERLAY")
    b.mark:SetTexture(CHECK)
    b.mark:SetWidth(BOX - 2); b.mark:SetHeight(BOX - 2)
    b.mark:SetPoint("CENTER", b, "CENTER", 0, 0)
    b.tipAnchor = "ANCHOR_TOP"
    cell.box = b
    return b
end
local function fillSpec(b, grey)
    local dom = dominant(active())
    b.dim = grey
    b:SetImage(dom and dom.icon or QMARK, ICON_CROP)
    b.icon:ClearAllPoints()
    b.icon:SetPoint("CENTER", b, "CENTER", 0, 0)
    b.icon:SetWidth(SPEC_ICON); b.icon:SetHeight(SPEC_ICON)
end
local function stylePanel(f)
    if ns.QuickLocked() then
        f:SetBackdrop(nil)
    else
        Kit.StylePanel(f)
    end
end
local function dressCtrl()
    local c = panel.ctrl
    local locked = ns.QuickLocked()
    local v = ns.QuickScale()
    local title = ns.T("quick.scale_tip", math.floor(v * 100 + 0.5))
    c.less.tipTitle, c.more.tipTitle = title, title
    c.less:SetOff(v - ns.QUICK_SCALE_STEP < ns.QUICK_SCALE_MIN - 0.001)
    c.more:SetOff(v + ns.QUICK_SCALE_STEP > ns.QUICK_SCALE_MAX + 0.001)
    c.lock:SetKey(locked and "lock" or "unlock")
    c.lock.tipTitle = ns.T(locked and "quick.unlock" or "quick.lock")
    c.lock.tipBody = ns.T(locked and "quick.unlock_tip" or "quick.lock_tip")
    c.lock.hints = { ns.Hint(locked and "swap_unlock" or "swap_lock") }
    c.less.hints, c.more.hints = { ns.Hint("swap_less") }, { ns.Hint("swap_more") }
    c.settings.tipTitle = ns.T("quick.settings")
    c.settings.hints = { ns.Hint("swap_settings") }
end
local function layout()
    local locked = ns.QuickLocked()
    local grey = combat()
    local circles = ns.QuickCircles(not locked)
    local used = {}
    local x = PAD
    for _, c in ipairs(circles) do
        local b = cellFor(c.key)
        used[b] = true
        b.slot, b.locked = c.slot, c.locked
        if c.key == "spec" then
            fillSpec(b, grey)
        else
            ns.FillGlyphSocket(b.socket, c.slot, grey)
            b.socket.rim:SetAlpha(c.slot.spell and 1 or 0.6)
        end
        b:SetAlpha(c.on and 1 or OFF_ALPHA)
        b:ClearAllPoints()
        b:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", x, PAD)
        b:Show()
        if locked then
            if b.box then b.box:Hide() end
        else
            local box = boxFor(b)
            local circle = c
            box.active, box.off = c.on and true or false, c.locked and true or false
            box.tipTitle = ns.QuickCircleName(c)
            box.tipBody = c.locked and ns.QuickUnlockText(c.key) or nil
            box.hints = { ns.Hint(c.on and "swap_hide" or "swap_show") }
            box.onClick = function()
                ns.QuickSetShow(circle.key, not circle.on)
                GameTooltip:Hide()
                ns.QuickRefresh()
                settingsRefresh()
            end
            if c.on then box.mark:Show() else box.mark:Hide() end
            box:ClearAllPoints()
            box:SetPoint("BOTTOM", b, "TOP", 0, BOX_GAP)
            box:Restyle()
            box:Show()
        end
        x = x + CELL + GAP
    end
    for _, b in pairs(cells) do
        if not used[b] then
            b:Hide()
            if b.box then b.box:Hide() end
        end
    end
    local n = math.max(1, #circles)
    panel:SetWidth(PAD * 2 + n * CELL + (n - 1) * GAP)
    panel:SetHeight(PAD * 2 + CELL + (locked and 0 or (BOX + BOX_GAP)))
    panel:EnableMouse(not locked)
    if not locked then
        panel.hot = true
        panel.ctrl:Show()
    end
    stylePanel(panel)
    dressCtrl()
end
function ns.QuickRefresh()
    if not (panel and panel:IsShown()) then return end
    layout()
    if list and list:IsShown() and list.owner then
        local b = list.owner
        if combat() or not b:IsShown() or b.locked then
            closeList()
        else
            cellEnter(b)
        end
    end
end
function ns.QuickZoom(dir)
    ns.QuickSetScale(ns.QuickScale() + dir * ns.QUICK_SCALE_STEP)
    ns.QuickApply()
    settingsRefresh()
end
function ns.QuickLock(on)
    ns.QuickSetLocked(on)
    closeList()
    ns.QuickApply()
    settingsRefresh()
end
local function ctrlOrb(key, icon, fn)
    local b
    b = Kit.Orb(panel.ctrl, icon, nil, nil, function()
        fn()
        if b.hovered and b:IsShown() then
            local enter = b:GetScript("OnEnter")
            if enter then enter(b) end
        end
    end, CTRL)
    panel.ctrl[key] = b
    return b
end
local function applyScale()
    local v = ns.QuickScale()
    local old = panel.zoom or v
    panel.zoom = v
    if old == v then return end
    local l, b = panel:GetLeft(), panel:GetBottom()
    panel:SetScale(v)
    if l and b then
        local k = old / v
        panel:ClearAllPoints()
        panel:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", l * k, b * k)
        ns.QuickDB().pos = { "BOTTOMLEFT", "BOTTOMLEFT", l * k, b * k }
    end
    closeList()
end
local function hoverStep(self, elapsed)
    self.t = (self.t or 0) + elapsed
    if self.t < HOVER_STEP then return end
    self.t = 0
    if not self.placed then
        self.placed = true
        savePlace()
    end
    local extra = math.max(0, self.ctrl:GetWidth() - self:GetWidth())
    local hot = not ns.QuickLocked() or (self:IsMouseOver(CTRL + CTRL_LIFT + 2, 0, -extra, 0) and true or false)
    if hot ~= self.hot then
        self.hot = hot
        if hot then self.ctrl:Show() else self.ctrl:Hide() end
    end
end
local function create()
    local q = ns.QuickDB()
    panel = CreateFrame("Frame", "HTP_TalentsQuick", UIParent)
    panel:SetWidth(CELL); panel:SetHeight(CELL)
    panel:SetFrameStrata("MEDIUM")
    panel:SetMovable(true)
    panel:SetClampedToScreen(true)
    panel.zoom = ns.QuickScale()
    panel:SetScale(panel.zoom)
    if q.pos then
        panel:SetPoint(q.pos[1], UIParent, q.pos[2], q.pos[3], q.pos[4])
    else
        panel:SetPoint("CENTER", UIParent, "CENTER", 0, -220)
    end
    draggable(panel)
    local ctrl = CreateFrame("Frame", nil, panel)
    ctrl:SetWidth(#CTRL_KEYS * CTRL + (#CTRL_KEYS - 1) * CTRL_GAP)
    ctrl:SetHeight(CTRL)
    ctrl:SetPoint("BOTTOMRIGHT", panel, "TOPRIGHT", 0, CTRL_LIFT)
    ctrl:SetFrameLevel((panel:GetFrameLevel() or 0) + 5)
    ctrl:Hide()
    panel.ctrl = ctrl
    ctrlOrb("less", "minus", function() ns.QuickZoom(-1) end)
    ctrlOrb("more", "plus", function() ns.QuickZoom(1) end)
    ctrlOrb("lock", "unlock", function() ns.QuickLock(not ns.QuickLocked()) end)
    ctrlOrb("settings", "settings", function() ns.OpenOptions() end)
    for i, key in ipairs(CTRL_KEYS) do
        ctrl[key]:SetPoint("LEFT", ctrl, "LEFT", (i - 1) * (CTRL + CTRL_GAP), 0)
    end
    Kit.Track(panel, stylePanel)
    panel:SetScript("OnUpdate", hoverStep)
end
function ns.QuickApply()
    if not ns.QuickShown() then
        closeList()
        if panel then panel:Hide() end
        return
    end
    if not panel then create() end
    applyScale()
    panel:Show()
    layout()
end
function ns.QuickToggle()
    ns.QuickSetShown(not ns.QuickShown())
    ns.QuickApply()
    settingsRefresh()
end
local watch = CreateFrame("Frame")
for _, ev in ipairs({ "PLAYER_LOGIN", "BAG_UPDATE", "PLAYER_LEVEL_UP", "GLYPH_ADDED", "GLYPH_REMOVED", "GLYPH_UPDATED",
                      "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "CHARACTER_POINTS_CHANGED",
                      "EQUIPMENT_SETS_CHANGED" }) do
    watch:RegisterEvent(ev)
end
local function later(self, elapsed)
    self.wait = (self.wait or 0) - elapsed
    if self.wait > 0 then return end
    self:SetScript("OnUpdate", nil)
    ns.QuickRefresh()
end
watch:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        inCombat = InCombatLockdown() and true or false
        ns.QuickApply()
        return
    end
    if event == "BAG_UPDATE" or event == "PLAYER_LEVEL_UP" then
        self.wait = EVENT_DELAY
        self:SetScript("OnUpdate", later)
        return
    end
    if event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
        closeList()
    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false
    end
    ns.QuickRefresh()
end)
