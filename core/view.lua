local ADDON, ns = ...
local V = { mode = "live" }
ns.View = V
local builders = {}
function ns.PlayerClass()
    local _, c = UnitClass("player")
    return c
end
function V.Ensure()
    if not V.class then V.class = ns.PlayerClass() end
end
function V.Own()
    return V.class == ns.PlayerClass()
end
function V.Group()
    return V.group or GetActiveTalentGroup() or 1
end
function V.Mode()
    if V.mode == "pick" and not V.pick then V.mode = "live" end
    if V.mode == "inspect" and not V.inspect then V.mode = "live" end
    if V.mode == "stored" and (not V.Own() or not ns.CircleThirdSet() or ns.CircleLoaded() == V.stored) then
        V.mode = "live"
    end
    return V.mode
end
function V.Source()
    local mode = V.Mode()
    if mode == "compare" then return "compare" end
    if mode == "builder" then return "builder" end
    if mode == "inspect" then return "target" end
    if mode == "stored" then return "stored" end
    if V.Own() then return "set" end
    return nil
end
function V.Pane()
    return HTP_TalentsDB.pane == "glyphs" and "glyphs" or "tree"
end
function V.SetPane(pane)
    HTP_TalentsDB.pane = pane == "glyphs" and "glyphs" or nil
    if pane == "glyphs" and (V.mode == "builder" or V.mode == "inspect" or V.mode == "compare" or V.mode == "stored") then
        V.mode = V.pick and "pick" or "live"
    end
end
function V.OnGlyphs()
    if V.Pane() ~= "glyphs" or V.Source() ~= "set" then return false end
    return (UnitLevel("player") or 0) >= (SHOW_INSCRIPTION_LEVEL or 15)
end
local REFRESH_DELAY = 0.15
local soon = CreateFrame("Frame")
soon:Hide()
local soonOn, soonLeft = false, 0
soon:SetScript("OnUpdate", function(self, elapsed)
    soonLeft = soonLeft - elapsed
    if soonLeft > 0 then return end
    soonOn = false
    self:Hide()
    if ns.RefreshWindow then ns.RefreshWindow() end
end)
function ns.RefreshSoon()
    if soonOn then return end
    soonOn, soonLeft = true, REFRESH_DELAY
    soon:Show()
end
function ns.RefreshSoonPending()
    return soonOn
end
function V.Builder()
    V.Ensure()
    builders[V.class] = builders[V.class] or {}
    return builders[V.class]
end
function V.SetBuilder(ranks)
    V.Ensure()
    builders[V.class] = ns.CopyRanks(ranks or {})
end
function V.SetClass(class)
    if not ns.specs[class] then return false end
    if class ~= V.class then
        V.compare = nil
        V.pick = nil
        if V.mode == "pick" then V.mode = "live" end
        if V.mode == "inspect" and not (V.inspect and V.inspect.class == class) then V.mode = "live" end
    end
    V.class = class
    return true
end
function V.Live()
    V.pick = nil
    V.mode = "live"
end
function V.Pick(ranks, name, toggle)
    if toggle and V.pick and V.pick.ranks == ranks then
        V.Live()
        return
    end
    V.pick = { ranks = ranks, name = name }
    V.mode = "pick"
end
function V.OpenBuilder(ranks)
    if ranks then V.SetBuilder(ranks) end
    V.mode = "builder"
end
function V.ShowInspect(data)
    local old = V.inspect
    if old and old ~= data and old.name == data.name and old.shown and old.shown ~= data.shown then
        ns.InspectShow(data, old.shown)
    end
    V.inspect = data
    if data.class ~= V.class then V.compare = nil end
    V.class = data.class
    V.pick = nil
    V.mode = "inspect"
end
function V.InspectGroup(g)
    return V.inspect ~= nil and ns.InspectShow(V.inspect, g)
end
function V.InspectLabel(data)
    data = data or V.inspect
    if not data then return "" end
    return ns.T(data.auto and "mini.target_label" or "mini.inspect_label", data.name)
