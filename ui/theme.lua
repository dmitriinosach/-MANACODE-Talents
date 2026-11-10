local ADDON, ns = ...
local WHITE     = "Interface\\Buttons\\WHITE8X8"
local TIP_BG    = "Interface\\Tooltips\\UI-Tooltip-Background"
local TIP_EDGE  = "Interface\\Tooltips\\UI-Tooltip-Border"
local DLG_EDGE  = "Interface\\DialogFrame\\UI-DialogBox-Border"
local DLG_GOLD  = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border"
local DLG_DARK  = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark"
local ACH_BG    = "Interface\\AchievementFrame\\UI-Achievement-AchievementBackground"
local PARCHMENT = "Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal"
local DLG_INSET = { left = 11, right = 12, top = 12, bottom = 11 }
ns.QMARK = "Interface\\Icons\\INV_Misc_QuestionMark"
function ns.ClassColor(token)
    local pal = _G.CUSTOM_CLASS_COLORS or _G.RAID_CLASS_COLORS
    local c = token and pal and pal[token]
    if not c then return { 1, 1, 1 } end
    return { c.r, c.g, c.b }
end
local function copy(src)
    if type(src) ~= "table" then return src end
    local out = {}
    for k, v in pairs(src) do out[k] = copy(v) end
    return out
