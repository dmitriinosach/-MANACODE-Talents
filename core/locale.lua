local ADDON, ns = ...
ns.locales = ns.locales or {}
ns.L = ns.L or {}
local AREAS = {
    common = true, panel = true, tip = true, msg = true,
    window = true, sub = true, status = true, act = true, popup = true, foot = true, menu = true, seg = true, base = true, hint = true, key = true, lib = true, names = true, options = true, mini = true, tree = true, glyph = true, quick = true, theme = true, bind = true, about = true, bars = true, show = true, model = true, caps = true,
}
ns.BINDINGS = { "window", "quick", "settings" }
local function bindingNames()
    BINDING_HEADER_MANACODE_TALENTS = "ManaCode Talents"
    for _, id in ipairs(ns.BINDINGS) do
        _G["BINDING_NAME_MANACODE_TALENTS_" .. id:upper()] = ns.L["bind." .. id]
    end
end
local function flatten(src, prefix, out)
    for k, v in pairs(src) do
        local key = prefix and (prefix .. "." .. k) or k
        if type(v) == "table" then
            if prefix or AREAS[k] then flatten(v, key, out) end
        else
            out[key] = v
        end
    end
    return out
end
local effective = "enUS"
local ALIASES = { enGB = "enUS", esMX = "esES" }
function ns.CurrentLocale() return effective end
function ns.ApplyLocale(lang)
    local code = ALIASES[lang] or lang
    if not code or not ns.locales[code] then
        local client = GetLocale()
        client = ALIASES[client] or client
        code = ns.locales[client] and client or "enUS"
    end
    effective = code
    wipe(ns.L)
    flatten(ns.locales.enUS or ns.locales.ruRU or {}, nil, ns.L)
    if code ~= "enUS" and ns.locales[code] then
        for k, v in pairs(flatten(ns.locales[code], nil, {})) do ns.L[k] = v end
    end
    bindingNames()
end
ns.LANG_ORDER = { "auto", "enUS", "esES", "ruRU" }
local LANG_CODES = { en = "enUS", enus = "enUS", es = "esES", eses = "esES", ru = "ruRU", ruru = "ruRU", auto = "auto" }
local LANG_NAMES = { enUS = "English", esES = "Español" }
local listeners = {}
function ns.OnLocale(fn)
    listeners[#listeners + 1] = fn
end
function ns.LangId()
    local v = HTP_TalentsDB and HTP_TalentsDB.lang
    return v and ns.locales[v] and v or "auto"
end
function ns.LangName(id)
    if id == "ruRU" then return GetLocale() == "ruRU" and "Русский" or "Russian" end
    return LANG_NAMES[id]
end
function ns.SetLang(id)
    local code = LANG_CODES[tostring(id or ""):lower()]
    if not code then return false end
    HTP_TalentsDB.lang = code ~= "auto" and code or nil
    ns.ApplyLocale(HTP_TalentsDB.lang)
    if ns.Kit and ns.Kit.FlyHide then ns.Kit.FlyHide() end
    GameTooltip:Hide()
    for _, fn in ipairs(listeners) do fn() end
    if ns.RefreshWindow then ns.RefreshWindow() end
    if ns.QuickRefresh then ns.QuickRefresh() end
    if ns.SettingsRefresh then ns.SettingsRefresh() end
    return true
end
function ns.T(key, ...)
    local s = ns.L[key]
    if s == nil then return "[" .. tostring(key) .. "]" end
    if select("#", ...) > 0 then return s:format(...) end
    return s
end
function ns.GlyphText(text)
    if not text or effective == "ruRU" then return text end
    local own = ns.locales[effective]
    local base = ns.locales.enUS
    return (own and own.glyphText and own.glyphText[text])
        or (base and base.glyphText and base.glyphText[text]) or text
end
