local ADDON, ns = ...
local MODEL = "Creature\\MurlocCostume\\murloccostume_noflag.M2"
local SLOT_ART = "Interface\\Buttons\\UI-Quickslot"
local SEQ_RUN, LEN_RUN = 5, 666
local BODY, HAND = 56, 30
local MODEL_BOX, MODEL_SCALE, MODEL_DY = BODY * 2, 0.5, 0
local HAND_DX, HAND_DY = 14, -6
local SPEED = 620
local STAGGER = 0.12
local MAX_RUNNERS = 36
local FACE_OFF = math.pi
local STEP_GAP = 0.28
local SND_START = "Sound\\Creature\\Murloc\\mMurlocAggroOld.wav"
local SND_DROP = "sound\\creature\\murloc\\mmurlocpreaggroa.wav"
local SND_STEP = {
    "Sound\\Character\\Footsteps\\FootstepFishA.wav",
    "Sound\\Character\\Footsteps\\FootstepFishB.wav",
    "Sound\\Character\\Footsteps\\FootstepFishC.wav",
    "Sound\\Character\\Footsteps\\FootstepFishD.wav",
}
local BARS = { "ActionButton", "BonusActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
               "MultiBarRightButton", "MultiBarLeftButton" }
function ns.MurlocsEnabled()
    return not (HTP_TalentsDB and HTP_TalentsDB.murlocs == false)
end
local function blizzardButtons()
    local out = {}
    for _, prefix in ipairs(BARS) do
        for i = 1, 12 do
            local b = _G[prefix .. i]
            if b and b:IsVisible() then
                local slot = b.action
                if type(slot) ~= "number" and ActionButton_GetPagedID then
                    local ok, id = pcall(ActionButton_GetPagedID, b)
                    if ok and type(id) == "number" then slot = id end
                end
                if type(slot) == "number" and not out[slot] then out[slot] = b end
            end
        end
    end
    return out
end
local function uiPoint(f)
    local cx, cy = f:GetCenter()
    if not cx then return nil end
    local k = f:GetEffectiveScale() / UIParent:GetEffectiveScale()
    return cx * k, cy * k
end
local function edgeFrom(x, y)
    local W, H = UIParent:GetWidth(), UIParent:GetHeight()
    local d = { x, W - x, y, H - y }
    local best, bi = d[1], 1
    for i = 2, 4 do if d[i] < best then best, bi = d[i], i end end
    if bi == 1 then return -BODY, y end
    if bi == 2 then return W + BODY, y end
    if bi == 3 then return x, -BODY end
    return x, H + BODY
end
local pool, covers, active = {}, {}, {}
local queue, clock, stepT = {}, 0, 0
local driver
local function play(path)
    PlaySoundFile(path)
end
local function coverFor(b)
    local c = covers[b]
    if not c then
        c = CreateFrame("Frame", nil, UIParent)
        c:SetFrameStrata("HIGH")
        c:EnableMouse(false)
        c.fill = c:CreateTexture(nil, "BACKGROUND")
        c.fill:SetTexture("Interface\\Buttons\\WHITE8X8")
        c.fill:SetAllPoints()
        c.art = c:CreateTexture(nil, "ARTWORK")
        c.art:SetTexture(SLOT_ART)
        c.art:SetPoint("CENTER", c, "CENTER", 0, -1)
        covers[b] = c
    end
    local e = ns.C.slotEmpty
    c.fill:SetVertexColor(e[1], e[2], e[3], e[4] or 1)
    local w, h = b:GetWidth(), b:GetHeight()
    c:SetScale(b:GetEffectiveScale() / UIParent:GetEffectiveScale())
    c:ClearAllPoints()
    c:SetPoint("CENTER", b, "CENTER", 0, 0)
    c:SetWidth(w); c:SetHeight(h)
    c.art:SetWidth(w * 66 / 36); c.art:SetHeight(h * 66 / 36)
    c:Show()
    return c
end
local function newRunner()
    local r = CreateFrame("Frame", nil, UIParent)
    r:SetFrameStrata("FULLSCREEN_DIALOG")
    r:SetWidth(BODY); r:SetHeight(BODY)
    r:EnableMouse(false)
    local ok, m = pcall(CreateFrame, "PlayerModel", nil, r)
    if ok and m and m.SetModel and m.SetSequenceTime then
        m:SetWidth(MODEL_BOX); m:SetHeight(MODEL_BOX)
        m:SetPoint("CENTER", r, "CENTER", 0, MODEL_DY)
        if pcall(m.SetModel, m, MODEL) then r.model = m else m:Hide() end
    end
    r.hand = r:CreateTexture(nil, "OVERLAY")
    r.hand:SetWidth(HAND); r.hand:SetHeight(HAND)
    r.hand:SetPoint("CENTER", r, "CENTER", HAND_DX, HAND_DY)
    r:Hide()
    return r
