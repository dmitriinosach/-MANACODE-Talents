local ADDON, ns = ...
ns.capsources = ns.capsources or {}
ns.capgroups = ns.capgroups or {}
local SPELL_HIT_RAID = "spellhit_raid"
ns.capgroups[SPELL_HIT_RAID] = true
ns.capsources.heroic_presence = {
    spell   = 6562,
    byClass = { PRIEST = 28878, SHAMAN = 28878, MAGE = 28878 },
    stats   = { "meleehit", "rangedhit", "spellhit" },
    pct     = 1,
    faction = "Alliance",
    race    = "Draenei",
}
ns.capsources.misery = {
    spell    = 33193,
    debuff   = 33198,
    onTarget = true,
    talent   = { PRIEST = 33193 },
    form     = { PRIEST = 15473 },
    stats    = { "spellhit" },
    pct      = 3,
    group    = SPELL_HIT_RAID,
}
ns.capsources.faerie_fire = {
    spell    = 33602,
    debuff   = 770,
    onTarget = true,
    talent   = { DRUID = 33602 },
    form     = { DRUID = 24858 },
    stats    = { "spellhit" },
    pct      = 3,
    group    = SPELL_HIT_RAID,
}
ns.capsources.weapon_mastery = {
    spell = 46866, class = "WARRIOR", spec = { "arms", "prot" },
    at = { tab = 1, row = 7, col = 3 }, perRank = 2, max = 2, stats = { "expertise" },
}
ns.capsources.vitality = {
    spell = 29144, class = "WARRIOR", spec = { "prot" },
    at = { tab = 3, row = 8, col = 2 }, perRank = 2, max = 3, stats = { "expertise" },
}
ns.capsources.combat_expertise = {
    spell = 31860, class = "PALADIN", spec = { "prot_tank", "prot_dps" },
    at = { tab = 2, row = 8, col = 3 }, perRank = 2, max = 3, stats = { "expertise" },
}
ns.capsources.veteran_third_war = {
    spell = 50029, class = "DEATHKNIGHT", spec = { "blood_tank", "blood_str", "blood_agi" },
    at = { tab = 1, row = 5, col = 3 }, perRank = 2, max = 3, stats = { "expertise" },
}
ns.capsources.tundra_stalker = {
    spell = 50130, class = "DEATHKNIGHT", spec = { "frost" },
    at = { tab = 2, row = 10, col = 2 }, perRank = 1, max = 5, stats = { "expertise" },
}
ns.capsources.rage_rivendare = {
    spell = 50121, class = "DEATHKNIGHT", spec = { "unholy" },
    at = { tab = 3, row = 10, col = 2 }, perRank = 1, max = 5, stats = { "expertise" },
}
ns.capsources.weapon_expertise = {
    spell = 30920, class = "ROGUE", spec = { "combat" },
    at = { tab = 2, row = 6, col = 2 }, perRank = 5, max = 2, stats = { "expertise" },
}
ns.capsources.primal_precision = {
    spell = 48410, class = "DRUID", spec = { "cat", "bear" },
    at = { tab = 2, row = 4, col = 4 }, perRank = 5, max = 2, stats = { "expertise" },
}
ns.capsources.unleashed_rage = {
    spell = 30809, class = "SHAMAN", spec = { "enh_phys", "enh_spell" },
    at = { tab = 2, row = 6, col = 1 }, perRank = 3, max = 3, stats = { "expertise" },
}
ns.capsources.glyph_seal_vengeance = {
    spell = 56416, glyph = 56416, class = "PALADIN", pct = 10, stats = { "expertise" },
}
local SWORDS = { 8, 9 }
local MACES  = { 5, 6 }
local AXES   = { 1, 2 }
local FIST   = { 14 }
ns.capsources.sword_specialization = {
    spell = 20597, race = "Human", personal = true, pct = 3, weapon = SWORDS, stats = { "expertise" },
}
ns.capsources.mace_specialization_human = {
    spell = 20864, race = "Human", personal = true, pct = 3, weapon = MACES, stats = { "expertise" },
}
ns.capsources.mace_specialization_dwarf = {
    spell = 59224, race = "Dwarf", personal = true, pct = 5, weapon = MACES, stats = { "expertise" },
}
ns.capsources.axe_specialization = {
    spell = 20574, race = "Orc", personal = true, pct = 5, weapon = { AXES[1], AXES[2], FIST[1] },
    stats = { "expertise" },
}
