local ADDON, ns = ...
local RING_ART = "Interface\\Minimap\\MiniMap-TrackingBorder"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local DISC = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local RING = "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"
local BOMB_ICON = "Interface\\Icons\\INV_Misc_Bomb_01"
local SMITH_MODEL = "Creature\\HUMLBlackSmith\\HUMLBlackSmith.m2"
local SND_RAGE = "Sound\\Creature\\Goblin\\GoblinAggroA.wav"
local SND_FUSE = "Sound\\Item\\UseSounds\\UseFuseLighting.wav"
local SND_TICK = "Sound\\Spells\\SimonGame_Visual_GameTick.wav"
local SND_BOOM = "Sound\\Spells\\DynamiteExplode.wav"
local SEQ = { smStand = 0, smWalk = 4, smBye = 35 }
local LEN_SMITH = { [0] = 2000, [4] = 1066, [35] = 1500 }
local SMITH_SZ = 80
local MODEL_HOLD, TURN = 3, 16
local TWO_PI = math.pi * 2
local FROM_DX, FROM_DY = -280, 300
local FLY_T, ARC_H, BOMB_SZ, SPARK_SZ = 0.6, 180, 44, 10
local FALL_T, BOUNCE_H = 0.3, 24
local FUSE_T, FUSE_TICK, BLINK_MAX, BLINK_MIN = 1.0, 0.34, 0.3, 0.08
local FLASH_UP, FLASH_DOWN = 0.06, 0.55
local RING_T, RING_K, RING_MIN = 0.7, 1.7, 60
local GRAIN_CAP = 560
local ART_CELL, ART_GRID = 18, 4
local SAND_ROWS_T, SAND_JITTER = 0.6, 0.08
local SAND_GRAV, SAND_SPREAD, SAND_HOP = 900, 90, 160
local SAND_HEAP, SAND_SHRINK, SAND_TINT_T = 16, 0.55, 0.45
local DUST_DRAG, DUST_KICK, DUST_STEP = 5, 2.2, 0.05
local SAND_T, SAND_FADE = 2.0, 0.6
local PACE, ENTER_MIN = 650, 0.8
local HOLD_UP = 30
local DROP_T, DROP_BOUNCE_T, DROP_BOUNCE_H = 0.3, 0.2, 12
local FLIP_T, FLIP_GAP, FLIP_SPREAD, FLIP_REST = 0.24, 0.08, 0.8, 0.2
local COPY_FADE = 0.3
local BYE_T, LEAVE_FADE = 0.6, 0.35
local WATCHDOG_T = 18
local PANEL_ART = {
    "MainMenuBarTexture0", "MainMenuBarTexture1", "MainMenuBarTexture2", "MainMenuBarTexture3",
    "MainMenuBarLeftEndCap", "MainMenuBarRightEndCap",
}
local BARS = {
    { "ActionButton", "low" }, { "BonusActionButton", "low" },
    { "MultiBarBottomLeftButton", "low" }, { "MultiBarBottomRightButton", "low" },
    { "MultiBarRightButton", "side" }, { "MultiBarLeftButton", "side" },
}
local LOADS = { "low", "side" }
local bomb, flash, ring, sand, drv
local kits = {}
local groups = {}
local grains, grainN = {}, 0
local phase, t, total = nil, 0, 0
local fuse = { blink = 0, ticks = 0 }
local dv = {}
local sandT, sandFade
local from, to = { x = 0, y = 0 }, { x = 0, y = 0 }
local hidden = {}
local before
local function blizzardButtons()
    local out, load = {}, {}
    for _, bar in ipairs(BARS) do
        for i = 1, 12 do
            local b = _G[bar[1] .. i]
            if b and b:IsVisible() then
                local slot = b.action
                if type(slot) ~= "number" and ActionButton_GetPagedID then
                    local ok, id = pcall(ActionButton_GetPagedID, b)
                    if ok and type(id) == "number" then slot = id end
                end
                if type(slot) == "number" and not out[slot] then out[slot], load[slot] = b, bar[2] end
            end
        end
    end
    return out, load