end
local function release(r)
    r:Hide()
    if r.cover then r.cover:Hide(); r.cover = nil end
    for i, a in ipairs(active) do
        if a == r then table.remove(active, i); break end
    end
    pool[#pool + 1] = r
end
local function launch(job)
    local r = table.remove(pool) or newRunner()
    r.x, r.y, r.tx, r.ty = job.x, job.y, job.tx, job.ty
    r.tex, r.cover, r.back, r.anim = job.tex, job.cover, job.back, 0
    r.hand:SetTexture(job.tex)
    if job.tex then r.hand:Show() else r.hand:Hide() end
    if r.model then
        pcall(r.model.SetModel, r.model, MODEL)
        r.model:Show()
    end
    r:ClearAllPoints()
    r:SetPoint("CENTER", UIParent, "BOTTOMLEFT", r.x, r.y)
    r:Show()
    active[#active + 1] = r
end
local function step(r, dt)
    local dx, dy = r.tx - r.x, r.ty - r.y
    local d = math.sqrt(dx * dx + dy * dy)
    if d < 2 then return true end
    local s = math.min(d, SPEED * dt)
    r.x, r.y = r.x + dx / d * s, r.y + dy / d * s
    r:ClearAllPoints()
    r:SetPoint("CENTER", UIParent, "BOTTOMLEFT", r.x, r.y)
    if r.model then
        if r.model.SetModelScale then pcall(r.model.SetModelScale, r.model, MODEL_SCALE) end
        pcall(r.model.SetFacing, r.model, FACE_OFF - math.atan2(dx, dy))
        r.anim = (r.anim + dt * 1000) % LEN_RUN
        pcall(r.model.SetSequenceTime, r.model, SEQ_RUN, r.anim)
    end
    return d - s < 2
end
local function stopAll()
    for i = #active, 1, -1 do release(active[i]) end
    for _, c in pairs(covers) do c:Hide() end
    queue = {}
    if driver then driver:Hide() end
end
local function tick(_, dt)
    if dt > 0.1 then dt = 0.1 end
    if InCombatLockdown() then stopAll(); return end
    clock = clock + dt
    while queue[1] and clock >= queue[1].at do
        launch(table.remove(queue, 1))
    end
    for i = #active, 1, -1 do
        local r = active[i]
        if step(r, dt) then
            if r.back then
                release(r)
            else
                if r.cover then r.cover:Hide(); r.cover = nil end
                r.hand:Hide()
                if math.random(3) == 1 then play(SND_DROP) end
                r.tx, r.ty = edgeFrom(r.x, r.y)
                r.back = true
            end
        end
    end
    stepT = stepT + dt
    if #active > 0 and stepT >= STEP_GAP then
        stepT = 0
        play(SND_STEP[math.random(#SND_STEP)])
    end
    if #active == 0 and not queue[1] then driver:Hide() end
end
local function parade(ops)
    if not (ops and ops[1]) or not ns.MurlocsEnabled() or InCombatLockdown() then return end
    local buttons = blizzardButtons()
    if ns.Parade then
        for _, op in ipairs(ops) do
            if buttons[op.slot] then ns.Parade.StopAll(); break end
        end
    end
    local n = 0
    for _, op in ipairs(ops) do
        local b = buttons[op.slot]
        local x, y
        if b then x, y = uiPoint(b) end
        if x and n < MAX_RUNNERS then
            n = n + 1
            local job = { at = clock + (n - 1) * STAGGER, tex = op.tex }
            if op.kind == "clear" then
                job.x, job.y = x - HAND_DX, y - HAND_DY
                job.tx, job.ty = edgeFrom(x, y)
                job.back = true
            else
                job.cover = coverFor(b)
                job.tx, job.ty = x - HAND_DX, y - HAND_DY
                local src = op.from and buttons[op.from]
                local sx, sy
                if src then sx, sy = uiPoint(src) end
                if sx then
                    job.x, job.y = sx - HAND_DX, sy - HAND_DY
                else
                    local W = UIParent:GetWidth()
                    job.x, job.y = math.random(math.floor(W * 0.15), math.floor(W * 0.85)), -BODY
                end
            end
            queue[#queue + 1] = job
        end
    end
    if n == 0 then return end
    table.sort(queue, function(a, b) return a.at < b.at end)
    if not driver then
        driver = CreateFrame("Frame")
        driver:SetScript("OnUpdate", function(self, dt)
            local ok, err = pcall(tick, self, dt)
            if not ok then
                ns.ParadeError = err
                if ns.ParadeWatch and GetTime() < ns.ParadeWatch then
                    ns.ParadeWatch = nil
                    ns.say(ns.T("msg.show_error", tostring(err)))
                end
                stopAll()
            end
        end)
    end
    PlaySoundFile(SND_START, "Master")
    driver:Show()
end
function ns.MurlocParade(ops)
    local ok, err = pcall(parade, ops)
    if not ok then ns.ParadeError = err; stopAll() end
end
if ns.RegisterParade then ns.RegisterParade("murlocs", ns.MurlocParade, stopAll) end
