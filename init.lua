local ADDON, ns = ...
local PREFIX_COLOR = "|cff33ff99"
function ns.say(msg)
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX_COLOR .. ns.T("common.prefix") .. ":|r " .. tostring(msg))
end
function ns.warn(msg)
    if UIErrorsFrame and UIErrorsFrame.AddMessage then
        UIErrorsFrame:AddMessage(tostring(msg), 1, 0.1, 0.1, 1)
    else
        ns.say(msg)
    end
end
function ns.CharKey()
    local name = UnitName and UnitName("player")
    if not name or name == "" or name == UNKNOWNOBJECT then return nil end
    return name .. "-" .. ((GetRealmName and GetRealmName()) or "")
end
local limbo = {}
function ns.CharDB()
    local key = ns.CharKey()
    if not key then return limbo, false end
    HTP_TalentsDB.chars = HTP_TalentsDB.chars or {}
    local ch = HTP_TalentsDB.chars[key]
    if not ch then
        ch = {}
        HTP_TalentsDB.chars[key] = ch
    end
    if not ch.class and UnitClass then
        local _, class = UnitClass("player")
        ch.class = class
    end
    return ch, true
end
local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name == ADDON then
            HTP_TalentsDB = HTP_TalentsDB or {}
            if HTP_TalentsDB.sub == "glyphs" then
                HTP_TalentsDB.sub, HTP_TalentsDB.pane = nil, "glyphs"
            end
            ns.ApplyLocale(HTP_TalentsDB.lang)
            ns.ApplyTheme(true)
        end
    elseif event == "PLAYER_LOGIN" then
        ns.ImportLegacyBuilds()
    end
end)
