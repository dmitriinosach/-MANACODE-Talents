local ADDON, ns = ...
local P = ns.Parade
if not P then return end
local T_IN, T_ZAP, ZAP_T, SHRINK_T = 1.4, 1.5, 0.3, 0.6
local T_GRAB, GRAB_T, TOSS_T = T_ZAP + SHRINK_T + 0.1, 0.5, 0.7
local T_TINKER = T_GRAB + GRAB_T + TOSS_T
local T_OUT, SET_T = T_TINKER + 1.7, 0.6
local T_ZAP2, GROW_T = T_OUT + SET_T + 0.1, 0.7
local T_END = T_ZAP2 + GROW_T + 0.2
local TOY = 0.14
local HEN_RUN, HEN_HOME, HEN_SPEED, HEN_TURN = 2.2, 0.55, 430, 0.7
local MISHAP = 3
local BOW_T, OUT_T = 0.9, 1.3
local LENGTH = T_END + HEN_RUN + HEN_HOME + 0.3 + BOW_T + OUT_T + 0.2
local DOTS, ZAPS, TINK = 22, 3, 4
local MUZZLE_DX, MUZZLE_DY, HAND_DX, HAND_DY = 34, 8, 26, 4
local FX_BEAM, FX_ZAP, FX_BOX, FX_POOF, FX_TINK = 1, 30, 40, 41, 42
local BOX = "Interface\\Icons\\INV_Misc_Wrench_01"
local BOX_SZ = 30
local function setup(ctx)
    if not P.Stage(ctx) then return false end
    local C = ns.C.show
    local low = ctx.low
    ctx.gx = math.max(60, low.x1 - 70)
    ctx.gy = math.max(50, low.cy + 10)
    ctx.gnome, ctx.hen = P.Actor("gnome"), P.Actor("chicken")
    ctx.beam = {}
    for i = 1, DOTS do ctx.beam[i] = P.Fx(FX_BEAM + i - 1, P.DISC, C.ray, true) end
    ctx.zap = {}
    for i = 1, ZAPS do ctx.zap[i] = P.Fx(FX_ZAP + i - 1, P.RING, C.ray, true) end
    ctx.box = P.Fx(FX_BOX, BOX)
    ctx.poof = P.Fx(FX_POOF, P.RING, C.rayBack, true)
    ctx.tink = {}
    for i = 1, TINK do ctx.tink[i] = P.Fx(FX_TINK + i - 1, P.RING, C.star, true) end
    ctx.wantMishap = math.random(MISHAP) == 1
    P.Play(P.SND.machine)
    return true
end
local function beam(ctx, tx, ty, c, alpha)
    local t = ctx.t
    local x0, y0 = ctx.gnome.x + MUZZLE_DX, ctx.gnome.y + MUZZLE_DY
    local dx, dy = tx - x0, ty - y0
    local d = math.max(1, math.sqrt(dx * dx + dy * dy))
    local nx, ny = -dy / d, dx / d
    for i = 1, DOTS do
        local k = i / DOTS
        local wob = math.sin(i * 0.9 + t * 34) * 5 * math.sin(math.pi * k)
        local dot = ctx.beam[i]
        if dot then P.Tint(dot, c) end
        P.FxPut(dot, x0 + dx * k + nx * wob, y0 + dy * k + ny * wob, 9 + 5 * math.sin(i + t * 20), nil, alpha * 0.8)
    end
    for i = 1, ZAPS do
        local z = ctx.zap[i]
        if z then P.Tint(z, c) end
        local a = t * 23 + i * 2.1
        P.FxPut(z, tx + math.cos(a) * 14, ty + math.sin(a * 1.3) * 14, 22 + 8 * math.sin(a), nil, alpha * 0.8)
    end
