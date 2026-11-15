local ADDON, ns = ...
local C = ns.C
local WHITE = "Interface\\Buttons\\WHITE8X8"
local CLASS_TEX = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
local ICON_CROP = { 0.08, 0.92, 0.08, 0.92 }
local W = 520
local PAD = 20
local GAP = 10
local BTN_GAP = 6
local BTN_PAD = 12
local ICON = 14
local ICON_GAP = 5
local ORB = 20
local FIELD_H = 24
local KEY_W = 46
local CARD_GAP = 10
local CARD_IN = 10
local CHAR = 16
local RELEASE = "https://github.com/dmitriinosach/-MANACODE-Talents/releases"
local CURSE = "https://www.curseforge.com/projects/1796018"
local DISCORD = "https://discord.gg/CYnxS6R9qY"
local SITE = "https://wow-addons.manacode.su"
local ICONS = {
    release = "Interface\\Icons\\INV_Crate_02",
    tool = "Interface\\Icons\\INV_Gizmo_02",
    discord = "Interface\\Icons\\INV_Misc_GroupLooking",
    site = "Interface\\Icons\\INV_Misc_Map_01",
    mirror = "Interface\\Icons\\INV_Misc_Book_09",
}
local CHARS = {
    { name = "Futex", class = "PRIEST" },
    { name = "Syncpool", class = "PALADIN" },
    { name = "Alonaboreals", class = "MAGE", coauthor = true },
}
local OTHERS = {
    { folder = "ManaCode_RaidHelper", url = "https://github.com/dmitriinosach/-MANACODE-RaidHelper",
      name = "Raid Helper",
      desc = { ruRU = "Разбор рейда по боевому логу: сводка, смерти с причинами, таймлайн, угроза, реплей",
               enUS = "Raid review from the combat log: summary, deaths with causes, timeline, threat, replay",
               esES = "Análisis de la banda por el registro de combate: resumen, muertes con causas, cronología, amenaza, repetición" } },
    { folder = "ManaCode_RaidWaitingArcade", url = "https://github.com/dmitriinosach/-MANACODE-RaidWaitingArcade",
      name = "Raid Waiting Arcade",
      desc = { ruRU = "Мини-игры, пока собирается рейд", enUS = "Mini-games while the raid gathers",
               esES = "Minijuegos mientras se reúne la banda" } },
    { folder = "ManaCode_LazyBuffBar", url = "https://github.com/dmitriinosach/-MANACODE-LazyBuffBar",
      name = "LazyBuffBar",
      desc = { ruRU = "Панель бафов: что держать классу и спеку, проки, кулдауны",
               enUS = "Buff bar: what your class and spec should keep up, procs, cooldowns",
               esES = "Barra de buffs: qué debe mantener tu clase y especialización, procs, tiempos de reutilización" } },
    { folder = "ManaCode_Vendor", url = "https://github.com/dmitriinosach/-MANACODE-Vendor",
      name = "Vendor",
      desc = { ruRU = "Окно торговца: весь товар одним списком, покупка пачкой, обмен валют",
               enUS = "Vendor window: all goods in one list, bulk buying, currency exchange",
               esES = "Ventana de mercader: todos los artículos en una lista, compra por lotes, cambio de monedas" } },
    { folder = "ManaCode_AuctionScan", url = "https://github.com/dmitriinosach/-MANACODE-MarketBasedAuction",
      name = "Market Based Auction",
      desc = { ruRU = "Рынок аукциона: цены, крафты, реагенты, распыление, покупка и продажа",
               enUS = "Auction market: prices, crafting, reagents, disenchanting, buying and selling",
               esES = "Mercado de subastas: precios, fabricación, componentes, desencantamiento, compra y venta" } },
}
local TOOL, SERVER
TOOL = "https://github.com/dmitriinosach/-MANACODE-Update/releases"
SERVER = "about.circle_server"
table.insert(OTHERS, 2, { folder = "Manacode_PlayerRaidsInfo", url = "https://github.com/dmitriinosach/-MANACODE-PlayerRaidsInfo",
    name = "Player Raids Info",
    desc = { ruRU = "Дополнение по данным к Raid Helper: статистика рейдов игроков",
             enUS = "Data add-on for Raid Helper: player raid stats",
             esES = "Complemento de datos para Raid Helper: estadísticas de banda de los jugadores" } })
local win
local ui = {}
local function loc(t)
    return t[ns.CurrentLocale()] or t.enUS or t.ruRU or ""
end
local function site()
    return SITE .. (ns.CurrentLocale() == "ruRU" and "/" or "/en/")
end
local function installed(folder)
    if not GetAddOnInfo then return false end
    local _, _, _, _, _, reason = GetAddOnInfo(folder)
    return reason ~= "MISSING"
