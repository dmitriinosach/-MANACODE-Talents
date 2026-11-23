local ADDON, ns = ...
local P = ns.Parade
if not P then return end
local CAPTION_T = 0.1
local SIZE, SIZE_MAX, PAD, TEXT_H = 256, 560, 10, 92
local SEQ_MAX = 500
local LEN_DEF, LEN_STEP, LEN_MIN = 2000, 100, 100
local FACE_STEP, SCALE_STEP, SCALE_MIN, POS_STEP = math.pi / 8, 0.05, 0.05, 0.1
local HOLD = 3
local view
local function applySeq(self)
    local m = self.model
    if not m then return end
    if self.timed then
        pcall(m.SetSequenceTime, m, self.seq, self.time)
    elseif self.setSeq ~= self.seq then
        self.setSeq = self.seq
        if m.SetSequence then pcall(m.SetSequence, m, self.seq) end
    end
end
local function build()
    local f = CreateFrame("Frame", "HTP_TalentsModelView", UIParent)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:EnableMouse(true)
    f:EnableMouseWheel(true)
    if ns.Kit and ns.Kit.StylePanel then ns.Kit.StylePanel(f) end
    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.text:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", PAD, PAD)
    f.text:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, PAD)
    f.text:SetHeight(TEXT_H)
    f.text:SetJustifyH("LEFT")
    f.text:SetJustifyV("TOP")
    local ok, m = pcall(CreateFrame, "PlayerModel", nil, f)
    if ok and m and m.SetModel then
        m:SetPoint("TOP", f, "TOP", 0, -PAD)
        if m.EnableMouse then m:EnableMouse(false) end
        f.model = m
    end
    f:SetScript("OnMouseWheel", function(self, d)
        local shift, ctrl, alt = IsShiftKeyDown(), IsControlKeyDown(), IsAltKeyDown()
        if ctrl and shift then
            self.px = self.px + d * POS_STEP
        elseif ctrl and alt then
            self.py = self.py + d * POS_STEP
        elseif shift and alt then
            self.pz = self.pz + d * POS_STEP
        elseif shift then
            self.facing = self.facing + d * FACE_STEP
        elseif ctrl then
            self.scale = math.max(SCALE_MIN, self.scale + d * SCALE_STEP)
        elseif alt then
            self.len = math.max(LEN_MIN, self.len + d * LEN_STEP)
        else
            self.seq = (self.seq + d) % SEQ_MAX
            self.time = 0
            local known = self.def and self.def.len and self.def.len[self.seq]
            self.len = known or LEN_DEF
            self.timed = known ~= nil
        end
        self.hold = HOLD
    end)
    f:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            self.timed = not self.timed
            self.setSeq = nil
        else
            self.paused = not self.paused
        end
    end)
    f:SetScript("OnUpdate", function(self, dt)
        if not self.paused then
            self.time = self.time + dt * 1000
            if self.time >= self.len then self.time = self.time - self.len end
        end
        local m = self.model
        if m then
            if self.hold > 0 then
                self.hold = self.hold - dt
                if m.SetModelScale then pcall(m.SetModelScale, m, self.scale) end
                if m.SetPosition then pcall(m.SetPosition, m, self.px, self.py, self.pz) end
                if m.SetFacing then pcall(m.SetFacing, m, self.facing) end
            end
            if P.ModelStep(m, dt) then
                self.hold = HOLD
                self.setSeq = nil
                if m.def and self.def and m.def ~= self.def then
                    self.def = m.def
                    self.label = (m.def.key or self.label) .. " (fallback)"
                    local known = m.def.len and m.def.len[self.seq]
                    self.len, self.timed = known or LEN_DEF, known ~= nil
                end
            end
            if not m.ready and P.ModelLoaded(m) then
                m.ready = true
                m:SetAlpha(1)
            end
            if not self.paused then applySeq(self) end
        end
        self.capLeft = (self.capLeft or 0) - dt
        if self.capLeft > 0 then return end
        self.capLeft = CAPTION_T
        local got = m and m.GetModel and select(2, pcall(m.GetModel, m))
        self.text:SetText(ns.T("model.caption", self.label, self.seq, self.facing, self.scale, self.px, self.py, self.pz,
                                self.w, self.h, self.time / 1000, self.len / 1000)
            .. "\n" .. ns.T(self.timed and "model.timed" or "model.client")
            .. (self.paused and ("  " .. ns.T("model.paused")) or "")
            .. "\n" .. ns.T("model.loaded", type(got) == "string" and got or "-")
            .. "\n" .. ns.T("model.hint"))
    end)
    f:Hide()
    tinsert(UISpecialFrames, "HTP_TalentsModelView")
    return f