end
local function merge(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" and type(dst[k]) == "table" and v[1] == nil and k ~= "backdrop" then
            merge(dst[k], v)
        else
            dst[k] = copy(v)
        end
    end
    return dst
end
local BASE = {
    look = {
        window = {
            backdrop = { bgFile = PARCHMENT, edgeFile = DLG_GOLD, tile = false, edgeSize = 32, insets = DLG_INSET },
            edge = { 1, 1, 1, 1 },
            grainInset = 11,
        },
        panel = {
            backdrop = {
                bgFile = TIP_BG, edgeFile = DLG_EDGE, tile = true, tileSize = 16, edgeSize = 14,
                insets = { left = 4, right = 4, top = 4, bottom = 4 },
            },
            edge = { 1, 1, 1, 1 },
            alpha = 0.92,
        },
        card = { edgeFile = TIP_EDGE, edgeSize = 12 },
        grain = {},
    },
    background = { 0.72, 0.64, 0.5, 1 },
    panel      = { 0, 0, 0, 0.6 },
    card       = { 1, 1, 1, 0.06 },
    field      = { 0, 0, 0, 0.45 },
    edge       = { 0.72, 0.60, 0.38, 0.7 },
    line       = { 1, 1, 1, 0.15 },
    hover      = { 1, 1, 1, 0.06 },
    selected   = { 1, 0.82, 0, 0.14 },
    text       = { 1, 1, 1 },
    heading    = { 1, 0.82, 0 },
    secondary  = { 1, 0.78, 0.498 },
    off        = { 0.5, 0.5, 0.5 },
    gold       = { 1, 0.82, 0 },
    accent     = { 1, 0.80, 0.30 },
    positive   = { 0.2, 1, 0.2 },
    negative   = { 1, 0.3, 0.3 },
    alert      = { 1, 0.125, 0.125 },
    keycap     = { face = { 0.78, 0.70, 0.55 }, side = { 0.33, 0.28, 0.20 }, text = { 0.10, 0.08, 0.05 },
                   action = { 0.86, 0.86, 0.86 } },
    spell      = { 0.44, 0.84, 1 },
    glyph = {
        name = { 1, 0.82, 0 }, major = { 1, 0.62, 0.22 }, minor = { 0.56, 0.78, 1 },
        text = { 1, 1, 1 }, sub = { 0.88, 0.80, 0.64 }, paper = { 0.46, 0.40, 0.33, 1 },
    },
    none       = { 0, 0, 0, 0 },
    veil       = { 0, 0, 0, 0.55 },
    plain      = { 1, 1, 1, 1 },
    shade      = { 0, 0, 0, 0.85 },
    slotEmpty  = { 0.04, 0.04, 0.04, 1 },
    boom = {
        flash = { 1, 0.82, 0.55, 0.7 }, ring = { 1, 0.6, 0.2, 1 }, spark = { 1, 0.15, 0.1, 1 }, sand = { 0.80, 0.68, 0.45, 1 },
    },
    control = {
        bg = { 0, 0, 0, 0.7 }, hover = { 0, 0, 0, 0.45 }, on = { 0.088, 0.288, 0.128, 0.95 }, off = { 0, 0, 0, 0.75 },
        edge = { 1, 0.82, 0, 0.65 }, edgeLit = { 1, 0.82, 0, 1 }, edgeOff = { 0.45, 0.45, 0.45, 0.6 },
        text = { 1, 1, 1 }, textLit = { 1, 1, 1 }, textOff = { 0.45, 0.45, 0.45 },
    },
    main = {
        bg = { 0.40, 0.30, 0.08, 1 }, hover = { 0.50, 0.38, 0.11, 1 }, down = { 0.30, 0.22, 0.05, 1 },
        edge = { 0.88, 0.72, 0.24, 1 }, text = { 1, 0.82, 0 }, fill = { 1, 0.82, 0.25, 0.42 },
    },
    quiet = {
        bg = { 1, 0.9, 0.7, 0.05 }, hover = { 1, 0.9, 0.7, 0.11 }, down = { 0, 0, 0, 0.25 },
        edge = { 0.46, 0.40, 0.30, 1 }, text = { 0.7, 0.66, 0.58 },
    },
    tab = { edge = { 1, 0.82, 0, 1 }, pressed = { 1, 0.82, 0.30, 0.18 }, underline = { 1, 0.82, 0.25, 1 } },
    bar = { bg = { 0.05, 0.06, 0.05, 0.85 }, edge = { 1, 0.675, 0.125, 1 } },
    grip = { idle = { 1, 0.80, 0.30 }, lit = { 1, 0.93, 0.62 }, press = { 0.78, 0.58, 0.18 }, glow = { 1, 0.93, 0.62, 0.35 } },
    cast = { 1, 0.93, 0.62 },
    mode = {
        set = { 1, 0.82, 0 }, builder = { 0.4, 0.85, 1 }, target = { 0.78, 0.55, 1 },
        compare = { 0.45, 0.9, 0.55 }, none = { 0.86, 0.80, 0.64 },
    },
    cmp = { { 0.35, 0.7, 1 }, { 1, 0.45, 0.8 } },
    marks = { done = { 0.1, 1, 0.1 }, short = { 1, 0.82, 0 }, over = { 1, 0.2, 0.2 } },
    tree = {
        bg = { 0.12, 0.10, 0.08, 0.92 }, border = { 0.5, 0.44, 0.28, 0.7 },
        rank = { 0.1, 1, 0.1 }, rankMax = { 1, 0.82, 0 }, preview = { 0.4, 0.85, 1 },
        slot = { 0.5, 0.5, 0.5 }, art = { 0.65, 0.65, 0.65, 1 }, artBg = { 0, 0, 0, 1 },
        badgeEdge = { 1, 0.82, 0, 0.9 },
    },
    rows = { head = { 0.85, 0.68, 0.3, 0.18 }, odd = { 0, 0, 0, 0.18 }, lit = { 1, 0.82, 0, 0.22 } },
    native = { sepDark = { 0, 0, 0, 0.9 }, sepLight = { 0.55, 0.47, 0.30, 0.9 } },
}
local TRADE = {
    text = { 0.96, 0.93, 0.87 }, heading = { 0.96, 0.93, 0.87 }, secondary = { 0.74, 0.68, 0.58 }, off = { 0.52, 0.47, 0.40 },
    gold = { 1, 0.82, 0 }, accent = { 0.95, 0.78, 0.28 }, positive = { 0.40, 0.82, 0.48 }, negative = { 1, 0.52, 0.44 },
    background = { 0.135, 0.115, 0.09, 1 }, panel = { 0.185, 0.16, 0.125, 1 }, card = { 0.235, 0.205, 0.165, 1 },
    field = { 0.075, 0.065, 0.05, 1 }, edge = { 0.46, 0.40, 0.30, 1 }, line = { 1, 0.90, 0.70, 0.12 },
    hover = { 1, 0.90, 0.70, 0.10 }, selected = { 1, 0.82, 0.30, 0.10 },
    control = { bg = { 0.32, 0.275, 0.215, 1 }, hover = { 0.40, 0.345, 0.27, 1 }, down = { 0.24, 0.205, 0.16, 1 },
        edge = { 0.60, 0.52, 0.40, 1 }, text = { 0.96, 0.93, 0.87 } },
    main = { bg = { 0.40, 0.30, 0.08, 1 }, hover = { 0.50, 0.38, 0.11, 1 }, down = { 0.30, 0.22, 0.05, 1 },
        edge = { 0.88, 0.72, 0.24, 1 }, text = { 1, 0.82, 0 } },
    quiet = { bg = { 1, 0.90, 0.70, 0.05 }, hover = { 1, 0.90, 0.70, 0.11 }, down = { 0, 0, 0, 0.25 },
        edge = { 0.46, 0.40, 0.30, 1 }, text = { 0.88, 0.84, 0.76 } },
    chosen = { bg = { 0.46, 0.40, 0.31, 1 }, edge = { 0.70, 0.61, 0.47, 1 }, text = { 1, 1, 1 } },
}
local SLATE = {
    background = { 0.105, 0.125, 0.155, 1 }, panel = { 0.145, 0.17, 0.205, 1 }, card = { 0.19, 0.215, 0.25, 1 },
    field = { 0.07, 0.08, 0.1, 1 }, hover = { 0.8, 0.88, 1, 0.09 }, selected = { 1, 0.82, 0.30, 0.10 },
    edge = { 0.4, 0.46, 0.54, 1 }, line = { 0.8, 0.88, 1, 0.12 },
    text = { 0.93, 0.95, 0.98 }, heading = { 0.93, 0.95, 0.98 }, secondary = { 0.7, 0.75, 0.82 }, off = { 0.48, 0.52, 0.58 },
    gold = { 1, 0.82, 0 }, accent = { 0.96, 0.78, 0.3 }, positive = { 0.45, 0.85, 0.52 }, negative = { 1, 0.54, 0.46 },
    control = { bg = { 0.25, 0.29, 0.35, 1 }, hover = { 0.31, 0.36, 0.43, 1 }, down = { 0.18, 0.21, 0.26, 1 },
        edge = { 0.52, 0.58, 0.67, 1 }, text = { 0.93, 0.95, 0.98 } },
    main = { bg = { 0.36, 0.29, 0.1, 1 }, hover = { 0.46, 0.37, 0.13, 1 }, down = { 0.27, 0.21, 0.06, 1 },
        edge = { 0.9, 0.74, 0.26, 1 }, text = { 1, 0.84, 0.1 } },
    quiet = { bg = { 0.8, 0.88, 1, 0.05 }, hover = { 0.8, 0.88, 1, 0.11 }, down = { 0, 0, 0, 0.25 },
        edge = { 0.4, 0.46, 0.54, 1 }, text = { 0.84, 0.88, 0.93 } },
    chosen = { bg = { 0.4, 0.46, 0.54, 1 }, edge = { 0.64, 0.7, 0.78, 1 }, text = { 1, 1, 1 } },
}
local BLIZZARD = {
    background = { 0.06, 0.06, 0.09, 1 }, panel = { 0.09, 0.09, 0.16, 1 }, card = { 0.13, 0.13, 0.21, 1 },
    field = { 0.04, 0.04, 0.07, 1 }, hover = { 1, 0.82, 0, 0.08 }, selected = { 1, 0.82, 0, 0.16 },
    edge = { 0.8, 0.66, 0.36, 1 }, line = { 1, 0.82, 0, 0.14 },
    text = { 1, 1, 1 }, heading = { 1, 0.82, 0 }, secondary = { 0.8, 0.72, 0.52 }, off = { 0.52, 0.52, 0.52 },
    gold = { 1, 0.82, 0 }, accent = { 1, 0.82, 0 }, positive = { 0.3, 0.9, 0.3 }, negative = { 1, 0.4, 0.36 },
    control = { bg = { 0.34, 0.1, 0.07, 1 }, hover = { 0.45, 0.15, 0.1, 1 }, down = { 0.24, 0.07, 0.05, 1 },
        edge = { 0.76, 0.6, 0.28, 1 }, text = { 1, 0.82, 0 } },
    main = { bg = { 0.48, 0.14, 0.09, 1 }, hover = { 0.58, 0.2, 0.12, 1 }, down = { 0.34, 0.1, 0.07, 1 },
        edge = { 1, 0.82, 0, 1 }, text = { 1, 1, 1 } },
    quiet = { bg = { 1, 1, 1, 0.04 }, hover = { 1, 0.82, 0, 0.1 }, down = { 0, 0, 0, 0.25 },
        edge = { 0.5, 0.42, 0.26, 1 }, text = { 0.9, 0.86, 0.74 } },
    chosen = { bg = { 0.36, 0.3, 0.14, 1 }, edge = { 1, 0.82, 0, 1 }, text = { 1, 1, 1 } },
}
local NIGHT = {
    background = { 0.035, 0.035, 0.04, 1 }, panel = { 0.065, 0.065, 0.075, 1 }, card = { 0.105, 0.105, 0.12, 1 },
    field = { 0.02, 0.02, 0.025, 1 }, hover = { 1, 1, 1, 0.1 }, selected = { 1, 0.82, 0.30, 0.13 },
    edge = { 0.44, 0.44, 0.48, 1 }, line = { 1, 1, 1, 0.14 },
    text = { 0.98, 0.98, 0.98 }, heading = { 0.98, 0.98, 0.98 }, secondary = { 0.76, 0.76, 0.78 }, off = { 0.55, 0.55, 0.57 },
    gold = { 1, 0.85, 0.1 }, accent = { 1, 0.72, 0.3 }, positive = { 0.45, 0.9, 0.55 }, negative = { 1, 0.52, 0.46 },
    control = { bg = { 0.2, 0.2, 0.23, 1 }, hover = { 0.27, 0.27, 0.31, 1 }, down = { 0.14, 0.14, 0.16, 1 },
        edge = { 0.64, 0.64, 0.68, 1 }, text = { 0.98, 0.98, 0.98 } },
    main = { bg = { 0.38, 0.3, 0.06, 1 }, hover = { 0.5, 0.4, 0.09, 1 }, down = { 0.27, 0.21, 0.04, 1 },
        edge = { 1, 0.85, 0.1, 1 }, text = { 1, 0.88, 0.2 } },
    quiet = { bg = { 1, 1, 1, 0.05 }, hover = { 1, 1, 1, 0.11 }, down = { 0, 0, 0, 0.3 },
        edge = { 0.44, 0.44, 0.48, 1 }, text = { 0.88, 0.88, 0.9 } },
    chosen = { bg = { 0.42, 0.42, 0.46, 1 }, edge = { 0.72, 0.72, 0.76, 1 }, text = { 1, 1, 1 } },
}
local LOOKS = {
    flat = {
        window = { bgFile = WHITE, edgeFile = TIP_EDGE, tile = false, edgeSize = 16,
                   insets = { left = 4, right = 4, top = 4, bottom = 4 } },
        panel = { bgFile = WHITE, edgeFile = TIP_EDGE, tile = false, edgeSize = 12,
                  insets = { left = 3, right = 3, top = 3, bottom = 3 } },
        inset = 4,
    },
    blizzard = {
        window = { bgFile = WHITE, edgeFile = DLG_EDGE, tile = false, edgeSize = 32, insets = DLG_INSET },
        panel = { bgFile = WHITE, edgeFile = DLG_EDGE, tile = false, edgeSize = 16,
                  insets = { left = 4, right = 4, top = 4, bottom = 4 } },
        inset = 11,
        frame = true,
    },
}
local function alpha(c, a)
    return { c[1], c[2], c[3], a }
end
local function mix(c, to, k)
    return { c[1] + (to[1] - c[1]) * k, c[2] + (to[2] - c[2]) * k, c[3] + (to[3] - c[3]) * k }
end
local function trade(over, lookKey, grain)
    local c = merge(copy(TRADE), over or {})
    local look = LOOKS[lookKey]
    local frameEdge = look.frame and { 1, 1, 1, 1 } or c.edge
    return merge(copy(BASE), {
        look = {
            window = { backdrop = look.window, edge = frameEdge, grainInset = look.inset },
            panel = { backdrop = look.panel, edge = frameEdge, alpha = 1 },
            grain = grain or {},
        },
        background = c.background, panel = c.panel, card = c.card, field = c.field, edge = c.edge,
        line = c.line, hover = c.hover, selected = c.selected,
        text = c.text, heading = c.heading, secondary = c.secondary, off = c.off,
        gold = c.gold, accent = c.accent, positive = c.positive, negative = c.negative, alert = c.negative,
        control = {
            bg = c.control.bg, hover = c.control.hover, on = c.chosen.bg, off = c.control.down,
            edge = c.control.edge, edgeLit = alpha(c.gold, 1), edgeOff = alpha(c.off, 0.6),
            text = c.control.text, textLit = c.chosen.text, textOff = c.off,
        },
        main = {
            bg = c.main.bg, hover = c.main.hover, down = c.main.down, edge = c.main.edge, text = c.main.text,
            fill = alpha(c.main.edge, 0.42),
        },
        quiet = c.quiet,
        bar = { bg = c.field, edge = c.edge },
        grip = {
            idle = c.accent, lit = mix(c.accent, { 1, 1, 1 }, 0.5), press = mix(c.accent, { 0, 0, 0 }, 0.25),
            glow = alpha(mix(c.accent, { 1, 1, 1 }, 0.5), 0.35),
        },
        mode = { none = c.secondary },
        tree = { bg = alpha(c.panel, 0.92), border = c.edge },
    })
end
local GRAIN_DARK = { path = DLG_DARK, alpha = 0.30, tile = 128 }
local PRESETS = {
    parchment = copy(BASE),
    clean = trade(nil, "flat"),
    dark = trade(nil, "flat", GRAIN_DARK),
    slate = trade(SLATE, "flat", { path = ACH_BG, alpha = 0.15 }),
    blizzard = trade(BLIZZARD, "blizzard", GRAIN_DARK),
    night = trade(NIGHT, "flat"),
}
ns.THEME_ORDER = { "parchment", "clean", "dark", "slate", "blizzard", "night" }
ns.THEMES = PRESETS
ns.C = copy(BASE)
ns.C.key = "parchment"
local C = ns.C
ns.MODE_COLORS = C.mode
ns.CMP_COLORS = C.cmp
function ns.ThemeId()
    local id = type(HTP_TalentsDB) == "table" and HTP_TalentsDB.theme
    if id and PRESETS[id] then return id end
    return "parchment"
end
local function fill(dst, src)
    for k in pairs(dst) do
        if src[k] == nil then dst[k] = nil end
    end
    for k, v in pairs(src) do
        if type(v) == "table" and type(dst[k]) == "table" then
            fill(dst[k], v)
        else
            dst[k] = copy(v)
        end
    end
end
function ns.Token(path)
    local node = C
    for part in path:gmatch("[^%.]+") do
        if type(node) ~= "table" then return nil end
        node = node[tonumber(part) or part]
    end
    return type(node) == "table" and node or nil
end
local function byte(x)
    return math.floor(math.max(0, math.min(1, x or 0)) * 255 + 0.5)
end
function ns.HexColor(c)
    return format("|cff%02x%02x%02x", byte(c[1]), byte(c[2]), byte(c[3]))
end
function ns.Hex(path)
    return ns.HexColor(ns.Token(path) or C.text)
end
function ns.ApplyTheme(force)
    local id = ns.ThemeId()
    if id == C.key and not force then return false end
    fill(C, PRESETS[id])
    C.key = id
    local edits = type(HTP_TalentsDB) == "table" and type(HTP_TalentsDB.themeEdits) == "table"
        and HTP_TalentsDB.themeEdits[id]
    if type(edits) == "table" then
        for path, v in pairs(edits) do
            local t = ns.Token(path)
            if t and type(v) == "table" then
                for i = 1, 4 do
                    if t[i] ~= nil and type(v[i]) == "number" then t[i] = v[i] end
                end
            end
        end
    end
    return true
end
function ns.SetTheme(key)
    if not PRESETS[key] then return false end
    HTP_TalentsDB = HTP_TalentsDB or {}
    HTP_TalentsDB.theme = key ~= "parchment" and key or nil
    ns.ApplyTheme()
    if ns.Kit and ns.Kit.Sync then ns.Kit.Sync() end
    if ns.RefreshWindow then ns.RefreshWindow() end
    if ns.QuickRefresh then ns.QuickRefresh() end
    if ns.SettingsRefresh then ns.SettingsRefresh() end
    return true
end
local function fitGrain(self)
    local tx, g = self.htpGrain, C.look.grain
    if not tx then return end
    if not (g and g.tile) then
        tx:SetTexCoord(0, 1, 0, 1)
        return
    end
    local inset = (C.look.window.grainInset or 0) * 2
    local w = math.max(1, (self:GetWidth() or 0) - inset)
    local h = math.max(1, (self:GetHeight() or 0) - inset)
    tx:SetTexCoord(0, w / g.tile, 0, h / g.tile)
end
function ns.ApplyDecor(frame)
    if not frame then return end
    local g = C.look.grain
    local tx = frame.htpGrain
    if not (g and g.path) then
        if tx then tx:Hide() end
        return
    end
    if not tx then
        tx = frame:CreateTexture(nil, "BORDER")
        frame.htpGrain = tx
        frame:HookScript("OnSizeChanged", fitGrain)
    end
    local inset = C.look.window.grainInset or 0
    tx:ClearAllPoints()
    tx:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -inset)
    tx:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset)
    tx:SetTexture(g.path)
    tx:SetVertexColor(C.plain[1], C.plain[2], C.plain[3], g.alpha or 1)
    fitGrain(frame)
    tx:Show()
end
