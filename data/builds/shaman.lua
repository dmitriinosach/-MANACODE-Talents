local ADDON, ns = ...
ns.builds = ns.builds or {}
ns.builds.SHAMAN = ns.builds.SHAMAN or {}
ns.builds.SHAMAN.ele = {
    { name = "Elemental", ranks = {
        [1] = {0,5,3,3,0,0,1,5,2,3,2,1,3,3,5,1,3,2,2,3,0,1,3,5,1},
        [2] = {0,0,5,0,5,0,0,3,1},
        [3] = {},
    } },
}
ns.builds.SHAMAN.enh_phys = {
    { name = "Enhancement", ranks = {
        [1] = {0,5,3,0,3,0,1,5,2},
        [2] = {3,0,3,0,5,0,0,3,1,0,5,0,2,1,3,3,3,0,3,1,1,3,1,1,3,1,0,5,1},
        [3] = {},
    } },
}
ns.builds.SHAMAN.enh_spell = ns.builds.SHAMAN.enh_phys
ns.builds.SHAMAN.resto = {
    { name = "Restoration", ranks = {
        [1] = {},
        [2] = {0,0,5,0,5,0,3},
        [3] = {5,0,0,0,5,3,3,1,3,3,5,3,1,0,5,0,1,1,2,2,3,3,1,2,5,1},
    } },
}
