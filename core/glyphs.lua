local ADDON, ns = ...
local GLYPH_MINOR = 2
local SLOTS = 6
function ns.GlyphSlots(group)
    local major, minor = {}, {}
    for id = 1, (NUM_GLYPH_SLOTS or SLOTS) do
        local enabled, glyphType, spell, icon = GetGlyphSocketInfo(id, group)
        local slot = {
            id = id, enabled = enabled and true or false, major = glyphType ~= GLYPH_MINOR,
            spell = spell, icon = icon, name = spell and GetSpellInfo(spell) or nil,
        }
        if slot.major then major[#major + 1] = slot else minor[#minor + 1] = slot end
    end
    return major, minor
end
function ns.GlyphLockText(id)
    return _G["GLYPH_SLOT_TOOLTIP" .. id]
end
function ns.IsActiveGroup(group)
    return group == (GetActiveTalentGroup() or 1)
end
