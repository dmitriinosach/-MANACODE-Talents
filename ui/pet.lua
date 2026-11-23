local ADDON, ns = ...
local C = ns.C
local GAP = 12
local CARD_BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}
local CARD_PAD = 10
local NAME_Y = 4
local SUB_Y = 22
local MOOD_Y = 42
local DIET_Y = 60
local DIET_H = 26
local XP_Y = 88
local XP_BAR_Y = 102
local XP_BAR_H = 6
local XP_INSET = 30
local MODEL_Y = 114
local STAT_ROW = 18
local STAT_ROWS = 5
local STAT_TOP = 8
local STATS_H = STAT_TOP + STAT_ROWS * STAT_ROW + 6
local COL_GAP = 18
local MODEL_TURN = 0.61
local MOOD_TEX = "Interface\\PetPaperDollFrame\\UI-PetHappiness"
local MOOD_COORD = {
    { 0.375, 0.5625, 0, 0.359375 },
    { 0.1875, 0.375, 0, 0.359375 },
    { 0, 0.1875, 0, 0.359375 },
}
local MOOD_ICON = 16
local MOOD_GAP = 4
local MOOD_KEYS = { "window.pet_mood1", "window.pet_mood2", "window.pet_mood3" }
local MOOD_TINT = { "negative", "gold", "positive" }
local FILL = "Interface\\Buttons\\WHITE8X8"
local STAT_KEYS = {
    "window.pet_stat1", "window.pet_stat2", "window.pet_stat3", "window.pet_stat4", "window.pet_stat5",
    "window.pet_hp", "window.pet_dmg", "window.pet_ap", "window.pet_speed", "window.pet_armor",
}
local vals, tints = {}, {}
local sigParts = {}
local CARD_EVENTS = {
    "UNIT_HAPPINESS", "UNIT_PET_EXPERIENCE", "UNIT_NAME_UPDATE", "UNIT_LEVEL", "UNIT_STATS", "UNIT_DAMAGE",
    "UNIT_ATTACK_SPEED", "UNIT_ATTACK_POWER", "UNIT_RESISTANCES", "UNIT_MAXHEALTH", "UNIT_MODEL_CHANGED",
}
local view
local function buffTint(pos, neg)
    if (neg or 0) < 0 then return -1 end
    if (pos or 0) > 0 then return 1 end
    return 0
end
local function readStats()
    for i = 1, STAT_ROWS do
        local _, eff, pos, neg = UnitStat("pet", i)
        vals[i], tints[i] = tostring(eff or 0), buffTint(pos, neg)
    end
    vals[6], tints[6] = tostring(UnitHealthMax("pet") or 0), 0
    local lo, hi = UnitDamage("pet")
    vals[7], tints[7] = format("%d - %d", math.max(math.floor(lo or 0), 1), math.max(math.ceil(hi or 0), 1)), 0
    local base, pos, neg = UnitAttackPower("pet")
    vals[8], tints[8] = tostring((base or 0) + (pos or 0) + (neg or 0)), buffTint(pos, neg)
    vals[9], tints[9] = format("%.2f", UnitAttackSpeed("pet") or 0), 0
    local _, armor, _, apos, aneg = UnitArmor("pet")
    vals[10], tints[10] = tostring(armor or 0), buffTint(apos, aneg)
end
local function dietText(...)
    if select("#", ...) == 0 then return nil end
    return ns.T("window.pet_diet", table.concat({ ... }, ", "))