end
local function text(font)
    local fs = win:CreateFontString(nil, "OVERLAY", font)
    fs:SetJustifyH("LEFT")
    return fs
end
local function paint(tex, c)
    tex:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
end
local function pick(link, focus)
    ui.pick = link
    ui.field.url = link.url
    ui.field:SetText(link.url)
    ui.field:SetCursorPosition(0)
    for _, l in ipairs(ui.links) do
        l.button.active = l == link
        l.button:Restyle()
    end
    if focus then ui.field:SetFocus() end
end
local function labelLink(link)
    local b = link.button
    if link.labelKey then link.label = ns.T(link.labelKey) end
    if link.id == "site" then link.url = site() end
    b.text:SetText(link.label)
    local tip = link.tipKey and ns.T(link.tipKey)
    b.tipTitle, b.tipBody = link.label, tip and (tip .. "\n" .. link.url) or link.url
end
local function addLink(id, labelKey, label, url, tipKey, icon)
    if not url or url == "" then return end
    local b = ns.Kit.Button(win)
    b.icon = b:CreateTexture(nil, "OVERLAY")
    b.icon:SetTexture(icon)
    b.icon:SetTexCoord(ICON_CROP[1], ICON_CROP[2], ICON_CROP[3], ICON_CROP[4])
    b.icon:SetWidth(ICON); b.icon:SetHeight(ICON)
    b.icon:SetPoint("RIGHT", b.text, "LEFT", -ICON_GAP, 0)
    b.text:ClearAllPoints()
    b.text:SetPoint("CENTER", b, "CENTER", (ICON + ICON_GAP) / 2, 0)
    local link = { id = id, labelKey = labelKey, label = label, url = url, tipKey = tipKey, button = b }
    labelLink(link)
    b.onClick = function() pick(link, true) end
    ui.links[#ui.links + 1] = link
end
local function makeField()
    local e = CreateFrame("EditBox", nil, win)
    e:SetAutoFocus(false)
    e:SetFontObject(GameFontHighlightSmall)
    e:SetHeight(FIELD_H)
    e:SetTextInsets(8, KEY_W, 3, 3)
    e:SetBackdrop(ns.Kit.ROUND)
    e:SetScript("OnTextChanged", function(self)
        if self.url and self:GetText() ~= self.url then self:SetText(self.url) end
    end)
    e:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    e:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0, 0)
        self:SetCursorPosition(0)
    end)
    e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    e:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    e.key = e:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    e.key:SetPoint("RIGHT", e, "RIGHT", -8, 0)
    return e
