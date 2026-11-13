local ADDON, ns = ...
local P = ns.Parade
if not P or not P.Layer then return end
local T_IN, LAND_T, DUST_T = 1.1, 0.3, 0.6
local T_LOCK, LOCK_SPREAD, LOCK_T = 1.5, 0.6, 0.25
local T_FIRE, FIRE_SPREAD, GAP, FLY_T = 2.1, 1.7, 0.11, 0.5
local BIG_WAIT, BIG_T, BIG_AIM = 0.2, 0.75, 0.5
local FLASH_UP, FLASH_DOWN, RING_T = 0.06, 0.55, 0.7
local LIFT_WAIT, OUT_T = 0.5, 1.0
local LIGHT_WAIT, SWEEP_T, SHAFT_T, RISE_AT, APPEAR_T = 1.3, 1.3, 0.7, 0.35, 0.45
local LENGTH = T_FIRE + FIRE_SPREAD + FLY_T + BIG_WAIT + BIG_T + LIGHT_WAIT + SWEEP_T + SHAFT_T + APPEAR_T + 0.6
local BOT_UP, DROP_FROM, FEET, LAND_DIP = 70, 140, 50, 8
local BOT_POSE = 0
local PODS = { { 20, 38 }, { 34, 30 } }
local BIG_POD = { 26, 44 }
local MUZZLE_T, MUZZLE_SZ = 0.14, 38
local SALVO, TRAIL, TRAIL_STEP = 16, 3, 0.07
local POOL = math.ceil(FLY_T / (FIRE_SPREAD / SALVO)) + 1
local ROCKET_SZ, ROCKET_RISE, RISE_STEP = 20, 110, 22
local BIG_SZ, BIG_RISE, BIG_TRAIL = 36, 240, 4
local MARK_BIG, MARK_SMALL = 280, 120
local FIRE_T, SMOKE_T, SHAKE_T, SHAKE_HIT, SHAKE_BLAST = 0.22, 0.8, 0.18, 3, 9
local GRAV, HIT_LIFE, BLOW_LIFE, SPIN_MIN, SPIN_MAX, SHRINK = 900, 0.8, 0.9, 5, 11, 0.45
local HIT_VX, HIT_VY, BLOW_PUSH, BLOW_DIST, BLOW_UP = 140, 260, 150, 1.4, 220
local SPARKS, SPARK_V, SPARK_SZ, SPARK_T = 4, 220, 7, 0.5
local DARK_FIRE, DARK_EMPTY = 0.5, 0.75
local SWEEP_W, SWEEP_HK, SHAFT_HK, SHAFT_DROP, GLOW_K = 260, 3, 4, 50, 2.6
local PUFFS, PUFF_GAP, JET_W, JET_H = 6, 32, 34, 64
local function fx(ctx, path, c, add)
    local L = ctx.fxL
    L.n = L.n + 1
    local tex = L.tex[L.n]
    if not tex then
        tex = L:CreateTexture(nil, "OVERLAY")
        L.tex[L.n] = tex
    end
    tex:SetTexture(path)
    tex:SetTexCoord(0, 1, 0, 1)
    tex:SetBlendMode(add and "ADD" or "BLEND")
    P.Tint(tex, c)
    tex:Hide()
    return tex
end
local function newRocket(ctx, n)
    local C = ns.C.show
    local r = { trail = {} }
    for j = 1, n do r.trail[j] = fx(ctx, P.BLOB, C.smoke) end
    r.glow = fx(ctx, P.RING, C.fire, true)
    r.head = fx(ctx, P.RING, C.rocket, true)
    return r
end
local function hideRocket(r)
    P.FxPut(r.head, 0, 0, 0, nil, 0)
    P.FxPut(r.glow, 0, 0, 0, nil, 0)
    for j = 1, #r.trail do P.FxPut(r.trail[j], 0, 0, 0, nil, 0) end
