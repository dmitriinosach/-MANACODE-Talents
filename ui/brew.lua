local ADDON, ns = ...
local P = ns.Parade
if not P then return end
local T_IN, T_SHOVE, T_FLEE, FLEE_T, ROLL_T = 1.3, 1.4, 1.7, 0.9, 0.9
local T_BURST, WAVE_T, DRAIN_T = T_SHOVE + ROLL_T, 2.9, 1.2
local T_DRAIN = T_BURST + WAVE_T
local T_POP, POP_SPREAD, POP_T, GROW_T = T_DRAIN + 0.9, 1.6, 0.15, 0.3
local GAP = 0.07
local BACK_T, SIP_T, LAUGH_AT, OUT_T = 0.8, 1.2, 0.6, 0.9
local LENGTH = T_POP + POP_SPREAD + POP_T + GROW_T + 0.2 + BACK_T + SIP_T + OUT_T + 0.2
local WAVE_MIN, WAVE_OVER, BASE = 190, 30, 0.62
local FACE, CREST_AT, CREST_W, RIPPLE, TAPER = 50, 70, 90, 7, 80
local COLS, DEEP, FOAM_N, CURL, SPRAY, FIZZ = 48, 4, 80, 8, 10, 12
local FOAM_SZ = 22
local DRIFT, SPIN, BOB = 0.85, 5, 10
local DWARF_X, KEG_DX, MUG_SZ = 70, 62, 30
local ROLL_MIN, BLAST_GAP, BLAST_MAX, KEG_HOP = 140, 110, 0.45, 12
local KEG_SZ, HOOP_K, SEAMS, SEAM_DOTS, SEAM_SZ, SEAM_GAP, BUNG_SZ, ROLL_K = 60, 1.16, 4, 12, 5, 0.3, 9, 1
local DWARF_LEVEL, KEG_LEVEL = 20, 23
local STAVES, STAVE_T, STAVE_G, RING_T, FLASH_T = 10, 1.0, 420, 0.45, 0.25
local MUG = "Interface\\Icons\\INV_Drink_04"
local FX_MUG, FX_DEEP, FX_COL, FX_FOAM, FX_CURL, FX_SPRAY, FX_FIZZ, FX_BUBBLE = 2, 3, 7, 55, 135, 143, 153, 165
local FX_RING, FX_STAVE, STAVE_OWN = 245, 246, 5
local function kegArt(a)
    if a.art then return a.art end
    local C = ns.C.show
    if a.model then a.model:Hide() end
    if a.icon then a.icon:Hide() end
    local function disc(layer, c, size)
        local tx = a:CreateTexture(nil, layer)
        tx:SetTexture(P.BLOB)
        P.Tint(tx, c)
        tx:SetWidth(size)
        tx:SetHeight(size)
        tx:SetPoint("CENTER", a, "CENTER", 0, 0)
        return tx
    end
    local art = { dots = {} }
    disc("BORDER", C.iron, KEG_SZ * HOOP_K)
    disc("ARTWORK", C.wood, KEG_SZ)
    for i = 1, SEAMS * SEAM_DOTS do art.dots[i] = disc("OVERLAY", C.stave, SEAM_SZ) end
    art.bung = disc("OVERLAY", C.iron, BUNG_SZ)
    a.art = art
    return art
end
local function kegTurn(a, ang)
    local art = a.art
    local r = KEG_SZ / 2
    local cs, sn = math.cos(ang), math.sin(ang)
    local n = 0
    for j = 1, SEAMS do
        local d = (j - (SEAMS + 1) / 2) * SEAM_GAP * r
        local half = math.sqrt((0.9 * r) ^ 2 - d * d)
        for q = 1, SEAM_DOTS do
            local u = -half + 2 * half * (q - 1) / (SEAM_DOTS - 1)
            n = n + 1
            art.dots[n]:SetPoint("CENTER", a, "CENTER", u * cs - d * sn, u * sn + d * cs)
        end
    end
    art.bung:SetPoint("CENTER", a, "CENTER", 0.45 * r * cs, 0.45 * r * sn)
end
local function surface(ctx, x, t, front, lvl)
    local s = front - x
    if s <= 0 or x < ctx.kx then return 0, 0 end
    local face = P.Ease(P.K(s, 0, FACE))
    local d = (s - CREST_AT) / CREST_W
    local crest = math.exp(-d * d)
    local rip = RIPPLE * math.sin(x * 0.021 - t * 5) + RIPPLE * 0.5 * math.sin(x * 0.047 + t * 3.1)
    local hgt = (lvl * (BASE + (1 - BASE) * crest) + rip * math.min(1, lvl / 60)) * face * P.Ease(P.K(x - ctx.kx, 0, TAPER))
    return math.max(0, hgt), crest * face
