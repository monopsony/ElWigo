local EW = ElWigoAddon
local pairs, ipairs = pairs, ipairs
local unpack = unpack
local tremove = table.remove
local tsort = table.sort
local tinsert = table.insert
local unpack = unpack
local frameTemplate = "BackdropTemplate" -- change to "BackdropTemplate" in SL
local IsEncounterInProgress = IsEncounterInProgress

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0")

function EW:updateBars()
    for i = 1, 4 do
        self:updateBar(i)
    end
end

local function createBar(n)
    local f =
        CreateFrame("Frame", ("ElWigoBar%s"):format(n), UIParent, frameTemplate)
    f:SetFrameStrata("MEDIUM")

    f.n = n
    f.frames = {}

    f.texture = f:CreateTexture(nil, "BACKGROUND")
    f.texture:SetAllPoints()
    f:SetFrameLevel(5)
    return f
end

EW.bars = {}
function EW:updateBar(n)
    if not n then
        return
    end
    if not EW.bars[n] then
        EW.bars[n] = createBar(n)
    end

    local bar = EW.bars[n]
    local para = self.para.bars[n]
    bar.para = para
    bar.maxTime = para.maxTime
    bar.scheduledAnchorUpdate = 0

    -- do the updating
    bar:ClearAllPoints()
    local anchor = (para.vertical and "BOTTOM") or "LEFT"
    bar:SetPoint(anchor, UIParent, "BOTTOMLEFT", unpack(para.pos))

    if para.vertical then
        bar:SetSize(para.width, para.length)
    else
        bar:SetSize(para.length, para.width)
    end
    bar.vertical = para.vertical

    local bg = LSM:Fetch("background", para.backgroundTexture)
    local edge = LSM:Fetch("border", para.backgroundBorder)
    local bd = {
        bgFile = bg,
        edgeFile = edge,
        tile = false,
        tileSize = 0,
        edgeSize = para.backgroundBorderSize,
        insets = {left = 0, right = 0, top = 0, bottom = 0}
    }

    bar:SetBackdrop(bd)
    bar:SetBackdropColor(unpack(para.backgroundColor))
    bar:SetBackdropBorderColor(unpack(para.backgroundBorderColor))

    -- Frame position related
    if para.vertical then
        bar.startAnchor = (para.reverse and "BOTTOM") or "TOP"
        bar.endAnchor = (para.reverse and "TOP") or "BOTTOM"
        bar.x_mul = 0
        bar.y_mul = (para.reverse and -1) or 1
    else
        bar.startAnchor = (para.reverse and "LEFT") or "RIGHT"
        bar.endAnchor = (para.reverse and "RIGHT") or "LEFT"
        bar.x_mul = (para.reverse and -1) or 1
        bar.y_mul = 0
    end
    bar.lengthPerTime = para.length / para.maxTime

    self:updateBarVisibility(n)

    -- TICKS
    bar.ticks = bar.ticks or {}
    local ticks = bar.ticks
    local maxBars = floor(para.maxTime / para.tickSpacing)
    if para.maxTime % para.tickSpacing == 0 then
        maxBars = maxBars - 1
    end
    local N = max(#ticks, maxBars)

    for i = 1, N do
        ticks[i] = ticks[i] or CreateFrame("Frame", nil, bar, frameTemplate)
        ticks[i]:SetFrameStrata("MEDIUM")
        local t = ticks[i]
        if (not para.hasTicks) or i > maxBars then
            t:Hide()
        else
            t:Show()
            t:SetFrameLevel(
                bar:GetFrameLevel() + ((para.aboveIcons and 6) or 1)
            )
            -- t:SetFrameLevel(bar:GetFrameLevel() + 1)

            local thicknessOffset = floor(para.tickWidth / 2)
            local l = i * para.tickSpacing * bar.lengthPerTime + thicknessOffset
            t:ClearAllPoints()
            t:SetPoint(
                para.vertical and "TOP" or "RIGHT",
                bar,
                bar.endAnchor,
                bar.x_mul * l,
                bar.y_mul * l
            )

            -- Why not just "CENTER": because then your min thickness is 2 pxs

            t:SetSize(
                para.vertical and para.tickLength or para.tickWidth,
                para.vertical and para.tickWidth or para.tickLength
            )

            if not t.texture then
                t.texture = t:CreateTexture(nil, "BACKGROUND")
            end
            t.texture:SetAllPoints()
            t.texture:SetColorTexture(unpack(para.tickColor))

            if not t.text then
                t.text = t:CreateFontString(nil, "BACKGROUND")
            end
            if para.tickText then
                t:Show()
            else
                t:Hide()
            end
            local a1, a2 = unpack(EW.utils.dirToAnchors[para.tickTextPosition])
            t.text:ClearAllPoints()
            t.text:SetPoint(a2, t, a1)
            t.text:SetTextColor(unpack(para.tickTextColor))

            local font =
                LSM:Fetch("font", para.tickFont) or "Fonts\\FRIZQT__.TTF"
            t.text:SetFont(font, para.tickTextFontSize, "OUTLINE")
            t.text:SetText(i * para.tickSpacing)
        end
    end
end

local FRAME_ID_COUNTER = 0
local function createIconFrame()
    local f = CreateFrame("Frame", nil, UIParent, frameTemplate)
    f:SetFrameStrata("MEDIUM")

    f.icon = f:CreateTexture(nil, "BACKGROUND")
    f.icon:SetAllPoints()

    f.nameText = f:CreateFontString(nil, "OVERLAY")

    f.durationText = f:CreateFontString(nil, "OVERLAY")
    f.durationText:SetPoint("CENTER")

    FRAME_ID_COUNTER = FRAME_ID_COUNTER + 1
    f.id = FRAME_ID_COUNTER

    return f
end

function EW:removeFrame(frame)
    -- toad proper recycling/removal
    frame:Hide()

    -- pop it
    local id = frame.id
    local frames = frame.bar_.frames
    for i, v in ipairs(frames) do
        if v.id == id then
            tremove(frames, i)
            break
        end
    end
    if #frames == 0 then
        self:updateBarVisibility(frame.bar_.n)
    end

    -- update anchors
    self:scheduleAnchorUpdate(frame.bar_)
end

local function moveFrame(frame, bar)
    local t = frame.remDuration * bar.lengthPerTime
    frame:SetPoint("CENTER", bar, bar.endAnchor, t * bar.x_mul, t * bar.y_mul)
    -- frame:SetFrameLevel(frame.bar:GetFrameLevel() + 4)
end

local function frameOnUpdate(frame)
    local t = GetTime()
    if t - frame.lastUpdated < frame.refreshRate then
        return
    end

    frame.lastUpdated = t
    local para = frame.para

    -- UPDATE REM. DURATION
    local dur = frame.expTime - t
    frame.remDuration = dur
    if para.duration then
        if dur <= 60 then
            frame.durationText:SetText(("%i"):format(dur))
        else
            frame.durationText:SetText(("%i:%02i"):format(dur / 60, dur % 60))
        end
    end

    -- MOVE FRAME
    if not frame.anchored then
        moveFrame(frame, frame.bar_)
    end

    if t > frame.expTime then
        EW:removeFrame(frame)
    end

    if frame.headQueue then
        if (frame.remDuration < frame.maxTime) then
            frame.headQueue = false
            EW:scheduleAnchorUpdate(frame.bar_)
        elseif frame.smoothQueueing then
            local effRemDuration = frame.effectiveExpTime - t
            if not frame.pinned and (effRemDuration <= frame.maxTime) then
                EW:pinHeadQueue(frame)
            end
        end
    end
end
EW._frameOnUpdate = frameOnUpdate

local paraMetaTable = {
    __index = function(tbl, key)
        if tbl.__user[key] ~= nil then
            return tbl.__user[key]
        else
            return tbl.__default[key]
        end
    end
}

function EW:getIconPara(spellID, engageID, name)
    local bossID = engageID or self.engageID or 0
    local barID = 1
    local userPara = {}
    if self.para.bosses[bossID] and self.para.bosses[bossID][spellID] then
        barID = self.para.bosses[bossID][spellID]["bar"] or 1
        userPara = self.para.bosses[bossID][spellID]
    else
        local id = self:getParaIDByName(name)
        if id and self.para.bosses[bossID] and self.para.bosses[bossID][id] then
            barID = self.para.bosses[bossID][id]["bar"] or 1
            userPara = self.para.bosses[bossID][id]
        end
    end

    local para = {
        __default = self.para.icons.defaults[barID],
        __user = userPara
    }

    setmetatable(para, paraMetaTable)
    return para
end

function EW:getParaIDByName(name)
    if not self.para.instanceSpellNameToID then
        return nil
    end
    local id = self.para.instanceSpellNameToID[name] or nil
    return id
end

local strip = EW.utils.stringStrip
local sacro = EW.utils.acronym
local srbn = EW.utils.removeBracketsNumber
function EW:spawnIcon(spellID, name1, duration, iconID, para)
    local name, num = strip(name1)
    local para = para or EW:getIconPara(spellID, nil, name)
    -- self:removeBarFrameByID(para.bar, spellID)
    self:removeBarFrameByName(para.bar, name)

    local frame = createIconFrame()
    local bar = self.bars[para.bar]
    if not bar.para.shown then
        return
    end

    frame:Show()

    frame.bar_ = bar
    frame.para = para
    frame.name = name
    frame.name1 = name1
    frame.num = num or -1
    frame.spellID = spellID
    frame.size = para.width
    frame.duration = duration
    frame.spawnTime = GetTime()
    frame.expTime = GetTime() + duration
    frame.iconID = iconID
    frame.maxTime = bar.maxTime
    frame.smoothQueueing = self.para.smoothQueueing
    frame.anchored = true -- will prevent a flashing of the icon when it appears, as it wont be moved before the anchor update
    self:updateFramePara(frame)

    frame.effectiveExpTime = frame.expTime

    -- set up OnUpdateHandler
    frame.lastUpdated = 0
    frame.refreshRate = EW.para.refreshRate

    tinsert(bar.frames, frame)
    if #bar.frames == 1 then
        self:updateBarVisibility(para.bar)
    end
    self:scheduleAnchorUpdate(bar)

    frame:SetParent(bar)
    frame:SetFrameLevel(bar:GetFrameLevel() + 4) -- set parent resets it

    frame:SetScript("OnUpdate", frameOnUpdate)
end

local function compareExpTime(frame1, frame2)
    return (((frame1.expTime or 1000) == (frame2.expTime or 1000)) and
        (tostring(frame1.id) < tostring(frame2.id))) or
        ((frame1.expTime or 1000) < (frame2.expTime or 1000))
end

function EW:pinHeadQueue(frame)
    local bar = frame.bar_
    frame.pinned = true
    frame.anchored = true
    frame.anchor = bar
    frame.effectiveExpTime = frame.expTime
    frame:SetPoint("CENTER", bar, bar.startAnchor)
end

function EW:setFrameAnchor(frame1, frame2, outOfSight)
    if outOfSight then
        frame1.anchored = true
        frame1.anchor = UIParent
        frame1.effectiveExpTime = frame1.expTime
        frame1:SetPoint("CENTER", UIParent, "CENTER", 0, 20000)
    elseif not frame2 then
        -- force an update if it was previously anchored
        if frame1.anchored then
            frame1.lastUpdated = 0
        end

        frame1.anchored = false
        frame1.anchor = nil
        frame1.effectiveExpTime = frame1.expTime
    else
        frame1.anchored = true
        frame1.anchor = frame2

        local bar = frame1.bar_
        local dist = frame1.size / 2 + frame2.size / 2

        frame1:SetPoint(
            "CENTER",
            frame2,
            "CENTER",
            dist * bar.x_mul,
            dist * bar.y_mul
        )

        frame1.effectiveExpTime =
            frame2.effectiveExpTime + dist / bar.lengthPerTime
    end
    frame1.pinned = false
end

function EW:scheduleAnchorUpdate(bar)
    local t = GetTime()
    if bar.scheduledAnchorUpdate == t then
        return
    end
    bar.scheduledAnchorUpdate = t
    self:ScheduleTimer(self.updateAnchors, 0, self, bar)
end

function EW:updateAnchors(bar)
    local frames = bar.frames

    -- sort the frames
    tsort(frames, compareExpTime)

    -- set anchors
    local lengthPerTime = bar.lengthPerTime
    local maxTime = bar.maxTime or 0
    local aboveMax = false
    local maxExp = GetTime() + maxTime

    for i, v in ipairs(frames) do
        -- if below max time
        if v.expTime and v.expTime <= maxExp then
            -- if above max time
            if i == 1 then -- if first frame
                self:setFrameAnchor(v, nil)
            else
                local prev = frames[i - 1]
                local overlapTime = (v.size / 2 + prev.size / 2) / lengthPerTime

                -- IF OVERLAP
                local overlaps = v.expTime - prev.effectiveExpTime < overlapTime
                self:setFrameAnchor(v, (overlaps and prev) or nil)
            end
        else
            -- if first frame in queue
            local pinned = false
            if not aboveMax then
                v.headQueue = true
                aboveMax = true
            else
                v.headQueue = false
            end
            if v.headQueue then
            end
            if bar.para.invisibleQueue then
                self:setFrameAnchor(v, nil, true)
            elseif (i == 1) then
                self:pinHeadQueue(v)
                pinned = true
            else
                local prev = frames[i - 1]
                if (not self.para.smoothQueueing) then
                    if v.headQueue then
                        self:pinHeadQueue(v)
                    else
                        self:setFrameAnchor(v, prev)
                    end
                else
                    local overlapTime =
                        (v.size / 2 + prev.size / 2) / lengthPerTime
                    local overlaps =
                        maxExp - prev.effectiveExpTime < overlapTime
                    if overlaps then
                        self:setFrameAnchor(v, prev)
                    else
                        self:pinHeadQueue(v)
                        pinned = true
                    end
                end
            end
            v.pinned = pinned
        end -- end of if below max time else
    end -- end of for i, v in ipairs(frames) do

    -- toad cleaner code please, could be its own function
    if bar.para.resolveNameOverlaps and (not bar.vertical) then
        for i = 2, #frames do
            local frame = frames[i]
            local text = frame.nameText
            local prevFrame = frames[i - 1]
            local prevText = prevFrame.nameText
            if (prevText:GetRight() > text:GetLeft()) then
                text.offset = not prevText.offset
                local mult = text.offset and 1 or 0
                local a1, a2 =
                    unpack(EW.utils.dirToAnchors[frame.para.namePosition])
                local offset =
                    (prevText:GetHeight() / 2 + text:GetHeight() / 2) + 2
                if frame.para.namePosition == "ABOVE" then
                    frame.nameText:SetPoint(a2, frame, a1, 0, offset * mult)
                elseif frame.para.namePosition == "BELOW" then
                    frame.nameText:SetPoint(a2, frame, a1, 0, -offset * mult)
                end
            end
        end
    end
    -- local a1, a2 = unpack(EW.utils.dirToAnchors[para.namePosition])
    -- frame.nameText:SetPoint(a2, frame, a1)
    if bar.para.invisibleQueue then
        self:updateBarVisibility(bar.n)
    end
end

function EW:updateFramePara(frame)
    local para = frame.para
    frame:SetSize(para.width, para.height)

    local bg = LSM:Fetch("background", para.background)
    local edge = LSM:Fetch("border", para.border)
    local bd = {
        bgFile = bg,
        edgeFile = edge,
        tile = false,
        tileSize = 0,
        edgeSize = para.borderSize,
        insets = {left = 0, right = 0, top = 0, bottom = 0}
    }

    frame:SetBackdrop(bd)
    frame:SetBackdropColor(unpack(para.color))
    frame:SetBackdropBorderColor(unpack(para.borderColor))
    frame:SetFrameLevel(frame.bar_:GetFrameLevel() + 4)

    local font = LSM:Fetch("font", para.nameFont) or "Fonts\\FRIZQT__.TTF"
    frame.nameText:SetFont(font, para.nameFontSize, "OUTLINE")
    frame.nameText:ClearAllPoints()
    local a1, a2 = unpack(EW.utils.dirToAnchors[para.namePosition])
    frame.nameText:SetPoint(a2, frame, a1)
    frame.nameText:SetTextColor(unpack(para.nameColor))

    if para.name then
        local s = ""
        if para.nameManual then
            s = para.nameManualEntry
            if para.nameNumber and frame.num > 0 then
                s = s .. frame.num
            end
        elseif para.nameAcronym then
            s = sacro(srbn(frame.name1)) -- acronym of string without number
            if para.nameNumber and frame.num > 0 then
                s = s .. frame.num
            end
        else
            s = para.nameNumber and frame.name1 or frame.name
        end

        frame.nameText:SetText(s)
    else
        frame.nameText:SetText("")
    end

    local font = LSM:Fetch("font", para.durationFont) or "Fonts\\FRIZQT__.TTF"
    frame.durationText:SetFont(font, para.durationFontSize, "OUTLINE")

    local a1, a2 = unpack(EW.utils.dirToAnchors[para.durationPosition])
    frame.durationText:SetPoint(a2, frame, a1)
    frame.durationText:SetTextColor(unpack(para.durationColor))

    if para.automaticIcon then
        frame.icon:SetTexture(frame.iconID)
    else
        frame.icon:SetTexture(para.selectedIcon or 134400)
    end
end

function EW:removeAllFrames()
    for i, v in ipairs(self.bars) do
        for i = #v.frames, 1, -1 do
            self:removeFrame(v.frames[i])
        end
    end
    EW:CancelAllTimers()
    EW:updateBarsVisibility() -- technically shouldnt be needed right?

    -- this also canceled the scheduled anchors updates, so put them back
    local t = GetTime()
    for i = 1, 4 do
        if self.bars[i].scheduledAnchorUpdate == t then
            self.bars[i].scheduledAnchorUpdate = 0
            self:scheduleAnchorUpdate(self.bars[i])
        end
    end
end

function EW:removeFrameByName(name, all)
    if not name then
        return
    end
    for i, v in ipairs(self.bars) do
        for i = #v.frames, 1, -1 do
            if v.frames[i].name == name then
                self:removeFrame(v.frames[i])
                if not all then
                    return
                end
            end
        end
    end
end

function EW:removeFrameByID(ID, all)
    if not ID then
        return
    end
    for i, v in ipairs(self.bars) do
        for i = #v.frames, 1, -1 do
            if v.frames[i].spellID == ID then
                self:removeFrame(v.frames[i])
                if not all then
                    return
                end
            end
        end
    end
end

function EW:removeBarFrameByID(bar, ID, all)
    if not ID then
        return
    end
    local v = self.bars[bar]
    for i = #v.frames, 1, -1 do
        if v.frames[i].spellID == ID then
            self:removeFrame(v.frames[i])
            if not all then
                return
            end
        end
    end
end

function EW:removeBarFrameByName(bar, name, all)
    if not name then
        return
    end
    local v = self.bars[bar]
    for i = #v.frames, 1, -1 do
        if v.frames[i].name == name then
            self:removeFrame(v.frames[i])
            if not all then
                return
            end
        end
    end
end

function EW:startCustomTimers()
    if not self.engageID then
        return
    end
    local para = self.para.bosses[self.engageID]
    if not para then
        return
    end

    for _, extraKey in ipairs(para.__extras or {}) do
        local p = self:getIconPara(extraKey)

        if p then
            -- toad icon handling
            local icon
            if p.automaticIcon then
                icon = 134400
            end

            -- actual handling of the times thing
            local prevTime = 0

            if p.customType == "Time" then
                for i, t in ipairs(p.customTimes) do
                    if i == 1 then
                        -- first element launch it straight up
                        self:spawnIcon(extraKey, extraKey, t, icon, p)
                    else
                        EW:ScheduleTimer(
                            EW.spawnIcon,
                            prevTime,
                            EW,
                            extraKey,
                            extraKey,
                            t - prevTime,
                            icon,
                            p
                        )
                    end
                    prevTime = t
                end
            end -- end of 'Time' type
        end
    end
end

EW.runningCustomPhaseTimerTimers = {} -- dont judge me, the name is fine
function EW:startCustomPhaseTimers()
    if not self.engageID then
        return
    end

    local para = self.para.bosses[self.engageID]
    if not para then
        return
    end
    local phase = self.phase
    for _, extraKey in ipairs(para.__extras or {}) do
        local p = self:getIconPara(extraKey)
        local phase = (p.usePhaseCount and self.phaseCount) or self.phase
        if p and p.customPhaseTimes[phase] then
            -- toad icon handling
            local icon
            if p.automaticIcon then
                icon = 134400
            end

            -- actual handling of the times thing
            local prevTime = 0

            if p.customType == "Phase time" then
                for i, t in ipairs(p.customPhaseTimes[phase]) do
                    if i == 1 then
                        -- first element launch it straight up
                        self:spawnIcon(extraKey, extraKey, t, icon, p)
                    else
                        local id =
                            EW:ScheduleTimer(
                            EW.spawnIcon,
                            prevTime,
                            EW,
                            extraKey,
                            extraKey,
                            t - prevTime,
                            icon,
                            p
                        )
                        tinsert(EW.runningCustomPhaseTimerTimers, id)
                    end
                    prevTime = t
                end
            end
        end
    end
end

function EW:cancelPhaseTimers()
    -- first cancel the icons
    for _, bar in ipairs(self.bars) do
        for _, frame in ipairs(bar.frames) do
            if frame.para.customType == "Phase time" then
                self:removeFrame(frame)
            end
        end
    end

    -- then the upcoming timers
    for _, id in ipairs(self.runningCustomPhaseTimerTimers) do
        self:CancelTimer(id)
    end
end

local getNumberAfterSpace = EW.utils.getNumberAfterSpace
function EW:phaseTransition(stage)
    if type(stage) == "string" then
        stage = getNumberAfterSpace(stage)
    end

    if (not stage) or (not type(stage) == "number") then
        return
    end
    self.phase = stage
    self.phaseCount = self.phaseCount + 1

    -- handle stage timers
    self:cancelPhaseTimers()
    self:startCustomPhaseTimers()
end

function EW:updateBarVisibility(n)
    local bar = self.bars[n]
    local para = bar.para

    if not para.shown then
        bar:Hide()
        return
    end
    if IsEncounterInProgress() or self.optionsOpened then
        bar:Show()
    else
        if para.hideOutOfCombat then
            if not para.invisibleQueue then
                if #bar.frames < 1 then
                    bar:Hide()
                else
                    bar:Show()
                end
            else
                local frames = bar.frames
                tsort(frames, compareExpTime)
                if (not frames[1]) or (frames[1].anchored) then
                    bar:Hide()
                else
                    bar:Show()
                end
            end
        else
            bar:Show()
        end
    end
end

function EW:updateBarsVisibility()
    for i = 1, 4 do
        self:updateBarVisibility(i)
    end
end

function EW:selectedIconTest()
    local optKey = self.options.selectedOptionKey
    if optKey then
        local o = self.options.options[optKey]
        if not o then
            return
        end

        local para = self:getIconPara(o.id, self.options.selectedBossID)
        self:spawnIcon(o.id, o.name, 15 + (random(20) - 10), o.icon, para)
    else
        local barID = self.options.selectedBar
        if not barID then
            return
        end

        local para = self.para.icons.defaults[barID]
        self:spawnIcon("Test", "Test", 15 + (random(20) - 10), 134400, para)
    end
end

local function launchTestIcon(tbl)
    -- function EW:spawnIcon(spellID, name1, duration, iconID, para)
    EW:ScheduleTimer(
        EW.spawnIcon,
        tbl["spawnIn"],
        EW,
        tbl["spellID"],
        tbl["name"],
        tbl["duration"],
        tbl["icon"]
    )
end

function EW:_debugTestBoss(tbl)
    for k, v in pairs(tbl) do
        launchTestIcon(v)
    end
end

--[[
    The above is a test function that takes in a table like such:
local tbl = {
    {
        name = "Berserk",
        duration = 420,
        spawnIn = 0,
        spellID = 106951,
        icon = 236149
    },
    {
        name = "Gluttonous Miasma (1)",
        duration = 2,
        spawnIn = 0,
        spellID = 329298,
        icon = 1390943
    },
    {
        name = "Gluttonous Miasma (2)",
        duration = 24,
        spawnIn = 2,
        spellID = 329298,
        icon = 1390943
    },
    {
        name = "Gluttonous Miasma (3)",
        duration = 24,
        spawnIn = 26,
        spellID = 329298,
        icon = 1390943
   },
    {
        name = "Volatile Ejection (1)",
        duration = 10,
        spawnIn = 0,
        spellID = 334228,
        icon = 342917
    },
    {
        name = "Volatile Ejection (2)",
        duration = 35,
        spawnIn = 10,
        spellID = 334228,
        icon = 342917
    },
    {
        name = "Expunge (1)",
        duration = 32,
        spawnIn = 0,
        spellID = 329742,
        icon = 1778228
    },
    {
        name = "Expunge (2)",
        duration = 35,
        spawnIn = 35,
        spellID = 329742,
        icon = 1778228
    }
}
]]
