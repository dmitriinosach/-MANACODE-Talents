local ADDON, ns = ...
ns.capstats = ns.capstats or {}
ns.capstats.spellhit = {
    label = "hit", kind = "hard", stat = "spellhit",
    basePct = 17, perPct = 26.23, convRate = 23 / 20,
}
ns.capstats.meleehit = {
    label = "hit", kind = "hard", stat = "meleehit",
    basePct = 8, perPct = 32.79, convRate = 2,
}
ns.capstats.rangedhit = {
    label = "hit", kind = "hard", stat = "rangedhit",
    basePct = 8, perPct = 32.79, convRate = 2,
}
ns.capstats.expertise = {
    label = "expertise", kind = "hard", stat = "expertise",
    thresholds = { tank = { 26, 56 }, default = { 26 } },
    perPct = 8.1974, unit = "", have = "units", haveFromRating = true,
    pctPerPoint = 0.25, convRate = 2,
}
ns.capstats.arp = { label = "arp", kind = "arp", stat = "arp" }
ns.capstats.defense = { label = "defense", kind = "target", stat = "defense", show = "rating", need = 540 }
ns.capstats.spellpower = { label = "spellpower", kind = "more", stat = "spellpower", show = "rating" }
ns.capstats.crit = { label = "crit", kind = "more", show = "pct", virtual = "crit" }
ns.capstats.mainstat = { kind = "more", show = "rating", virtual = "mainstat" }
ns.capstats.spellhaste = { label = "spellhaste", kind = "more", stat = "spellhaste", show = "rating" }
ns.capstats.meleehaste = { label = "haste", kind = "more", stat = "meleehaste", show = "rating" }
ns.capstats.rangedhaste = { label = "haste", kind = "more", stat = "rangedhaste", show = "rating" }
ns.capstats.stamina = { label = "stamina", kind = "more", stat = "stamina", show = "rating" }
ns.capstats.armor = { label = "armor", kind = "more", stat = "armor", show = "rating" }
ns.capstats.dodge = { label = "dodge", kind = "more", stat = "dodge", show = "pct" }
ns.capstats.parry = { label = "parry", kind = "more", stat = "parry", show = "pct" }
ns.capstats.block = { label = "block", kind = "more", stat = "block", show = "pct" }
ns.capstats.resilience = { label = "resilience", kind = "more", stat = "resilience", show = "rating" }
ns.capstats.mp5 = { label = "mp5", kind = "more", stat = "mp5", show = "rating" }
ns.caparp = {
    cap = 1400,
    steps = { { 100, 29 }, { 60, 12 }, { 30, 5 }, { 10, 1 } },
}
ns.capweights = ns.capweights or {}
ns.capweights.PRIEST = { shadow = { main = 0.75, at = 2793 } }