end
local function ensure(host)
    if view then return view end
    local f = CreateFrame("Frame", nil, host)
    f:SetPoint("TOPLEFT", host, "TOPLEFT", 0, 0)
    local card = CreateFrame("Frame", nil, f)
    card:SetBackdrop(CARD_BACKDROP)
    card.name = card:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    card.name:SetPoint("TOP", card, "TOP", 0, -NAME_Y)
    card.sub = card:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    card.sub:SetPoint("TOP", card, "TOP", 0, -SUB_Y)
    card.mood = card:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    card.mood:SetPoint("TOP", card, "TOP", (MOOD_ICON + MOOD_GAP) / 2, -MOOD_Y)
    card.moodIcon = card:CreateTexture(nil, "ARTWORK")
    card.moodIcon:SetTexture(MOOD_TEX)
    card.moodIcon:SetWidth(MOOD_ICON); card.moodIcon:SetHeight(MOOD_ICON)
    card.moodIcon:SetPoint("RIGHT", card.mood, "LEFT", -MOOD_GAP, 0)
    card.diet = card:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    card.diet:SetPoint("TOP", card, "TOP", 0, -DIET_Y)
    card.diet:SetHeight(DIET_H)
    card.diet:SetJustifyH("CENTER"); card.diet:SetJustifyV("TOP")
    card.xp = card:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    card.xp:SetPoint("TOP", card, "TOP", 0, -XP_Y)
    card.xpTrack = card:CreateTexture(nil, "BORDER")
    card.xpTrack:SetTexture(FILL)
    card.xpTrack:SetHeight(XP_BAR_H)
    card.xpTrack:SetPoint("TOP", card, "TOP", 0, -XP_BAR_Y)
    card.xpFill = card:CreateTexture(nil, "ARTWORK")
    card.xpFill:SetTexture(FILL)
    card.xpFill:SetHeight(XP_BAR_H)
    card.xpFill:SetPoint("LEFT", card.xpTrack, "LEFT", 0, 0)
    card.warn = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    card.warn:SetPoint("TOP", card, "TOP", 0, -MODEL_Y - 4)
    card.warn:SetJustifyH("CENTER")
    card.line = card:CreateTexture(nil, "ARTWORK")
    card.line:SetTexture(FILL)
    card.line:SetHeight(1)
    card.line:SetPoint("BOTTOM", card, "BOTTOM", 0, STATS_H)
    card.rows = {}
    for i = 1, #STAT_KEYS do
        card.rows[i] = { label = card:CreateFontString(nil, "ARTWORK", "GameFontHighlight"),
                         value = card:CreateFontString(nil, "ARTWORK", "GameFontHighlight") }
    end
    local ok, model = pcall(CreateFrame, "PlayerModel", nil, card)
    if ok and model then
        model:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, -MODEL_Y)
        model:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -CARD_PAD, STATS_H + 4)
        if model.SetRotation then pcall(model.SetRotation, model, MODEL_TURN) end
        model:SetScript("OnHide", function(self) self.petGuid = nil end)
    else
        model = nil
    end
    view = { frame = f, tree = ns.NewTree(f, ns.TREE_GEOM.pet), card = card, model = model }
    return view
end
local function layout(card, w)
    if card.laidW == w then return end
    card.laidW = w
    local inner = w - 2 * CARD_PAD
    card.diet:SetWidth(inner)
    card.warn:SetWidth(inner)
    card.xpTrack:SetWidth(inner - 2 * XP_INSET)
    card.line:SetWidth(inner)
    local colW = (inner - COL_GAP) / 2
    for i, row in ipairs(card.rows) do
        local x = CARD_PAD + ((i > STAT_ROWS) and (colW + COL_GAP) or 0)
        local y = STATS_H - STAT_TOP - ((i - 1) % STAT_ROWS) * STAT_ROW
        row.label:ClearAllPoints()
        row.label:SetPoint("TOPLEFT", card, "BOTTOMLEFT", x, y)
        row.value:ClearAllPoints()
        row.value:SetPoint("TOPRIGHT", card, "BOTTOMLEFT", x + colW, y)
    end
