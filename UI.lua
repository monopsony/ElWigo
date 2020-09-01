local EW = ElWigoAddon
local pairs, ipairs = pairs, ipairs
local unpack  = unpack 
local tremove = table.remove
local tsort   = table.sort
local tinsert = table.insert
local unpack  = unpack
local frameTemplate = nil -- change to "BackdropTemplate" in SL
local IsEncounterInProgress = IsEncounterInProgress

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0")

function EW:updateBars()
	for i = 1, 4 do
		self:updateBar(i)
	end
end

local function createBar(n)
	local f = CreateFrame(
		"Frame", ("ElWigoBar%s"):format(n), UIParent, frameTemplate)
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
	if not n then return end
	if not EW.bars[n] then EW.bars[n] = createBar(n) end

	local bar = EW.bars[n]
	local para = self.para.bars[n]
	bar.para = para
	bar.maxTime = para.maxTime

	-- do the updating
	bar:ClearAllPoints()
	local anchor = (para.vertical and 'BOTTOM') or 'LEFT'
	bar:SetPoint(anchor, UIParent, "BOTTOMLEFT", unpack(para.pos))

	if para.vertical then
		bar:SetSize(para.width, para.length)
	else
		bar:SetSize(para.length, para.width)
	end
	bar.vertical = para.vertical

	local bg = LSM:Fetch("background",para.backgroundTexture)
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
		bar.endAnchor   = (para.reverse and "TOP") or "BOTTOM"
		bar.x_mul       = 0
		bar.y_mul       = (para.reverse and -1) or 1
	else
		bar.startAnchor = (para.reverse and "LEFT") or "RIGHT"
		bar.endAnchor   = (para.reverse and "RIGHT") or "LEFT"
		bar.x_mul       = (para.reverse and -1) or 1
		bar.y_mul       = 0
	end
	bar.lengthPerTime = para.length / para.maxTime

	self:updateBarVisibility(n)

	-- TICKS

	bar.ticks = bar.ticks or {}
	local ticks = bar.ticks
	local N = max(#ticks, floor(para.maxTime/para.tickSpacing))
	if para.maxTime % para.tickSpacing == 0 then N = N -1 end

	for i = 1, N do 
		ticks[i] = ticks[i] or CreateFrame("Frame", nil, bar, frameTemplate)
		ticks[i]:SetFrameStrata("MEDIUM")
		local t = ticks[i]
		if para.hasTicks then t:Show() else t:Hide() end
		t:SetFrameLevel(bar:GetFrameLevel() + ((para.aboveIcons and 6) or 1))
		--t:SetFrameLevel(bar:GetFrameLevel() + 1)

		local thicknessOffset = floor(para.tickWidth/2)
		local l = i * para.tickSpacing * bar.lengthPerTime + thicknessOffset
		t:SetPoint("TOP", bar, bar.endAnchor, bar.x_mul*l, bar.y_mul*l)
		-- Why not just "CENTER": because then your minimum thickness is 2 pxs

		t:SetSize(para.vertical and para.tickLength or para.tickWidth,
			para.vertical and para.tickWidth or para.tickLength)

		if not t.texture then t.texture = t:CreateTexture(nil, "BACKGROUND") end
		t.texture:SetAllPoints()
		t.texture:SetColorTexture(unpack(para.tickColor))

		if not t.text then t.text = t:CreateFontString(nil, "BACKGROUND") end
		if para.tickText then t:Show() else t:Hide() end
		local a1, a2 = unpack(EW.utils.dirToAnchors[para.tickTextPosition])
		t.text:ClearAllPoints()
		t.text:SetPoint(a2, t, a1)

		t.text:SetFont("Fonts\\FRIZQT__.TTF", para.tickTextFontSize, "OUTLINE")
		t.text:SetText(i*para.tickSpacing)
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
	local frames = frame.bar.frames
	for i, v in ipairs(frames) do 
		if v.id == id then tremove(frames, i); break end
	end
	if #frames == 0 then self:updateBarVisibility(frame.bar.n) end

	-- update anchors
	self:updateAnchors(frame.bar)
end

local function moveFrame(frame, bar)
	local t = frame.remDuration * bar.lengthPerTime
	frame:SetPoint("CENTER", bar, bar.endAnchor, t*bar.x_mul, t*bar.y_mul)
	--frame:SetFrameLevel(frame.bar:GetFrameLevel() + 4)
end

local function frameOnUpdate(frame)

	local t = GetTime()
	if t - frame.lastUpdated < frame.refreshRate then return end

	frame.lastUpdated = t
	local para = frame.para


	-- UPDATE REM. DURATION
	frame.remDuration = frame.expTime - t
	if para.duration then 
		frame.durationText:SetText(("%i"):format(frame.remDuration))
	end

	-- MOVE FRAME
	if not frame.anchored then moveFrame(frame, frame.bar) end

	if t > frame.expTime then 
		EW:removeFrame(frame)
	end

	if frame.headQueue and (frame.remDuration < frame.maxTime) then 
		frame.headQueue = false
		EW:updateAnchors(frame.bar)
	end
end

local paraMetaTable = {
	__index = function(tbl, key)
		if tbl.__user[key] ~= nil then return tbl.__user[key] 
		else return tbl.__default[key] end
	end
}

function EW:getIconPara(spellID)
	local bossID    = self.engageID or 0
	local barID     = 1
	local userPara  = {}

	if self.para.bosses[bossID] and self.para.bosses[bossID][spellID] then 
		barID = self.para.bosses[bossID][spellID]['bar'] or 1
		userPara = self.para.bosses[bossID][spellID]
	end

	local para    = {
		__default = self.para.icons.defaults[barID],
		__user    = userPara,
	}
	setmetatable(para, paraMetaTable)
	return para
end

local strip = EW.utils.stringStrip
local sacro = EW.utils.acronym
local srbn  = EW.utils.removeBracketsNumber
function EW:spawnIcon(spellID, name1, duration, iconID, para)
	local name, num = strip(name1)
	local para = para or EW:getIconPara(spellID)

	local frame = createIconFrame()
	local bar   = self.bars[para.bar]
	if not bar.para.shown then return end

	frame:Show()

	frame.bar       = bar
	frame.para      = para
	frame.name      = name
	frame.name1     = name1
	frame.num       = num or -1
	frame.spellID   = spellID
	frame.size      = para.width
	frame.duration  = duration
	frame.spawnTime = GetTime()
	frame.expTime   = GetTime() + duration
	frame.iconID    = iconID
	frame.maxTime   = bar.maxTime
	self:updateFramePara(frame)

	
	frame.effectiveExpTime = frame.expTime

	-- set up OnUpdateHandler
	frame.lastUpdated = 0
	frame.refreshRate = EW.para.refreshRate

	tinsert(bar.frames, frame)
	if #bar.frames == 1 then self:updateBarVisibility(para.bar) end
	self:updateAnchors(bar)

	frame:SetParent(bar)
	frame:SetFrameLevel(bar:GetFrameLevel() + 4) -- set parent resets it

	frame:SetScript("OnUpdate", frameOnUpdate)

end

local function compareExpTime(frame1, frame2)
	return ((frame1.expTime == frame2.expTime) and (frame1.id < frame2.id)) 
		or (frame1.expTime < frame2.expTime)
end

function EW:frameToQueue(frame)
	if not frame then return end
	local bar = frame.bar
	frame.anchored  = true 
	frame.anchor    = bar
	frame.headQueue = true
	frame:SetPoint("CENTER", bar, bar.startAnchor)
end

function EW:setFrameAnchor(frame1, frame2)
	if not frame2 then
		-- force an update if it was previously anchored
		if frame1.anchored then frame1.lastUpdated = 0 end

		frame1.anchored         = false
		frame1.anchor           = nil
		frame1.effectiveExpTime = frame1.expTime
	else
		frame1.anchored = true
		frame1.anchor   = frame2

		local bar  = frame1.bar
		local dist = frame1.size/2 + frame2.size/2
		
		frame1:SetPoint("CENTER", frame2, "CENTER", 
			dist*bar.x_mul, dist*bar.y_mul)

		frame1.effectiveExpTime = frame2.effectiveExpTime + dist/bar.lengthPerTime
	end
end

function EW:updateAnchors(bar)
	local frames = bar.frames

	-- sort the frames
	tsort(frames, compareExpTime)

	-- set anchors
	local lengthPerTime = bar.lengthPerTime
	local maxTime       = bar.maxTime or 0
	local aboveMax      = false
	local maxExp        = GetTime() + maxTime

	for i, v in ipairs(frames) do 

		-- if below max time
		if v.expTime <= maxExp then

			if i == 1 then -- if first frame
				self:setFrameAnchor(v, nil)
			else
				local prev = frames[i - 1]
				local overlapTime = (v.size/2 + prev.size/2)/lengthPerTime

				-- IF OVERLAP
				local overlaps = v.expTime - prev.effectiveExpTime < overlapTime
				self:setFrameAnchor(v, (overlaps and prev) or nil)
			end

		-- if above max time
		else
			-- if first frame in queue
			if not aboveMax then 
				self:frameToQueue(v)
				aboveMax = true
			else
				local prev = frames[i - 1]
				self:setFrameAnchor(v, prev)
			end
		end -- end of if below max time else 

	end -- end of for i, v in ipairs(frames) do
end

function EW:updateFramePara(frame)
	local para = frame.para
	frame:SetSize(para.width, para.height)

	local bg = LSM:Fetch("background",para.background)
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
	frame:SetFrameLevel(frame.bar:GetFrameLevel() + 4)

	-- toad font handling
	frame.nameText:SetFont("Fonts\\FRIZQT__.TTF", para.nameFontSize, "OUTLINE")
	frame.nameText:ClearAllPoints()
	local a1, a2 = unpack(EW.utils.dirToAnchors[para.namePosition])
	frame.nameText:SetPoint(a2, frame, a1)
	frame.nameText:SetTextColor(unpack(para.nameColor))

	if para.name then
		local s = ''
		if para.nameManual then 
			s = para.nameManualEntry
			if para.nameNumber and frame.num > 0 then s = s..frame.num end
		elseif para.nameAcronym then
			s = sacro(srbn(frame.name1)) -- acronym of string without number
			if para.nameNumber and frame.num > 0 then s = s..frame.num end
		else
			s = para.nameNumber and frame.name1 or frame.name
		end

		frame.nameText:SetText(s)
	else
		frame.nameText:SetText('')
	end

	-- toad font handling
	frame.durationText:SetFont(
		"Fonts\\FRIZQT__.TTF", para.durationFontSize, "OUTLINE")

	local a1, a2 = unpack(EW.utils.dirToAnchors[para.durationPosition])
	frame.durationText:SetPoint(a2, frame, a1)
	frame.durationText:SetTextColor(unpack(para.durationColor))


	if para.automaticIcon then 
		frame.icon:SetTexture(frame.iconID)
	else
		frame.icon:Hide()
	end


end

function EW:removeAllFrames()
	for i, v in ipairs(self.bars) do
		for i = #v.frames,1,-1 do self:removeFrame(v.frames[i]) end
	end
	EW:CancelAllTimers()
end

function EW:removeFrameByName(name, all)
	if not name then return end
	for i, v in ipairs(self.bars) do
		for i = #v.frames,1,-1 do 
			if v.frames[i].name1 == name then self:removeFrame(v.frames[i]) end
			if not all then return end 
		end
	end
end

local function TEST(...)

end

function EW:startCustomTimers()

	if not self.engageID then return end
	local para = self.para.bosses[self.engageID]
	if not para then return end


	for _, extraKey in ipairs(para.__extras or {}) do 
		local p = self:getIconPara(extraKey)

		if p then
			-- toad icon handling
			local icon
			if p.automaticIcon then icon = 134400 end

			-- actual handling of the times thing
			local prevTime = 0

			if p.customType == 'Time' then 
				for i, t in ipairs(p.customTimes) do 
					if i == 1 then 
						-- first element launch it straight up 
						self:spawnIcon(extraKey, extraKey, t, icon, p)
					else
						EW:ScheduleTimer(EW.spawnIcon, prevTime, EW,
							extraKey, extraKey, t - prevTime, icon, p)
					end
					prevTime = t
				end
			end -- end of 'Time' type
		end
	end
end

EW.runningCustomPhaseTimerTimers = {} -- dont judge me, the name is fine 
function EW:startCustomPhaseTimers()

	if not self.engageID then return end
	local para = self.para.bosses[self.engageID]
	if not para then return end
	local phase = self.phase 

	for _, extraKey in ipairs(para.__extras or {}) do 
		local p = self:getIconPara(extraKey)
		local phase = (p.usePhaseCount and self.phaseCount) or self.phase 

		if p and p.customPhaseTimes[phase] then
			-- toad icon handling
			local icon
			if p.automaticIcon then icon = 134400 end

			-- actual handling of the times thing
			local prevTime = 0

			if p.customType == 'Phase time' then 
				for i, t in ipairs(p.customPhaseTimes[phase]) do 
					if i == 1 then 
						-- first element launch it straight up 
						self:spawnIcon(extraKey, extraKey, t, icon, p)
					else
						local id = EW:ScheduleTimer(EW.spawnIcon, prevTime, EW,
							extraKey, extraKey, t - prevTime, icon, p)
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
		for _,frame in ipairs(bar.frames) do 
			if frame.para.customType == 'Phase time' then 
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
	if type(stage) == 'string' then 
		stage = getNumberAfterSpace(stage)
	end

	if (not stage) or (not type(stage) == 'number') then return end
	self.phase = stage
	self.phaseCount = self.phaseCount + 1

	-- handle stage timers
	self:cancelPhaseTimers()
	self:startCustomPhaseTimers()
end

function EW:updateBarVisibility(n)
	local bar  = self.bars[n]
	local para = bar.para

	if not para.shown then bar:Hide(); return end
	if IsEncounterInProgress() or self.optionsOpened then 
		bar:Show()
	else
		if para.hideOutOfCombat and #bar.frames < 1 then 
			bar:Hide()
		else
			bar:Show()
		end
	end
end


function EW:updateBarsVisibility()
	for i = 1, 4 do self:updateBarVisibility(i) end
end

function EW:selectedIconTest()

	local optKey = self.options.selectedOptionKey
	if optKey then 
		local o = self.options.options[optKey]
		if not o then return end

		self:spawnIcon(o.id, o.name, 15 + (random(20) - 10), o.icon)
	else
		local barID = self.options.selectedBar
		if not barID then return end

		local para = self.para.icons.defaults[barID]
		self:spawnIcon('Test', 'Test', 15 + (random(20) - 10), 134400, para)
	end
end
