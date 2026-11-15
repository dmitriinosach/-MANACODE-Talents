local ADDON, ns = ...
ns.capdata = ns.capdata or {}
local MELEE  = { "meleehit", "expertise", "arp", "crit", "meleehaste", "mainstat" }
local RANGED = { "rangedhit", "arp", "crit", "rangedhaste", "mainstat" }
local CASTER = { "spellhit", "spellhaste", "crit", "spellpower" }
local HEALER = { "spellhaste", "crit", "spellpower", "mp5" }
local TANK   = { "defense", "meleehit", "expertise", "dodge", "parry", "block", "armor", "stamina", "resilience" }
ns.capdata.DEATHKNIGHT = {
    blood_tank = { priority = TANK },
    blood_str  = { priority = MELEE },
    blood_agi  = { priority = MELEE },
    frost      = { priority = MELEE },
    unholy     = { priority = MELEE },
}
ns.capdata.DRUID = {
    balance = { priority = CASTER },
    cat     = { priority = MELEE },
    bear    = { priority = TANK },
    resto   = { priority = HEALER },
}
ns.capdata.HUNTER = {
    bm   = { priority = RANGED },
    mm   = { priority = RANGED },
    surv = { priority = RANGED },
}
ns.capdata.MAGE = {
    arcane = { priority = CASTER },
    fire   = { priority = CASTER },
    frost  = { priority = CASTER },
}
ns.capdata.PALADIN = {
    holy = {
        priority = HEALER,
        spellhaste = {
            desc = "PALADIN.holy.spellhaste",
            targets = { { v = 600, t = "floor" }, { v = 800, t = "work" } },
        },
        crit       = { desc = "PALADIN.holy.crit" },
        spellpower = { desc = "PALADIN.holy.spellpower" },
        mp5        = { desc = "PALADIN.holy.mp5" },
    },
    prot_tank = {
        priority = TANK,
        defense   = { desc = "PALADIN.prot_tank.defense" },
        meleehit  = { desc = "PALADIN.prot_tank.meleehit" },
        expertise = { desc = "PALADIN.prot_tank.expertise" },
        dodge     = { desc = "PALADIN.prot_tank.dodge" },
        parry     = { desc = "PALADIN.prot_tank.parry" },
        block     = { desc = "PALADIN.prot_tank.block" },
        armor     = { desc = "PALADIN.prot_tank.armor" },
        stamina   = { desc = "PALADIN.prot_tank.stamina" },
    },
    prot_dps = { priority = MELEE },
    ret_agi  = { priority = MELEE },
}
ns.capdata.PRIEST = {
    shadow = {
        priority = { "spellhit", "spellpower", "spellhaste", "crit" },
        avgDps   = 15000,
        mainStat = "spellpower",
        sources = {
            { stat = "spellhit", perRank = 1, max = 3, tab = 3, row = 2, col = 3, spellId = 15328 },
        },
        spellhaste = { desc = "PRIEST.shadow.spellhaste" },
    },
    disc = {
        priority = { "spellhaste", "spellpower", "crit", "mp5" },
        spellhaste = {
            desc = "PRIEST.disc.spellhaste",
            targets = { { v = 434, t = "shield" }, { v = 600, t = "comfort" } },
        },
        spellpower = { desc = "PRIEST.disc.spellpower" },
    },
    holy = {
        priority = { "spellhaste", "spellpower", "crit", "mp5" },
        spellhaste = {
            desc = "PRIEST.holy.spellhaste",
            targets = { { v = 800, t = "work" } },
        },
    },
}
ns.capdata.ROGUE = {
    assassination = { priority = MELEE },
    combat        = { priority = MELEE },
}
ns.capdata.SHAMAN = {
    ele       = { priority = CASTER },
    enh_phys  = { priority = MELEE },
    enh_spell = { priority = MELEE },
    resto     = { priority = HEALER },
}
ns.capdata.WARLOCK = {
    affli  = { priority = CASTER },
    demo   = { priority = CASTER },
    destro = { priority = CASTER },
}
ns.capdata.WARRIOR = {
    fury = {
        priority = { "mainstat", "meleehit", "expertise", "arp", "crit", "meleehaste" },
        avgDps   = 15000,
        mainStat = "attackpower",
        sources = {
            { stat = "meleehit", perRank = 1, max = 3, tab = 2, row = 5, col = 1, spellId = 29592 },
        },
    },
    prot = { priority = { "defense", "stamina", "meleehit", "expertise", "dodge", "parry", "block" } },
    arms = { priority = { "meleehit", "expertise", "arp", "crit", "mainstat", "meleehaste" } },
}