end
local function uiPoint(f)
    local cx, cy = f:GetCenter()
    if not cx then return nil end
    local k = f:GetEffectiveScale() / UIParent:GetEffectiveScale()
    return cx * k, cy * k
end
local function screen()
    return UIParent:GetWidth(), UIParent:GetHeight()
end
local function place(f, x, y)
    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
end
local function tint(tex, c)
    tex:SetVertexColor(c[1], c[2], c[3])
end
local function topFrame()
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:EnableMouse(false)
    f:Hide()
    return f
end
local function makeModel(parent)
    local ok, m = pcall(CreateFrame, "PlayerModel", nil, parent)
    if not ok or not m or not m.SetModel or not m.SetSequenceTime then return nil end
    m:SetWidth(SMITH_SZ)
    m:SetHeight(SMITH_SZ)
    m:SetPoint("CENTER", parent, "CENTER", 0, 0)
    m:SetFrameLevel(parent:GetFrameLevel() + 1)
    if not pcall(m.SetModel, m, SMITH_MODEL) then
        m:Hide()
        return nil
    end
    m.hold = MODEL_HOLD
    m.anim = 0
    m:SetScript("OnShow", function(self)
        pcall(self.SetModel, self, SMITH_MODEL)
        self.hold = MODEL_HOLD
        self.seq = nil
        self.facing = nil
        self.shown = nil
    end)
    return m
end
local function drive(m, dt, id, facing)
    if m.hold > 0 then m.hold = m.hold - dt end
    if m.facing == nil then m.facing = facing end
    local diff = (facing - m.facing) % TWO_PI
    if diff > math.pi then diff = diff - TWO_PI end
    local step = TURN * dt
    if math.abs(diff) <= step then m.facing = facing else m.facing = m.facing + (diff > 0 and step or -step) end
    if m.hold > 0 or m.shown ~= m.facing then
        m.shown = m.facing
        if m.SetModelScale then pcall(m.SetModelScale, m, 1) end
        if m.SetPosition then pcall(m.SetPosition, m, 0, 0, 0) end
        if m.SetFacing then pcall(m.SetFacing, m, m.facing) end
    end
    if m.seq ~= id then
        m.seq = id
        m.anim = 0
    end
    m.anim = m.anim + dt * 1000
    local len = LEN_SMITH[id] or 1000
    if m.anim >= len then m.anim = m.anim - len end
    pcall(m.SetSequenceTime, m, id, m.anim)
end
local function walkFacing(dir)
    return math.pi + math.atan2(dir, 0)
end
local function makeSmith()
    local f = topFrame()
    f:SetWidth(SMITH_SZ)
    f:SetHeight(SMITH_SZ)
    f.model = makeModel(f)
    return f
end
local function ensure()
    if drv then return end
    local B = ns.C.boom
    local b = topFrame()
    b:SetWidth(BOMB_SZ)
    b:SetHeight(BOMB_SZ)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetTexture(BOMB_ICON)
    b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    b.icon:SetWidth(BOMB_SZ * 20 / 32)
    b.icon:SetHeight(BOMB_SZ * 20 / 32)
    b.icon:SetPoint("CENTER", b, "CENTER", 0, BOMB_SZ / 32)
    b.ring = b:CreateTexture(nil, "BORDER")
    b.ring:SetTexture(RING_ART)
    b.ring:SetWidth(BOMB_SZ * 53 / 32)
    b.ring:SetHeight(BOMB_SZ * 53 / 32)
    b.ring:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
    b.spark = b:CreateTexture(nil, "OVERLAY")
    b.spark:SetTexture(DISC)
    b.spark:SetBlendMode("ADD")
    tint(b.spark, B.spark)
    b.spark:SetWidth(SPARK_SZ)
    b.spark:SetHeight(SPARK_SZ)
    b.spark:SetPoint("CENTER", b, "TOPRIGHT", -8, -8)
    local fl = topFrame()
    fl:SetAllPoints(UIParent)
    fl.tex = fl:CreateTexture(nil, "BACKGROUND")
    fl.tex:SetTexture(WHITE)
    fl.tex:SetAllPoints(fl)
    tint(fl.tex, B.flash)
    fl.t = 0
    local rg = topFrame()
    rg.tex = rg:CreateTexture(nil, "ARTWORK")
    rg.tex:SetTexture(RING)
    rg.tex:SetBlendMode("ADD")
    tint(rg.tex, B.ring)
    rg.tex:SetAllPoints(rg)
    rg.t = 0
    local sd = topFrame()
    sd:SetAllPoints(UIParent)
    sd.grain = {}
    for _, key in ipairs(LOADS) do
        local cp = topFrame()
        cp.list, cp.fl = {}, {}
        kits[key] = { copy = cp, left = makeSmith(), right = makeSmith() }
    end
    bomb, flash, ring, sand = b, fl, rg, sd
    drv = CreateFrame("Frame", nil, UIParent)
    drv:Hide()
