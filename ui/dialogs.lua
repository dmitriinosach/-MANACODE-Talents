local ADDON, ns = ...
function ns.Popup(name, arg1, arg2, data)
    local d = StaticPopupDialogs[name]
    local keys = d and d.htpKeys
    if keys then
        d.text = ns.T(type(data) == "table" and data.textKey or keys.text)
        d.button1 = ns.T(type(data) == "table" and data.btnKey or keys.button1)
        d.button2 = ns.T(keys.button2)
    end
    return StaticPopup_Show(name, arg1, arg2, data)
end
local function report(ok, msg)
    if msg and not ok then ns.warn(msg) end
    if ns.RefreshWindow then ns.RefreshWindow() end
end
local function editBoxOf(self)
    return _G[self:GetName() .. "EditBox"]
end
local function saveNamed(data, name)
    if data and data.ranks then
        report(ns.SaveBuilderBuild(data.ranks, name, data.class))
    else
        report(ns.SaveCustomBuild(name, data and data.group))
    end
end
StaticPopupDialogs["HTP_TALENTS_SAVE"] = {
    htpKeys = { text = "popup.name", button1 = "popup.save", button2 = "popup.cancel" },
    hasEditBox = 1, maxLetters = 40,
    OnAccept = function(self, data)
        local eb = editBoxOf(self)
        saveNamed(data, eb and eb:GetText() or "")
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        saveNamed(parent.data, self:GetText())
        parent:Hide()
    end,
    EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
    timeout = 0, whileDead = 1, hideOnEscape = 1,
}
StaticPopupDialogs["HTP_TALENTS_RENAME"] = {
    htpKeys = { text = "popup.rename", button1 = "popup.rename_btn", button2 = "popup.cancel" },
    hasEditBox = 1, maxLetters = 40,
    OnShow = function(self)
        local eb = editBoxOf(self)
        if eb and self.data then
            eb:SetText(self.data.name or "")
            eb:HighlightText()
        end
    end,
    OnAccept = function(self, data)
        local eb = editBoxOf(self)
        local text = eb and eb:GetText() or ""
        if data.apply then report(data.apply(text)) else report(ns.RenameCustomBuild(data.class, data.index, text)) end
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        local d = parent.data
        if d.apply then report(d.apply(self:GetText())) else report(ns.RenameCustomBuild(d.class, d.index, self:GetText())) end
        parent:Hide()
    end,
    EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
    timeout = 0, whileDead = 1, hideOnEscape = 1,
}
StaticPopupDialogs["HTP_TALENTS_DELETE"] = {
    htpKeys = { text = "popup.delete", button1 = "popup.delete_btn", button2 = "popup.cancel" },
    OnAccept = function(self, data)
        if data then ns.DeleteCustomBuild(data.class, data.index) end
        report(true, nil)
    end,
    timeout = 0, whileDead = 1, hideOnEscape = 1,
}
StaticPopupDialogs["HTP_TALENTS_OFFER"] = {
    OnAccept = function()
        local data = ns.PendingSharedBuild()
        local ok, msg = ns.SavePendingShared()
        local _, own = UnitClass("player")
        if ok and data and data.class ~= own and ns.ShowClass then ns.ShowClass(data.class, "mine") end
        report(ok, msg)
    end,
    OnCancel = function(self, data, reason) ns.DeclinePendingShared(reason == "timeout") end,
    OnHide = function() ns.DeclinePendingShared(false) end,
    timeout = ns.SHARE_POPUP_TIME, whileDead = 1, hideOnEscape = 1,
}
StaticPopupDialogs["HTP_TALENTS_REMOVE_GLYPH"] = {
    OnAccept = function(self, id) RemoveGlyphFromSocket(id) end,
    timeout = 0, whileDead = 1, hideOnEscape = 1,
}
StaticPopupDialogs["HTP_TALENTS_REPLACE_GLYPH"] = {
    OnAccept = function(self, id) PlaceGlyphInSocket(id) end,
    timeout = 0, whileDead = 1, hideOnEscape = 1,
}
StaticPopupDialogs["HTP_TALENTS_LEARN"] = {
    OnAccept = function(self, group) ns.LearnCommitNow(group) end,
    timeout = 0, whileDead = 1, hideOnEscape = 1, exclusive = 1,
}
function ns.ShowLearnPopup(group)
    local d = StaticPopupDialogs["HTP_TALENTS_LEARN"]
    d.text, d.button1, d.button2 = CONFIRM_LEARN_PREVIEW_TALENTS, YES, NO
    StaticPopup_Show("HTP_TALENTS_LEARN", nil, nil, group)
end
function ns.ShowGlyphPopup(name, text, arg1, id)
    local d = StaticPopupDialogs[name]
    d.text, d.button1, d.button2 = text, YES, NO
    StaticPopup_Show(name, arg1, nil, id)
end
function ns.OnBuildReceived(sender, data)
    local name = (data.name ~= "" and data.name) or ns.T("msg.unknown_name")
    local d = StaticPopupDialogs["HTP_TALENTS_OFFER"]
    d.text = (ns.T("popup.offer", sender, name, ns.ClassName(data.class)):gsub("%%", "%%%%"))
    d.button1, d.button2 = ns.T("popup.save"), ns.T("popup.no")
    return StaticPopup_Show("HTP_TALENTS_OFFER")
end
