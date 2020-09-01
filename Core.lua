ElWigoAddon = LibStub("AceAddon-3.0"):NewAddon(
	"ElWigo",
	"AceConsole-3.0",
	"AceTimer-3.0")

local EW = ElWigoAddon
local AceConfigDialog=LibStub("AceConfigDialog-3.0")
local AceGUI = LibStub("AceGUI-3.0")

local defaults = {
	profile = {
		bars = {
			[1] = {
				shown      = true,
				pos        = {1000, 500},
				vertical   = true,
				reverse    = false,
				length     = 300,
				width      = 13,
				maxTime    = 20,

				backgroundColor = {0, 0, 0, 0.5},
				backgroundTexture = 'Solid',
				backgroundBorder = 'Blizzard Tooltip',
				backgroundBorderSize = 8,			
				backgroundBorderColor = {1, 1, 1, 1},

				hideOutOfCombat = true,

				hasTicks         = true,
				aboveIcons       = true,
				tickSpacing      = 5,
				tickLength       = 20,
				tickWidth        = 1,
				tickColor        = {1, 1, 1, 1},
				tickText         = true,
				tickTextFontSize = 10,
				tickTextPosition = 'LEFT',
				tickTextColor    = {1, 1, 1, 1},
			},

			[2] = {
				shown      = true,
				pos        = {1050, 500},
				vertical   = true,
				reverse    = false,
				length     = 300,
				width      = 13,
				maxTime    = 20,

				backgroundColor = {0, 0, 0, 0.5},
				backgroundTexture = 'Solid',
				backgroundBorder = 'Blizzard Tooltip',
				backgroundBorderSize = 8,
				backgroundBorderColor = {1, 1, 1, 1},
				
				hideOutOfCombat = true,
				hasTicks         = true,
				aboveIcons       = true,
				tickSpacing      = 5,
				tickLength       = 20,
				tickWidth        = 1,
				tickColor        = {1, 1, 1, 1},
				tickText         = true,
				tickTextFontSize = 10,
				tickTextPosition = 'LEFT',
				tickTextColor    = {1, 1, 1, 1},
			},

			[3] = {
				shown      = false,
				pos        = {1100, 500},
				vertical   = true,
				reverse    = false,
				length     = 300,
				width      = 13,
				maxTime    = 20,

				backgroundColor = {0, 0, 0, 0.5},
				backgroundTexture = 'Solid',
				backgroundBorder = 'Blizzard Tooltip',
				backgroundBorderSize = 8,
				backgroundBorderColor = {1, 1, 1, 1},

				hideOutOfCombat = true,
				hasTicks         = true,
				aboveIcons       = true,
				tickSpacing      = 5,
				tickLength       = 20,
				tickWidth        = 1,
				tickColor        = {1, 1, 1, 1},
				tickText         = true,
				tickTextFontSize = 10,
				tickTextPosition = 'LEFT',
				tickTextColor    = {1, 1, 1, 1},
			},


			[4] = {
				shown      = false,
				pos        = {1150, 500},
				vertical   = true,
				reverse    = false,
				length     = 300,
				width      = 13,
				maxTime    = 20,

				backgroundColor = {0, 0, 0, 0.5},
				backgroundTexture = 'Solid',
				backgroundBorder = 'Blizzard Tooltip',
				backgroundBorderSize = 8,
				backgroundBorderColor = {1, 1, 1, 1},

				hideOutOfCombat = true,
				hasTicks         = true,
				aboveIcons       = true,
				tickSpacing      = 5,
				tickLength       = 20,
				tickWidth        = 1,
				tickColor        = {1, 1, 1, 1},
				tickText         = true,
				tickTextFontSize = 10,
				tickTextPosition = 'LEFT',
				tickTextColor    = {1, 1, 1, 1},
			},
		}, -- end of bars

		refreshRate = .05,

		icons = {
			defaults = { -- defaults for each bar
				[1] = {
					width            = 35,
					height           = 35,
					border           = 'None',
					borderSize       = 8,
					background       = 'None',
					color            = {1, 1, 1, 1},
					borderColor      = {1, 1, 1, 1},
					duration         = true,
					durationFontSize = 15,
					durationPosition = 'CENTER',
					durationColor    = {1, 1, 1, 1},
					name             = true,
					nameFontSize     = 15,
					namePosition     = 'LEFT',
					nameColor        = {1, 1, 1, 1},
					nameAcronym      = false,
					nameNumber       = true,
					nameManual       = false,
					nameManualEntry  = '',
					automaticIcon    = true,
					selectedIcon     = 134400,
					bar              = 1,
					customType       = 'Time',
					customTimes      = {},
					customPhaseTimes = {},
					usePhaseCount    = false,
				},

				[2] = {
					width            = 25,
					height           = 25,
					border           = 'None',
					borderSize       = 8,
					background       = 'None',
					color            = {1, 1, 1, 1},
					borderColor      = {1, 1, 1, 1},
					duration         = true,
					durationFontSize = 15,
					durationPosition = 'CENTER',
					durationColor    = {1, 1, 1, 1},
					name             = true,
					nameFontSize     = 15,
					namePosition     = 'LEFT',
					nameColor        = {1, 1, 1, 1},
					nameAcronym      = false,
					nameNumber       = true,
					nameManual       = false,
					nameManualEntry  = '',
					automaticIcon    = true,
					selectedIcon     = 134400,
					bar              = 2,
					customType       = 'Time',
					customTimes      = {},
					customPhaseTimes = {},
					usePhaseCount    = false,
				},

				[3] = {
					width            = 35,
					height           = 35,
					border           = 'None',
					borderSize       = 8,
					background       = 'None',
					color            = {1, 1, 1, 1},
					borderColor      = {1, 1, 1, 1},
					duration         = true,
					durationFontSize = 15,
					durationPosition = 'CENTER',
					durationColor    = {1, 1, 1, 1},
					name             = true,
					nameFontSize     = 15,
					namePosition     = 'LEFT',
					nameColor        = {1, 1, 1, 1},
					nameAcronym      = false,
					nameNumber       = true,
					nameManual       = false,
					nameManualEntry  = '',
					automaticIcon    = true,
					selectedIcon     = 134400,
					bar              = 3,
					customType       = 'Time',
					customTimes      = {},
					customPhaseTimes = {},
					usePhaseCount    = false,
				},

				[4] = {
					width            = 35,
					height           = 35,
					border           = 'None',
					borderSize       = 8,
					background       = 'None',
					color            = {1, 1, 1, 1},
					borderColor      = {1, 1, 1, 1},
					duration         = true,
					durationFontSize = 15,
					durationPosition = 'CENTER',
					durationColor    = {1, 1, 1, 1},
					name             = true,
					nameFontSize     = 15,
					namePosition     = 'LEFT',
					nameColor        = {1, 1, 1, 1},
					nameAcronym      = false,
					nameNumber       = true,
					nameManual       = false,
					nameManualEntry  = '',
					automaticIcon    = true,
					selectedIcon     = 134400,
					bar              = 4,
					customType       = 'Time',
					customTimes      = {},
					customPhaseTimes = {},
					usePhaseCount    = false,
				},
			}, -- end of icons/defaults
		}, -- end of icons

		bosses = {

		}

	}, -- end of profile
}

