local ADDON, ns = ...
local V = ns.View
local function refresh()
    if ns.RefreshWindow then ns.RefreshWindow() end
end
local storedActions
local function waiting()
    if ns.SpecCast() then return ns.T("tip.off_casting") end
    if ns.LearnPending() or ns.CirclePending() then return ns.T("tip.off_wait") end
    return nil
end
function ns.LearnBlock()
    if not V.Own() then return ns.T("tip.off_foreign") end
    local group = V.Group()
    if not ns.IsActiveGroup(group) then return ns.T("tip.off_inactive") end
    local busy = waiting()
    if busy then return busy end
    if (GetUnspentTalentPoints(false, false, group) or 0) <= 0 then return ns.T("tip.off_no_points") end
    return nil
end
function ns.LearnBuild(ranks)
    if not ranks then ns.warn(ns.T("msg.no_pick")); return end
    if ns.LearnPending() then ns.warn(ns.T("msg.learn_busy")); return end
    local group = V.Group()
    local ok, lines = ns.FillPreview(ranks, group)
    for _, s in ipairs(lines) do ns.warn(s) end
    if not ok then return end
    if V.mode == "builder" then
        V.Live()
    elseif V.mode == "inspect" or V.mode == "compare" then
        V.mode = V.pick and "pick" or "live"
    end
    refresh()
    ns.LearnCommit(group)
end
function ns.OpenBuilderTab()
    if V.Mode() == "builder" then return end
    V.OpenBuilder()
    refresh()
end
function ns.BaseCurrentAction()
    local mine = V.MyRanks()
    return {
        label = ns.T("act.base_current"), tip = ns.T("tip.base_current"), icon = "base", kind = "word",
        off = (not V.Own() and ns.T("tip.off_foreign")) or (not mine and ns.T("tip.off_no_live")) or nil,
        onClick = function()
            V.SetBuilder(V.MyRanks(), { glyphs = ns.LiveGlyphPlan(V.Group()) })
            refresh()
        end,
    }
end
function ns.BaseMenu()
    local mine, p = V.MyRanks(), V.pick
    return {
        { label = ns.T("base.current", V.SetName(V.Group())), tip = ns.T("tip.base_current"),
          off = (not V.Own() and ns.T("tip.off_foreign")) or (not mine and ns.T("tip.off_no_live")) or nil,
          onClick = function()
              V.SetBuilder(V.MyRanks(), { glyphs = ns.LiveGlyphPlan(V.Group()) })
              refresh()
          end },
        { label = p and ns.T("base.pick", p.name) or ns.T("base.pick_none"),
          tip = p and ns.T("tip.base_pick", p.name) or nil,
          off = (not p and ns.T("tip.off_no_pick")) or nil,
          onClick = function()
              if not V.pick then return end
              V.SetBuilder(V.pick.ranks, V.pick.plan)
              refresh()
          end },
        { label = ns.T("base.empty"), tip = ns.T("tip.clear_builder"), sep = true,
          onClick = function()
              V.SetBuilder(nil)
              refresh()
          end },
    }
end
function ns.CompareAddAction(ranks, name, off)
    local i = ranks and V.CompareFind(ranks, name)
    return {
        label = ns.T(i and "act.compare_open" or "act.compare_add"), icon = "compare",
        tip = i and ns.T("tip.compare_in", ns.CMP_LETTERS[i]) or ns.T("tip.compare"),
        hints = i and { ns.Hint("cmp_open"), ns.Hint("cmp_remove") } or { ns.Hint("cmp_add") },
        tint = i and V.compare[i].color or nil,
        off = off or (not ranks and ns.T("tip.off_no_live")) or nil,
        onClick = function(button)
            V.CompareClick(ranks, name, button)
            refresh()
        end,
    }
end
function ns.ShareAction(ranks, spec, name, plan)
    local st = ns.ShareTargetState()
    return {
        label = ns.T(st.name and "act.share_target" or "act.share"), icon = "share",
        tip = st.tip or ns.T("tip.share"),
        off = st.off or (not ranks and ns.T("tip.off_no_live")) or nil,
        hover = function() ns.ShareTargetState(true) end,
        onClick = function()
            local ok, msg = ns.ShareBuild(ranks, spec, name, V.class, plan)
            if msg and not ok then ns.warn(msg) end
        end,
    }
end
local function learnTip(plan)
    if plan and ns.GlyphPlanCount(plan.glyphs) > 0 then
        return ns.T("tip.learn") .. "\n\n" .. ns.T("tip.learn_no_glyphs")
    end
    return ns.T("tip.learn")
end
ns.LearnTip = learnTip
local function toBuilderAction(ranks, plan)
    return { label = ns.T("act.builder"), tip = ns.T("tip.builder"), icon = "builder",
             onClick = function()
                 V.OpenBuilder(ranks, plan)
                 refresh()
             end }
end
local function gearAction(group)
    if not (ns.GearSets and ns.QuickGear) then return nil end
    local key = (group == 2 and ns.CircleLoaded() == 3) and "3" or tostring(group)
    local gear = ns.QuickGear()
    local bound = gear[key]
    if bound and not ns.GearExists(bound) then bound = nil end
    local sets = ns.GearSets()
    local name = V.SetName(group)
    local active = ns.IsActiveGroup(group)
    local menu = { { label = ns.T("menu.gear_none"), check = bound == nil, tip = ns.T("tip.set_gear_none"),
                     onClick = function() gear[key] = nil; refresh() end } }
    for _, set in ipairs(sets) do
        local n = set
        menu[#menu + 1] = { label = n, check = bound == n, tip = ns.T("tip.set_gear_bind", n, name),
                            onClick = function()
                                gear[key] = n
                                if active then ns.WearGear(n) end
                                refresh()
                            end }
    end
    return { label = bound and ns.T("act.gear_bound", bound) or ns.T("act.set_gear"),
             tip = ns.T("tip.set_gear", name), icon = "gear", menu = menu,
             off = #sets == 0 and ns.T("tip.gear_none") or nil,
             tint = bound and ns.C.positive or nil }
