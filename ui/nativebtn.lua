local ADDON, ns = ...
local button
local function onClick()
    ns.SetMode("wide")
end
local function attach()
    if button or not PlayerTalentFrame then return end
    button = CreateFrame("Button", nil, PlayerTalentFrame)
    button:SetWidth(32); button:SetHeight(32)
    button:SetPoint("CENTER", PlayerTalentFrame, "TOPRIGHT", -70, -25)
    button:SetNormalTexture("Interface\\Buttons\\UI-Panel-BiggerButton-Up")
    button:SetPushedTexture("Interface\\Buttons\\UI-Panel-BiggerButton-Down")
    button:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
    button:SetScript("OnClick", onClick)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(ns.T("act.native_back"), 1, 1, 1)
        GameTooltip:AddLine(ns.T("tip.native_back"), nil, nil, nil, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end
local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function(_, event, name)
    if event == "PLAYER_LOGIN" or name == "Blizzard_TalentUI" then
        if IsAddOnLoaded("Blizzard_TalentUI") then attach() end
    end
end)
