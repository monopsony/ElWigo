local EW = ElWigoAddon
EW.bigWigs = {}
local BW = EW.bigWigs
local IsInInstance = IsInInstance
LibStub("AceEvent-3.0"):Embed(BW)

-- register bigwigs messages
function BW:registerAllMessages()
    -- need to use BigWigsLoader for it?
    -- rather than just AceEvent
    local register = BigWigsLoader.RegisterMessage
    register(self, "BigWigs_StartBar", self.startBar)
    register(self, "BigWigs_StopBar", self.stopBar)
    register(self, "BigWigs_StopBars", self.stopBars)
    register(self, "BigWigs_OnBossDisable", self.onBossDisable)
    register(self, "BigWigs_Message", self.message)
    register(self, "BigWigs_SetStage", self.stage)
    -- register(self, "BigWigs_OnBossEngage",   self.bossEngaged)

    register(self, "BigWigs_BarCreated", self.barCreated)
    register(self, "BigWigs_BarEmphasized", self.barCreated)
    -- technically dont need on emphasize because if bar is hidden
    -- it doesnt onUpdate and thus doesnt trigger the emphasize
end

function BW:startBar(_, spellID, name, duration, icon)
    if EW.para.ignoreDungeons then
        local inInstance, instanceType = IsInInstance()
        if inInstance and (instanceType == "party") then
            return
        end
    end
    -- toad remove
    EW:spawnIcon(spellID, name, duration, icon)
end

function BW:stopBar(table1, name)
    if EW.para.ignoreDungeons then
        local inInstance, instanceType = IsInInstance()
        if inInstance and (instanceType == "party") then
            return
        end
    end
    EW:removeFrameByName(name)
end

function BW:stopBars(...)
    if EW.para.ignoreDungeons then
        local inInstance, instanceType = IsInInstance()
        if inInstance and (instanceType == "party") then
            return
        end
    end
    EW:removeAllFrames()
end

function BW:onBossDisable(...)
    -- not doing anything with that yet
end

function BW:barCreated(table1, bar, _, name1, name2, duration, icon)
    if EW.para.ignoreDungeons then
        local inInstance, instanceType = IsInInstance()
        if inInstance and (instanceType == "party") then
            return
        end
    end
    if EW.para.hideBW then
        -- bar:Hide()
        if EW.para.preserveExtras then
            bar:SetAlpha(0)
        else
            bar:Hide()
        end
    end
end

function BW:stage(tbl, stage, ...)
    EW:phaseTransition(stage)
end

function BW:message(key, text, color, icon)
    if EW.para.ignoreDungeons then
        local inInstance, instanceType = IsInInstance()
        if inInstance and (instanceType == "party") then
            return
        end
    end
    -- not yet doing anything with that
end

-- function BW:bossEngaged(bossTbl, difficulty)
--	EW.engageID = bossTbl.engageId
--	EW.bossTbl  = bossTbl
-- end