end
local function makeTile(o)
    local b = ns.Kit.Button(win)
    b.text:ClearAllPoints()
    b.text:SetPoint("TOPLEFT", b, "TOPLEFT", CARD_IN, -CARD_IN)
    b.text:SetJustifyH("LEFT")
    b.text:SetText(o.name)
    b.state = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.state:SetPoint("TOPRIGHT", b, "TOPRIGHT", -CARD_IN, -CARD_IN)
    b.desc = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.desc:SetJustifyH("LEFT"); b.desc:SetJustifyV("TOP")
    b.desc:SetPoint("TOPLEFT", b, "TOPLEFT", CARD_IN, -(CARD_IN + 16))
    local link = { id = o.folder or o.name, label = o.name, url = o.url, button = b }
    b.tipTitle, b.tipBody = o.name, o.url
    b.onClick = function() pick(link, true) end
    b.other = o
    ui.links[#ui.links + 1] = link
    return b
end
local function build()
    win = CreateFrame("Frame", "HTP_TalentsAbout", UIParent)
    win:SetWidth(W)
    win:SetFrameStrata("FULLSCREEN_DIALOG")
    win:SetToplevel(true)
    win:SetClampedToScreen(true)
    win:EnableMouse(true)
    win:SetMovable(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop", win.StopMovingOrSizing)
    win:Hide()
    tinsert(UISpecialFrames, "HTP_TalentsAbout")
    ui.links, ui.tiles, ui.chars = {}, {}, {}
    ui.close = ns.Kit.Orb(win, "close", CLOSE, nil, function() win:Hide() end, ORB)
    ui.close:SetPoint("TOPRIGHT", win, "TOPRIGHT", -12, -12)
    ui.title = text("GameFontNormalHuge")
    ui.ver = text("GameFontHighlightSmall")
    ui.line1 = text("GameFontHighlight")
    ui.line2 = text("GameFontHighlightSmall")
    ui.cmds = text("GameFontHighlightSmall")
    ui.rule = win:CreateTexture(nil, "ARTWORK")
    ui.rule:SetTexture(WHITE)
    ui.rule:SetHeight(1)
    addLink("release", "about.release", nil, RELEASE, "about.tip_release", ICONS.release)
    addLink("tool", "about.tool", nil, TOOL, "about.tip_tool", ICONS.tool)
    addLink("discord", nil, "Discord", DISCORD, "about.tip_discord", ICONS.discord)
    addLink("site", "about.site", nil, site(), "about.tip_site", ICONS.site)
    addLink("curse", nil, "CurseForge", CURSE, "about.tip_curse", ICONS.mirror)
    ui.field = makeField()
    ui.othersHead = text("GameFontNormal")
    for i, o in ipairs(OTHERS) do ui.tiles[i] = makeTile(o) end
    ui.foot = win:CreateTexture(nil, "BORDER")
    ui.foot:SetTexture(WHITE)
    ui.footLine = win:CreateTexture(nil, "ARTWORK")
    ui.footLine:SetTexture(WHITE)
    ui.footLine:SetHeight(1)
    ui.charsHead = text("GameFontHighlightSmall")
    ui.coHead = text("GameFontHighlightSmall")
    for i, c in ipairs(CHARS) do
        local hit = CreateFrame("Frame", nil, win)
        hit:EnableMouse(true)
        local icon = hit:CreateTexture(nil, "OVERLAY")
        icon:SetTexture(CLASS_TEX)
        local tc = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[c.class]
        if tc then icon:SetTexCoord(tc[1], tc[2], tc[3], tc[4]) end
        icon:SetWidth(CHAR); icon:SetHeight(CHAR)
        icon:SetPoint("LEFT", hit, "LEFT", 0, 0)
        local fs = hit:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        fs:SetPoint("LEFT", icon, "RIGHT", 4, 0)
        fs:SetText(c.name)
        local cc = ns.ClassColor(c.class)
        fs:SetTextColor(cc[1], cc[2], cc[3])
        hit:SetHeight(CHAR)
        hit:SetWidth(CHAR + 4 + fs:GetStringWidth())
        if c.coauthor then
            hit:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:AddLine(c.name, cc[1], cc[2], cc[3])
                GameTooltip:AddLine(ns.T("about.coauthor_tip"), 1, 1, 1, true)
                GameTooltip:Show()
            end)
            hit:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end
        ui.chars[i] = { frame = hit, text = fs, def = c }
    end
    if SERVER then ui.server = text("GameFontHighlightSmall") end
    ns.Kit.Sync()
    ns.Kit.Window(win)
end
local function linkRows(y)
    local room = W - PAD * 2
    local buttons, want = {}, {}
    for _, l in ipairs(ui.links) do
        if not l.button.other then
            labelLink(l)
            local b = l.button
            b:SetHeight(ns.Kit.H.ctrl + 2)
            buttons[#buttons + 1] = b
            want[#buttons] = math.ceil(b.text:GetStringWidth()) + ICON + ICON_GAP + BTN_PAD * 2
        end
    end
    local i, n = 1, #buttons
    while i <= n do
        local k, used = i, want[i]
        while k < n and used + BTN_GAP + want[k + 1] <= room do
            k = k + 1
            used = used + BTN_GAP + want[k]
        end
        local extra = (room - used) / (k - i + 1)
        local x = PAD
        for j = i, k do
            local b = buttons[j]
            local bw = math.floor(want[j] + extra)
            if j == k then bw = PAD + room - x end
            b:SetWidth(bw)
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", win, "TOPLEFT", x, -y)
            x = x + bw + BTN_GAP
        end
        y = y + buttons[i]:GetHeight() + BTN_GAP
        i = k + 1
    end
    local e = ui.field
    local f, ed = C.field, C.edge
    e:SetBackdropColor(f[1], f[2], f[3], f[4] or 1)
    e:SetBackdropBorderColor(ed[1], ed[2], ed[3], ed[4] or 1)
    e.key:SetText(ns.T("about.copy"))
    local s = C.secondary
    e.key:SetTextColor(s[1], s[2], s[3])
    e:SetWidth(room)
    e:ClearAllPoints()
    e:SetPoint("TOPLEFT", win, "TOPLEFT", PAD, -(y + 2))
    return y + 2 + FIELD_H + GAP * 2
end
local function tiles(y)
    local h = C.heading
    ui.othersHead:SetText(ns.T("about.others"))
    ui.othersHead:SetTextColor(h[1], h[2], h[3])
    ui.othersHead:ClearAllPoints()
    ui.othersHead:SetPoint("TOPLEFT", win, "TOPLEFT", PAD, -y)
    y = y + 18 + GAP - 2
    local cardW = math.floor((W - PAD * 2 - CARD_GAP) / 2)
    local descH = 0
    for _, b in ipairs(ui.tiles) do
        b.desc:SetWidth(cardW - CARD_IN * 2)
        b.desc:SetText(loc(b.other.desc))
        descH = math.max(descH, b.desc:GetStringHeight())
    end
    local cardH = math.ceil(CARD_IN + 16 + descH + CARD_IN)
    local pos, s = C.positive, C.secondary
    for i, b in ipairs(ui.tiles) do
        local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
        b:SetWidth(cardW)
        b:SetHeight(cardH)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", win, "TOPLEFT", PAD + col * (cardW + CARD_GAP), -(y + row * (cardH + CARD_GAP)))
        local folder = b.other.folder
        local on = folder and installed(folder)
        b.state:SetText(folder and ns.T(on and "about.addon_on" or "about.addon_off") or "")
        local c = on and pos or s
        b.state:SetTextColor(c[1], c[2], c[3])
        b.desc:SetTextColor(s[1], s[2], s[3])
    end
    return y + math.ceil(#ui.tiles / 2) * (cardH + CARD_GAP) - CARD_GAP + GAP * 2
end
local function footer(y)
    local bg, l, s = C.field, C.line, C.secondary
    ui.foot:ClearAllPoints()
    ui.foot:SetPoint("TOPLEFT", win, "TOPLEFT", 5, -y)
    ui.foot:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -5, 5)
    paint(ui.foot, bg)
    ui.footLine:ClearAllPoints()
    ui.footLine:SetPoint("TOPLEFT", ui.foot, "TOPLEFT", 0, 0)
    ui.footLine:SetPoint("TOPRIGHT", ui.foot, "TOPRIGHT", 0, 0)
    paint(ui.footLine, l)
    local mid = y + GAP + 2 + CHAR / 2
    local x = PAD
    local function head(fs, key)
        fs:SetText(ns.T(key))
        fs:SetTextColor(s[1], s[2], s[3])
        fs:ClearAllPoints()
        fs:SetPoint("LEFT", win, "TOPLEFT", x, -mid)
        x = x + math.ceil(fs:GetStringWidth()) + 8
    end
    head(ui.charsHead, "about.chars")
    for _, ch in ipairs(ui.chars) do
        if ch.def.coauthor then
            x = x + 6
            head(ui.coHead, "about.coauthor")
        end
        ch.frame:ClearAllPoints()
        ch.frame:SetPoint("LEFT", win, "TOPLEFT", x, -mid)
        x = x + ch.frame:GetWidth() + 12
    end
    local bottom = mid + CHAR / 2
    if ui.server then
        ui.server:SetText(ns.T(SERVER))
        ui.server:SetTextColor(s[1], s[2], s[3])
        ui.server:ClearAllPoints()
        ui.server:SetPoint("TOPLEFT", win, "TOPLEFT", PAD, -(bottom + 6))
        bottom = bottom + 6 + ui.server:GetStringHeight()
    end
    return bottom + GAP + 4
end
local function layout()
    local h, t, s = C.heading, C.text, C.secondary
    local w = W - PAD * 2
    local y = PAD - 2
    ui.title:SetText(ns.T("about.title"))
    ui.title:SetTextColor(h[1], h[2], h[3])
    ui.title:ClearAllPoints()
    ui.title:SetPoint("TOPLEFT", win, "TOPLEFT", PAD, -y)
    y = y + 26
    ui.ver:SetText(ns.T("about.ver", GetAddOnMetadata and GetAddOnMetadata(ADDON, "Version") or "?"))
    ui.ver:SetTextColor(s[1], s[2], s[3])
    ui.ver:ClearAllPoints()
    ui.ver:SetPoint("TOPLEFT", win, "TOPLEFT", PAD, -y)
    y = y + ui.ver:GetStringHeight() + GAP + 2
    for _, row in ipairs({ { ui.line1, "about.line1", t }, { ui.line2, "about.line2", s }, { ui.cmds, "about.cmds", s } }) do
        local fs = row[1]
        fs:SetWidth(w)
        fs:SetText(ns.T(row[2]))
        fs:SetTextColor(row[3][1], row[3][2], row[3][3])
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", win, "TOPLEFT", PAD, -y)
        y = y + fs:GetStringHeight() + 4
    end
    y = y + GAP
    paint(ui.rule, C.line)
    ui.rule:ClearAllPoints()
    ui.rule:SetPoint("TOPLEFT", win, "TOPLEFT", PAD, -y)
    ui.rule:SetWidth(w)
    y = y + 1 + GAP + 4
    y = linkRows(y)
    y = tiles(y)
    win:SetHeight(footer(y))
end
function ns.ShowAbout(anchor)
    if not win then build() end
    if win:IsShown() then
        win:Hide()
        return
    end
    GameTooltip:Hide()
    if ns.Kit.FlyHide then ns.Kit.FlyHide() end
    local main = _G.HTP_TalentsFrame
    win:ClearAllPoints()
    win:SetPoint("CENTER", (main and main:IsShown()) and main or UIParent, "CENTER", 0, 0)
    layout()
    pick(ui.links[1])
    win:Show()
end
