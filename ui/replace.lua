local ADDON, ns = ...
local BINDING = "TOGGLETALENTS"
local owner = CreateFrame("Frame")
local toggle = CreateFrame("Button", "HTP_TalentsToggle", UIParent)
toggle:SetScript("OnClick", function() ns.ToggleWindow() end)
local appliedSig
local pending = false
function ns.NativeMode()
    return HTP_TalentsDB.native == true
end
function ns.WideMode()
    return HTP_TalentsDB.mode == "wide" and not ns.NativeMode()
end
local function boundKeys()
    local out = {}
    for _, key in ipairs({ GetBindingKey(BINDING) }) do
        if key then out[#out + 1] = key end
    end
    return out
end
local function signature(keys)
    return (ns.WideMode() and "ours|" or "native|") .. table.concat(keys, "|")
end
function ns.ApplyKeyBinding()
    if InCombatLockdown() then
        pending = true
        return
    end
    pending = false
    local keys = boundKeys()
    local sig = signature(keys)
    if sig == appliedSig then return end
    appliedSig = sig
    ClearOverrideBindings(owner)
    if not ns.WideMode() then return end
    for _, key in ipairs(keys) do
        SetOverrideBindingClick(owner, false, key, "HTP_TalentsToggle")
    end
end
function ns.SetNativeMode(on)
    HTP_TalentsDB.native = on and true or nil
    ns.ApplyKeyBinding()
end
local GLYPH_USE_SECONDS = 1
local glyphUseAt = -10
local WIPE_SECONDS = 1
local wipeAt = -10
local SWAP_SECONDS = 1
local swapAt = -10
local quiet = false
function ns.GlyphSwapQuiet()
    local f = PlayerTalentFrame
    if f and f:IsShown() then return end
    swapAt = GetTime()
end
local redirect = CreateFrame("Frame")
redirect:Hide()
redirect:SetScript("OnUpdate", function(self)
    self:Hide()
    local f = PlayerTalentFrame
    if not f then return end
    if quiet then
        quiet = false
        if f:IsShown() then HideUIPanel(f) end
        f:SetAlpha(1)
        return
    end
    if not f:IsShown() then f:SetAlpha(1); return end
    local glyphs = PanelTemplates_GetSelectedTab(f) == GLYPH_TALENT_TAB
    HideUIPanel(f)
    f:SetAlpha(1)
    if GetTime() - wipeAt < WIPE_SECONDS then
        ns.View.Home()
        ns.View.SetPane("tree")
        ns.OpenFromNative(false, true)
        ns.RefreshWindow()
        return
    end
    ns.OpenFromNative(glyphs, GetTime() - glyphUseAt < GLYPH_USE_SECONDS)
end)
local passNative = false
function ns.OpenNativePet()
    if not PlayerTalentFrame and TalentFrame_LoadUI then TalentFrame_LoadUI() end
    if not (PlayerTalentFrame and PlayerTalentFrame_Toggle) then return false end
    if PlayerTalentFrame:IsShown() then HideUIPanel(PlayerTalentFrame) end
    passNative = true
    PlayerTalentFrame_Toggle(true, 1)
    passNative = false
    return true
end
local function onNativeShow(self)
    if passNative then return end
    if GetTime() - swapAt < SWAP_SECONDS then
        swapAt = -10
        quiet = true
        self:SetAlpha(0)
        redirect:Show()
        return
    end
    if not ns.WideMode() then return end
    self:SetAlpha(0)
    redirect:Show()
end
local hooked = false
local function hookNative()
    if hooked or not PlayerTalentFrame then return end
    hooked = true
    PlayerTalentFrame:HookScript("OnShow", onNativeShow)
end
owner:RegisterEvent("PLAYER_LOGIN")
owner:RegisterEvent("UPDATE_BINDINGS")
owner:RegisterEvent("PLAYER_REGEN_ENABLED")
owner:RegisterEvent("ADDON_LOADED")
owner:RegisterEvent("USE_GLYPH")
owner:RegisterEvent("CONFIRM_TALENT_WIPE")
owner:SetScript("OnEvent", function(_, event, name)
    if event == "USE_GLYPH" then
        if GetTime() - swapAt < SWAP_SECONDS then return end
        glyphUseAt = GetTime()
        return
    end
    if event == "CONFIRM_TALENT_WIPE" then
        wipeAt = GetTime()
        return
    end
    if event == "ADDON_LOADED" then
        if name == "Blizzard_TalentUI" then hookNative() end
        return
    end
    if event == "PLAYER_LOGIN" and IsAddOnLoaded("Blizzard_TalentUI") then hookNative() end
    if event == "PLAYER_REGEN_ENABLED" and not pending then return end
    ns.ApplyKeyBinding()
end)
