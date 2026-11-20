local ADDON, ns = ...
function ns.GetSpec()
    local group = 1
    if GetActiveTalentGroup then
        group = GetActiveTalentGroup() or 1
    end
    local bestIndex, bestName, bestPoints = nil, nil, -1
    local secondPoints, total = -1, 0
    for i = 1, GetNumTalentTabs() do
        local name, _, points = GetTalentTabInfo(i, false, false, group)
        points = points or 0
        total = total + points
        if points > bestPoints then
            secondPoints = bestPoints
            bestIndex, bestName, bestPoints = i, name, points
        elseif points > secondPoints then
            secondPoints = points
        end
    end
    local confident = bestPoints >= 20 and (bestPoints - secondPoints) >= 10
    return bestIndex, bestName, bestPoints, confident, total
end
function ns.SpecName(class, variant)
    local info = ns.SpecInfo and ns.SpecInfo(class, variant)
    return ns.LocalName(info) or tostring(variant or "?")
end
function ns.CurrentVariant()
    local _, class = UnitClass("player")
    local tab = ns.GetSpec() or 1
    local v = ns.DefaultVariant and ns.DefaultVariant(class, tab)
    if v then return v end
    local c = ns.specs and ns.specs[class]
    return (c and c.order[1]) or tab
end
function ns.SpecFrom(bySpec, class, variant)
    if not bySpec then return nil end
    if variant ~= nil and bySpec[variant] ~= nil then return bySpec[variant] end
    local info = ns.SpecInfo and ns.SpecInfo(class, variant)
    if info then
        if info.base and bySpec[info.base] ~= nil then return bySpec[info.base] end
        if info.tab and bySpec[info.tab] ~= nil then return bySpec[info.tab] end
    end
    if type(variant) == "number" and bySpec[variant] ~= nil then return bySpec[variant] end
    return nil
end
function ns.SpecData(store, class, variant)
    return ns.SpecFrom(store and store[class], class, variant)
end