end
local function setActions()
    local out = {}
    if not V.Own() then return out end
    local group = V.Group()
    local active = ns.IsActiveGroup(group)
    if active and ns.PreviewSpent(group) > 0 then
        local busy = waiting()
        return {
            { label = ns.T("act.reset_preview"), tip = ns.T("tip.reset_preview"), off = busy, icon = "reset", kind = "word",
              onClick = function() ns.LearnReset(group) end },
            { label = ns.T("act.learn_preview"), tip = ns.T("tip.learn_preview"), off = busy, icon = "learn", kind = "main",
              onClick = function() ns.LearnCommit(group) end },
        }
    end
    local glyphs = V.OnGlyphs()
    local pick = not glyphs and V.Mode() == "pick" and V.pick or nil
    if pick then
        out[#out + 1] = toBuilderAction(pick.ranks, pick.plan)
        out[#out + 1] = ns.CompareAddAction(pick.ranks, pick.name)
    elseif not glyphs then
        local mine, label = V.MyRanks(), V.GroupLabel()
        if mine then
            local snap = ns.SnapshotTalents(group)
            out[#out + 1] = { label = ns.T("act.save_current"), tip = ns.T("tip.save"), icon = "save",
                              onClick = function() ns.Popup("HTP_TALENTS_SAVE", nil, nil, { group = group }) end }
            out[#out + 1] = ns.CompareAddAction(mine, label)
            out[#out + 1] = ns.ShareAction(mine, snap and snap.spec, label, { glyphs = ns.LiveGlyphPlan(group) })
        end
    end
    local gearAct = gearAction(group)
    if gearAct then out[#out + 1] = gearAct end
    if not active and (GetNumTalentGroups() or 1) >= 2 then
        out[#out + 1] = { label = ns.T("act.activate"), tip = ns.T("tip.activate"), off = waiting(), cast = true,
                          kind = "main", icon = "activate",
                          onClick = function() ns.ActivateSpec(group) end }
    elseif pick then
        local ranks = pick.ranks
        out[#out + 1] = { label = ns.T("act.learn"), tip = learnTip(pick.plan), off = ns.LearnBlock(), icon = "learn",
                          kind = "main",
                          onClick = function() ns.LearnBuild(ranks) end }
    end
    return out
end
local function builderActions()
    local ranks, class = V.Builder(), V.class
    if ns.RanksTotal(ranks) == 0 then
        if not V.Own() then return {} end
        return { ns.BaseCurrentAction() }
    end
    local copy = ns.CopyRanks(ranks)
    local out = {
        { label = ns.T("act.base"), tip = ns.T("tip.base"), icon = "base", menu = ns.BaseMenu() },
        ns.CompareAddAction(copy, ns.T("sub.builder")),
        ns.ShareAction(copy, nil, ns.T("sub.builder"), ns.PlanCopy(V.BuilderPlan())),
        { label = ns.T("act.save"), tip = ns.T("tip.save_builder"), icon = "save", kind = "word",
          onClick = function() ns.Popup("HTP_TALENTS_SAVE", nil, nil, { ranks = ns.CopyRanks(ranks), class = class,
                                                                      plan = ns.PlanCopy(V.BuilderPlan()) }) end },
    }
    if V.Own() then
        out[#out + 1] = { label = ns.T("act.learn"), tip = learnTip(V.BuilderPlan()), off = ns.LearnBlock(), icon = "learn",
                          kind = "main",
                          onClick = function() ns.LearnBuild(ranks) end }
    end
    return out
end
local function targetActions()
    local d = V.inspect
    local snap = ns.SnapshotTalents(GetActiveTalentGroup() or 1)
    local mine = snap and snap.points > 0 and snap.ranks or nil
    return {
        { label = ns.T("act.save_mine"), tip = ns.T("tip.save_inspect"), icon = "save",
          onClick = function()
              local ok, msg = ns.SaveCopiedBuild(d)
              if msg and not ok then ns.warn(msg) end
              refresh()
          end },
        toBuilderAction(d.ranks),
        ns.CompareAddAction(d.ranks, ns.InspectName(d)),
        { label = ns.T("act.compare_mine"), tip = ns.T("tip.compare_mine"), icon = "target", kind = "word",
          off = (d.class ~= ns.PlayerClass() and ns.T("tip.off_cmp_class")) or (not mine and ns.T("tip.off_no_live")) or nil,
          onClick = function()
              V.compare = nil
              V.CompareAdd(d.ranks, ns.InspectName(d))
              V.CompareAdd(mine, ns.View.GroupName(GetActiveTalentGroup() or 1))
              V.OpenCompare()
              refresh()
          end },
    }
end
function storedActions()
    local n = V.stored
    local off = (InCombatLockdown() and ns.T("quick.off_combat")) or waiting()
    return {
        { label = ns.T("act.load_set"), tip = ns.T("tip.load_set", n), off = off, kind = "main", icon = "activate",
          onClick = function() ns.CircleLoad(n) end },
    }
end
function ns.SourceActions()
    V.Ensure()
    local src = V.Source()
    if src == "builder" then return builderActions(), V.Status() end
    if src == "target" then return targetActions(), V.Status() end
    if src == "compare" then return {}, V.Status() end
    if src == "stored" then return storedActions(), V.Status() end
    return setActions(), V.Status()
end