end
local function fillCard(v, force)
    local card = v.card
    local name = UnitName("pet") or ""
    local family, level = UnitCreatureFamily("pet"), UnitLevel("pet") or 0
    local sub = family or ""
    if level > 0 then
        sub = family and ns.T("window.pet_sub", family, level) or ns.T("window.pet_level", level)
    end
    local mood, dmg = GetPetHappiness()
    local moodText = mood and MOOD_KEYS[mood] and ns.T("window.pet_mood_dmg", ns.T(MOOD_KEYS[mood]), dmg or 100) or nil
    local diet = dietText(GetPetFoodTypes())
    local cur, nxt = GetPetExperience()
    local _, gainsXP = HasPetUI()
    local xpText = gainsXP and (nxt or 0) > 0 and ns.T("window.pet_xp", cur or 0, nxt) or nil
    readStats()
    local guid = UnitGUID("pet")
    sigParts[1], sigParts[2], sigParts[3] = name, sub, moodText or ""
    sigParts[4], sigParts[5], sigParts[6] = diet or "", xpText or "", (guid or "") .. (v.missing and "!" or "") .. (v.cached and "*" or "")
    for i = 1, #STAT_KEYS do sigParts[6 + i] = vals[i] .. ":" .. tints[i] end
    local sig = table.concat(sigParts, "|")
    if not force and sig == card.sig then return end
    card.sig = sig
    local bg, edge, head, text, soft = C.tree.bg, C.tree.border, C.heading, C.text, C.secondary
    card:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
    card:SetBackdropBorderColor(edge[1], edge[2], edge[3], edge[4])
    card.name:SetTextColor(head[1], head[2], head[3])
    card.name:SetText(name)
    card.sub:SetTextColor(text[1], text[2], text[3])
    card.sub:SetText(sub)
    if moodText then
        local mc, coord = C[MOOD_TINT[mood]], MOOD_COORD[mood]
        card.mood:SetText(moodText)
        card.mood:SetTextColor(mc[1], mc[2], mc[3])
        card.moodIcon:SetTexCoord(coord[1], coord[2], coord[3], coord[4])
        card.mood:Show(); card.moodIcon:Show()
    else
        card.mood:Hide(); card.moodIcon:Hide()
    end
    card.diet:SetTextColor(soft[1], soft[2], soft[3])
    card.diet:SetText(diet or "")
    if xpText then
        local track, fill = C.caps.track, C.mode.pet
        card.xp:SetTextColor(soft[1], soft[2], soft[3])
        card.xp:SetText(xpText)
        card.xpTrack:SetVertexColor(track[1], track[2], track[3], track[4])
        card.xpFill:SetVertexColor(fill[1], fill[2], fill[3])
        local part = math.min(1, math.max(0, (cur or 0) / nxt))
        card.xpFill:SetWidth(math.max(1, (card.xpTrack:GetWidth() or 1) * part))
        card.xp:Show(); card.xpTrack:Show(); card.xpFill:Show()
    else
        card.xp:Hide(); card.xpTrack:Hide(); card.xpFill:Hide()
    end
    local wc = v.cached and C.gold or C.alert
    card.warn:SetTextColor(wc[1], wc[2], wc[3])
    card.warn:SetText((v.cached and ns.T("window.pet_cached")) or (v.missing and ns.T("window.pet_nodata")) or "")
    local line, up, down = C.line, C.positive, C.negative
    card.line:SetVertexColor(line[1], line[2], line[3], line[4] or 1)
    for i, row in ipairs(card.rows) do
        local vc = (tints[i] > 0 and up) or (tints[i] < 0 and down) or text
        row.label:SetTextColor(soft[1], soft[2], soft[3])
        row.label:SetText(ns.T(STAT_KEYS[i]))
        row.value:SetTextColor(vc[1], vc[2], vc[3])
        row.value:SetText(vals[i])
    end
    local model = v.model
    if not model or model.petGuid == guid then return end
    model.petGuid = guid
    if guid then
        pcall(model.SetUnit, model, "pet")
    elseif model.ClearModel then
        pcall(model.ClearModel, model)
    end
end
local function onCardEvent(self, event, unit)
    if unit and unit ~= "pet" then return end
    if not view then return end
    if event == "UNIT_MODEL_CHANGED" and view.model then view.model.petGuid = nil end
    view.dirty = true
end
local function onCardUpdate(self)
    if not (view and view.dirty) then return end
    view.dirty = nil
    fillCard(view, false)
end
local function watchPet(f, on)
    for _, ev in ipairs(CARD_EVENTS) do
        if on then f:RegisterEvent(ev) else f:UnregisterEvent(ev) end
    end
end
function ns.PetRender(host, trees, width, border)
    local fresh = view == nil
    local v = ensure(host)
    if fresh then
        v.frame:SetScript("OnEvent", onCardEvent)
        v.frame:SetScript("OnUpdate", onCardUpdate)
        v.frame:SetScript("OnShow", function(self) watchPet(self, true) end)
        v.frame:SetScript("OnHide", function(self) watchPet(self, false) end)
        watchPet(v.frame, true)
    end
    v.frame:Show()
    local h = v.tree:Render(trees.grid, { edit = trees.edit, class = ns.PlayerClass(), border = border })
    local treeW = v.tree.frame:GetWidth()
    v.frame:SetWidth(width)
    v.frame:SetHeight(h)
    v.card:ClearAllPoints()
    v.card:SetPoint("TOPLEFT", v.frame, "TOPLEFT", treeW + GAP, 0)
    v.card:SetWidth(width - treeW - GAP)
    v.card:SetHeight(h)
    layout(v.card, width - treeW - GAP)
    v.missing, v.cached = trees.missing, trees.cached
    v.dirty = nil
    fillCard(v, true)
    return h
end
function ns.PetHide()
    if view then view.frame:Hide() end
end
