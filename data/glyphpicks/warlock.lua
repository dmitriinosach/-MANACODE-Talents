local ADDON, ns = ...
ns.glyphs = ns.glyphs or {}
ns.glyphs.WARLOCK = {
    demo = {
        major = {
            { glyph = 70947 },
            { glyph = 63320 },
            { glyph = 56246 },
        },
        minor = {
            { glyph = 58079 },
            { glyph = 58070 },
        },
    },
    affli = {
        major = {
            { glyph = 70947 },
            { glyph = 63302, note = "Главный урон афли." },
            { glyph = 63320 },
        },
        minor = {
            { glyph = 58070 },
            { glyph = 58079 },
        },
    },
}
ns.glyphsLoadedWarlock = true