end
function V.Home()
    V.class = ns.PlayerClass()
    V.group = nil
    V.pick = nil
    V.compare = nil
    V.mode = "live"
end
function V.IsHome()
    V.Ensure()
    local active = GetActiveTalentGroup() or 1
    return V.Own() and (V.group == nil or V.group == active) and V.Mode() == "live" and not V.compare
end
function V.SetGroup(g)
    V.group = g
    V.Live()
end
function V.ClickSet(g)
    local keep = V.Source() == "set" and V.Group() ~= g
    V.SetClass(ns.PlayerClass())
    V.SetGroup(g)
    if not keep then V.SetPane("tree") end
end
function V.ShowStored(n)
    V.SetClass(ns.PlayerClass())
    V.group = 2
    V.pick = nil
    V.stored = n
    V.mode = "stored"
end
local CMP_MAX = 2
ns.CMP_LETTERS = { "A", "B" }
function V.OpenCompare()
    if V.mode ~= "compare" then V.cmpBack = V.mode end
    V.mode = "compare"
end
function V.CloseCompare()
    if V.mode ~= "compare" then return end
    local back = V.cmpBack
    V.mode = (back == "builder" and "builder") or (back == "inspect" and V.inspect and "inspect")
        or (V.pick and "pick") or "live"
end
function V.CompareSwap()
    local c = V.compare
    if not (c and c[1] and c[2]) then return false end
    c[1], c[2] = c[2], c[1]
    for k, it in ipairs(c) do it.color = ns.CMP_COLORS[k] end
    return true
end
function ns.CompareDiffCount(a, b)
    local n = 0
    local tabs = {}
    for tab in pairs(a or {}) do tabs[tab] = true end
    for tab in pairs(b or {}) do tabs[tab] = true end
    for tab in pairs(tabs) do
        local x, y = (a and a[tab]) or {}, (b and b[tab]) or {}
        for i, r in pairs(x) do
            if (r or 0) ~= (y[i] or 0) then n = n + 1 end
        end
        for i, r in pairs(y) do
            if x[i] == nil and (r or 0) ~= 0 then n = n + 1 end
        end
    end
    return n
end
function V.CompareFind(ranks, name)
    local sig
    for i, it in ipairs(V.compare or {}) do
        if it.ranks == ranks or it.src == ranks then return i end
        sig = sig or ns.RanksSig(ranks)
        if ns.RanksSig(it.ranks) == sig then return i end
    end
    return nil
end
function V.CompareRemove(i)
    if not V.compare then return end
    table.remove(V.compare, i)
    for k, it in ipairs(V.compare) do it.color = ns.CMP_COLORS[k] end
    if #V.compare == 0 then V.compare = nil end
