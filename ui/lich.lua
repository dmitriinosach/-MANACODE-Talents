local ADDON, ns = ...
local P = ns.Parade
if not P then return end
local BONKER = "lichbonker"
local BONK_SIZE = 70
do
    local base = P.MODELS.bonker
    P.MODELS[BONKER] = { key = BONKER, path = base.path, size = BONK_SIZE, w = BONK_SIZE * 2, h = BONK_SIZE * 2,
                         scale = base.scale, seq = base.seq, len = base.len }
end
local BONK_LEVEL = 14
local VOICE = { come = "murlocCry", bye = "murlocBye" }
local NONE = {}
local LENGTH = 7.1
local T_RISE, RISE_T, T_HOPE, T_HARVEST = 0, 0.4, 0.05, 0.3
local T_DROP, T_BONK, T_HOP, HOP_T, T_FALL, T_RUN, RUN_T = 4.05, 4.5, 5.0, 0.35, 5.05, 5.6, 1.0
local T_THAW, THAW_T = 6.0, 1.0
local SINK_AT, SINK_T = 0.7, 0.7
local SOUL_T, LAST_GO, HANG_T, FADE_T = 0.8, 0.4, 0.12, 0.35
local BACK_SPREAD, BACK_T, LAND_T = 0.8, 0.6, 0.15
local GAP = 0.08
local FOOT_UP = 35
local FEET_DY, HEAD_DY, BLADE_DX, BLADE_DY = 182, 16, -26, 131
local STEP_T = 0.2
local HOP_KX, POP_KX, POP_KY, STAR_K, HOP_H = 0.45, 0.55, 0.2, 0.16, 50
local SIT_K = 0.35
local STARS, STAR_SZ = 5, 20
local WISP_K, WISP_A, GLOW_A, HALO_K = 1.25, 0.32, 0.5, 1.1
local FLASH_T, FLASH_A = 0.2, 0.45
local FX_GLOW, FX_LIGHT, FX_BURST, FX_STAR = 81, 82, 83, 84
local function setup(ctx)
    if not P.Stage(ctx) then return false end
    local C = ns.C.show
    local W, H = P.Screen()
    local low = ctx.low
    local size = P.MODELS[BONKER].size
    ctx.lx = math.max(140, math.min(W - 260, low.cx))
    local body = P.MODELS.lich.size
    ctx.body = body
    ctx.ly = math.min(H - P.MODELS.lich.h / 2, low.y2 + FOOT_UP + FEET_DY)
    ctx.bx, ctx.by = ctx.lx + BLADE_DX, ctx.ly + BLADE_DY
    ctx.head = ctx.ly + HEAD_DY
    ctx.lich, ctx.tirion = P.Actor("lich"), P.Actor(BONKER)
    ctx.tirion:SetFrameLevel(BONK_LEVEL)
    if ctx.tirion.model then ctx.tirion.model:SetFrameLevel(BONK_LEVEL + 1) end
    ctx.ty = ctx.ly - FEET_DY + size / 2
    ctx.hy = ctx.head + size * SIT_K
    ctx.top = H + size
    local n = 0
    for _, p in ipairs(ctx.btns) do
        p.wisp = P.Fx(p.i, P.RING, C.soul, true)
        if p.old then n = n + 1 end
    end
    local gap = (T_BONK - LAST_GO - T_HARVEST) / math.max(1, n - 1)
    local i = 0
    for _, p in ipairs(ctx.btns) do
        if p.old then
            p.go = T_HARVEST + i * gap
            p.phase = i * 1.7
            i = i + 1
        end
    end
    ctx.souls, ctx.eaten = n, 0
    ctx.glow = P.Fx(FX_GLOW, P.RING, C.soul, true)
    ctx.light = P.Fx(FX_LIGHT, P.RING, C.light, true)
    ctx.burst = P.Fx(FX_BURST, P.RING, C.soul, true)
    ctx.stars = {}
    for s = 1, STARS do ctx.stars[s] = P.Fx(FX_STAR + s - 1, P.RING, C.star, true) end
    P.Play(P.SND.wind)
    return true
