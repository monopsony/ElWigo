local EW = ElWigoAddon
local pairs, ipairs = pairs, ipairs
local unpack = unpack
local tremove = table.remove
local tsort = table.sort
local tinsert = table.insert
local unpack = unpack
local frameTemplate = nil -- change to "BackdropTemplate" in SL
local IsEncounterInProgress = IsEncounterInProgress
local LSM = LibStub:GetLibrary("LibSharedMedia-3.0")

EW.activeTrackedWAs = {}
EW.trackedWAs = {}

function EW:hookWANameUpdate()
    if not WeakAuras then
        return
    end
    local func = WeakAuras.Rename
    WeakAuras.Rename = function(...)
        func(...)
        EW:updateTrackedWAs()
    end

    local func2 = WeakAuras.Add
    WeakAuras.Add = function(...)
        func2(...)
        EW:updateTrackedWAs()
    end
end

local isWANameEW = EW.utils.isWANameEW
function EW:updateTrackedWAs()
    if not WeakAurasSaved then
        return
    end
    local was = WeakAurasSaved.displays
    wipe(self.trackedWAs)
    for k, _ in pairs(was) do
        local bar = isWANameEW(k)
        if bar and bar < 5 then
            EW.trackedWAs[k] = bar
        end
    end

    self:applyTrackedWAs()
end

local function trackWA(f)
    local atw = EW.activeTrackedWAs
    local name1 = f.name1

    for i = 1, #atw do
        if atw[i].name1 == name1 then
            return
        end
    end

    atw[#atw + 1] = f
end

local function untrackWA(f)
    local atw = EW.activeTrackedWAs
    local name1 = f.name1

    for i = 1, #atw do
        if atw[i].name1 == name1 then
            tremove(atw, i)
            return
        end
    end
end

local function getWARegion(name)
    -- return WeakAuras.regions[name] and WeakAuras.regions[name].region
    return WeakAuras.GetRegion(name)
end

local function getWAPara(name)
    return WeakAurasSaved.displays[name]
end

function EW:applyTrackedWAs()
    for name, _ in pairs(self.trackedWAs) do
        local f = getWARegion(name)
        if f then
            f:SetScript(
                "OnShow",
                function()
                    EW:notifyWAShow(name, true)
                end
            )

            f:SetScript(
                "OnHide",
                function()
                    EW:notifyWAShow(name, false)
                end
            )
        end
    end
end

function EW:getWAName(name)
    return ("__WA%s"):format(name)
end

function EW:prepareWA(wa, name)
    wa.para = {bar = self.trackedWAs[name]}

    local bar = self.bars[wa.para.bar]
    if not bar.para.shown then
        wa.__EWDontMove = true
        return
    end

    local name1 = self:getWAName(name)
    local t = GetTime()
    -- local para = getWAPara(name)

    wa.bar_ = bar
    wa.name = name1
    wa.name1 = name1
    wa.num = -1
    wa.spellID = name1
    wa.spawnTime = t
    wa.size = bar.vertical and wa.height or wa.width or wa.height or 20
    wa.maxTime = bar.maxTime
    wa.expTime = wa.state.expirationTime
    wa.lastUpdated = 0
    wa.refreshRate = EW.para.refreshRate
    wa.smoothQueueing = EW.para.smoothQueueing

    wa:ClearAllPoints()

    local exp = wa.state.expirationTime
    local rem = (exp and exp - t) or 1000
    wa.remDuration = rem

    -- bar handling and frame level
    tinsert(bar.frames, wa)
    if #bar.frames == 1 then
        self:updateBarVisibility(wa.para.bar)
    end
    self:scheduleAnchorUpdate(bar)

    -- wa:SetParent(bar)
    wa:SetFrameLevel(bar:GetFrameLevel() + 4) -- set parent resets it
end

local function moveWA(frame)
    local bar = frame.bar_
    local t = frame.remDuration * bar.lengthPerTime
    frame:SetPoint("CENTER", bar, bar.endAnchor, t * bar.x_mul, t * bar.y_mul)
    -- frame:SetFrameLevel(frame.bar:GetFrameLevel() + 4)
end

function EW:notifyWAShow(name, shown)
    local f = getWARegion(name)
    if shown then
        self:prepareWA(f, name)
        trackWA(f)
        moveWA(f)
    else
        untrackWA(f)
        if not f.para then
            return
        end
        local nBar, name = f.para.bar, f.name
        if nBar then
            self:removeBarFrameByName(nBar, name)
        end
    end
end

local frameOnUpdate = EW._frameOnUpdate

function EW:moveActiveWAs()
    local atw = self.activeTrackedWAs
    local t = GetTime()

    for i = 1, #atw do
        -- local f = atw[i]
        -- local exp = f.state.expirationTime
        -- f.expTime = exp
        -- local rem = (exp and exp - t) or 1000
        -- f.remDuration = rem
        -- if not f.anchored then
        --     moveWA(f)
        -- end

        -- if f.headQueue and (f.remDuration < f.maxTime) then
        --     f.headQueue = false
        --     EW:scheduleAnchorUpdate(f.bar_)
        -- end
        frameOnUpdate(atw[i])
    end
end

local ouf = CreateFrame("Frame") -- on update frame
ouf.lastUpdated = 0
function ouf.onUpdate(self, elapsed)
    local t = GetTime()
    if t - ouf.lastUpdated < EW.para.refreshRate then
        return
    end
    ouf.lastUpdated = t

    EW:moveActiveWAs()
end
ouf:SetScript("OnUpdate", ouf.onUpdate)