end
local function path(x0, y0, x2, y2, rise, k)
    k = k * (0.45 + 0.55 * k)
    local cx, cy = x0 + (x2 - x0) * 0.3, math.max(y0, y2) + rise
    local u = 1 - k
    return u * u * x0 + 2 * u * k * cx + k * k * x2, u * u * y0 + 2 * u * k * cy + k * k * y2
end
local function rocket(r, x0, y0, x2, y2, rise, k, size, t)
    if k <= 0 or k >= 1 then return end
    local x, y = path(x0, y0, x2, y2, rise, k)
    local n = #r.trail
    for j = 1, n do
        local kj = k - j * TRAIL_STEP
        if kj > 0 then
            local tx, ty = path(x0, y0, x2, y2, rise, kj)
            P.FxPut(r.trail[j], tx, ty, size * (0.5 + 0.22 * j), nil, 0.5 * (1 - j / (n + 1)))
        end
    end
    P.FxPut(r.glow, x, y, size * (1.7 + 0.25 * math.sin(t * 60)), nil, 0.8)
    P.FxPut(r.head, x, y, size, nil, 1)
end
local function launch(p, at, vx, vy, life)
    p.flyAt, p.vx, p.vy, p.life = at, vx, vy, life
    local spin = SPIN_MIN + math.random() * (SPIN_MAX - SPIN_MIN)
    p.spin = (vx < 0) and spin or -spin
end
local function flyTick(p, t)
    local s = t - p.flyAt
    if s >= p.life then
        P.Icon(p, nil, 0, 0, 0, 0)
        P.Spin(p.sp, 0)
        return false
    end
    local k = s / p.life
    P.Spin(p.sp, p.spin * s)
    P.Icon(p, p.old, p.x + p.vx * s, p.y + p.vy * s - 0.5 * GRAV * s * s, 1 - SHRINK * k, 1 - k * k)
    return true
end
local function blowAway(ctx)
    local cx, cy = ctx.low.cx, ctx.low.cy
    for _, p in ipairs(ctx.btns) do
        if p.old and not p.flyAt then
            local dx, dy = p.x - cx, p.y - cy
            local d = math.sqrt(dx * dx + dy * dy)
            local a = (d > 0) and math.atan2(dy, dx) or (math.random() * math.pi * 2)
            local push = BLOW_PUSH + d * BLOW_DIST + math.random() * 60
            launch(p, ctx.blast, math.cos(a) * push, math.abs(math.sin(a)) * push * 0.4 + BLOW_UP * (0.6 + 0.6 * math.random()),
                   BLOW_LIFE)
        end
    end