function EW:OnInitialize()
	self.db=LibStub("AceDB-3.0"):New("ElWigoDB", defaults, true)
	self.para = self.db.profile

	local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	self.__aceOptions.args.profiles = profiles
	for k,v in pairs(profiles) do print(k,v) end


	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

	AceConfigDialog:SetDefaultSize('ElWigo', 1200, 700)

	-- fill in info
	self.encounterID = nil
	self.bigWigs:registerAllMessages()

	-- load BW raids 
	self.options:updateBWRaidList()

	-- UI
	self:updateBars()
end 

function EW:OnEnable()
	-- 
end

function EW:OnDisable()
	--
end

function EW:RefreshConfig()
	-- ReloadUI()
	self.para = self.db.profile
	self:updateBars()
	--self.options:updateRaidListAll()
end

-- toad remove
EW.engageID = 2329 -- Nyalotha Wrathion, BY DEFAULT FOR TESTING PURPOSES
EW.optionsOpened = false
function EW:chatCommandHandler(msg)
	SlashCmdList.BigWigs()
	AceConfigDialog:Close("BigWigs")
	if BigWigsOptions:IsOpen() then BigWigsOptions:Open() end

	--EW.options:updateRaidListAll()
	if not self.optionsOpened then
		local frame = AceGUI:Create("Frame")
		self.currentOptionsFrame = frame

		frame:Show()
		frame:SetTitle("ElWigo")
		frame:SetCallback("OnClose", function(widget)
			AceGUI:Release(widget)
			EW:optionsOnClose()
		end)

		AceConfigDialog:Open("ElWigo", frame)

		self:optionsOnOpen()

	else
		self.currentOptionsFrame:Hide()
		self.currentOptionsFrame = nil
	end

	self.options:selectCurrentRaidBoss()
end
EW:RegisterChatCommand("ew","chatCommandHandler")

function EW:optionsOnOpen()
	self.optionsOpened = true
	self:updateBarsVisibility()
end

function EW:optionsOnClose()
	self.optionsOpened = false
	self:updateBarsVisibility()
end

EW.eventFrame = CreateFrame("Frame", "ElWigoEventFrame", UIParent)
EW.eventFrame:RegisterEvent("ENCOUNTER_START")
EW.eventFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "ENCOUNTER_START" then
		local id = ...
		EW.engageID = id
		EW.phaseCount = 0 -- EW:phaseTransition() increments it to 1
		EW:startCustomTimers()
		EW:phaseTransition(1)
	end
end)
