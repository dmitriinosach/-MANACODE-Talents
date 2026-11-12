local ADDON, ns = ...
local button
local function onClick()
    local unit = InspectFrame and InspectFrame.unit
    if not unit or not UnitExists(unit) then return end
    local _, class = UnitClass(unit)
    local data = ns.InspectSnapshot(UnitName(unit), class)
    if not data then
        ns.warn(ns.T("msg.target_empty", UnitName(unit)))
        return
    end
    ns.ShowInspected(data)
end
local function attach()
    if button or not InspectTalentFrame then return end
    button = ns.Kit.Button(InspectTalentFrame)
    local function label() ns.Kit.SetButton(button, ns.T("act.inspect_trees"), ns.T("tip.inspect_trees"), onClick) end
    label()
    ns.OnLocale(label)
    button:SetPoint("TOPRIGHT", InspectTalentFrame, "TOPRIGHT", -40, -42)
    button:SetFrameLevel(InspectTalentFrame:GetFrameLevel() + 5)
end
local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function(_, event, name)
    if event == "PLAYER_LOGIN" or name == "Blizzard_InspectUI" then
        if IsAddOnLoaded("Blizzard_InspectUI") then attach() end
    end
end)