end
local function setup(ctx)
    if not P.Stage(ctx) then return false end
    local C = ns.C.show
    local W = P.Screen()
    local low = ctx.low
    ctx.gx, ctx.gy = DWARF_X, math.max(60, low.cy + 20)
    ctx.ky = ctx.gy - (P.MODELS.dwarf.size - KEG_SZ) / 2
    ctx.k0 = ctx.gx + KEG_DX
    ctx.kx = math.max(ctx.k0 + ROLL_MIN, math.min(low.x1 - BLAST_GAP, W * BLAST_MAX))
    ctx.ang = 0
    ctx.wh = math.max(WAVE_MIN, (low.y2 + WAVE_OVER) / BASE)
    ctx.speed = (W + 260 - ctx.kx) / WAVE_T
    ctx.span = W + 80 - ctx.kx
    ctx.dwarf, ctx.keg = P.Actor("dwarf"), P.Actor("keg")
    ctx.dwarf:SetFrameLevel(DWARF_LEVEL)
    if ctx.dwarf.model then ctx.dwarf.model:SetFrameLevel(DWARF_LEVEL + 1) end
    ctx.keg:SetFrameLevel(KEG_LEVEL)
    kegArt(ctx.keg)
    ctx.mug = P.Fx(FX_MUG, MUG)
    ctx.ring = P.Fx(FX_RING, P.RING, C.blast, true)
    ctx.staves = {}
    local spare = FX_BUBBLE + #ctx.btns
    for i = 1, STAVES do
        local id = (i <= STAVE_OWN) and (FX_STAVE + i - 1) or (spare + i - STAVE_OWN - 1)
        if i > STAVE_OWN and id >= FX_RING then break end
        ctx.staves[i] = P.Fx(id, P.WHITE, C.stave)
    end
    ctx.wave = {}
    local function many(n, first, path, c)
        local list = {}
        for i = 1, n do
            list[i] = P.Fx(first + i - 1, path, c)
            ctx.wave[#ctx.wave + 1] = list[i]
        end
        return list
    end
    ctx.cols = many(COLS, FX_COL, P.WHITE, C.beer)
    ctx.deep = many(DEEP, FX_DEEP, P.WHITE, C.beerDeep)
    ctx.foam = many(FOAM_N, FX_FOAM, P.BLOB, C.foam)
    ctx.curl = many(CURL, FX_CURL, P.BLOB, C.foam)
    ctx.spray = many(SPRAY, FX_SPRAY, P.BLOB, C.foam)
    ctx.fizz = many(FIZZ, FX_FIZZ, P.BLOB, C.fizz)
    local n = 0
    for _, p in ipairs(ctx.btns) do
        p.hit = T_BURST + math.max(0, p.x - ctx.kx) / ctx.speed
        p.bubble = P.Fx(FX_BUBBLE + n, P.BLOB, C.foam)
        p.spin = ((p.i % 2 == 0) and 1 or -1) * (SPIN + (p.i % 5))
        n = n + 1
    end
    return true
end
local function planPop(ctx)
    local n = #ctx.btns
    local gap = math.min(GAP, POP_SPREAD / math.max(1, n))
    for i, p in ipairs(ctx.btns) do
        p.new = P.NewTex(ctx, p)
        p.pop = T_POP + ((i * 7) % n) * gap
    end
    ctx.fin = T_POP + math.max(0, n - 1) * gap + POP_T + GROW_T + 0.2
end
local function drawWave(ctx, t, front, lvl)
    local C = ns.C.show
    local W = P.Screen()
    local kx = ctx.kx
    local beerA, foamA = C.beer[4] or 1, (C.foam[4] or 1) * math.min(1, lvl / 40)
    local cw = ctx.span / COLS
    for i = 1, COLS do
        local cx = kx + (i - 0.5) * cw
        local hgt = surface(ctx, cx, t, front, lvl)
        P.FxPut(ctx.cols[i], cx, hgt / 2, cw, hgt, (hgt > 1) and beerA or 0)
    end
    local x1, x2 = kx + TAPER, math.min(front - FACE - 10, W + 60)
    local flat = lvl * BASE - RIPPLE * 1.5 - 4
    for j = 1, DEEP do
        local hj = flat * (1 - j / (DEEP + 1))
        P.FxPut(ctx.deep[j], (x1 + x2) / 2, hj / 2, x2 - x1, hj, (hj > 1) and (C.beerDeep[4] or 1) or 0)
    end
    local fs = ctx.span / FOAM_N
    local sz = math.max(FOAM_SZ, fs * 1.5)
    for i = 1, FOAM_N do
        local fx = kx + (i - 0.5) * fs
        local hgt, crest = surface(ctx, fx, t, front, lvl)
        local d = sz + 8 * math.sin(i * 1.7) + 4 * math.sin(t * 3 + i) + sz * crest
        P.FxPut(ctx.foam[i], fx, hgt + d * 0.15 + 3 * math.sin(i * 2.3 + t * 4), d, nil, (hgt > 6) and foamA or 0)
    end
    local live = (front < W + 80) and 1 or 0
    for i = 1, CURL do
        local k = i / CURL
        local sx = front - FACE * k
        local hgt = surface(ctx, sx, t, front, lvl)
        P.FxPut(ctx.curl[i], sx + 12 * k + 6 * math.sin(t * 7 + i), hgt + 4,
                sz + sz * k + 4 * math.sin(t * 8 + i * 1.3), nil, live * foamA)
    end
    local top = surface(ctx, front - CREST_AT, t, front, lvl)
    for i = 1, SPRAY do
        local ph = (t * 1.5 + i * 0.37) % 1
        P.FxPut(ctx.spray[i], front - 20 + ph * (70 + 10 * i), top * (0.75 + 0.03 * i) + 140 * ph * (1 - ph) - 50 * ph,
                11 - 6 * ph, nil, live * (1 - ph) * foamA)
    end
    for i = 1, FIZZ do
        local bx = kx + TAPER + ((i * 0.618) % 1) * (W - kx - TAPER)
        local ph = (t * 0.6 + i * 0.29) % 1
        local hgt = surface(ctx, bx, t, front, lvl)
        P.FxPut(ctx.fizz[i], bx + 4 * math.sin(t * 5 + i), 8 + ph * (hgt - 24), 5 + (i % 4) * 2, nil,
                (hgt > 40) and (C.fizz[4] or 1) * math.sin(math.pi * ph) or 0)
    end
end
local function tick(ctx, dt)
    local t = ctx.t
    local C, S = ns.C.show, P.SND
    local W = P.Screen()
    local low = ctx.low
    local gx, gy, kx = ctx.gx, ctx.gy, ctx.kx
    if P.At(ctx, "plan", T_POP) then planPop(ctx) end
    local fin = ctx.fin or LENGTH
    local dm = ctx.dwarf.model
    local car = dm and dm.def and dm.def.key == "rocketcar" or false
    local x, y, seq, dir, da = gx, gy, "stand", 1, 1
    if t < T_IN then
        x = -70 + (gx + 70) * P.K(t, 0, T_IN)
        seq = "walk"
    elseif t < T_FLEE then
        seq = "stand"
    elseif t < fin then
        local k = P.K(t, T_FLEE, FLEE_T)
        x = gx + (-90 - gx) * k
        seq, dir, da = "run", -1, (k < 1) and 1 or 0
    elseif t < fin + BACK_T then
        x = -70 + (gx + 70) * P.K(t, fin, BACK_T)
        seq = "walk"
    elseif t < fin + BACK_T + SIP_T then
        seq, dir = "laugh", 0
    else
        local k = P.K(t, fin + BACK_T + SIP_T, OUT_T)
        x = gx + (-90 - gx) * k
        y = gy + (car and 0 or 10 * math.sin(k * math.pi * 5))
        seq, dir, da = car and "run" or "walk", -1, 1 - P.K(k, 0.6, 0.4)
    end
    P.Act(ctx.dwarf, dt, x, y, seq, dir, da)
    if P.At(ctx, "shove", T_SHOVE) then P.Play(S.dwarfShout, true) end
    if P.At(ctx, "burst", T_BURST) then
        P.Play(S.kegBoom, true)
        P.Play(S.kegBreak, true)
        P.Play(S.splash)
        P.Play(S.wave)
    end
    if P.At(ctx, "crash", T_BURST + WAVE_T * 0.5) then P.Play(S.crash) end
    if P.At(ctx, "sip", fin + BACK_T + 0.1) then
        if car then P.Play(S.gnomeDrink, true) else P.Play(S.drink) end
    end
    if not car and P.At(ctx, "laugh", fin + BACK_T + LAUGH_AT) then P.Play(S.dwarfLaugh, true) end
    local keg = ctx.keg
    if t < T_BURST then
        local bx, by = x + KEG_DX, ctx.ky + 5 * math.abs(math.sin(t * 9))
        if t >= T_SHOVE then
            local k = P.K(t, T_SHOVE, ROLL_T)
            bx = ctx.k0 + (kx - ctx.k0) * k * (0.7 + 0.3 * k)
            by = ctx.ky + KEG_HOP * math.abs(math.sin(k * math.pi * 3)) * (1 - 0.5 * k)
        elseif t >= T_IN then
            by = ctx.ky
        end
        ctx.ang = ctx.ang - (bx - (ctx.lastX or bx)) / (KEG_SZ / 2) * ROLL_K
        ctx.lastX = bx
        kegTurn(keg, ctx.ang)
        P.Place(keg, bx, by)
        keg:SetAlpha(1)
        if not keg:IsShown() then keg:Show() end
    elseif keg:IsShown() then
        keg:Hide()
    end
    local tb = t - T_BURST
    P.Flash(C.blast, (tb >= 0) and (C.blast[4] or 1) * (1 - P.K(tb, 0, FLASH_T)) or 0)
    local rk = P.K(tb, 0, RING_T)
    P.FxPut(ctx.ring, kx, ctx.ky, 60 + 420 * rk, nil, (tb >= 0) and (C.blast[4] or 1) * (1 - rk) or 0)
    local count = #ctx.staves
    for i = 1, count do
        if tb < 0 or tb >= STAVE_T then
            P.FxPut(ctx.staves[i], 0, 0, 0, nil, 0)
        else
            local a = math.pi * (0.12 + 0.76 * i / (count + 1))
            local v = 260 + (i * 53) % 140
            local ph = tb * (7 + i % 4) + i
            P.FxPut(ctx.staves[i], kx + math.cos(a) * v * tb, ctx.ky + math.sin(a) * v * tb - STAVE_G * tb * tb,
                    6 + 16 * math.abs(math.cos(ph)), 6 + 16 * math.abs(math.sin(ph)), 1 - P.K(tb, STAVE_T - 0.3, 0.3))
        end
    end
    local ma = (car and 0 or 1) * P.K(t, fin + BACK_T, 0.15) * (1 - P.K(t, fin + BACK_T + SIP_T - 0.2, 0.2))
    P.FxPut(ctx.mug, gx + 20, gy + 10 + 14 * math.sin(math.pi * P.K(t, fin + BACK_T + 0.1, 0.7)), MUG_SZ, nil, ma)
    local front = kx + ctx.speed * (t - T_BURST)
    local rise = P.Ease(P.K(t, T_BURST, 0.5))
    local drain = 1 - P.Ease(P.K(t, T_DRAIN, DRAIN_T))
    local lvl = ctx.wh * rise * drain
    if t >= T_BURST and lvl > 2 then
        drawWave(ctx, t, front, lvl)
    else
        for i = 1, #ctx.wave do P.FxPut(ctx.wave[i], 0, 0, 0, nil, 0) end
    end
    P.ScreenTint(C.beer, 0.1 * rise * drain)
    if not ctx.unstaged then
        local under = P.K(t, T_BURST + math.max(0, low.cx - kx) / ctx.speed, 0.4)
        local back = P.K(t, T_DRAIN + DRAIN_T * 0.5, 0.8)
        P.Art(ctx, (t < T_DRAIN) and (1 - under) or back)
        for _, p in ipairs(ctx.btns) do
            if t < T_POP then
                if t < p.hit then
                    P.Icon(p, p.old, p.x, p.y, 1, 1)
                else
                    local dtm = t - p.hit
                    local ix = p.x + ctx.speed * DRIFT * dtm
                    local top = surface(ctx, ix, t, front, lvl)
                    local iy = p.y + (top - p.h * 0.15 - p.y) * P.K(dtm, 0, 0.4) + BOB * math.sin(dtm * 6 + p.i)
                    P.Icon(p, p.old, ix, iy, 1 - 0.2 * P.K(dtm, 0, 1), (ix < W + 40) and drain or 0)
                    P.Spin(p.sp, dtm * p.spin)
                end
                P.FxPut(p.bubble, p.x, p.y, p.w * (0.8 + 0.1 * math.sin(t * 5 + p.i)), nil,
                        (C.foam[4] or 1) * P.K(t, T_DRAIN + 0.2, 0.5))
            else
                if P.At(ctx, "flat", T_POP) then
                    for _, q in ipairs(ctx.btns) do P.Spin(q.sp, 0) end
                end
                local k = P.K(t, p.pop, POP_T)
                if k <= 0 then
                    P.Icon(p, nil, 0, 0, 0, 0)
                    P.FxPut(p.bubble, p.x, p.y, p.w * (0.8 + 0.1 * math.sin(t * 5 + p.i)), nil, C.foam[4] or 1)
                else
                    P.FxPut(p.bubble, p.x, p.y, p.w * (0.8 + 0.6 * k), nil, (C.foam[4] or 1) * (1 - k))
                    local g = P.K(t, p.pop + POP_T * 0.5, GROW_T)
                    P.Icon(p, p.new, p.x, p.y, 0.6 + 0.4 * g + 0.15 * math.sin(math.pi * g), 1)
                    if not p.popped then
                        p.popped = true
                        if p.i % 4 == 1 then P.Play(S.bubble) end
                    end
                end
            end
        end
    end
    if t >= fin then P.Unstage(ctx) end
    return t >= fin + BACK_T + SIP_T + OUT_T
end
local DEF = { key = "brew", length = LENGTH, setup = setup, tick = tick }
function ns.BrewParade(ops)
    P.Start(DEF, ops)
end
ns.RegisterParade("brew", ns.BrewParade)