end
function V.ToggleCompare(ranks, name)
    local i = V.CompareFind(ranks, name)
    if i then
        V.CompareRemove(i)
        return true
    end
    V.compare = V.compare or {}
    local slot = math.min(#V.compare + 1, CMP_MAX)
    V.compare[slot] = { ranks = ns.CopyRanks(ranks), name = name, color = ns.CMP_COLORS[slot], src = ranks }
    V.OpenCompare()
    return true
end
function V.CompareAdd(ranks, name)
    local i = V.CompareFind(ranks, name)
    if i then return i end
    V.compare = V.compare or {}
    local slot = math.min(#V.compare + 1, CMP_MAX)
    V.compare[slot] = { ranks = ns.CopyRanks(ranks), name = name, color = ns.CMP_COLORS[slot], src = ranks }
    V.compareAt = GetTime and GetTime() or 0
    if #V.compare >= CMP_MAX then V.OpenCompare() end
    return slot
end
function V.CompareClick(ranks, name, button)
    local i = V.CompareFind(ranks, name)
    if i then
        if button == "RightButton" then V.CompareRemove(i) else V.OpenCompare() end
        return nil
    end
    if button == "RightButton" then return nil end
    V.CompareAdd(ranks, name)
    return nil
end
function V.Shown()
    local mode = V.Mode()
    if mode == "builder" then return V.Builder(), ns.T("sub.builder") end
    if mode == "inspect" then return V.inspect.ranks, ns.InspectName(V.inspect) end
    if mode == "pick" then return V.pick.ranks, V.pick.name end
    if mode == "stored" then
        local snap = ns.CircleSnap(V.stored)
        return snap and snap.ranks or {}, ns.T("window.set", V.stored)
    end
    if mode == "compare" then
        local a = V.compare and V.compare[1]
        return a and a.ranks or {}, a and a.name or ns.T("status.compare")
    end
    return nil, V.GroupLabel()
end
function V.SetName(g)
    return ns.T("window.set", (g == 2 and ns.CircleLoaded() == 3) and 3 or g)
end
local function pickProgress(want, group)
    local snap = ns.SnapshotTalents(group)
    local live = snap and snap.ranks or {}
    local have, total = 0, 0
    for tab, col in pairs(want) do
        for index, rank in pairs(col) do
            total = total + (rank or 0)
            have = have + math.min(rank or 0, (live[tab] and live[tab][index]) or 0)
        end
    end
    return have, total
end
local function setInfo(st, g)
    local C = ns.C
    local cast = ns.SpecCast()
    st.infoColor = C.secondary
    if cast then
        st.info, st.casting = ns.T("foot.switching", ns.SpecCastLeft(cast)), true
        return
    end
    if ns.LearnPending() or ns.CirclePending() then
        st.info = ns.T("foot.wait")
        return
    end
    if V.OnGlyphs() then return end
    local active = g == (GetActiveTalentGroup() or 1)
    local preview = active and ns.PreviewSpent(g) or 0
    if preview > 0 then
        st.info, st.infoColor = ns.T("foot.preview", preview), C.tree.preview
    end
    if st.pick then st.pickInfo = ns.T("foot.pick", pickProgress(V.pick.ranks, g)) end
end
function V.Status()
    V.Ensure()
    local src = V.Source()
    local colors = ns.MODE_COLORS or {}
    local st = {
        source = src, color = (src and colors[src]) or colors.none,
        pick = V.Mode() == "pick" and V.pick and V.pick.name or nil,
    }
    if src == "set" then
        local g = V.Group()
        local key = (V.OnGlyphs() and "status.set_glyphs")
            or (g == (GetActiveTalentGroup() or 1) and "status.set_active") or "status.set_idle"
        st.text, st.short = ns.T(key, V.SetName(g)), V.SetName(g)
        setInfo(st, g)
    elseif src == "stored" then
        local name = ns.T("window.set", V.stored)
        st.text, st.short, st.color = ns.T("window.set_unloaded", V.stored), name, colors.set or st.color
        st.hint = ns.T(ns.CircleSnap(V.stored) and "status.stored_hint" or "status.stored_none")
        if ns.CirclePending() then st.info, st.infoColor = ns.T("foot.wait"), ns.C.secondary end
    elseif src == "builder" then
        local used = ns.RanksTotal(V.Builder())
        st.text, st.short = ns.T("status.builder", ns.ClassName(V.class)), ns.T("sub.builder")
        if used == 0 then
            st.hint = ns.T("foot.builder_empty")
        else
            st.info = ns.T("foot.builder", ns.MAX_TALENT_POINTS - used, ns.MAX_TALENT_POINTS)
            st.infoColor = colors.builder
        end
    elseif src == "target" then
        st.text = V.InspectLabel()
        if (V.inspect.free or 0) > 0 then
            st.info, st.infoColor = ns.T("foot.points", V.inspect.free), ns.C.gold
        end
    elseif src == "compare" then
        st.text = ns.T("status.compare")
        local a, b = V.compare and V.compare[1], V.compare and V.compare[2]
        if a and b then
            local n = ns.CompareDiffCount(a.ranks, b.ranks)
            st.info = n > 0 and ns.T("foot.cmp_diff", n) or ns.T("foot.cmp_same")
            st.infoColor = colors.compare
        end
    else
        st.text = ns.T("status.browse", ns.ClassName(V.class))
        st.hint = ns.T("status.browse_hint")
    end
    return st
end
local GROUP_NAME = { "TALENT_SPEC_PRIMARY", "TALENT_SPEC_SECONDARY" }
function V.GroupName(g)
    g = g or V.Group()
    if g == 2 and ns.CircleLoaded() == 3 then return ns.T("window.set", 3) end
    return _G[GROUP_NAME[g]] or TALENTS
end
function V.GroupLabel()
    if (GetNumTalentGroups() or 1) > 1 then return V.GroupName() end
    return ns.T("window.current")
end
function V.MyRanks()
    if not V.Own() then return nil end
    local snap = ns.SnapshotTalents(V.Group())
    return snap and snap.points > 0 and snap.ranks or nil
end
local function builderEdit(grid, ranks, tab, index, delta)
    ranks[tab] = ranks[tab] or {}
    if delta > 0 then
        if ns.BuilderCanAdd(grid, ranks, tab, index) then
            ranks[tab][index] = (ranks[tab][index] or 0) + 1
        end
    elseif ns.BuilderCanRemove(grid, ranks, tab, index) then
        ranks[tab][index] = (ranks[tab][index] or 0) - 1
    end
    if ns.RefreshWindow then ns.RefreshWindow() end
end
function ns.BuilderEdit(grid, ranks)
    return {
        onAdd = function(t, i) builderEdit(grid, ranks, t, i, 1) end,
        onRemove = function(t, i) builderEdit(grid, ranks, t, i, -1) end,
        gate = function(t, i) return ns.BuilderGate(grid, ranks, t, i) end,
        branch = function(t) return grid[t] and grid[t].name end,
        left = ns.MAX_TALENT_POINTS - ns.RanksTotal(ranks),
    }
end
function V.RanksGrid(ranks)
    V.Ensure()
    if V.Own() then return ns.PreviewGrid(ranks, V.Group()) end
    local baked = ns.talentgrids and ns.talentgrids[V.class] or nil
    return baked and ns.ApplyRanksToGrid(baked, ranks, V.class) or nil
end
function V.Trees()
    V.Ensure()
    local class, own, mode = V.class, V.Own(), V.Mode()
    local baked = ns.talentgrids and ns.talentgrids[class] or nil
    local group = V.Group()
    local replaced = V.RanksGrid
    if mode == "builder" then
        local ranks = V.Builder()
        local grid = replaced(ranks)
        return { grid = grid, edit = grid and ns.BuilderEdit(grid, ranks) or nil, label = ns.T("sub.builder") }
    end
    if mode == "inspect" then
        return { grid = replaced(V.inspect.ranks), label = ns.InspectName(V.inspect) }
    end
    if mode == "compare" then
        local a = V.compare and V.compare[1]
        return { grid = replaced(a and a.ranks or {}), label = a and a.name or ns.T("status.compare") }
    end
    if mode == "stored" then
        local snap = ns.CircleSnap(V.stored)
        return { grid = replaced(snap and snap.ranks or {}), label = ns.T("window.set", V.stored) }
    end
    if own then
        local grid = ns.ReadTalentGrid(group)
        local pick = mode == "pick" and V.pick or nil
        return {
            grid = grid, edit = grid and ns.LiveEdit(grid, group) or nil,
            marks = pick and pick.ranks or nil,
            label = pick and pick.name or V.GroupLabel(),
        }
    end
    if mode == "pick" then
        return { grid = replaced(V.pick.ranks), label = V.pick.name }
    end
    return { grid = baked and ns.ApplyRanksToGrid(baked, nil, class) or nil, label = ns.T("window.empty_tree") }
end