end
local function setup(ctx)
    if not P.Stage(ctx) then return false end
    local C = ns.C.show
    local W, H = P.Screen()
    local low, box = ctx.low, ctx.box
    ctx.W, ctx.H = W, H
    ctx.y0 = low.y2 + BOT_UP
    ctx.x1 = math.max(110, math.min(W - 200, low.x1 + 40))
    ctx.bot = P.Actor("spidertank")
    ctx.fxL = P.Layer("spidertankFx", 10)
    ctx.fxL.tex = ctx.fxL.tex or {}
    ctx.fxL.n = 0
    local olds = {}
    for _, p in ipairs(ctx.btns) do
        p.mark = fx(ctx, P.RING, C.scan, true)
        p.fire = fx(ctx, P.RING, C.fire, true)
        p.smoke = fx(ctx, P.BLOB, C.smoke)
        p.shaft = fx(ctx, P.RING, C.holy, true)
        p.glow = fx(ctx, P.RING, C.holy, true)
        p.wash = fx(ctx, P.WHITE, C.white, true)
        p.washTex = nil
        p.flyAt, p.landed = nil, nil
        if p.old then olds[#olds + 1] = p end
    end
    local n = math.min(SALVO, #olds)
    local gap = math.min(GAP, FIRE_SPREAD / math.max(1, n))
    local lockGap = LOCK_SPREAD / math.max(1, n)
    ctx.salvo = {}
    for j = 1, n do
        local p = olds[math.floor((j - 0.5) * #olds / n) + 1]
        p.n = j - 1
        p.lock = T_LOCK + (j - 1) * lockGap
        p.shot = T_FIRE + (j - 1) * gap
        p.hit = p.shot + FLY_T
        p.pod = j % 2 + 1
        p.rise = ROCKET_RISE + (j * 3 % 5) * RISE_STEP
        p.sparks = {}
        for s = 1, SPARKS do p.sparks[s] = fx(ctx, P.DISC, C.fire, true) end
        ctx.salvo[j] = p
    end
    ctx.fireEnd = (n > 0) and ctx.salvo[n].hit or T_FIRE
    ctx.bigAt = ctx.fireEnd + BIG_WAIT
    ctx.blast = ctx.bigAt + BIG_T
    ctx.lift = ctx.blast + LIFT_WAIT
    ctx.light = ctx.blast + LIGHT_WAIT
    local span = math.max(1, box.x2 - box.x1)
    for _, p in ipairs(ctx.btns) do
        p.lit = ctx.light + SWEEP_T * (p.x - box.x1) / span
    end
    ctx.fin = ctx.light + SWEEP_T + SHAFT_T + APPEAR_T + 0.2
    ctx.rk = {}
    for r = 1, POOL do ctx.rk[r] = newRocket(ctx, TRAIL) end
    ctx.big = newRocket(ctx, BIG_TRAIL)
    ctx.muzzle = { fx(ctx, P.RING, C.fire, true), fx(ctx, P.RING, C.fire, true) }
    ctx.bigMark = fx(ctx, P.RING, C.scan, true)
    ctx.ring = fx(ctx, P.RING, ns.C.boom.ring, true)
    ctx.jet = fx(ctx, P.RING, C.fire, true)
    ctx.sweep = fx(ctx, P.RING, C.holy, true)
    ctx.puff = {}
    for j = 1, PUFFS do ctx.puff[j] = fx(ctx, P.BLOB, C.smoke) end
    for i = ctx.fxL.n + 1, #ctx.fxL.tex do ctx.fxL.tex[i]:Hide() end
    P.Play(P.SND.launch, true)
    return true
end
local function planLight(ctx)
    local m = 0
    for _, p in ipairs(ctx.btns) do
        p.new = P.NewTex(ctx, p)
        if p.new then
            p.m = m
            m = m + 1
        end
    end
end
local function jet(ctx, x, y, way, t)
    P.FxPut(ctx.jet, x, y - FEET - JET_H * 0.3, JET_W + 8 * math.sin(t * 50), JET_H + 14 * math.sin(t * 37), 0.9)
    for j = 1, PUFFS do
        local py = (way > 0) and (y + 10 + j * PUFF_GAP) or (y - FEET - JET_H * 0.5 - j * PUFF_GAP)
        P.FxPut(ctx.puff[j], x + 7 * math.sin(t * 9 + j * 1.7), py, 22 + j * 9, nil, 0.5 * (1 - j / (PUFFS + 1)))
    end
end
local function dust(ctx, k)
    local e = math.sqrt(k)
    for j = 1, PUFFS do
        local side = (j % 2 == 0) and 1 or -1
        local rank = math.ceil(j / 2)
        P.FxPut(ctx.puff[j], ctx.x1 + side * (18 + 34 * rank * e), ctx.y0 - FEET + 4 + 9 * rank * k,
                26 + 30 * k, nil, 0.55 * (1 - k))
    end
end
local function hitFx(p, t)
    local h = t - p.hit
    if h < FIRE_T then
        local k = h / FIRE_T
        P.FxPut(p.fire, p.x, p.y, p.w * (0.9 + 1.6 * k), nil, 1 - 0.5 * k)
    else
        P.FxPut(p.fire, 0, 0, 0, nil, 0)
    end
    if h < SPARK_T then
        local k = h / SPARK_T
        for s = 1, SPARKS do
            local a = (s - 0.5) / SPARKS * math.pi + (p.i % 3) * 0.3
            local d = SPARK_V * h
            P.FxPut(p.sparks[s], p.x + math.cos(a) * d, p.y + math.sin(a) * d - 0.5 * GRAV * 0.4 * h * h,
                    SPARK_SZ * (1 - 0.5 * k), nil, 1 - k)
        end
    else
        for s = 1, SPARKS do P.FxPut(p.sparks[s], 0, 0, 0, nil, 0) end
    end
    if h < SMOKE_T then
        local k = h / SMOKE_T
        P.FxPut(p.smoke, p.x + 5 * math.sin(h * 6 + p.i), p.y + 34 * k, p.w * (0.8 + 0.9 * k), nil, 0.4 * (1 - k))
    else
        P.FxPut(p.smoke, 0, 0, 0, nil, 0)
    end
end
local function lightFx(ctx, p, t)
    local C = ns.C.show
    local s = t - p.lit
    if s < 0 then
        P.Icon(p, nil, 0, 0, 0, 0)
        return
    end
    if s < SHAFT_T then
        local k = s / SHAFT_T
        P.FxPut(p.shaft, p.x, p.y + SHAFT_DROP * (1 - k) + p.h * SHAFT_HK * 0.3, p.w * (1.1 - 0.4 * k),
                p.h * SHAFT_HK, math.sin(math.pi * k))
    else
        P.FxPut(p.shaft, 0, 0, 0, nil, 0)
    end
    local a = s - SHAFT_T * RISE_AT
    if a < 0 then
        P.Icon(p, nil, 0, 0, 0, 0)
        return
    end
    local k = math.min(1, a / APPEAR_T)
    P.FxPut(p.glow, p.x, p.y, p.w * (0.8 + GLOW_K * k), nil, (k < 1) and (1 - k) or 0)
    if not p.new then return end
    if not p.landed then
        p.landed = true
        P.Spin(p.sp, 0)
        if p.m % 3 == 0 then P.Play(P.SND.tick) end
    end
    local scale = 1.3 - 0.3 * P.Ease(k)
    P.Icon(p, p.new, p.x, p.y, scale, k)
    if p.washTex ~= p.new then
        p.washTex = p.new
        p.wash:SetTexture(p.new)
        p.wash:SetTexCoord(p.sp:GetTexCoord())
        P.Tint(p.wash, C.white)
    end
    P.FxPut(p.wash, p.x, p.y, p.w * scale, p.h * scale, 1 - k)
end
local function tick(ctx, dt)
    local t = ctx.t
    local C, B, S = ns.C.show, ns.C.boom, P.SND
    local x1, y0, low, box = ctx.x1, ctx.y0, ctx.low, ctx.box
    if P.At(ctx, "plan", ctx.light) then planLight(ctx) end
    local sky = ctx.H + DROP_FROM - y0
    for r = 1, POOL do hideRocket(ctx.rk[r]) end
    hideRocket(ctx.big)
    P.FxPut(ctx.jet, 0, 0, 0, nil, 0)
    for j = 1, PUFFS do P.FxPut(ctx.puff[j], 0, 0, 0, nil, 0) end
    P.FxPut(ctx.muzzle[1], 0, 0, 0, nil, 0)
    P.FxPut(ctx.muzzle[2], 0, 0, 0, nil, 0)
    for _, p in ipairs(ctx.salvo) do
        if t >= p.shot and not p.fired then
            p.fired = true
            ctx.lastShot, ctx.pod = p.shot, p.pod
            if p.n == 0 then P.Play(S.launch, true) elseif p.n % 3 == 0 then P.Play(S.launch) end
        end
        if t >= p.hit and not p.boomed then
            p.boomed = true
            ctx.lastHit, ctx.shake = p.hit, SHAKE_HIT
            launch(p, p.hit, (math.random() < 0.5 and -1 or 1) * HIT_VX * (0.6 + 0.8 * math.random()),
                   HIT_VY * (0.7 + 0.6 * math.random()), HIT_LIFE)
            if p.n == 0 then P.Play(S.blast, true) elseif p.n % 3 == 0 then P.Play(S.cracker) end
        end
    end
    if P.At(ctx, "load", T_LOCK) then P.Play(S.gunLoad) end
    if P.At(ctx, "big", ctx.bigAt) then
        ctx.lastShot, ctx.pod = ctx.bigAt, nil
        P.Play(S.mortar, true)
    end
    if P.At(ctx, "blast", ctx.blast) then
        ctx.lastHit, ctx.shake = ctx.blast, SHAKE_BLAST
        blowAway(ctx)
        P.Play(S.boom, true)
        P.Play(S.cannon)
    end
    if P.At(ctx, "light", ctx.light) then P.Play(S.holy, true) end
    local x, y, dir, ba = x1, y0, 1, 1
    if t < T_IN then
        local e = 1 - P.K(t, 0, T_IN)
        y = y0 + sky * e * (0.4 + 0.6 * e)
        dir = 0
        jet(ctx, x, y, 1, t)
    elseif t < T_IN + DUST_T then
        y = y0 - LAND_DIP * math.sin(math.pi * P.K(t, T_IN, LAND_T))
        if t < T_IN + LAND_T * 0.5 then dir = 0 end
        dust(ctx, P.K(t, T_IN, DUST_T))
    elseif t >= ctx.lift then
        local k = P.K(t, ctx.lift, OUT_T)
        y = y0 + sky * k * k
        dir = 0
        if k < 1 then jet(ctx, x, y, -1, t) else ba = 0 end
        if P.At(ctx, "off", ctx.lift) then P.Play(S.launch, true) end
    end
    if P.At(ctx, "land", T_IN) then P.Play(S.step, true) end
    if ctx.lastShot then
        local pod = ctx.pod and PODS[ctx.pod] or BIG_POD
        local m = P.K(t, ctx.lastShot, MUZZLE_T)
        local big = ctx.pod and 1 or 2
        P.FxPut(ctx.muzzle[ctx.pod or 1], x1 + pod[1], y0 + pod[2], MUZZLE_SZ * big * (1 - 0.6 * m), nil, 1 - m)
    end
    P.Act(ctx.bot, dt, x, y, "stand", dir, ba, BOT_POSE)
    for _, p in ipairs(ctx.salvo) do
        local pod = PODS[p.pod]
        rocket(ctx.rk[p.n % POOL + 1], x1 + pod[1], y0 + pod[2], p.x, p.y, p.rise, (t - p.shot) / FLY_T, ROCKET_SZ, t)
    end
    rocket(ctx.big, x1 + BIG_POD[1], y0 + BIG_POD[2], low.cx, low.cy, BIG_RISE, (t - ctx.bigAt) / BIG_T, BIG_SZ, t)
    if t < ctx.blast then
        local k = P.K(t, ctx.bigAt - BIG_AIM, BIG_AIM)
        P.FxPut(ctx.bigMark, low.cx, low.cy, MARK_BIG + (MARK_SMALL - MARK_BIG) * k, nil, k * (0.6 + 0.4 * math.sin(t * 25)))
    else
        P.FxPut(ctx.bigMark, 0, 0, 0, nil, 0)
    end
    local bt = t - ctx.blast
    local fa = 0
    if bt >= 0 then
        local peak = B.flash[4] or 1
        if bt < FLASH_UP then fa = peak * bt / FLASH_UP else fa = peak * (1 - (bt - FLASH_UP) / FLASH_DOWN) end
    end
    P.Flash(B.flash, fa)
    if bt >= 0 and bt < RING_T then
        local k = bt / RING_T
        local e = 1 - (1 - k) * (1 - k)
        P.FxPut(ctx.ring, low.cx, low.cy, 60 + (ctx.W * 1.7 - 60) * e, nil, 1 - k)
    else
        P.FxPut(ctx.ring, 0, 0, 0, nil, 0)
    end
    local lt = t - ctx.light
    if lt >= 0 and lt < SWEEP_T + SHAFT_T then
        local k = math.min(1, lt / SWEEP_T)
        local a = (lt < SWEEP_T) and 1 or (1 - (lt - SWEEP_T) / SHAFT_T)
        local h = math.max(1, box.y2 - box.y1) * SWEEP_HK
        P.FxPut(ctx.sweep, box.x1 + (box.x2 - box.x1) * k, (box.y1 + box.y2) / 2, SWEEP_W, h, 0.8 * a)
        P.ScreenTint(C.light, (C.light[4] or 1) * 0.5 * math.sin(math.pi * math.min(1, lt / (SWEEP_T + SHAFT_T))))
    else
        P.FxPut(ctx.sweep, 0, 0, 0, nil, 0)
        P.ScreenTint(C.light, 0)
    end
    if not ctx.unstaged then
        local sx, sy = 0, 0
        if ctx.lastHit then
            local amp = ctx.shake * (1 - P.K(t, ctx.lastHit, SHAKE_T))
            sx, sy = amp * math.sin(t * 90), amp * math.cos(t * 70)
        end
        local dark
        if t < ctx.blast then
            dark = DARK_FIRE * P.K(t, T_FIRE, ctx.fireEnd - T_FIRE + 0.01)
        else
            dark = DARK_FIRE + (DARK_EMPTY - DARK_FIRE) * P.K(t, ctx.blast, 0.3)
            dark = dark * (1 - P.K(t, ctx.light, SWEEP_T + SHAFT_T * 0.5))
        end
        P.Art(ctx, 1, C.dark, dark, 1, sx, sy)
        for _, p in ipairs(ctx.btns) do
            if p.flyAt and t >= p.flyAt and not p.flown then
                if not flyTick(p, t) then p.flown = true end
            elseif (not p.flyAt and t < ctx.blast) or (p.flyAt and t < p.flyAt) then
                P.Icon(p, p.old, p.x + sx, p.y + sy, 1, 1)
                if p.lock then
                    local k = P.K(t, p.lock, LOCK_T)
                    P.FxPut(p.mark, p.x, p.y, p.w * (2.4 - 1.1 * k), nil, k * (0.6 + 0.4 * math.sin(t * 25 + p.i)))
                end
            elseif t >= ctx.light then
                lightFx(ctx, p, t)
            else
                P.Icon(p, nil, 0, 0, 0, 0)
            end
            if p.hit and t >= p.hit then
                if p.lock then P.FxPut(p.mark, 0, 0, 0, nil, 0) end
                hitFx(p, t)
            elseif t >= ctx.blast and p.lock then
                P.FxPut(p.mark, 0, 0, 0, nil, 0)
            end
        end
    end
    if t >= ctx.fin then
        P.Unstage(ctx)
        P.ScreenTint(C.light, 0)
        for _, p in ipairs(ctx.btns) do
            P.FxPut(p.shaft, 0, 0, 0, nil, 0)
            P.FxPut(p.glow, 0, 0, 0, nil, 0)
            P.Spin(p.sp, 0)
            P.FxPut(p.wash, 0, 0, 0, nil, 0)
        end
    end
    return t >= math.max(ctx.fin, ctx.lift + OUT_T)
end
local DEF = { key = "spidertank", length = LENGTH, setup = setup, tick = tick }
function ns.SpiderTankParade(ops)
    P.Start(DEF, ops)
end
ns.RegisterParade("spidertank", ns.SpiderTankParade)