end
local function planBack(ctx)
    local list = {}
    for _, p in ipairs(ctx.btns) do
        p.new = P.NewTex(ctx, p)
        if p.new then list[#list + 1] = p end
    end
    ctx.fin = T_END
    if ctx.wantMishap and list[1] then
        local p = list[math.random(#list)]
        ctx.hen1 = p
        ctx.henAt = T_END - 0.2
        ctx.hx, ctx.hy = p.x, p.y
        ctx.hdx, ctx.hdy, ctx.hturn = 1, 0.4, 0
        ctx.fin = ctx.henAt + HEN_RUN + HEN_HOME + 0.3
    end
end
local function henRun(ctx, dt)
    local W, H = P.Screen()
    ctx.hturn = ctx.hturn - dt
    if ctx.hturn <= 0 then
        ctx.hturn = HEN_TURN * (0.7 + math.random() * 0.6)
        local a = math.random() * math.pi * 2
        ctx.hdx, ctx.hdy = math.cos(a), math.sin(a) * 0.6
    end
    ctx.hx = ctx.hx + ctx.hdx * HEN_SPEED * dt
    ctx.hy = ctx.hy + ctx.hdy * HEN_SPEED * dt
    if ctx.hx < 60 then ctx.hx, ctx.hdx = 60, math.abs(ctx.hdx) end
    if ctx.hx > W - 60 then ctx.hx, ctx.hdx = W - 60, -math.abs(ctx.hdx) end
    if ctx.hy < 90 then ctx.hy, ctx.hdy = 90, math.abs(ctx.hdy) end
    if ctx.hy > H * 0.55 then ctx.hy, ctx.hdy = H * 0.55, -math.abs(ctx.hdy) end
end
local function tick(ctx, dt)
    local t = ctx.t
    local C, S = ns.C.show, P.SND
    local low = ctx.low
    local gx, gy = ctx.gx, ctx.gy
    local hx, hy = gx + HAND_DX, gy + HAND_DY
    if P.At(ctx, "plan", T_OUT) then planBack(ctx) end
    local fin = ctx.fin or LENGTH
    local x, seq, dir, ga = gx, "stand", 1, 1
    if t < T_IN then
        x = -60 + (gx + 60) * P.K(t, 0, T_IN)
        seq = "walk"
    elseif t >= T_TINKER and t < T_OUT then
        seq = "think"
    elseif t >= fin and t < fin + BOW_T then
        seq, dir = "bow", 0
    elseif t >= fin + BOW_T then
        local k = P.K(t, fin + BOW_T, OUT_T)
        x = gx + (-70 - gx) * k
        seq, dir, ga = "walk", -1, 1 - P.K(k, 0.6, 0.4)
    end
    P.Act(ctx.gnome, dt, x, gy, seq, dir, ga)
    if P.At(ctx, "zap1", T_ZAP) then P.Play(S.ray, true); P.Play(S.zap) end
    if P.At(ctx, "toss", T_GRAB + GRAB_T) then P.Play(S.throw) end
    if P.At(ctx, "box", T_TINKER) then P.Play(S.box) end
    if P.At(ctx, "tink1", T_TINKER + 0.2) then P.Play(S.tinker) end
    if P.At(ctx, "grunt", T_TINKER + 0.8) then P.Play(S.gnome) end
    if P.At(ctx, "tink2", T_TINKER + 1.0) then P.Play(S.tinker) end
    if P.At(ctx, "out", T_OUT) then P.Play(S.tick) end
    if P.At(ctx, "zap2", T_ZAP2) then P.Play(S.ray, true); P.Play(S.zap) end
    if P.At(ctx, "bye", fin) then P.Play(S.gnomeBye) end
    local ba = P.K(t, T_TINKER, 0.2) * (1 - P.K(t, T_OUT + 0.3, 0.3))
    P.FxPut(ctx.box, hx + 6, gy - 24 + 3 * math.abs(math.sin(t * 14)) * ba, BOX_SZ, nil, ba)
    for i = 1, TINK do
        local ph = (t * 2.3 + i * 0.27) % 1
        local on = (t >= T_TINKER + 0.1 and t < T_OUT) and 1 or 0
        P.FxPut(ctx.tink[i], hx + 6 + (i - 2.5) * 12 * ph, gy - 14 + 50 * ph * (1 - ph * 0.6), 12 - 6 * ph, nil, on * (1 - ph))
    end
    local s, ox, oy, alpha, new = 1, 0, 0, 1, false
    if t < T_GRAB then
        s = 1 - (1 - TOY) * P.Ease(P.K(t, T_ZAP + 0.1, SHRINK_T))
    elseif t < T_GRAB + GRAB_T then
        local k = P.Ease(P.K(t, T_GRAB, GRAB_T))
        s, ox, oy = TOY, (hx - low.cx) * k, (hy - low.cy) * k
    elseif t < T_OUT then
        local k = P.K(t, T_GRAB + GRAB_T, TOSS_T)
        local ax, ay = P.Arc(hx, hy, -160, gy + 120, k, 260)
        s, ox, oy = TOY, ax - low.cx, ay - low.cy
        alpha = (k < 1) and 1 or 0
    elseif t < T_ZAP2 then
        local k = P.Ease(P.K(t, T_OUT, SET_T))
        local ax, ay = P.Arc(hx, gy - 20, low.cx, low.cy, k, 90)
        s, ox, oy, new = TOY * (0.4 + 0.6 * P.K(t, T_OUT, 0.2)), ax - low.cx, ay - low.cy, true
    else
        local k = P.K(t, T_ZAP2 + 0.1, GROW_T)
        s, new = TOY + (1 - TOY) * (k + 0.1 * math.sin(math.pi * k)), true
    end
    local shown = false
    if t >= T_ZAP and t < T_ZAP + ZAP_T then
        beam(ctx, low.cx, low.cy, C.ray, 1)
        shown = true
    elseif t >= T_ZAP2 and t < T_ZAP2 + ZAP_T then
        beam(ctx, low.cx, low.cy, C.rayBack, 1)
        shown = true
    end
    if not ctx.unstaged then
        P.Art(ctx, alpha, nil, nil, s, ox, oy)
        local caught = ctx.hen1 and (ctx.henAt + HEN_RUN)
        for _, p in ipairs(ctx.btns) do
            if new and p == ctx.hen1 and t >= ctx.henAt then
                if t >= caught then
                    local k = P.K(t, caught, HEN_HOME)
                    local ix, iy = P.Arc(ctx.hx, ctx.hy, p.x, p.y, P.Ease(k), 70)
                    P.Icon(p, p.new, ix, iy, 0.5 + 0.5 * k + 0.2 * math.sin(math.pi * P.K(t, caught + HEN_HOME, 0.15)), 1)
                else
                    P.Icon(p, nil, 0, 0, 0, 0)
                end
            else
                local path = p.old
                if new then path = p.new end
                P.Icon(p, path, low.cx + ox + (p.x - low.cx) * s, low.cy + oy + (p.y - low.cy) * s, s, alpha)
            end
        end
    end
    if ctx.hen1 then
        local caught = ctx.henAt + HEN_RUN
        if t >= ctx.henAt and t < caught then
            if P.At(ctx, "poly", ctx.henAt) then P.Play(S.poly); P.Play(S.chicken, true) end
            if P.At(ctx, "cluck", ctx.henAt + 1.1) then P.Play(S.chicken) end
            henRun(ctx, dt)
            P.Act(ctx.hen, dt, ctx.hx, ctx.hy, "run", (ctx.hdx >= 0) and 1 or -1, 1)
            if t >= caught - 0.9 then
                beam(ctx, ctx.hx, ctx.hy, C.rayBack, 0.4 + 0.6 * P.K(t, caught - 0.5, 0.5))
                shown = true
            end
        elseif t >= caught then
            if P.At(ctx, "caught", caught) then P.Play(S.poly); P.Play(S.zap) end
            P.Act(ctx.hen, dt, ctx.hx, ctx.hy, "stand", 0, 0)
            local k = P.K(t, caught, 0.4)
            P.FxPut(ctx.poof, ctx.hx, ctx.hy, 30 + 120 * k, nil, 0.8 * (1 - k))
        end
    end
    if not shown then
        for i = 1, DOTS do P.FxPut(ctx.beam[i], 0, 0, 0, nil, 0) end
        for i = 1, ZAPS do P.FxPut(ctx.zap[i], 0, 0, 0, nil, 0) end
    end
    if t >= fin then P.Unstage(ctx) end
    return t >= fin + BOW_T + OUT_T
end
local DEF = { key = "gnomeray", length = LENGTH, setup = setup, tick = tick }
function ns.GnomeRayParade(ops)
    P.Start(DEF, ops)
end
ns.RegisterParade("gnomeray", ns.GnomeRayParade)