end
local function setPhase(p)
    phase = p
    t = 0
end
local function showPanel()
    local list = hidden
    hidden = {}
    for i = 1, #list do
        pcall(list[i].f.SetAlpha, list[i].f, list[i].a)
    end
end
local function dim(f)
    local ok, a = pcall(f.GetAlpha, f)
    hidden[#hidden + 1] = { f = f, a = (ok and type(a) == "number") and a or 1 }
    pcall(f.SetAlpha, f, 0)
end
local function dimPanel()
    if InCombatLockdown() or hidden[1] then return end
    if MainMenuBar and MainMenuBar:IsVisible() then dim(MainMenuBar) end
    for _, g in ipairs(groups) do
        for _, p in ipairs(g.pieces) do
            if p.btn then dim(p.btn) end
        end
    end
end
local function hideSand()
    if sand then
        for i = 1, #sand.grain do sand.grain[i]:Hide() end
        sand:Hide()
    end
    grains, grainN = {}, 0
    sandT, sandFade = nil, nil
end
local function finish()
    phase = nil
    showPanel()
    if drv then
        drv:Hide()
        bomb:Hide()
        flash:Hide()
        ring:Hide()
        for _, kit in pairs(kits) do
            kit.copy:Hide()
            kit.left:Hide()
            kit.right:Hide()
        end
    end
    hideSand()
    groups = {}
end
local function abort()
    pcall(showPanel)
    pcall(finish)
end
local function flashTick(dt)
    if not flash:IsShown() then return false end
    flash.t = flash.t + dt
    local peak = ns.C.boom.flash[4] or 1
    local a
    if flash.t < FLASH_UP then
        a = peak * flash.t / FLASH_UP
    else
        a = peak * math.max(0, 1 - (flash.t - FLASH_UP) / FLASH_DOWN)
    end
    flash:SetAlpha(a)
    if a <= 0 and flash.t >= FLASH_UP then
        flash:Hide()
        return false
    end
    return true
end
local function ringTick()
    if not ring:IsShown() then return false end
    local W = screen()
    local k = math.min(1, ring.t / RING_T)
    local e = 1 - (1 - k) * (1 - k)
    local size = RING_MIN + (W * RING_K - RING_MIN) * e
    ring:SetWidth(size)
    ring:SetHeight(size)
    ring:SetAlpha(1 - k)
    if k >= 1 then
        ring:Hide()
        return false
    end
    return true
end
local function actionTex(slot)
    return HasAction(slot) and GetActionTexture(slot) or nil
end
local function collect()
    local byKey = {}
    local function load(key)
        local g = byKey[key]
        if not g then
            g = { key = key, pieces = {} }
            byKey[key] = g
        end
        return g
    end
    for i = 1, #PANEL_ART do
        local tx = _G[PANEL_ART[i]]
        if type(tx) == "table" and tx.GetObjectType and tx:GetObjectType() == "Texture"
            and tx:IsVisible() and tx:GetTexture() then
            local p = tx:GetParent()
            local cx, cy = tx:GetCenter()
            if p and cx then
                local k = p:GetEffectiveScale() / UIParent:GetEffectiveScale()
                local ulx, uly, llx, lly, urx = tx:GetTexCoord()
                local list = load("low").pieces
                list[#list + 1] = { x = cx * k, y = cy * k, w = tx:GetWidth() * k, h = tx:GetHeight() * k,
                                    tex = tx:GetTexture(), coords = { ulx, urx, uly, lly }, art = true }
            end
        end
    end
    local buttons, loads = blizzardButtons()
    for slot, b in pairs(buttons) do
        local x, y = uiPoint(b)
        if x then
            local k = b:GetEffectiveScale() / UIParent:GetEffectiveScale()
            local old
            if before then old = before[slot] else old = actionTex(slot) end
            local list = load(loads[slot]).pieces
            list[#list + 1] = { x = x, y = y, w = b:GetWidth() * k, h = b:GetHeight() * k,
                                old = old or nil, slot = slot, btn = b }
        end
    end
    groups = {}
    for _, key in ipairs(LOADS) do
        local g = byKey[key]
        if g and g.pieces[1] then
            local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
            for _, p in ipairs(g.pieces) do
                minX, maxX = math.min(minX, p.x - p.w / 2), math.max(maxX, p.x + p.w / 2)
                minY, maxY = math.min(minY, p.y - p.h / 2), math.max(maxY, p.y + p.h / 2)
            end
            g.pw, g.ph = maxX - minX, maxY - minY
            g.cx, g.cy = (minX + maxX) / 2, (minY + maxY) / 2
            g.minY, g.maxY = minY, maxY
            g.kit = kits[key]
            groups[#groups + 1] = g
        end
    end
end
local function paint(tex, p, path)
    tex:SetTexture(path)
    if p.coords then
        tex:SetTexCoord(p.coords[1], p.coords[2], p.coords[3], p.coords[4])
    else
        tex:SetTexCoord(0, 1, 0, 1)
    end
end
local function crumble(g, p, path, cols, rows)
    local w, h = p.w / cols, p.h / rows
    local l, r, top, bot = 0, 1, 0, 1
    if p.coords then l, r, top, bot = p.coords[1], p.coords[2], p.coords[3], p.coords[4] end
    local span = math.max(1, g.maxY - g.minY)
    for row = 1, rows do
        for col = 1, cols do
            if grainN >= GRAIN_CAP then return end
            grainN = grainN + 1
            local tex = sand.grain[grainN]
            if not tex then
                tex = sand:CreateTexture(nil, "ARTWORK")
                sand.grain[grainN] = tex
            end
            local x = p.x - p.w / 2 + (col - 1) * w
            local y = p.y + p.h / 2 - row * h
            tex:SetTexture(path)
            tex:SetTexCoord(l + (r - l) * (col - 1) / cols, l + (r - l) * col / cols,
                            top + (bot - top) * (row - 1) / rows, top + (bot - top) * row / rows)
            tex:SetWidth(w)
            tex:SetHeight(h)
            tex:ClearAllPoints()
            tex:SetPoint("BOTTOMLEFT", sand, "BOTTOMLEFT", x, y)
            tint(tex, ns.C.plain)
            tex:SetAlpha(1)
            tex:Show()
            grains[grainN] = {
                tex = tex, x = x, y = y, w = w, h = h,
                delay = (g.maxY - (y + h)) / span * SAND_ROWS_T + math.random() * SAND_JITTER,
                vx = (math.random() * 2 - 1) * SAND_SPREAD,
                vy = math.random() * SAND_HOP,
                floor = math.random() * SAND_HEAP,
                a = 0.75 + math.random() * 0.25,
            }
        end
    end
end
local function buildSand()
    hideSand()
    local icons = 0
    for _, g in ipairs(groups) do
        for _, p in ipairs(g.pieces) do
            if p.art then
                local cell = math.max(ART_CELL, math.min(p.w, p.h) / ART_GRID)
                crumble(g, p, p.tex, math.max(1, math.floor(p.w / cell + 0.5)), math.max(1, math.floor(p.h / cell + 0.5)))
            elseif p.old then
                icons = icons + 1
            end
        end
    end
    if icons > 0 then
        local per = (GRAIN_CAP - grainN) / icons
        local n = (per >= 16 and 4) or (per >= 9 and 3) or (per >= 4 and 2) or 1
        for _, g in ipairs(groups) do
            for _, p in ipairs(g.pieces) do
                if p.old then crumble(g, p, p.old, n, n) end
            end
        end
    end
    sandT, sandFade = 0, nil
    sand:SetAlpha(1)
    sand:Show()
end
local function sandTick(dt)
    if not sandT then return end
    sandT = sandT + dt
    local d = dt
    if d > DUST_STEP then d = DUST_STEP end
    local W = screen()
    local S = ns.C.boom.sand
    for i = 1, grainN do
        local g = grains[i]
        local age = sandT - g.delay
        if age > 0 and not (g.still and g.sandy) then
            if g.still then
            elseif g.rest then
                g.x = g.x + g.vx * d
                g.vx = g.vx - g.vx * DUST_DRAG * d
                if math.abs(g.vx) < 2 then g.still = true end
            else
                g.vy = g.vy - SAND_GRAV * d
                g.y = g.y + g.vy * d
                g.x = g.x + g.vx * d
                if g.y <= g.floor then
                    g.y, g.rest = g.floor, true
                    g.vx = g.vx * DUST_KICK
                end
            end
            if g.x < 0 then g.x = 0 elseif g.x > W - 2 then g.x = W - 2 end
            g.tex:SetPoint("BOTTOMLEFT", sand, "BOTTOMLEFT", g.x, g.y)
            if not g.sandy then
                local k = math.min(1, age / SAND_TINT_T)
                g.tex:SetVertexColor(1 + (S[1] - 1) * k, 1 + (S[2] - 1) * k, 1 + (S[3] - 1) * k)
                local s = 1 - SAND_SHRINK * k
                g.tex:SetWidth(math.max(2, g.w * s))
                g.tex:SetHeight(math.max(2, g.h * s))
                g.tex:SetAlpha(1 + (g.a - 1) * k)
                if k >= 1 then g.sandy = true end
            end
        end
    end
    if sandFade then
        sandFade = sandFade + dt
        local a = 1 - sandFade / SAND_FADE
        if a <= 0 then hideSand() else sand:SetAlpha(a) end
    end
end
local function boom()
    bomb:Hide()
    PlaySoundFile(SND_BOOM)
    flash.t = 0
    flash:SetAlpha(0)
    flash:Show()
    ring.t = 0
    ring:SetWidth(RING_MIN)
    ring:SetHeight(RING_MIN)
    ring:SetAlpha(1)
    place(ring, to.x, to.y)
    ring:Show()
    collect()
    if not groups[1] then
        setPhase("done")
        return
    end
    buildSand()
    dimPanel()
    setPhase("sand")
end
local function flyTick()
    local k = math.min(1, t / FLY_T)
    local x = from.x + (to.x - from.x) * k
    local y = from.y + (to.y - from.y) * k + ARC_H * 4 * k * (1 - k)
    place(bomb, x, y)
    if k >= 1 then
        PlaySoundFile(SND_FUSE)
        setPhase("fall")
    end
end
local function fallTick()
    local k = math.min(1, t / FALL_T)
    place(bomb, to.x, to.y + BOUNCE_H * 4 * k * (1 - k))
    if k >= 1 then
        fuse.blink, fuse.ticks = 0, 0
        bomb.spark:SetAlpha(1)
        bomb.spark:Show()
        setPhase("fuse")
    end
end
local function fuseTick(dt)
    local k = math.min(1, t / FUSE_T)
    local period = BLINK_MAX + (BLINK_MIN - BLINK_MAX) * k
    fuse.blink = fuse.blink + dt / period
    bomb.spark:SetAlpha((fuse.blink % 1) < 0.5 and 1 or 0.1)
    local n = math.floor(t / FUSE_TICK)
    if n >= fuse.ticks and t < FUSE_T then
        fuse.ticks = n + 1
        PlaySoundFile(SND_TICK)
    end
    if t >= FUSE_T then boom() end
end
local function buildCopy(g)
    local copy = g.kit.copy
    local n = 0
    for _, p in ipairs(g.pieces) do
        n = n + 1
        local tex = copy.list[n]
        if not tex then
            tex = copy:CreateTexture(nil, "ARTWORK")
            copy.list[n] = tex
            copy.fl[n] = copy:CreateTexture(nil, "OVERLAY")
            copy.fl[n]:SetTexture(WHITE)
            copy.fl[n]:SetBlendMode("ADD")
        end
        local fl = copy.fl[n]
        tex:SetDrawLayer(p.art and "BORDER" or "ARTWORK")
        tex:SetWidth(p.w)
        tex:SetHeight(p.h)
        tex:ClearAllPoints()
        tex:SetPoint("CENTER", copy, "CENTER", p.x - g.cx, p.y - g.cy)
        local path = p.art and p.tex or p.old
        if path then
            paint(tex, p, path)
            tex:Show()
        else
            tex:Hide()
        end
        tint(fl, ns.C.boom.flash)
        fl:SetWidth(p.w)
        fl:SetHeight(p.h)
        fl:ClearAllPoints()
        fl:SetPoint("CENTER", tex, "CENTER", 0, 0)
        fl:Hide()
        p.ct, p.cf, p.flipAt, p.flipped = tex, fl, nil, nil
    end
    for i = n + 1, #copy.list do
        copy.list[i]:Hide()
        copy.fl[i]:Hide()
    end
    copy:SetWidth(math.max(1, g.pw))
    copy:SetHeight(math.max(1, g.ph))
end
local function startDeliver()
    local W = screen()
    local arrive, leave = 0, 0
    for _, g in ipairs(groups) do
        g.span = math.max(SMITH_SZ / 2, g.pw / 2 - SMITH_SZ / 2)
        g.sy = math.max(SMITH_SZ / 2, g.minY + HOLD_UP - SMITH_SZ / 2)
        g.lift = g.sy + SMITH_SZ / 2 - g.minY
        local reach = math.max(g.pw / 2, g.span + SMITH_SZ / 2) + 4
        g.dir = (g.cx <= W * 0.6) and 1 or -1
        local edge = (g.dir == 1) and -reach or (W + reach)
        g.enterT = math.max(ENTER_MIN, math.abs(g.cx - edge) / PACE)
        g.x0 = g.cx - g.dir * PACE * g.enterT
        g.out = g.dir
        if g.cx < W * 0.3 then g.out = -1 elseif g.cx > W * 0.7 then g.out = 1 end
        g.x1 = (g.out == 1) and (W + reach) or -reach
        g.leaveT = math.max(0.3, math.abs(g.x1 - g.cx) / PACE)
        arrive, leave = math.max(arrive, g.enterT), math.max(leave, g.leaveT)
        buildCopy(g)
        g.kit.copy:SetAlpha(1)
        g.kit.copy:Hide()
        g.kit.left:Hide()
        g.kit.right:Hide()
        g.gone = nil
    end
    dv.arrive, dv.leave = arrive, leave
    dv.drop = arrive + DROP_T
    dv.land = dv.drop + DROP_BOUNCE_T
    dv.flipEnd, dv.swapped = nil, false
    setPhase("deliver")
end
local function startFlips()
    local list = {}
    for _, g in ipairs(groups) do
        for _, p in ipairs(g.pieces) do
            if p.slot then
                p.new = actionTex(p.slot)
                if p.new ~= p.old then list[#list + 1] = p end
            end
        end
    end
    table.sort(list, function(a, b)
        if a.y ~= b.y then return a.y < b.y end
        return a.x < b.x
    end)
    local gap = math.min(FLIP_GAP, FLIP_SPREAD / math.max(1, #list))
    for i, p in ipairs(list) do p.flipAt = (i - 1) * gap end
    dv.flips = list
    dv.flipEnd = dv.land + ((#list > 0) and ((#list - 1) * gap + FLIP_T * 1.6) or 0) + FLIP_REST
end
local function flipTick(tf)
    for i, p in ipairs(dv.flips) do
        local u = (tf - p.flipAt) / FLIP_T
        if u >= 0 and not p.done then
            if u < 0.5 then
                p.ct:SetWidth(math.max(1, p.w * (1 - 2 * u)))
                p.cf:SetAlpha(2 * u)
                p.cf:Show()
            else
                if not p.flipped then
                    p.flipped = true
                    if p.new then
                        paint(p.ct, p, p.new)
                        p.ct:Show()
                    else
                        p.ct:Hide()
                    end
                    if i % 3 == 1 then PlaySoundFile(SND_TICK) end
                end
                p.ct:SetWidth(math.max(1, p.w * math.min(1, 2 * u - 1)))
                local a = 1 - (u - 0.5)
                if a <= 0 then
                    p.cf:Hide()
                    p.done = true
                else
                    p.cf:SetAlpha(a)
                end
            end
        end
    end
end
local function swap()
    dv.swapped = true
    showPanel()
    if sandT then sandFade = 0 end
end
local function deliverTick(dt)
    if t >= dv.land and not dv.flipEnd then startFlips() end
    if dv.flipEnd and t < dv.flipEnd then flipTick(t - dv.land) end
    if dv.flipEnd and t >= dv.flipEnd and not dv.swapped then swap() end
    local bye = dv.flipEnd and (dv.flipEnd + BYE_T)
    local left = 0
    for _, g in ipairs(groups) do
        local kit = g.kit
        local gx, seq, facing, lift, a = g.cx, SEQ.smStand, 0, g.lift, 1
        local shown = true
        if t < dv.arrive then
            local tg = t - (dv.arrive - g.enterT)
            if tg < 0 then
                shown = false
            else
                gx = g.x0 + (g.cx - g.x0) * (tg / g.enterT)
                seq, facing = SEQ.smWalk, walkFacing(g.dir)
            end
        elseif t < dv.drop then
            local k = (t - dv.arrive) / DROP_T
            lift = g.lift * (1 - k * k)
        elseif t < dv.land then
            local k = (t - dv.drop) / DROP_BOUNCE_T
            lift = DROP_BOUNCE_H * math.sin(math.pi * k)
        elseif not dv.swapped then
            lift = 0
        elseif t < bye then
            lift = 0
            seq = SEQ.smBye
        else
            lift = 0
            local k = (t - bye) / g.leaveT
            if k >= 1 then
                shown = false
                g.gone = true
            else
                gx = g.cx + (g.x1 - g.cx) * k
                seq, facing = SEQ.smWalk, walkFacing(g.out)
                a = math.min(1, (1 - k) * g.leaveT / LEAVE_FADE)
            end
        end
        if not g.gone then left = left + 1 end
        if shown then
            kit.left:SetAlpha(a)
            kit.right:SetAlpha(a)
            place(kit.left, gx - g.span, g.sy)
            place(kit.right, gx + g.span, g.sy)
            if not kit.left:IsShown() then
                kit.left:Show()
                kit.right:Show()
            end
            if kit.left.model then drive(kit.left.model, dt, seq, facing) end
            if kit.right.model then drive(kit.right.model, dt, seq, facing) end
        else
            kit.left:Hide()
            kit.right:Hide()
        end
        local ca = 1
        if dv.swapped then ca = 1 - (t - dv.flipEnd) / COPY_FADE end
        if not shown and not dv.swapped then ca = 0 end
        if ca <= 0 then
            kit.copy:Hide()
        else
            kit.copy:SetAlpha(ca)
            place(kit.copy, gx, g.cy + lift)
            if dv.swapped then place(kit.copy, g.cx, g.cy) end
            kit.copy:Show()
        end
    end
    if left == 0 then finish() end
end
local function tick(dt)
    if dt > 0.1 then dt = 0.1 end
    if InCombatLockdown() then finish(); return end
    t = t + dt
    total = total + dt
    if total > WATCHDOG_T then finish(); return end
    local glow = flashTick(dt)
    if ring:IsShown() then
        ring.t = ring.t + dt
        if ringTick() then glow = true end
    end
    if phase == "fly" then
        flyTick()
    elseif phase == "fall" then
        fallTick()
    elseif phase == "fuse" then
        fuseTick(dt)
    elseif phase == "sand" then
        sandTick(dt)
        if t >= SAND_T then startDeliver() end
    elseif phase == "deliver" then
        sandTick(dt)
        deliverTick(dt)
    elseif phase == "done" then
        if not glow then finish() end
    else
        finish()
    end
end
local function target(list)
    if MainMenuBar and MainMenuBar:IsVisible() then
        local x, y = uiPoint(MainMenuBar)
        if x then return x, y end
    end
    local x1, x2, y1, y2
    for _, b in pairs(list) do
        local x, y = uiPoint(b)
        if x then
            x1, x2 = math.min(x1 or x, x), math.max(x2 or x, x)
            y1, y2 = math.min(y1 or y, y), math.max(y2 or y, y)
        end
    end
    if x1 then return (x1 + x2) / 2, (y1 + y2) / 2 end
    local W = screen()
    return W / 2, 40
end
local function enabled()
    return not (HTP_TalentsDB and HTP_TalentsDB.murlocs == false)
end
local function report(err)
    ns.ParadeError = err
    if ns.ParadeWatch and GetTime() < ns.ParadeWatch then
        ns.ParadeWatch = nil
        ns.say(ns.T("msg.show_error", tostring(err)))
    end
end
local function parade(ops)
    if not (ops and ops[1]) or not enabled() or InCombatLockdown() then return end
    local list = blizzardButtons()
    local seen = false
    for _, op in ipairs(ops) do
        if list[op.slot] then seen = true; break end
    end
    if not seen then return end
    if phase then finish() end
    ensure()
    before = (type(ops.before) == "table") and ops.before or nil
    to.x, to.y = target(list)
    from.x, from.y = to.x + FROM_DX, to.y + FROM_DY
    hideSand()
    groups = {}
    total = 0
    bomb.spark:Hide()
    place(bomb, from.x, from.y)
    bomb:SetAlpha(1)
    bomb:Show()
    drv:SetScript("OnUpdate", function(_, dt)
        local ok, err = pcall(tick, dt)
        if not ok then
            abort()
            report(err)
        end
    end)
    PlaySoundFile(SND_RAGE)
    setPhase("fly")
    drv:Show()
end
function ns.GoblinParade(ops)
    local ok, err = pcall(parade, ops)
    if not ok then
        abort()
        ns.ParadeError = err
    end
end
function ns.GoblinShowing()
    return phase ~= nil or hidden[1] ~= nil
end
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_LEAVING_WORLD")
events:RegisterEvent("PLAYER_LOGOUT")
events:SetScript("OnEvent", function()
    if phase or hidden[1] then abort() end
end)
local lastShow, sameRun = nil, 0
function ns.BarsParade(ops)
    local shows = { ns.GoblinParade }
    if ns.MurlocParade then shows[#shows + 1] = ns.MurlocParade end
    local pick = shows[math.random(#shows)]
    if #shows > 1 and pick == lastShow and sameRun >= 2 then
        pick = pick == shows[1] and shows[2] or shows[1]
    end
    sameRun = pick == lastShow and sameRun + 1 or 1
    lastShow = pick
    pick(ops)
end
function ns.ParadeTest(which)
    local show = which == "murlocs" and ns.MurlocParade or which == "goblins" and ns.GoblinParade or nil
    if not show then return ns.T("msg.show_usage") end
    if InCombatLockdown() then return ns.T("msg.bars_combat") end
    if HTP_TalentsDB and HTP_TalentsDB.murlocs == false then return ns.T("msg.show_off") end
    local ops = {}
    for slot in pairs(blizzardButtons()) do
        if HasAction(slot) and #ops < 12 then
            ops[#ops + 1] = { slot = slot, kind = "put", tex = GetActionTexture(slot) }
        end
    end
    if #ops == 0 then return ns.T("msg.show_empty") end
    ns.ParadeError = nil
    ns.ParadeWatch = GetTime() + 10
    show(ops)
    if ns.ParadeError then return ns.T("msg.show_error", tostring(ns.ParadeError)) end
    return nil
end