end
function ns.ModelView(arg)
    arg = strtrim(tostring(arg or ""))
    if arg == "" then
        if view and view:IsShown() then
            view:Hide()
            return nil
        end
        local keys = {}
        for k in pairs(P.MODELS) do keys[#keys + 1] = k end
        table.sort(keys)
        return ns.T("model.usage", table.concat(keys, ", "))
    end
    local what, seq = arg:match("^(.-)%s+(%d+)$")
    if not what then what = arg end
    local def = P.MODELS[what:lower()]
    local npc = tonumber(what:lower():match("^npc:(%d+)$"))
    local disp = tonumber(what:lower():match("^display:(%d+)$"))
    local target = what:lower() == "target"
    if target and not (UnitExists and UnitExists("target")) then return ns.T("msg.actor_target") end
    local src = (target and { unit = "target" }) or def or (disp and { display = disp }) or (npc and { npc = npc })
        or { path = what }
    if not src.npc and not src.npcs and not src.path and not src.display and not src.unit then
        return ns.T("model.none", what)
    end
    view = view or build()
    view.def, view.src = def, src
    if target then
        local id = P.UnitNpc("target")
        view.label = (UnitName("target") or "?") .. (id and (" (npc:" .. id .. ")") or "")
    else
        view.label = def and what:lower() or src.display and ("display:" .. src.display)
            or src.npc and ("npc:" .. src.npc) or src.path
    end
    view.seq = tonumber(seq) or 0
    view.time, view.paused, view.hold, view.setSeq = 0, false, HOLD, nil
    view.facing = def and def.face or 0
    view.scale = def and def.scale or 1
    view.px, view.py, view.pz = def and def.px or 0, def and def.py or 0, def and def.pz or 0
    local known = def and def.len and def.len[view.seq]
    view.len = known or LEN_DEF
    view.timed = known ~= nil
    local w, h = SIZE, SIZE
    if def then w, h = P.ModelSize(def) end
    w, h = math.min(SIZE_MAX, w), math.min(SIZE_MAX, h)
    view.w, view.h = w, h
    view:SetWidth(math.max(w, 360) + PAD * 2)
    view:SetHeight(h + PAD * 3 + TEXT_H)
    if view.model then
        view.model:SetWidth(w)
        view.model:SetHeight(h)
        P.ModelReset(view.model, src)
    end
    view:Show()
    return nil
end
local VOICES = {}
local function addVoices(dir, name, n)
    for i = 1, n do
        VOICES[#VOICES + 1] = { path = dir .. name .. format("%02d", i) .. ".wav", label = name .. format("%02d", i) }
    end
end
local NPC = "Sound\\Creature\\"
for _, kind in ipairs({ "Standard", "Grim", "Guard" }) do
    local dir = NPC .. "DwarfMale" .. kind .. "NPC\\"
    local base = "DwarfMale" .. kind .. "NPC"
    addVoices(dir, base .. "Vendor", 2)
    addVoices(dir, base .. "Greeting", 6)
    addVoices(dir, base .. "Farewell", kind == "Grim" and 3 or 4)
    addVoices(dir, base .. "Pissed", kind == "Standard" and 4 or 3)
end
local VOCAL = "Sound\\Character\\Dwarf\\DwarfVocalMale\\"
addVoices(VOCAL, "DwarfMaleFollowMe", 3)
addVoices(VOCAL, "DwarfMaleCharge", 2)
addVoices(VOCAL, "DwarfMaleIncoming", 2)
addVoices(VOCAL, "DwarfMaleCheer", 3)
addVoices(VOCAL, "DwarfMaleHello", 4)
addVoices(VOCAL, "DwarfMalePissed", 4)
local EMOTE = "Sound\\Character\\Dwarf\\DwarfMale\\"
addVoices(EMOTE, "DwarfMaleChooChoo", 1)
addVoices(EMOTE, "DwarfMaleLaugh", 1)
addVoices("Sound\\Creature\\KingMagniBronzebeard\\", "KingMagniBronzebeardGreeting", 4)
addVoices("Sound\\Creature\\KingMagniBronzebeard\\", "KingMagniBronzebeardAggro", 2)
addVoices("Sound\\Creature\\Brann\\", "HS_Brann_Greeting", 4)
addVoices("Sound\\Creature\\Brann\\", "HS_Brann_Farewell", 4)
local function addFiles(dir, names)
    for _, name in ipairs(names) do
        VOICES[#VOICES + 1] = { path = dir .. name .. ".wav", label = name }
    end
end
addFiles("Sound\\Character\\Dwarf\\DwarfMAleNpc\\DwarfMaleNpc1\\", { "DwarfMaleWarrior1PreAggro", "DwarfMaleWarrior1AggroA" })
addFiles("Sound\\Creature\\Rifleman\\", { "RiflemanPissed1", "RiflemanPissed2", "RiflemanPissed3", "RiflemanPissed4",
    "RiflemanReady1", "RiflemanWhat2", "RiflemanWhat3", "RiflemanYes1", "RiflemanYes2", "RiflemanYes4",
    "RiflemanYesAttack1", "RiflemanYesAttack2", "RiflemanYesAttack3", "RiflemanYesAttack4" })
addFiles("Sound\\Creature\\Mortar Team\\", { "MortarTeamPissed1", "MortarTeamPissed2", "MortarTeamPissed8",
    "MortarTeamPissed9", "MortarTeamReady1", "MortarTeamYesAttack4" })
addFiles("Sound\\Creature\\Muradin\\", { "MuradinYes1" })
addFiles(VOCAL, { "DwarfMalePissed05", "DwarfMalePissed06", "DwarfMalePissed07",
    "DwarfMaleFlirt01", "DwarfMaleFlirt02", "DwarfMaleFlirt03", "DwarfMaleFlirt04", "DwarfMaleFlirt05", "DwarfMaleFlirt06",
    "DwarfMaleCongratulations01", "DwarfMaleCongratulations02", "DwarfMaleCongratulations03",
    "DwarfMaleCongratulations04", "DwarfMaleCongratulations05",
    "DwarfMaleGoodbye01", "DwarfMaleGoodbye02", "DwarfMaleGoodbye03", "DwarfMaleRaspberry01",
    "DwarfMaleOpenFire01", "DwarfMaleOpenFire02", "DwarfMaleAttackMyTarget01", "DwarfMaleAttackMyTarget02",
    "DwarfMaleAttackMyTarget03", "DwarfMaleWaitHere01", "DwarfMaleWaitHere02", "DwarfMaleWaitHere03",
    "DwarfMaleHelp01", "DwarfMaleHelp02", "DwarfMaleThankYou01", "DwarfMaleThankYou02" })
for _, kit in ipairs({ "Dwarf Male Vocal 20 (Silly)", "Dwarf Male Vocal 19 (Flirt)", "Dwarf Male Vocal 09 (cheer)",
    "DwarfMaleGrimNPCGreetings", "DwarfMaleGrimVendorNPCGreetings", "DwarfMaleGrimNPCFarewells", "DwarfMaleGrimNPCPissed",
    "DwarfMaleStandardNPCGreetings", "DwarfMaleStandardNPCFarewells", "DwarfMaleStandardNPCPissed",
    "DwarfMaleGuardNPCGreetings", "DwarfMaleGuardNPCFarewells", "DwarfMaleGuardNPCPissed",
    "KingMagniBronzebeardGreetings", "NPCBrannBronzebeardGreeting" }) do
    VOICES[#VOICES + 1] = { kit = kit, label = "kit:" .. kit }
end
function ns.VoiceTest(arg)
    local n = tonumber(strtrim(tostring(arg or "")))
    local v = n and VOICES[n]
    if v then
        if v.kit then
            if not pcall(PlaySound, v.kit, "Master") then pcall(PlaySound, v.kit) end
        else
            PlaySoundFile(v.path, "Master")
        end
        return { ns.T("model.voice_play", n, v.label) }
    end
    local lines, parts = { ns.T("model.voice_usage", #VOICES) }, {}
    local i = 1
    while i <= #VOICES do
        local group = VOICES[i].label:gsub("%d+$", "")
        local j = i
        while VOICES[j + 1] and VOICES[j + 1].label:gsub("%d+$", "") == group do j = j + 1 end
        parts[#parts + 1] = (i == j and tostring(i) or (i .. "-" .. j)) .. " " .. group:gsub("^DwarfMale", "")
        i = j + 1
    end
    for k = 1, #parts, 4 do
        lines[#lines + 1] = "  " .. table.concat(parts, ", ", k, math.min(k + 3, #parts))
    end
    return lines
end
