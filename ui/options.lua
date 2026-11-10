local ADDON, ns = ...
local PAD = 16
local HINT_W = 540
local BTN_W = 220
local CHECK = 26
local panel
local checks = {}
local themeBtn
local function nextTheme()
    local order, cur = ns.THEME_ORDER, ns.ThemeId()
    local idx = 1
    for i, key in ipairs(order) do
        if key == cur then idx = i end
    end
    ns.SetTheme(order[idx % #order + 1])
end
local function refresh()
    for _, c in ipairs(checks) do c.check:SetChecked(c.item.get()) end
    themeBtn:SetText(ns.T("options.theme_btn", ns.T("theme." .. ns.ThemeId())))
end
local function option(it, anchor, dy)
    local c = CreateFrame("CheckButton", it.name, panel, "UICheckButtonTemplate")
    c:SetWidth(CHECK); c:SetHeight(CHECK)
    c:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", anchor == panel.title and -2 or -30, dy)
    c:SetScript("OnClick", function(self) ns.SettingSet(it, self:GetChecked() and true or false) end)
    local hint = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", c, "BOTTOMLEFT", 30, -2)
    hint:SetWidth(HINT_W)
    hint:SetJustifyH("LEFT")
    hint:SetJustifyV("TOP")
    checks[#checks + 1] = { item = it, check = c, hint = hint }
    return hint
end
local function button(anchor, dy, name)
    local b = CreateFrame("Button", name, panel, "UIPanelButtonTemplate")
    b:SetWidth(BTN_W); b:SetHeight(22)
    b:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, dy)
    return b
end
local function relabel()
    panel.name = ns.T("options.name")
    panel.title:SetText(ns.T("options.name"))
    for _, c in ipairs(checks) do
        local text = _G[c.item.name .. "Text"]
        if text then text:SetText(ns.T(c.item.label)) end
        c.hint:SetText(ns.T(c.item.hint))
    end
    panel.theme:SetText(ns.T("options.theme"))
    panel.settings:SetText(ns.T("options.open_settings"))
    panel.open:SetText(ns.T("options.open"))
    panel.note:SetText(ns.T("options.panel_note"))
    refresh()
end
local function build()
    panel = CreateFrame("Frame", "HTP_TalentsOptions", UIParent)
    panel:Hide()
    panel.title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    panel.title:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD, -PAD)
    local hint = panel.title
    local sec
    for _, it in ipairs(ns.Settings) do
        local dy = (hint == panel.title and -10) or (it.sub and -4) or (it.sec ~= sec and -10) or -8
        hint = option(it, hint, dy)
        sec = it.sec
    end
    local theme = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    theme:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", -30, -14)
    theme:SetWidth(HINT_W + 30)
    theme:SetJustifyH("LEFT")
    panel.theme = theme
    themeBtn = button(theme, -6, "HTP_TalentsOptTheme")
    themeBtn:SetScript("OnClick", function()
        nextTheme()
        refresh()
    end)
    themeBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(ns.T("theme." .. ns.ThemeId()), 1, 1, 1)
        GameTooltip:AddLine(ns.T("theme." .. ns.ThemeId() .. "_tip"), nil, nil, nil, true)
        ns.Kit.TipHints(GameTooltip, { ns.Hint("theme_next") })
        GameTooltip:Show()
    end)
    themeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    local settings = button(themeBtn, -12)
    settings:SetScript("OnClick", function()
        if InterfaceOptionsFrame then InterfaceOptionsFrame:Hide() end
        if not ns.SettingsShown() then ns.OpenSettings() end
    end)
    local open = button(settings, 0)
    open:ClearAllPoints()
    open:SetPoint("LEFT", settings, "RIGHT", 8, 0)
    local note = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", settings, "BOTTOMLEFT", 0, -6)
    note:SetWidth(HINT_W + 30)
    note:SetJustifyH("LEFT")
    panel.settings, panel.open, panel.note = settings, open, note
    open:SetScript("OnClick", function()
        if InterfaceOptionsFrame then InterfaceOptionsFrame:Hide() end
        ns.OpenWindow()
    end)
    relabel()
    panel.refresh = refresh
    panel:SetScript("OnShow", refresh)
    InterfaceOptions_AddCategory(panel)
    ns.OnLocale(function()
        relabel()
        if InterfaceAddOnsList_Update then InterfaceAddOnsList_Update() end
    end)
end
function ns.OptionsPanelRefresh()
    if panel and panel:IsShown() then refresh() end
end
function ns.OpenInterfaceOptions()
    if not panel then build() end
    InterfaceOptionsFrame_OpenToCategory(panel)
end
function ns.OpenOptions()
    if not ns.SettingsShown() then ns.OpenSettings() end
end
local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function() if not panel then build() end end)
