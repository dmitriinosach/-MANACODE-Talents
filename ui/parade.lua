local ADDON, ns = ...
local P = {}
ns.Parade = P
P.MODELS = {
    smith = { path = "Creature\\HUMLBlackSmith\\HUMLBlackSmith.m2", size = 80,
              seq = { stand = 0, walk = 4, bye = 35 }, len = { [0] = 2000, [4] = 1066, [35] = 1500 } },
    murloc = { path = "Creature\\MurlocCostume\\murloccostume_noflag.M2", size = 56,
               seq = { run = 5 }, len = { [5] = 666 } },
    bonker = { path = "Creature\\MurlocCostume\\murloccostume_noflag.M2", size = 120, w = 240, h = 240, scale = 0.5,
               seq = { stand = 0, run = 5, walk = 5, hit = 62, cheer = 70, jumpStart = 37, jump = 38, fall = 40, land = 39 },
               len = { [0] = 1667, [5] = 666, [62] = 1667, [70] = 2667, [37] = 433, [38] = 833, [40] = 833, [39] = 1666 } },
    lich = { path = "Creature\\Arthaslichking\\Arthaslichking.m2", size = 140, w = 410, h = 520, scale = 0.13,
             icon = "Interface\\Icons\\Achievement_Boss_LichKing",
             seq = { stand = 0, raise = 213, channel = 125, talk = 60, stun = 14, fall = 1 },
             len = { [0] = 4000, [213] = 3700, [125] = 1333, [60] = 6633, [14] = 2000, [1] = 11500 } },
    tirion = { npcs = { 38995, 37119, 34996 }, path = "Creature\\Tirion\\Tirion.m2", size = 170, w = 340, h = 340, scale = 0.5,
               icon = "Interface\\Icons\\Spell_Holy_HolyBolt",
               seq = { stand = 0, run = 5, walk = 4, hit = 18, cheer = 68 }, len = {}, fallback = "bonker" },
    gnome = { display = 29118, npc = 34184, size = 100, w = 200, h = 200, scale = 0.5,
              icon = "Interface\\Icons\\INV_Gizmo_02",
              seq = { stand = 0, walk = 4, run = 5, shoot = 0, think = 60, bow = 66 }, len = {}, fallback = "bonker" },
    spidertank = { path = "Creature\\t_robot\\t_robot.m2", size = 120, w = 240, h = 240, scale = 0.5,
                   icon = "Interface\\Icons\\INV_Gizmo_01",
                   seq = { stand = 0, walk = 4, run = 5 }, len = { [0] = 1500, [4] = 1000, [5] = 933 } },
    steamtank = { path = "World\\KhazModan\\Ironforge\\PassiveDoodads\\SteamTank\\IronForgeSteamTank.m2",
                  size = 170, w = 340, h = 340, scale = 0.5, seq = { stand = 0 }, len = {} },
    robot = { path = "Creature\\t_robot\\t_robot.m2", size = 100, w = 200, h = 200, scale = 0.5,
              seq = { stand = 0, walk = 4, run = 5 }, len = { [0] = 1500, [4] = 1000, [5] = 933 } },
    rocketcar = { path = "Creature\\GnomeRocketCar\\GnomeRocketCar.m2", size = 110, w = 220, h = 220, scale = 0.5,
                  icon = "Interface\\Icons\\INV_Gizmo_02",
                  seq = { stand = 0, walk = 4, run = 5, cheer = 0, laugh = 0 },
                  len = { [0] = 3300, [4] = 1666, [5] = 1500 } },
    rocket = { path = "Creature\\MissileRocketMount\\MissileRocketMount.m2", size = 140, w = 280, h = 280, scale = 0.5,
               seq = { stand = 0, walk = 4, run = 5, fly = 135 }, len = { [0] = 3000, [4] = 1667, [5] = 2000, [135] = 2000 } },
    copter = { path = "Creature\\GnomeCopter\\GnomeCopter.m2", size = 120, w = 240, h = 240, scale = 0.5,
               seq = { stand = 0 }, len = { [0] = 500 } },
    rocketchicken = { path = "Creature\\RocketChicken\\RocketChicken.m2", size = 70, w = 140, h = 140, scale = 0.5,
                      seq = { stand = 0, walk = 4, run = 5 }, len = { [0] = 2000, [4] = 1000, [5] = 667 } },
    chicken = { display = 6909, npc = 8836, path = "Creature\\Chicken\\Chicken.m2", size = 60, w = 120, h = 120, scale = 0.5,
                icon = "Interface\\Icons\\Spell_Magic_PolymorphChicken",
                seq = { stand = 0, run = 5 }, len = {}, fallback = "murloc" },
    dwarf = { npcs = { 34199, 26408, 29978 }, size = 110, w = 220, h = 220, scale = 0.5, icon = "Interface\\Icons\\INV_Drink_04",
              seq = { stand = 0, walk = 4, run = 5, cheer = 68, laugh = 70 },
              len = { [0] = 3334, [4] = 800, [5] = 600, [68] = 3000, [70] = 3000 }, fallback = "rocketcar" },
    keg = { path = "World\\Generic\\Dwarf\\Passive Doodads\\PowderKegs\\PowderKegFused.m2", size = 60, w = 120, h = 120,
            scale = 0.5, icon = "Interface\\Icons\\INV_Cask_01", seq = { stand = 0 }, len = {} },
    barrelBoom = { path = "World\\Goober\\G_BarrelExplode.m2", size = 70, w = 140, h = 140, scale = 0.5,
                   icon = "Interface\\Icons\\INV_Cask_01", seq = { stand = 0 }, len = {} },
    teleporter = { path = "World\\Generic\\Gnome\\Passive Doodads\\GnomeMachine\\GnomeMachine01.m2", size = 120,
                   seq = { stand = 0 }, len = {} },
}
for k, def in pairs(P.MODELS) do def.key = k end
local MODEL_SCALE = 1
local MODEL_HOLD, MODEL_RETRY, TURN = 3, 0.4, 16
local MODEL_SETTLE = 0.12
local TWO_PI = math.pi * 2
P.SND = {
    tick = "Sound\\Spells\\SimonGame_Visual_GameTick.wav",
    throw = "Sound\\Spells\\ThrowNet.wav",
    tinker = "Sound\\Spells\\Tradeskills\\Engineering.wav",
    goblinRage = "Sound\\Creature\\Goblin\\GoblinAggroA.wav",
    fuse = "Sound\\Item\\UseSounds\\UseFuseLighting.wav",
    boom = "Sound\\Spells\\DynamiteExplode.wav",
    wind = "sound\\spells\\shaman_windshear_01.wav",
    lichCome = "Sound\\Spells\\DeathKnight_Lichborne_State.wav",
    lichSay = "Sound\\Creature\\LichKing\\IC_Lich King_Slay01.wav",
    frost = "Sound\\Spells\\FrostNova.wav",
    funnel = "Sound\\Spells\\SoulFunnel.wav",
    soul = "Sound\\Spells\\SoulShatter_Cast.wav",
    holy = "Sound\\Spells\\Cast\\HolyCast.wav",
    bonk = { "Sound\\Spells\\Bonk1.wav", "Sound\\Spells\\Bonk2.wav", "Sound\\Spells\\Bonk3.wav" },
    murlocCry = "Sound\\Creature\\Murloc\\mMurlocAggroOld.wav",
    murlocBye = "sound\\creature\\murloc\\mmurlocpreaggroa.wav",
    fishStep = { "Sound\\Character\\Footsteps\\FootstepFishA.wav", "Sound\\Character\\Footsteps\\FootstepFishB.wav",
                 "Sound\\Character\\Footsteps\\FootstepFishC.wav", "Sound\\Character\\Footsteps\\FootstepFishD.wav" },
    glass = "Sound\\Spells\\GlassBreaking1.wav",
    release = "Sound\\Spells\\soulshatter_impact.wav",
    machine = "Sound\\Doodad\\GnomeMachine06_Closed.wav",
    box = "Sound\\Doodad\\G_GnomeMultiBoxOpen.wav",
    ray = "Sound\\Spells\\ShootWandLaunchLightning.wav",
    zap = { "Sound\\Doodad\\ID_Forge_Zap01.wav", "Sound\\Doodad\\ID_Forge_Zap02.wav", "Sound\\Doodad\\ID_Forge_Zap03.wav" },
    gnome = "Sound\\Creature\\Gnome\\GnomeAttackA.wav",
    gnomeBye = "Sound\\interface\\GnomeExploration.wav",
    chicken = "Sound\\Creature\\Chicken\\ChickenWoundA.wav",
    poly = "Sound\\Spells\\PolyMorphChicken.wav",
    dwarfShout = "kit:DwarfMaleGrimVendorNPCGreetings",
    dwarfLaugh = "Sound\\Character\\Dwarf\\DwarfMale\\DwarfMaleLaugh01.wav",
    kegBoom = "Sound\\Doodad\\G_BarrelExplodeCustom0.wav",
    kegBreak = "Sound\\Doodad\\G_KegDestroy.wav",
    gnomeDrink = "Sound\\Creature\\MillhouseManastorm\\TEMPEST_Millhouse_Drinks01.wav",
    splash = "Sound\\Character\\Footsteps\\EnterWaterSplash\\EnterWaterGiantA.wav",
    wave = "Sound\\Spells\\Missile_wave_Water.wav",
    crash = "Sound\\Effects\\DeathImpacts\\InWater\\mDeathImpactColossalWaterA.wav",
    drink = "Sound\\interface\\iDrinking1.wav",
    bubble = "sound\\spells\\ud_bubblegum_01.wav",
    gunLoad = "Sound\\Item\\Weapons\\Gun\\GunLoad01.wav",
    blast = "Sound\\Spells\\Hunter_ExplosiveShotImpact1.wav",
    step = { "Sound\\Creature\\GnomeSpiderTank\\GnomeSpiderTankFootstepA.wav",
             "Sound\\Creature\\GnomeSpiderTank\\GnomeSpiderTankFootstepB.wav",
             "Sound\\Creature\\GnomeSpiderTank\\GnomeSpiderTankFootstepC.wav" },
    launch = { "Sound\\Doodad\\G_FireworkLauncher02Custom0.wav", "Sound\\Doodad\\G_FireworkLauncher01Custom3.wav" },
    cracker = "Sound\\Doodad\\Firecrackers_ThrownExplode.wav",
    mortar = "Sound\\Doodad\\G_Mortar.wav",
    cannon = "Sound\\Doodad\\Cannon01_BlastA.wav",
}
P.WHITE = "Interface\\Buttons\\WHITE8X8"
P.DISC = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
P.BLOB = "Interface\\AddOns\\" .. ADDON .. "\\art\\kit\\plate.tga"
P.RING = "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"
local PANEL_ART = {
    "MainMenuBarTexture0", "MainMenuBarTexture1", "MainMenuBarTexture2", "MainMenuBarTexture3",
    "MainMenuBarLeftEndCap", "MainMenuBarRightEndCap",
}
local BARS = {
    { "ActionButton", "low" }, { "BonusActionButton", "low" },
    { "MultiBarBottomLeftButton", "low" }, { "MultiBarBottomRightButton", "low" },
    { "MultiBarRightButton", "side" }, { "MultiBarLeftButton", "side" },
}
local ICON_CAP, FX_CAP, ART_CAP = 80, 250, 12
local WATCH_EXTRA = 6
function P.Play(path, loud)
    if type(path) == "table" then path = path[math.random(#path)] end
    if not path then return end
    local kit = path:match("^kit:(.+)$")
    if kit then
        if not (loud and pcall(PlaySound, kit, "Master")) then pcall(PlaySound, kit) end
        return
    end
    if loud then PlaySoundFile(path, "Master") else PlaySoundFile(path) end
end
function P.Screen()
    return UIParent:GetWidth(), UIParent:GetHeight()
end
function P.UiPoint(f)
    local cx, cy = f:GetCenter()
    if not cx then return nil end
    local k = f:GetEffectiveScale() / UIParent:GetEffectiveScale()
    return cx * k, cy * k
end
function P.Place(f, x, y)
    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
end
function P.Tint(tex, c)
    tex:SetVertexColor(c[1], c[2], c[3])
end
function P.TintTo(tex, c, k)
    tex:SetVertexColor(1 + (c[1] - 1) * k, 1 + (c[2] - 1) * k, 1 + (c[3] - 1) * k)
end
function P.TopFrame(level)
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    if level then f:SetFrameLevel(level) end
    f:EnableMouse(false)
    f:Hide()
    return f
end
function P.K(t, t0, dur)
    local k = (t - t0) / dur
    if k < 0 then return 0 elseif k > 1 then return 1 end
    return k
end
function P.Ease(k)
    return k * k * (3 - 2 * k)
end
function P.Arc(x0, y0, x1, y1, k, h)
    return x0 + (x1 - x0) * k, y0 + (y1 - y0) * k + h * 4 * k * (1 - k)
end
function P.Spiral(x0, y0, x1, y1, k, radius, turns, phase)
    local a = phase + k * turns * TWO_PI
    local r = radius * (1 - k) * math.sin(math.pi * math.min(1, k * 3) / 2)
    return x0 + (x1 - x0) * k + math.cos(a) * r, y0 + (y1 - y0) * k + math.sin(a) * r
end
function P.Face(dir)
    if dir == 0 then return 0 end
    return math.pi - math.atan2(dir, 0)
end
function P.Buttons()
    local out, load, twins = {}, {}, {}
    for _, bar in ipairs(BARS) do
        for i = 1, 12 do
            local b = _G[bar[1] .. i]
            if b and b:IsVisible() then
                local slot = b.action
                if type(slot) ~= "number" and ActionButton_GetPagedID then
                    local ok, id = pcall(ActionButton_GetPagedID, b)
                    if ok and type(id) == "number" then slot = id end
                end
                if type(slot) == "number" then
                    if not out[slot] then
                        out[slot], load[slot] = b, bar[2]
                    else
                        twins[#twins + 1] = b
                    end
                end
            end
        end
    end
    return out, load, twins
end
function P.ActionTex(slot)
    return HasAction(slot) and GetActionTexture(slot) or nil
end
local hidden = {}
function P.Restore()
    local list = hidden
    hidden = {}
    for i = 1, #list do
        pcall(list[i].f.SetAlpha, list[i].f, list[i].a)
    end
end
function P.Dim(f)
    local ok, a = pcall(f.GetAlpha, f)
    hidden[#hidden + 1] = { f = f, a = (ok and type(a) == "number") and a or 1 }
    pcall(f.SetAlpha, f, 0)
end
function P.Collect(before)
    local art, btns = {}, {}
    for i = 1, #PANEL_ART do
        local tx = _G[PANEL_ART[i]]
        if type(tx) == "table" and tx.GetObjectType and tx:GetObjectType() == "Texture"
            and tx:IsVisible() and tx:GetTexture() then
            local p = tx:GetParent()
            local cx, cy = tx:GetCenter()
            if p and cx then
                local k = p:GetEffectiveScale() / UIParent:GetEffectiveScale()
                local ulx, uly, llx, lly, urx = tx:GetTexCoord()
                art[#art + 1] = { x = cx * k, y = cy * k, w = tx:GetWidth() * k, h = tx:GetHeight() * k,
                                  tex = tx:GetTexture(), coords = { ulx, urx, uly, lly }, art = true }
            end
        end
    end
    local buttons, loads = P.Buttons()
    for slot, b in pairs(buttons) do
        local x, y = P.UiPoint(b)
        if x then
            local k = b:GetEffectiveScale() / UIParent:GetEffectiveScale()
            local old
            if before then old = before[slot] else old = P.ActionTex(slot) end
            btns[#btns + 1] = { x = x, y = y, w = b:GetWidth() * k, h = b:GetHeight() * k,
                                old = old or nil, slot = slot, btn = b, load = loads[slot] }
        end
    end
    table.sort(btns, function(a, b)
        if a.x ~= b.x then return a.x < b.x end
        return a.y < b.y
    end)
    return art, btns
end
function P.ModelSources(def)
    local list = {}
    local own = def.key and HTP_TalentsDB.actors and HTP_TalentsDB.actors[def.key]
    if own then list[#list + 1] = { npc = own } end
    for _, id in ipairs(def.npcs or {}) do list[#list + 1] = { npc = id } end
    if def.npc then list[#list + 1] = { npc = def.npc } end
    local n = #list
    for k = 1, n do
        if list[k].npc then list[#list + 1] = list[k] end
    end
    if def.display then list[#list + 1] = { display = def.display } end
    if def.path and n == 0 and not def.display then list[#list + 1] = { path = def.path } end
    return list
end
function P.LoadModel(m, def, n)
    if def.unit then
        if (n or 1) > 1 then return false end
        if m.ClearModel then pcall(m.ClearModel, m) end
        return m.SetUnit ~= nil and (pcall(m.SetUnit, m, def.unit))
    end
    local src = P.ModelSources(def)[n or 1]
    if not src then return false end
    if m.ClearModel then pcall(m.ClearModel, m) end
    if src.display then
        if m.SetDisplayInfo then pcall(m.SetDisplayInfo, m, src.display) end
    elseif src.npc then
        if m.SetCreature then pcall(m.SetCreature, m, src.npc) end
    else
        pcall(m.SetModel, m, src.path)
    end
    return true
end
function P.UnitNpc(unit)
    local guid = UnitGUID and UnitGUID(unit)
    if type(guid) ~= "string" or #guid < 12 then return nil end
    local kind = tonumber(guid:sub(5, 5), 16)
    if not kind or (kind % 8 ~= 3 and kind % 8 ~= 5) then return nil end
    return tonumber(guid:sub(9, 12), 16)
end
function P.ActorKeys()
    local keys = {}
    for k, def in pairs(P.MODELS) do
        if def.npc or def.npcs or def.display then keys[#keys + 1] = k end
    end
    table.sort(keys)
    return keys
end
function ns.ParadeActor(arg)
    local key, rest = strtrim(tostring(arg or "")):lower():match("^(%S*)%s*(.-)$")
    local def = key ~= "" and P.MODELS[key]
    if not (def and (def.npc or def.npcs or def.display)) then
        local list = {}
        for _, k in ipairs(P.ActorKeys()) do
            local own = HTP_TalentsDB.actors and HTP_TalentsDB.actors[k]
            list[#list + 1] = own and (k .. " = npc:" .. own) or k
        end
        return ns.T("msg.actor_usage", table.concat(list, ", "))
    end
    if rest == "clear" then
        if HTP_TalentsDB.actors then
            HTP_TalentsDB.actors[key] = nil
            if not next(HTP_TalentsDB.actors) then HTP_TalentsDB.actors = nil end
        end
        return ns.T("msg.actor_clear", key)
    end
    local id = P.UnitNpc("target")
    if not id then return ns.T("msg.actor_target") end
    HTP_TalentsDB.actors = HTP_TalentsDB.actors or {}
    HTP_TalentsDB.actors[key] = id
    return ns.T("msg.actor_set", key, UnitName("target") or "?", id)
end
function P.ModelLoaded(m)
    if not m.GetModel then return true end
    local ok, got = pcall(m.GetModel, m)
    return ok and type(got) == "string" and got ~= ""
end
function P.ModelReset(m, def)
    m.def, m.try, m.age, m.nextTry, m.settled = def, 1, 0, MODEL_RETRY, nil
    m.ready, m.readyT = nil, 0
    if m.SetAlpha then m:SetAlpha(0) end
    P.LoadModel(m, def, 1)
end
function P.ModelStep(m, dt)
    if m.settled then return false end
    m.age = (m.age or 0) + dt
    if m.age < (m.nextTry or 0) then return false end
    if P.ModelLoaded(m) then
        m.settled = true
        return false
    end
    m.try = (m.try or 1) + 1
    m.nextTry = m.age + MODEL_RETRY
    if not P.LoadModel(m, m.def, m.try) then
        m.settled = true
        local other = m.def.fallback and P.MODELS[m.def.fallback]
        if not other then return false end
        m.def = other
        P.LoadModel(m, other, 1)
    end
    return true
end
function P.ModelSize(def)
    return def.w or def.size or 100, def.h or def.size or 100
end
function P.MakeModel(parent, size, def)
    if not def.path and not def.npc and not def.display and not def.npcs then return nil end
    local ok, m = pcall(CreateFrame, "PlayerModel", nil, parent)
    if not ok or not m or not m.SetModel or not m.SetSequenceTime then return nil end
    local w, h = P.ModelSize(def)
    if not def.w and size then w, h = size, size end
    m:SetWidth(w)
    m:SetHeight(h)
    m:SetPoint("CENTER", parent, "CENTER", 0, 0)
    m:SetFrameLevel(parent:GetFrameLevel() + 1)
    if m.EnableMouse then m:EnableMouse(false) end
    m.own = def
    m.hold = MODEL_HOLD
    m.anim = 0
    P.ModelReset(m, def)
    m:SetScript("OnShow", function(self)
        P.ModelReset(self, self.own)
        self.hold = MODEL_HOLD
        self.seq = nil
        self.facing = nil
        self.shown = nil
    end)
    return m
end
function P.Drive(m, dt, seq, facing, once)
    if P.ModelStep(m, dt) then
        m.seq = nil
        m.hold = math.max(m.hold, MODEL_HOLD * 0.5)
        m.ready, m.readyT = nil, 0
        if m.SetAlpha then m:SetAlpha(0) end
    end
    local def = m.def
    if m.hold > 0 then m.hold = m.hold - dt end
    local id = seq
    if type(seq) == "string" then id = def.seq[seq] or 0 end
    facing = facing + (def.face or 0)
    if m.facing == nil then m.facing = facing end
    local diff = (facing - m.facing) % TWO_PI
    if diff > math.pi then diff = diff - TWO_PI end
    local step = TURN * dt
    if math.abs(diff) <= step then m.facing = facing else m.facing = m.facing + (diff > 0 and step or -step) end
    if def.len[id] or m.hold > 0 or not m.ready or m.shown ~= m.facing then
        m.shown = m.facing
        if m.SetModelScale then pcall(m.SetModelScale, m, def.scale or MODEL_SCALE) end
        if m.SetPosition then pcall(m.SetPosition, m, def.px or 0, def.py or 0, def.pz or 0) end
        if m.SetFacing then pcall(m.SetFacing, m, m.facing) end
    end
    if not m.ready and P.ModelLoaded(m) then
        m.readyT = (m.readyT or 0) + dt
        if m.readyT >= MODEL_SETTLE then
            m.ready = true
            if m.SetAlpha then m:SetAlpha(1) end
        end
    end
    local len = def.len[id]
    if not len then
        if m.seq ~= id then
            m.seq = id
            if m.SetSequence then pcall(m.SetSequence, m, id) end
        end
        return
    end
    if m.seq ~= id then
        m.seq = id
        m.anim = 0
    end
    if type(once) == "number" then
        m.anim = math.min(once, len - 1)
    else
        m.anim = m.anim + dt * 1000
    end
    if m.anim >= len then
        if once then m.anim = len - 1 else m.anim = m.anim - len end
    end
    pcall(m.SetSequenceTime, m, id, m.anim)
end
local actors = {}
function P.Actor(key, n)
    local id = key .. (n or 1)
    local a = actors[id]
    if not a then
        local def = P.MODELS[key]
        local w, h = P.ModelSize(def)
        a = P.TopFrame(8)
        a:SetWidth(w)
        a:SetHeight(h)
        a.def = def
        a.model = P.MakeModel(a, nil, def)
        if not a.model and def.icon then
            a.icon = a:CreateTexture(nil, "ARTWORK")
            a.icon:SetTexture(def.icon)
            a.icon:SetWidth(def.size * 0.5)
            a.icon:SetHeight(def.size * 0.5)
            a.icon:SetPoint("CENTER", a, "CENTER", 0, 0)
        end
        actors[id] = a
    end
    a.x, a.y = 0, 0
    a:SetAlpha(1)
    return a
end
function P.Act(a, dt, x, y, seq, dir, alpha, once)
    a.x, a.y = x, y
    P.Place(a, x, y)
    alpha = alpha or 1
    if alpha <= 0 then
        a:SetAlpha(0)
        return
    end
    a:SetAlpha(alpha > 1 and 1 or alpha)
    if not a:IsShown() then a:Show() end
    if a.model then P.Drive(a.model, dt, seq, P.Face(dir), once) end
end
local stage, flash, pop, tintF
local function ensure()
    if stage then return end
    local s = P.TopFrame(2)
    s:SetAllPoints(UIParent)
    s.art, s.icon, s.fx = {}, {}, {}
    local t = P.TopFrame(1)
    t:SetAllPoints(UIParent)
    t.tex = t:CreateTexture(nil, "BACKGROUND")
    t.tex:SetTexture(P.WHITE)
    t.tex:SetAllPoints(t)
    local f = P.TopFrame(30)
    f:SetAllPoints(UIParent)
    f.tex = f:CreateTexture(nil, "BACKGROUND")
    f.tex:SetTexture(P.WHITE)
    f.tex:SetAllPoints(f)
    local p = P.TopFrame(32)
    p:SetWidth(10)
    p:SetHeight(10)
    p.text = p:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    p.text:SetPoint("CENTER", p, "CENTER", 0, 0)
    tintF, flash, pop = t, f, p
    stage = s
end
local function put(tex, x, y)
    tex:ClearAllPoints()
    tex:SetPoint("CENTER", stage, "BOTTOMLEFT", x, y)
end
local function paint(tex, p, path)
    tex:SetTexture(path)
    if p.coords then
        tex:SetTexCoord(p.coords[1], p.coords[2], p.coords[3], p.coords[4])
    else
        tex:SetTexCoord(0, 1, 0, 1)
    end
end
local layers = {}
function P.Layer(id, level)
    ensure()
    local f = layers[id]
    if not f then
        f = CreateFrame("Frame", nil, stage)
        f:SetAllPoints(stage)
        f:EnableMouse(false)
        layers[id] = f
    end
    f:SetFrameLevel(stage:GetFrameLevel() + level)
    f:SetAlpha(1)
    f:Show()
    return f
end
function P.Stage(ctx)
    ensure()
    local art, btns = P.Collect(ctx.before)
    if not btns[1] then return false end
    while #btns > ICON_CAP do table.remove(btns) end
    while #art > ART_CAP do table.remove(art) end
    ctx.art, ctx.btns = art, btns
    local box = { x1 = math.huge, x2 = -math.huge, y1 = math.huge, y2 = -math.huge }
    local low = { x1 = math.huge, x2 = -math.huge, y1 = math.huge, y2 = -math.huge }
    for i, p in ipairs(art) do
        local tex = stage.art[i]
        if not tex then
            tex = stage:CreateTexture(nil, "BORDER")
            stage.art[i] = tex
        end
        paint(tex, p, p.tex)
        P.Tint(tex, ns.C.plain)
        tex:SetAlpha(1)
        tex:SetWidth(p.w)
        tex:SetHeight(p.h)
        put(tex, p.x, p.y)
        tex:Show()
        p.sp = tex
    end
    for i = #art + 1, #stage.art do stage.art[i]:Hide() end
    for i, p in ipairs(btns) do
        local tex = stage.icon[i]
        if not tex then
            tex = stage:CreateTexture(nil, "ARTWORK")
            stage.icon[i] = tex
        end
        p.sp, p.i = tex, i
        P.Spin(tex, 0)
        P.Tint(tex, ns.C.plain)
        P.Icon(p, p.old, p.x, p.y, 1, 1)
        box.x1, box.x2 = math.min(box.x1, p.x - p.w / 2), math.max(box.x2, p.x + p.w / 2)
        box.y1, box.y2 = math.min(box.y1, p.y - p.h / 2), math.max(box.y2, p.y + p.h / 2)
        if p.load == "low" then
            low.x1, low.x2 = math.min(low.x1, p.x - p.w / 2), math.max(low.x2, p.x + p.w / 2)
            low.y1, low.y2 = math.min(low.y1, p.y - p.h / 2), math.max(low.y2, p.y + p.h / 2)
        end
    end
    for i = #btns + 1, #stage.icon do stage.icon[i]:Hide() end
    if low.x1 == math.huge then low = box end
    for _, b in ipairs({ box, low }) do
        b.cx, b.cy = (b.x1 + b.x2) / 2, (b.y1 + b.y2) / 2
    end
    ctx.box, ctx.low = box, low
    for _, tex in pairs(stage.fx) do tex:Hide() end
    for _, f in pairs(layers) do f:Hide() end
    stage:SetAlpha(1)
    stage:Show()
    if not InCombatLockdown() and not hidden[1] then
        if MainMenuBar and MainMenuBar:IsVisible() then P.Dim(MainMenuBar) end
        for _, p in ipairs(btns) do P.Dim(p.btn) end
        local _, _, twins = P.Buttons()
        for _, b in ipairs(twins) do P.Dim(b) end
    end
    return true
end
function P.Icon(p, path, x, y, scale, alpha)
    local tex = p.sp
    if not path or alpha <= 0 or scale <= 0 then
        tex:Hide()
        return
    end
    if p.shown ~= path then
        p.shown = path
        paint(tex, p, path)
    end
    tex:SetWidth(math.max(1, p.w * scale))
    tex:SetHeight(math.max(1, p.h * scale))
    tex:SetAlpha(alpha > 1 and 1 or alpha)
    put(tex, x, y)
    tex:Show()
end
function P.NewTex(ctx, p)
    if ctx.ops.pretendClear then return nil end
    return P.ActionTex(p.slot)
end
function P.Art(ctx, alpha, c, k, scale, dx, dy)
    scale = scale or 1
    dx, dy = dx or 0, dy or 0
    local b = ctx.low
    for _, p in ipairs(ctx.art) do
        if alpha <= 0 or scale <= 0 then
            p.sp:Hide()
        else
            p.sp:SetAlpha(alpha > 1 and 1 or alpha)
            if c then P.TintTo(p.sp, c, k or 0) end
            p.sp:SetWidth(math.max(1, p.w * scale))
            p.sp:SetHeight(math.max(1, p.h * scale))
            put(p.sp, b.cx + dx + (p.x - b.cx) * scale, b.cy + dy + (p.y - b.cy) * scale)
            p.sp:Show()
        end
    end
end
function P.Fx(i, path, c, add)
    if i > FX_CAP then return nil end
    local tex = stage.fx[i]
    if not tex then
        tex = stage:CreateTexture(nil, "OVERLAY")
        stage.fx[i] = tex
    end
    tex:SetTexture(path)
    tex:SetTexCoord(0, 1, 0, 1)
    tex:SetBlendMode(add and "ADD" or "BLEND")
    P.Spin(tex, 0)
    P.Tint(tex, c or ns.C.plain)
    tex:Hide()
    return tex
end
function P.Spin(tex, rad)
    if tex and tex.SetRotation then pcall(tex.SetRotation, tex, rad) end
end
function P.FxPut(tex, x, y, w, h, alpha)
    if not tex then return end
    if alpha <= 0 or w <= 0 then
        tex:Hide()
        return
    end
    tex:SetWidth(w)
    tex:SetHeight(h or w)
    tex:SetAlpha(alpha > 1 and 1 or alpha)
    put(tex, x, y)
    tex:Show()
end
function P.Unstage(ctx)
    if ctx.unstaged then return end
    ctx.unstaged = true
    P.Restore()
    for _, p in ipairs(ctx.art) do p.sp:Hide() end
    for _, p in ipairs(ctx.btns) do p.sp:Hide() end
end
function P.ScreenTint(c, alpha)
    if alpha <= 0 then
        tintF:Hide()
        return
    end
    P.Tint(tintF.tex, c)
    tintF:SetAlpha(alpha > 1 and 1 or alpha)
    tintF:Show()
end
function P.Flash(c, alpha)
    if alpha <= 0 then
        flash:Hide()
        return
    end
    P.Tint(flash.tex, c)
    flash:SetAlpha(alpha > 1 and 1 or alpha)
    flash:Show()
end
function P.Pop(text, c, x, y, scale, alpha)
    if alpha <= 0 or scale <= 0 then
        pop:Hide()
        return
    end
    pop.text:SetText(text)
    pop.text:SetTextColor(c[1], c[2], c[3])
    pop:SetScale(scale)
    pop:ClearAllPoints()
    pop:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    pop:SetAlpha(alpha > 1 and 1 or alpha)
    pop:Show()
end
function P.At(ctx, id, at)
    if ctx.t < at or ctx.fired[id] then return false end
    ctx.fired[id] = true
    return true
end
local driver, active
local shows, order, stops = {}, {}, {}
function P.Enabled()
    return not (HTP_TalentsDB and HTP_TalentsDB.murlocs == false)
end
function P.Report(err)
    ns.ParadeError = err
    if ns.ParadeWatch and GetTime() < ns.ParadeWatch then
        ns.ParadeWatch = nil
        ns.say(ns.T("msg.show_error", tostring(err)))
    end
end
local function finish()
    active = nil
    P.Restore()
    if driver then driver:Hide() end
    if stage then
        stage:Hide()
        tintF:Hide()
        flash:Hide()
        pop:Hide()
    end
    for _, a in pairs(actors) do a:Hide() end
end
local function abort()
    pcall(P.Restore)
    pcall(finish)
end
function P.StopAll()
    abort()
    for _, stop in pairs(stops) do pcall(stop) end
end
local function tick(dt)
    if dt > 0.1 then dt = 0.1 end
    local ctx = active
    if not ctx then
        finish()
        return
    end
    if InCombatLockdown() then finish(); return end
    ctx.t = ctx.t + dt
    if ctx.t > ctx.def.length + WATCH_EXTRA then finish(); return end
    if ctx.def.tick(ctx, dt) then finish() end
end
function P.Start(def, ops)
    local ok, err = pcall(function()
        if not (ops and ops[1]) or not P.Enabled() or InCombatLockdown() then return end
        local list = P.Buttons()
        local seen = false
        for _, op in ipairs(ops) do
            if list[op.slot] then seen = true; break end
        end
        if not seen then return end
        P.StopAll()
        ensure()
        local ctx = { def = def, ops = ops, t = 0, fired = {},
                      before = (type(ops.before) == "table") and ops.before or nil }
        if def.setup(ctx) == false then
            finish()
            return
        end
        if not driver then
            driver = CreateFrame("Frame", nil, UIParent)
            driver:SetScript("OnUpdate", function(_, dt)
                local good, e = pcall(tick, dt)
                if not good then
                    abort()
                    P.Report(e)
                end
            end)
        end
        active = ctx
        driver:Show()
    end)
    if not ok then
        abort()
        ns.ParadeError = err
    end
end
function P.Showing()
    return active ~= nil or hidden[1] ~= nil
end
function ns.ParadeShowing()
    return P.Showing() or (ns.GoblinShowing and ns.GoblinShowing()) or false
end
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_LEAVING_WORLD")
events:RegisterEvent("PLAYER_LOGOUT")
events:SetScript("OnEvent", function()
    if active or hidden[1] then abort() end
end)
function ns.RegisterParade(key, fn, stop)
    if not shows[key] then order[#order + 1] = key end
    shows[key] = fn
    stops[key] = stop
end
function ns.ParadeKeys()
    local out = {}
    for i, k in ipairs(order) do out[i] = k end
    return out
end
function ns.ParadeOn(key)
    local off = HTP_TalentsDB and HTP_TalentsDB.paradeOff
    return not (off and off[key])
end
function ns.ParadeSetOn(key, on)
    local off = HTP_TalentsDB.paradeOff
    if on then
        if off then
            off[key] = nil
            if next(off) == nil then HTP_TalentsDB.paradeOff = nil end
        end
    else
        if not off then
            off = {}
            HTP_TalentsDB.paradeOff = off
        end
        off[key] = true
    end
end
local lastKey, sameRun = nil, 0
function ns.ParadePick()
    local pool = {}
    for _, k in ipairs(order) do
        if ns.ParadeOn(k) then pool[#pool + 1] = k end
    end
    local n = #pool
    if n == 0 then return nil end
    local at = math.random(n)
    local key = pool[at]
    if n > 1 and key == lastKey and sameRun >= 2 then
        local i = math.random(n - 1)
        if i >= at then i = i + 1 end
        key = pool[i]
    end
    sameRun = (key == lastKey) and sameRun + 1 or 1
    lastKey = key
    return key
end
function ns.BarsParade(ops)
    local key = ns.ParadePick()
    if key then shows[key](ops) end
end
function ns.ParadeTest(arg)
    local which, mode = tostring(arg or ""):match("^(%S*)%s*(%S*)")
    local show = shows[which]
    if not show then return ns.T("msg.show_usage", table.concat(order, ", ")) end
    if InCombatLockdown() then return ns.T("msg.bars_combat") end
    if not P.Enabled() then return ns.T("msg.show_off") end
    local ops, before = {}, {}
    local clear = mode == "clear"
    for slot in pairs(P.Buttons()) do
        if HasAction(slot) then
            before[slot] = GetActionTexture(slot)
            ops[#ops + 1] = { slot = slot, kind = clear and "clear" or "put", tex = before[slot] }
        end
    end
    if #ops == 0 then return ns.T("msg.show_empty") end
    if clear then ops.before, ops.pretendClear = before, true end
    ns.ParadeError = nil
    ns.ParadeWatch = GetTime() + 10
    show(ops)
    if ns.ParadeError then return ns.T("msg.show_error", tostring(ns.ParadeError)) end
    return nil
end
