local ADDON, ns = ...
local C = ns.C
local function refreshWindow()
    if ns.RefreshWindow then ns.RefreshWindow() end
end
local LIST = {
    { id = "native", sec = "window", name = "HTP_TalentsOptNative",
      label = "options.native", hint = "options.native_hint",
      get = function() return ns.NativeMode() end,
      set = function(on)
          ns.SetNativeMode(on)
          if InCombatLockdown() then ns.warn(ns.T("msg.after_combat")) end
      end },
    { id = "preview", sec = "window", name = "HTP_TalentsOptPreview",
      label = "options.preview", hint = "options.preview_hint",
      get = function() return ns.PreviewEnabled() end,
      set = function(on)
          SetCVar("previewTalents", on and "1" or "0")
          refreshWindow()
      end },
    { id = "follow", sec = "window", name = "HTP_TalentsOptFollow",
      label = "options.follow", hint = "options.follow_hint",
      get = function() return ns.FollowEnabled() end,
      set = function(on)
          HTP_TalentsDB.followTarget = on or nil
          ns.FollowTarget()
      end },
    { id = "murlocs", sec = "window", name = "HTP_TalentsOptMurlocs",
      label = "options.murlocs", hint = "options.murlocs_hint",
      get = function() return not ns.MurlocsEnabled or ns.MurlocsEnabled() end,
      set = function(on) HTP_TalentsDB.murlocs = (not on) and false or nil end },
    { id = "quick", sec = "quick", name = "HTP_TalentsOptQuick",
      label = "options.quick", hint = "options.quick_hint",
      get = function() return ns.QuickShown() end,
      set = function(on)
          ns.QuickSetShown(on)
          ns.QuickApply()
      end },
    { id = "quick_lock", sec = "quick", name = "HTP_TalentsOptQuickLock", sub = true,
      label = "options.quick_lock", hint = "options.quick_lock_hint",
      get = function() return ns.QuickLocked() end,
      set = function(on)
          ns.QuickSetLocked(on)
          ns.QuickApply()
      end },
}
local SECTIONS = {
    { id = "window", title = "options.sec_window", col = 1 },
    { id = "quick", title = "options.sec_quick", col = 2 },
}
LIST[#LIST + 1] = {
    id = "circle", sec = "circle", name = "HTP_TalentsOptCircle",
    label = "options.circle", hint = "options.circle_hint",
    get = function() return HTP_TalentsDB.circleSet3 == true end,
    set = function(on)
        HTP_TalentsDB.circleSet3 = on or nil
        ns.CircleInit()
        refreshWindow()
    end,
}
SECTIONS[#SECTIONS + 1] = { id = "circle", title = "options.circle_sec", col = 2 }
ns.Settings = LIST
function ns.SettingSet(it, on)
    it.set(on and true or false)
    ns.SettingsRefresh()
end
local W = 664
local PAD = 20
local COL_GAP = 28
local COL_W = (W - PAD * 2 - COL_GAP) / 2
local TITLE_H = 44
local SEC_H = 24
local SEC_GAP = 16
local ROW_GAP = 12
local SUB_INDENT = 16
local TOGGLE_W = 34
local LABEL_X = TOGGLE_W + 10
local LINE_GAP = 4
local THEME_H = ns.Kit.H.ctrl
local THEME_GAP = 6
local THEME_COLS = 2
local SWATCH = 8
local SWATCH_H = 12
local SWATCHES = { "background", "control.bg", "main.bg", "heading" }
local SCREEN_MARGIN = 40
local ORB = 20
local CHIP_H = ns.Kit.H.small
local CHIP_GAP = 4
local CHIP_SPEC_W = 46
local CHIP_W = 34
local SIZE_ORB = 18
local WHITE = "Interface\\Buttons\\WHITE8X8"
local win
local ui = { rows = {}, heads = {}, themes = {}, chips = {}, langs = {} }
local function presetColor(preset, path)
    local node = preset
    for part in path:gmatch("[^%.]+") do
        if type(node) ~= "table" then return nil end
        node = node[part]
    end
    return type(node) == "table" and node or nil
end
local function rowAt(i)
    local r = ui.rows[i]
    if r then return r end
    r = { toggle = ns.Kit.Toggle(win) }
    r.label = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    r.label:SetJustifyH("LEFT")
    r.label:SetPoint("LEFT", r.toggle, "RIGHT", LABEL_X - TOGGLE_W, 0)
    r.hint = win:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.hint:SetJustifyH("LEFT"); r.hint:SetJustifyV("TOP")
    r.hint:SetPoint("TOPLEFT", r.toggle, "BOTTOMLEFT", LABEL_X, -LINE_GAP)
    r.hit = CreateFrame("Button", nil, win)
    r.hit:SetPoint("TOPLEFT", r.label, "TOPLEFT", -4, 3)
    r.hit:SetPoint("BOTTOMRIGHT", r.label, "BOTTOMRIGHT", 4, -3)
    r.hit:SetScript("OnClick", function()
        if r.toggle.onClick then r.toggle.onClick(not r.toggle.on) end
    end)
    r.hit:SetScript("OnEnter", function()
        r.toggle.hovered = true
        r.toggle:Restyle()
    end)
    r.hit:SetScript("OnLeave", function()
        r.toggle.hovered = false
        r.toggle:Restyle()
    end)
    ui.rows[i] = r
    return r
end
local function headAt(i)
    local h = ui.heads[i]
    if h then return h end
    h = { text = win:CreateFontString(nil, "OVERLAY", "GameFontNormal"), line = win:CreateTexture(nil, "ARTWORK") }
    h.text:SetJustifyH("LEFT")
    h.line:SetTexture(WHITE)
    h.line:SetHeight(1)
    ui.heads[i] = h
    return h
end
local function placeHead(n, title, x, y)
    local h = headAt(n)
    local hc, l = C.heading, C.line
    h.text:SetText(title)
    h.text:SetTextColor(hc[1], hc[2], hc[3])
    h.text:ClearAllPoints()
    h.text:SetPoint("BOTTOMLEFT", win, "TOPLEFT", x, -(y + SEC_H - 6))
    h.line:SetVertexColor(l[1], l[2], l[3], l[4] or 1)
    h.line:ClearAllPoints()
    h.line:SetPoint("TOPLEFT", win, "TOPLEFT", x, -(y + SEC_H))
    h.line:SetWidth(COL_W)
    h.text:Show(); h.line:Show()
    return y + SEC_H + ROW_GAP
end
local function themeAt(i)
    local b = ui.themes[i]
    if b then return b end
    b = ns.Kit.Button(win, THEME_H)
    b.swatches = {}
    for k = 1, #SWATCHES do
        local t = b:CreateTexture(nil, "ARTWORK")
        t:SetTexture(WHITE)
        t:SetWidth(SWATCH); t:SetHeight(SWATCH_H)
        t:SetPoint("LEFT", b, "LEFT", 8 + (k - 1) * SWATCH, 0)
        b.swatches[k] = t
    end
    b.text:ClearAllPoints()
    b.text:SetPoint("LEFT", b, "LEFT", 8 + #SWATCHES * SWATCH + 6, 0)
    ui.themes[i] = b
    return b
end
local function renderQuick(x, y)
    local tc = C.text
    x = x + SUB_INDENT
    if not ui.circles then
        ui.circles = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ui.circles:SetJustifyH("LEFT")
        ui.size = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ui.size:SetJustifyH("LEFT")
        ui.less = ns.Kit.Orb(win, "minus", nil, nil, function() ns.QuickZoom(-1) end, SIZE_ORB)
        ui.less.hints = { ns.Hint("swap_less") }
        ui.more = ns.Kit.Orb(win, "plus", nil, nil, function() ns.QuickZoom(1) end, SIZE_ORB)
        ui.more.hints = { ns.Hint("swap_more") }
    end
    ui.circles:SetText(ns.T("options.quick_circles"))
    ui.circles:SetTextColor(tc[1], tc[2], tc[3])
    ui.circles:ClearAllPoints()
    ui.circles:SetPoint("TOPLEFT", win, "TOPLEFT", x, -y)
    y = y + ui.circles:GetStringHeight() + LINE_GAP + 2
    local cx, n = x, 0
    for _, c in ipairs(ns.QuickCircles(true)) do
        n = n + 1
        local b = ui.chips[n]
        if not b then
            b = ns.Kit.Button(win, CHIP_H)
            ui.chips[n] = b
        end
        local circle = c
        local spec = c.key == "spec"
        if c.slot and not c.slot.major and c.n == 1 then cx = cx + CHIP_GAP * 2 end
        b.text:SetText(spec and ns.T("quick.chip_spec") or ns.T(c.slot.major and "quick.chip_major" or "quick.chip_minor", c.n))
        b.tipTitle = ns.QuickCircleName(c)
        b.tipBody = c.locked and ns.QuickUnlockText(c.key) or nil
        b.hints = { ns.Hint(c.on and "swap_hide" or "swap_show") }
        b.active, b.off = c.on and true or false, c.locked and true or false
        b.onClick = function()
            ns.QuickSetShow(circle.key, not circle.on)
            ns.QuickApply()
            ns.SettingsRefresh()
        end
        b:SetWidth(spec and CHIP_SPEC_W or CHIP_W)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", win, "TOPLEFT", cx, -y)
        b:Restyle()
        b:Show()
        cx = cx + b:GetWidth() + CHIP_GAP
    end
    for i = n + 1, #ui.chips do ui.chips[i]:Hide() end
    y = y + CHIP_H + ROW_GAP
    local v = ns.QuickScale()
    local sizeText = ns.T("options.quick_size", math.floor(v * 100 + 0.5))
    ui.size:SetText(sizeText)
    ui.size:SetTextColor(tc[1], tc[2], tc[3])
    ui.size:ClearAllPoints()
    ui.size:SetPoint("LEFT", win, "TOPLEFT", x, -(y + SIZE_ORB / 2))
    ui.more:ClearAllPoints()
    ui.more:SetPoint("TOPRIGHT", win, "TOPLEFT", x - SUB_INDENT + COL_W, -y)
    ui.less:ClearAllPoints()
    ui.less:SetPoint("RIGHT", ui.more, "LEFT", -CHIP_GAP, 0)
    ui.less.tipTitle, ui.more.tipTitle = sizeText, sizeText
    ui.less:SetOff(v - ns.QUICK_SCALE_STEP < ns.QUICK_SCALE_MIN - 0.001)
    ui.more:SetOff(v + ns.QUICK_SCALE_STEP > ns.QUICK_SCALE_MAX + 0.001)
    return y + SIZE_ORB + ROW_GAP
end
local function render()
    ns.Kit.Sync()
    local hc, tc, sc = C.heading, C.text, C.secondary
    ui.title:SetText(ns.T("options.title"))
    ui.title:SetTextColor(hc[1], hc[2], hc[3])
    local ys = { TITLE_H, TITLE_H }
    local xs = { PAD, PAD + COL_W + COL_GAP }
    local ri, hi = 0, 0
    for _, sec in ipairs(SECTIONS) do
        local col = sec.col
        local x = xs[col]
        if ys[col] > TITLE_H then ys[col] = ys[col] + SEC_GAP end
        hi = hi + 1
        local y = placeHead(hi, ns.T(sec.title), x, ys[col])
        for _, it in ipairs(LIST) do
            if it.sec == sec.id then
                ri = ri + 1
                local r = rowAt(ri)
                local item = it
                local indent = it.sub and SUB_INDENT or 0
                r.toggle:ClearAllPoints()
                r.toggle:SetPoint("TOPLEFT", win, "TOPLEFT", x + indent, -y)
                r.toggle:SetOn(it.get())
                r.toggle.onClick = function(on) ns.SettingSet(item, on) end
                r.label:SetText(ns.T(it.label))
                r.label:SetTextColor(tc[1], tc[2], tc[3])
                r.hint:SetWidth(COL_W - indent - LABEL_X)
                r.hint:SetText(ns.T(it.hint))
                r.hint:SetTextColor(sc[1], sc[2], sc[3])
                r.toggle:Show(); r.label:Show(); r.hint:Show(); r.hit:Show()
                y = y + r.toggle:GetHeight() + LINE_GAP + r.hint:GetStringHeight() + ROW_GAP
            end
        end
        if sec.id == "quick" then y = renderQuick(x, y) end
        ys[col] = y - ROW_GAP
    end
    for i = ri + 1, #ui.rows do
        local r = ui.rows[i]
        r.toggle:Hide(); r.label:Hide(); r.hint:Hide(); r.hit:Hide()
    end
    local bw = (COL_W - (THEME_COLS - 1) * THEME_GAP) / THEME_COLS
    hi = hi + 1
    local ly = placeHead(hi, ns.T("options.sec_lang"), xs[1], ys[1] + SEC_GAP)
    local lang = ns.LangId()
    for i, id in ipairs(ns.LANG_ORDER) do
        local key = id
        local b = ui.langs[i]
        if not b then
            b = ns.Kit.Button(win, THEME_H)
            ui.langs[i] = b
        end
        local name = ns.LangName(key) or ns.T("options.lang_auto")
        b.text:SetText(name)
        b.tipTitle, b.tipBody = name, key == "auto" and ns.T("options.lang_auto_tip") or nil
        b.active = key == lang
        b.onClick = function() ns.SetLang(key) end
        b:SetWidth(bw)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", win, "TOPLEFT", xs[1] + ((i - 1) % THEME_COLS) * (bw + THEME_GAP),
                   -(ly + math.floor((i - 1) / THEME_COLS) * (THEME_H + THEME_GAP)))
        b:Restyle()
        b:Show()
    end
    ly = ly + math.ceil(#ns.LANG_ORDER / THEME_COLS) * (THEME_H + THEME_GAP)
    ui.langNote:ClearAllPoints()
    ui.langNote:SetPoint("TOPLEFT", win, "TOPLEFT", xs[1], -(ly + 2))
    ui.langNote:SetWidth(COL_W)
    ui.langNote:SetText(ns.T("options.lang_note"))
    ui.langNote:SetTextColor(sc[1], sc[2], sc[3])
    ys[1] = ly + 2 + ui.langNote:GetStringHeight()
    local x = xs[2]
    hi = hi + 1
    local y = placeHead(hi, ns.T("options.sec_theme"), x, ys[2] + SEC_GAP)
    for i = hi + 1, #ui.heads do
        ui.heads[i].text:Hide(); ui.heads[i].line:Hide()
    end
    local cur = ns.ThemeId()
    for i, key in ipairs(ns.THEME_ORDER) do
        local k = key
        local b = themeAt(i)
        b.text:SetText(ns.T("theme." .. k))
        b.tipTitle, b.tipBody = ns.T("theme." .. k), ns.T("theme." .. k .. "_tip")
        b.active = k == cur
        b.onClick = function() ns.SetTheme(k) end
        for n, t in ipairs(b.swatches) do
            local c = presetColor(ns.THEMES[k], SWATCHES[n])
            if c then
                t:SetVertexColor(c[1], c[2], c[3], 1)
                t:Show()
            else
                t:Hide()
            end
        end
        b:SetWidth(bw)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", win, "TOPLEFT", x + ((i - 1) % THEME_COLS) * (bw + THEME_GAP),
                   -(y + math.floor((i - 1) / THEME_COLS) * (THEME_H + THEME_GAP)))
        b:Restyle()
        b:Show()
    end
    y = y + math.ceil(#ns.THEME_ORDER / THEME_COLS) * (THEME_H + THEME_GAP)
    ui.themeNote:ClearAllPoints()
    ui.themeNote:SetPoint("TOPLEFT", win, "TOPLEFT", x, -(y + 2))
    ui.themeNote:SetWidth(COL_W)
    ui.themeNote:SetText(ns.T("options.theme_note"))
    ui.themeNote:SetTextColor(sc[1], sc[2], sc[3])
    ys[2] = y + 2 + ui.themeNote:GetStringHeight()
    local h = math.max(ys[1], ys[2]) + PAD
    win:SetHeight(h)
    local room = (UIParent:GetHeight() or 0) - SCREEN_MARGIN
    win:SetScale((room > 0 and h > room) and (room / h) or 1)
    local v = C.veil
    ui.veilTex:SetVertexColor(v[1], v[2], v[3], v[4] or 1)
end
local function veilShow()
    local main = _G.HTP_TalentsFrame
    if not (main and main:IsShown()) then
        ui.veil:Hide()
        return
    end
    local inset = C.look.window.grainInset or 4
    ui.veil:SetParent(main)
    ui.veil:ClearAllPoints()
    ui.veil:SetPoint("TOPLEFT", main, "TOPLEFT", inset, -inset)
    ui.veil:SetPoint("BOTTOMRIGHT", main, "BOTTOMRIGHT", -inset, inset)
    ui.veil:SetFrameLevel(main:GetFrameLevel() + 60)
    ui.veil:Show()
end
local function create()
    win = CreateFrame("Frame", "HTP_TalentsSettings", UIParent)
    win:SetWidth(W)
    win:SetHeight(400)
    win:SetFrameStrata("DIALOG")
    win:SetToplevel(true)
    win:SetClampedToScreen(true)
    win:EnableMouse(true)
    win:SetMovable(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop", win.StopMovingOrSizing)
    win:Hide()
    tinsert(UISpecialFrames, "HTP_TalentsSettings")
    ui.title = win:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    ui.title:SetPoint("LEFT", win, "TOPLEFT", PAD, -(TITLE_H / 2 + 2))
    local close = ns.Kit.Orb(win, "close", CLOSE, nil, function() win:Hide() end, ORB)
    close:SetPoint("RIGHT", win, "TOPRIGHT", -PAD, -(TITLE_H / 2 + 2))
    ui.themeNote = win:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.themeNote:SetJustifyH("LEFT"); ui.themeNote:SetJustifyV("TOP")
    ui.langNote = win:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.langNote:SetJustifyH("LEFT"); ui.langNote:SetJustifyV("TOP")
    ui.veil = CreateFrame("Button", nil, UIParent)
    ui.veil:EnableMouse(true)
    ui.veilTex = ui.veil:CreateTexture(nil, "BACKGROUND")
    ui.veilTex:SetTexture(WHITE)
    ui.veilTex:SetAllPoints(ui.veil)
    ui.veil:SetScript("OnClick", function() win:Hide() end)
    ui.veil:Hide()
    ns.Kit.Sync()
    ns.Kit.Window(win)
    win:SetScript("OnShow", function()
        render()
        veilShow()
    end)
    win:SetScript("OnHide", function() ui.veil:Hide() end)
end
function ns.OpenSettings()
    if not win then create() end
    if win:IsShown() then
        win:Hide()
        return
    end
    if ns.Kit.FlyHide then ns.Kit.FlyHide() end
    local main = _G.HTP_TalentsFrame
    win:ClearAllPoints()
    if main and main:IsShown() then
        win:SetPoint("CENTER", main, "CENTER", 0, 0)
    else
        win:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    win:Show()
end
function ns.SettingsShown()
    return win ~= nil and win:IsShown()
end
function ns.SettingsRefresh()
    if win and win:IsShown() then render() end
    if ns.OptionsPanelRefresh then ns.OptionsPanelRefresh() end
end
