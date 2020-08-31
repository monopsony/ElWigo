local EW = ElWigoAddon
EW.bigWigs = {}
local BW = EW.bigWigs

LibStub("AceEvent-3.0"):Embed(BW)

-- register bigwigs messages
function BW:registerAllMessages()
	-- need to use BigWigsLoader for it?
	-- rather than just AceEvent 
	local register =  BigWigsLoader.RegisterMessage
	register(self, "BigWigs_StartBar",       self.startBar)
	register(self, "BigWigs_StopBar",        self.stopBar)
	register(self, "BigWigs_StopBars",       self.stopBars)
	register(self, "BigWigs_OnBossDisable",  self.onBossDisable)
	register(self, "BigWigs_Message",        self.message)
	--register(self, "BigWigs_OnBossEngage",   self.bossEngaged)

	register(self, "BigWigs_BarCreated",    self.barCreated)
	register(self, "BigWigs_BarEmphasized", self.barCreated) 
	-- technically dont need on emphasize because if bar is hidden
	-- it doesnt onUpdate and thus doesnt trigger the emphasize 

end

function BW:dummyFunction(...)
end

function BW:startBar(_, spellID, name, duration, icon)

	-- toad remove
	EW:spawnIcon(spellID, name, duration, icon)
end

function BW:stopBar(table1, name)
	EW:removeFrameByName(name)
end

function BW:stopBars(...)
	EW:removeAllFrames()
end

function BW:onBossDisable(...)
	EW.engageID = nil 
end

function BW:barCreated(table1, bar, _, name1, name2, duration, icon)
	if EW.para.hideBW then bar:Hide() end
end

function BW:barCreated2(table1, bar, _, name1, name2, duration, icon)
	if EW.para.hideBW then bar:Hide() end
end

function BW:message(key, text, color, icon)
	if key == 'stages' then EW:phaseTransition(text) end
end

--function BW:bossEngaged(bossTbl, difficulty)
--	EW.engageID = bossTbl.engageId
--	EW.bossTbl  = bossTbl
--end