end
local function planBack(ctx)
    local list = {}
    local last = T_BONK
    for _, p in ipairs(ctx.btns) do
        p.new = P.NewTex(ctx, p)
        P.FxPut(p.wisp, 0, 0, 0, nil, 0)
        if p.go and not p.gone then
            p.fx, p.fy, p.fs = p.cx or p.x, p.cy or p.y, p.cs or 1
            if p.new then
                p.back, p.arc = T_BONK + HANG_T, 30
                last = math.max(last, p.back + BACK_T + LAND_T)
            else
                p.fade = T_BONK
            end
        elseif p.new then
            list[#list + 1] = p
        end
    end
    local gap = math.min(GAP, BACK_SPREAD / math.max(1, #list))
    for i, p in ipairs(list) do
        p.back = T_BONK + HANG_T + (i - 1) * gap
        p.arc = 50 + (i * 37) % 90
        last = math.max(last, p.back + BACK_T + LAND_T)
    end
    ctx.lastBack = last
end
local function tick(ctx, dt)
    local t = ctx.t
    local C, S = ns.C.show, P.SND
    local lx, ly, bx, by = ctx.lx, ctx.ly, ctx.bx, ctx.by
    local frost = P.K(t, 0, 0.5) * (1 - P.K(t, T_THAW, THAW_T))
    P.ScreenTint(C.frost, (C.frost[4] or 1) * frost)
    local la = P.K(t, T_RISE, RISE_T) * (1 - P.K(t, T_FALL + SINK_AT, SINK_T))
    local seq, once = "stand", false
    if t >= T_FALL then seq, once = "fall", true
    elseif t >= T_BONK then seq = "stun"
    else seq = "channel" end
    local shake = (t >= T_BONK and t < T_FALL) and math.sin(t * 60) * 3 * (1 - P.K(t, T_BONK, T_FALL - T_BONK)) or 0
    P.Act(ctx.lich, dt, lx + shake, ly - 30 * (1 - P.Ease(P.K(t, T_RISE, RISE_T))), seq, 0, la, once)
    if P.At(ctx, "come", T_RISE) then P.Play(S.lichCome) end
    if P.At(ctx, "hope", T_HOPE) then P.Play(S.lichSay, true) end
    if P.At(ctx, "funnel", T_HARVEST) then P.Play(S.funnel); P.Play(S.frost) end
    if t < T_BONK then
        for _, p in ipairs(ctx.btns) do
            if p.go then
                local k = P.K(t, p.go, SOUL_T)
                if k <= 0 then
                    P.Icon(p, p.old, p.x, p.y, 1, 1)
                elseif k < 1 then
                    local e = P.Ease(k)
                    local x, y = P.Spiral(p.x, p.y, bx, by, e, 70, 1.25, p.phase)
                    p.cx, p.cy, p.cs = x, y, 1 - 0.75 * e
                    P.Icon(p, p.old, x, y, p.cs, 1 - P.K(k, 0.8, 0.2))
                    P.FxPut(p.wisp, x, y, p.w * (WISP_K - 0.5 * e), nil, WISP_A * math.sin(math.pi * k))
                elseif not p.gone then
                    p.gone = true
                    P.Icon(p, nil, 0, 0, 0, 0)
                    P.FxPut(p.wisp, 0, 0, 0, nil, 0)
                    ctx.eaten = ctx.eaten + 1
                    if ctx.eaten % 6 == 1 then P.Play(S.soul) end
                end
            end
        end
    end
    local ice = P.K(t, T_HARVEST, 1.4)
    local gone = P.K(t, T_HARVEST + 1.9, 0.5)
    local melt = P.K(t, T_BONK + 0.2, 1.0)
    if t < T_BONK then
        P.Art(ctx, 1 - gone, C.frost, ice)
    elseif not ctx.unstaged then
        P.Art(ctx, melt, C.frost, 1 - melt)
    end
    local full = ctx.eaten / math.max(1, ctx.souls)
    if t < T_BONK then
        local pulse = 0.75 + 0.25 * math.sin(t * 9)
        P.FxPut(ctx.glow, bx, by, 40 + 50 * full, nil, la * (0.15 + (GLOW_A - 0.15) * full) * pulse)
    else
        P.FxPut(ctx.glow, bx, by, 90, nil, GLOW_A * (1 - P.K(t, T_BONK, 0.3)))
    end
    if t >= T_DROP then
        local W = P.Screen()
        local size = P.MODELS[BONKER].size
        local once2 = false
        local gx = lx + ctx.body * HOP_KX
        local x, y, tseq, dir, ta = lx, ctx.hy, "cheer", 0, 1
        if t < T_BONK then
            local k = P.K(t, T_DROP, T_BONK - T_DROP)
            y = ctx.top + (ctx.hy - ctx.top) * k * k
            tseq = "fall"
        elseif t < T_HOP then
            tseq, once2 = "land", true
            x = lx + shake
            y = ctx.hy + 14 * math.abs(math.sin((t - T_BONK) * 9)) * (1 - P.K(t, T_BONK, T_HOP - T_BONK))
        elseif t < T_HOP + HOP_T then
            x, y = P.Arc(lx, ctx.hy, gx, ctx.ty, P.K(t, T_HOP, HOP_T), HOP_H)
            tseq, dir = "jump", 1
        elseif t < T_RUN then
            x, y = gx, ctx.ty
        else
            local k = P.K(t, T_RUN, RUN_T)
            x, y = gx + (W + 90 - gx) * k, ctx.ty
            tseq, dir, ta = "run", 1, 1 - P.K(k, 0.8, 0.2)
            ctx.stepT = (ctx.stepT or 0) - dt
            if ctx.stepT <= 0 and ta > 0.3 then
                ctx.stepT = STEP_T
                P.Play(S.fishStep)
            end
        end
        P.Act(ctx.tirion, dt, x, y, tseq, dir, ta, once2)
        P.FxPut(ctx.light, x, y + size * 0.1, size * HALO_K, nil, (C.light[4] or 1) * ta * (0.8 + 0.2 * math.sin(t * 5)))
    end
    if P.At(ctx, "drop", T_DROP) then P.Play(S[VOICE.come], true) end
    if P.At(ctx, "bonk", T_BONK) then
        P.Play(S.bonk, true)
        planBack(ctx)
    end
    if P.At(ctx, "crack", T_BONK + HANG_T) then P.Play(S.glass); P.Play(S.release) end
    if t >= T_BONK then
        local k = P.K(t, T_BONK, 0.25)
        local scale = (k < 0.6) and (0.3 + 1.4 * k / 0.6) or (1.7 - 0.5 * (k - 0.6) / 0.4)
        local wob = 1 - P.K(t, T_BONK, 0.6)
        P.Pop(ns.T("show.bonk"), C.bonk,
              lx - ctx.body * POP_KX + math.sin(t * 70) * 5 * wob,
              ctx.head + ctx.body * POP_KY + math.cos(t * 55) * 4 * wob,
              scale * 1.6, 1 - P.K(t, T_BONK + 0.9, 0.4))
        P.Flash(C.white, FLASH_A * (1 - P.K(t, T_BONK, FLASH_T)))
        local sa = 1 - P.K(t, T_FALL + 0.3, 0.4)
        local sr = ctx.body * STAR_K
        for s = 1, STARS do
            local a = t * 5 + s * (math.pi * 2 / STARS)
            P.FxPut(ctx.stars[s], lx + shake + math.cos(a) * sr, ctx.head + math.sin(a) * sr * 0.35, STAR_SZ, nil, sa)
        end
        local rk = P.K(t, T_BONK + HANG_T, 0.5)
        P.FxPut(ctx.burst, bx, by, 40 + 220 * rk, nil, 0.6 * (1 - rk) * P.K(t, T_BONK, HANG_T))
        for _, p in ipairs(ctx.unstaged and NONE or ctx.btns) do
            if p.back then
                local bk = P.K(t, p.back, BACK_T)
                if bk <= 0 then
                    if p.fx then P.Icon(p, p.old, p.fx, p.fy, p.fs, 1) else P.Icon(p, nil, 0, 0, 0, 0) end
                elseif bk < 1 then
                    local s0 = p.fs or 0.25
                    local x, y = P.Arc(p.fx or bx, p.fy or by, p.x, p.y, P.Ease(bk), p.arc)
                    P.Icon(p, p.new, x, y, s0 + (1 - s0) * bk, 1)
                    P.FxPut(p.wisp, x, y, p.w * WISP_K, nil, WISP_A * (1 - bk))
                else
                    local b = P.K(t, p.back + BACK_T, LAND_T)
                    P.Icon(p, p.new, p.x, p.y, 1 + 0.18 * math.sin(math.pi * b), 1)
                    if not p.landed then
                        p.landed = true
                        P.FxPut(p.wisp, 0, 0, 0, nil, 0)
                        if p.i % 4 == 1 then P.Play(S.tick) end
                    end
                end
            elseif p.fade then
                local fk = P.K(t, p.fade, FADE_T)
                P.Icon(p, p.old, p.fx, p.fy - 30 * fk, p.fs, 1 - fk)
            else
                P.Icon(p, nil, 0, 0, 0, 0)
            end
        end
        if t >= math.max(ctx.lastBack, T_BONK + 1.2) then P.Unstage(ctx) end
    end
    if P.At(ctx, "bye", T_HOP + HOP_T) then P.Play(S[VOICE.bye]) end
    return t >= LENGTH
end
local DEF = { key = "lich", length = LENGTH, setup = setup, tick = tick }
function ns.LichParade(ops)
    P.Start(DEF, ops)
end
ns.RegisterParade("lich", ns.LichParade)
