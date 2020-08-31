--------------------------------------------------------------
-- This is a bit of a mess
-- If you're considering looking through the code in this file, reconsider
-- 
-- Thank you
--------------------------------------------------------------

local EW = ElWigoAddon
local unpack                   = unpack 
local pairs, ipairs            = pairs, ipairs
local tremove                  = table.remove
local tsort                    = table.sort
local tremove                  = table.remove
local tinsert                  = table.insert
local CopyTable                = CopyTable
local SecondsToTime            = SecondsToTime
local getNumberAfterUnderscore = EW.utils.getNumberAfterUnderscore
local getNumberAfterSpace      = EW.utils.getNumberAfterSpace

EW.options  = {}
local opt   = EW.options
opt.options = {}

opt.selectedOptionKey = nil
opt.selectedBossID    = nil
opt.selectedBar       = nil

local function noOptionSelected()

	return (opt.selectedOptionKey and true) or false 
end

local AceConfig       = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceGUI          = LibStub("AceGUI-3.0")
local LSM             = LibStub:GetLibrary("LibSharedMedia-3.0")

local generalOptions = {
	refreshRate = {
		type = 'range',
		name = 'Refresh time (s)',
		order = 1,
		min = 0.01,
		softMax = 1,
		step = 0.01,
		desc = 'Refresh time of the frames. Smaller times means smoother '
			..'movement but larger impact on performance.',

		get = function()
			return EW.para.refreshRate
		end,

		set = function(tbl, value)
			EW.para.refreshRate = value
		end,
	},

	hideBW = {
		type = 'toggle',
		name = 'Hide BW bars',
		order = 2,

		get = function()
			return EW.para.hideBW
		end,

		set = function(tbl, value)
			EW.para.hideBW = value
		end,
	},
}

local aceOptions = {
	type='group',
	childGroups='tab',
	args= {
		refresh = {
			order = 1,
			name = 'Refresh',
			type = 'execute',
			desc = 'Refresh options to fix missing spell descriptions.',
			func = function(...)
				opt:updateRaidList(true)
				AceConfigDialog:Open("ElWigo")
				AceConfigDialog:Open("ElWigo")
			end,
		},

		general= {
			order = 10,
			name  = 'General',
			type  = 'group',
			args  = generalOptions,
		},

		bars= {
			order = 11,
			name  = 'Bars',
			type  = 'group',
			childGroups = 'tree',
			args  = {},
		},

		bosses= {
			order       = 12,
			name        = 'Bosses',
			type        = 'group',
			childGroups = 'select',
			args        = {},
		},
	}
}

local barOptions = {

	headerGeneral = {
		type = 'header',
		name = 'General',
		order = 10,
	},

	shown = {
		type = 'toggle',
		name = 'Shown',
		order = 11,
		desc = 'Toggle to control bar visibility.',

		set = function(tbl, value)
			opt:setSelectedBarPara('shown', value, true)
		end,
		get = function()
			return opt:getSelectedBarPara('shown')
		end,
	},

	posX = {
		type  = 'range',
		name  = 'X',
		order = 12,
		desc  = 'X position',
		min   = 0,
		step  = 1,
		max   = ceil(GetScreenWidth()),

		set = function(tbl, value)
			local pos = opt:getSelectedBarPara('pos')
			pos[1] = value
			opt:setSelectedBarPara('pos', pos, true)
		end,

		get = function()
			local pos = opt:getSelectedBarPara('pos')
			return pos[1]
		end,
	},

	posY = {
		type  = 'range',
		name  = 'Y',
		order = 12,
		desc  = 'Y position',
		min   = 0,
		step  = 1,
		max   = ceil(GetScreenHeight()),

		set = function(tbl, value)
			local pos = opt:getSelectedBarPara('pos')
			pos[2] = value
			opt:setSelectedBarPara('pos', pos, true)
		end,

		get = function()
			local pos = opt:getSelectedBarPara('pos')
			return pos[2]
		end,
	},

	vertical = {
		type = 'toggle',
		name = 'Vertical',
		order = 13,

		set = function(tbl, value)
			opt:setSelectedBarPara('vertical', value, true)
		end,
		get = function()
			return opt:getSelectedBarPara('vertical')
		end,
	},

	reverse = {
		type = 'toggle',
		name = 'Reverse',
		order = 14,
		desc = 'Reverse the direction of the bar (left <-> right, up <-> down)',
		set = function(tbl, value)
			opt:setSelectedBarPara('reverse', value, true)
		end,
		get = function()
			return opt:getSelectedBarPara('reverse')
		end,
	},	

	maxTime = {
		type  = 'range',
		name  = 'Maximum time',
		desc = 'Icons with remaining duration higher than this value will be '
			..'put in the queue before falling down.',
		order = 15,
		min   = 0,
		step  = .5,
		softMax   = 60,

		set = function(tbl, value)
			opt:setSelectedBarPara('maxTime', value, true)
		end,

		get = function()
			return opt:getSelectedBarPara('maxTime')
		end,
	},

	-- BACKGROUND
	headerBackground = {
		type = 'header',
		name = 'Background',
		order = 30,
	},

	length = {
		type  = 'range',
		name  = 'Length',
		order = 31,
		min   = 0,
		step  = 1,
		max   = ceil(GetScreenWidth()),

		set = function(tbl, value)
			opt:setSelectedBarPara('length', value, true)
		end,

		get = function()
			return opt:getSelectedBarPara('length')
		end,
	},

	width = {
		type  = 'range',
		name  = 'Thickness',
		order = 32,
		min   = 0,
		step  = 1,
		softMax   = 100,

		set = function(tbl, value)
			opt:setSelectedBarPara('width', value, true)
		end,

		get = function()
			return opt:getSelectedBarPara('width')
		end,
	},

	border = {
		order         = 33,
		type          = 'select',
		dialogControl = 'LSM30_Border',
		name          = 'Border',
		values        = LSM:HashTable("border"),
		set           = function(tbl, value)
			opt:setSelectedBarPara('backgroundBorder', value, true)
		end,
		get           = function()
			return opt:getSelectedBarPara('backgroundBorder')
		end,	
	},

	borderSize = {
		order   = 34,
		name    = 'Border thickness',
		type    = 'range',
		min     = 1,
		softMax = 30,
		step    = 1,
		set     = function(tbl, value)
			opt:setSelectedBarPara('backgroundBorderSize', value, true)
		end,
		get     = function()
			return opt:getSelectedBarPara('backgroundBorderSize')
		end,
	},

	background = {
		order         = 35,
		type          = 'select',
		dialogControl = 'LSM30_Background',
		name          = 'Background',
		values        = LSM:HashTable("background"),
		set           = function(tbl, value)
			opt:setSelectedBarPara('backgroundTexture', value, true)
		end,
		get           = function()
			return opt:getSelectedBarPara('backgroundTexture')
		end,	
	},

	backgroundColor = {
		order  = 36,
		type = 'color',
		name = 'Color',
		hasAlpha = true,
		set           = function(tbl, r, g, b,a)
			opt:setSelectedBarPara('backgroundColor', {r,g,b,a}, true)
		end,
		get           = function()
			return unpack(opt:getSelectedBarPara('backgroundColor'))
		end,	
	},

	-- BORDER
	headerBorder = {
		type = 'header',
		name = 'Border',
		order = 40,
	},


	border = {
		order         = 41,
		type          = 'select',
		dialogControl = 'LSM30_Border',
		name          = 'Border',
		values        = LSM:HashTable("border"),
		set           = function(tbl, value)
			opt:setSelectedBarPara('backgroundBorder', value, true)
		end,
		get           = function()
			return opt:getSelectedBarPara('backgroundBorder')
		end,	
	},

	borderSize = {
		order   = 42,
		name    = 'Border thickness',
		type    = 'range',
		min     = 1,
		softMax = 30,
		step    = 1,
		set     = function(tbl, value)
			opt:setSelectedBarPara('backgroundBorderSize', value, true)
		end,
		get     = function()
			return opt:getSelectedBarPara('backgroundBorderSize')
		end,
	},

	borderColor = {
		order  = 43,
		type = 'color',
		name = 'Color',
		hasAlpha = true,
		set           = function(tbl, r, g, b,a)
			opt:setSelectedBarPara('backgroundBorderColor', {r,g,b,a}, true)
		end,
		get           = function()
			return unpack(opt:getSelectedBarPara('backgroundBorderColor'))
		end,	
	},
}

local iconOptions = {
	hidden = {
		order = 0,
		type  = 'description',
		name = 'hidden',
		hidden = function(tbl)
			opt.selectedOptionKey = tbl[4]
			return true
		end,
	},

	description = {
		order = 1,
		type = 'description',
		disabled = noOptionSelected,
		name = function(...)
			if not opt.selectedOptionKey then return '' end
			if not opt.options[opt.selectedOptionKey] then return '' end
			local o = opt.options[opt.selectedOptionKey]
			return o.desc or 'N/A'
		end,
		imageWidth = 50,
		imageHeight = 50,
		image = function(...)
			if not opt.selectedOptionKey then return 134400 end
			local o = opt.options[opt.selectedOptionKey]
			return (o and o.icon) or 134400
		end,
	},

	-- GENERAL
	separatorGeneral = {
		order = 10,
		type = 'header',
		name = 'General',
	},

	bar = {
		desc = 'On which out of the 4 bars this icon should appear.',
		order   = 11,
		name    = 'Bar',
		type    = 'select',
		width   = 'half',
		values  = {[1]='1', [2]='2', [3]='3', [4]='4'},		

		set     = function(tbl, value)
			opt:setSelectedIconPara('bar', value)
		end,
		get     = function()
			return opt:getSelectedIconPara('bar')
		end,
	},

	size = {
		desc    = 'How big the icon should be.',
		order   = 12,
		name    = 'Size',
		type    = 'range',
		min     = 1,
		softMax = 50,
		step    = 1,
		set     = function(tbl, value)
			opt:setSelectedIconPara('width', value)
			opt:setSelectedIconPara('height', value)
		end,
		get     = function()
			return opt:getSelectedIconPara('width')
		end,
	},

	border = {
		order         = 13,
		type          = 'select',
		dialogControl = 'LSM30_Border',
		name          = 'Border',
		desc          = 'Choose the border of the frame.',
		values        = LSM:HashTable("border"),
		set           = function(tbl, value)
			opt:setSelectedIconPara('border', value)
		end,
		get           = function()
			return opt:getSelectedIconPara('border')
		end,	
	},

	borderSize = {
		desc    = 'How large the border should be.',
		order   = 14,
		name    = 'Border thickness',
		type    = 'range',
		min     = 1,
		softMax = 30,
		step    = 1,
		set     = function(tbl, value)
			opt:setSelectedIconPara('borderSize', value)
		end,
		get     = function()
			return opt:getSelectedIconPara('borderSize')
		end,
	},

	borderColor = {
		order  = 15,
		type = 'color',
		name = 'Border color',
		desc = 'Color of the border.',
		set           = function(tbl, r, g, b,a)
			opt:setSelectedIconPara('borderColor', {r,g,b,a})
		end,
		get           = function()
			return unpack(opt:getSelectedIconPara('borderColor'))
		end,	
	},

	background = {
		order         = 16,
		type          = 'select',
		dialogControl = 'LSM30_Background',
		name          = 'Background',
		desc          = 'Choose the background of the frame.',
		values        = LSM:HashTable("background"),
		set           = function(tbl, value)
			opt:setSelectedIconPara('background', value)
		end,
		get           = function()
			return opt:getSelectedIconPara('background')
		end,	
	},

	color = {
		order  = 17,
		type = 'color',
		name = 'Background color',
		desc = 'Color of the background.',
		set           = function(tbl, r, g, b,a)
			opt:setSelectedIconPara('color', {r,g,b,a})
		end,
		get           = function()
			return unpack(opt:getSelectedIconPara('color'))
		end,	
	},

	-- DURATION
	separatorDuration = {
		order = 30,
		type  = 'header',
		name  = 'Duration Text',		
	},

	durationText = {
		order = 31,
		type  = 'toggle',
		desc  = 'Show remaining duration text.',
		name  = 'Show',

		set   = function(tbl, value)
			opt:setSelectedIconPara('duration', value)
		end,
		get   = function()
			return opt:getSelectedIconPara('duration')
		end,	
	},

	durationFontSize = {
		order   = 32,
		type    = 'range',
		desc    = 'Font size of the remaining duration text.',
		name    = 'Font size',
		min     = 0,
		softMax = 25,
		step    = 1,

		set     = function(tbl, value)
			opt:setSelectedIconPara('durationFontSize', value)
		end,
		get     = function()
			return opt:getSelectedIconPara('durationFontSize')
		end,		
	},

	durationPosition = {
		order = 33,
		type = 'select',
		values = EW.utils.dirToAnchorValues,
		name = 'Position',
		desc = 'Position of the name text.',
		set     = function(tbl, value)
			opt:setSelectedIconPara('durationPosition', value)
		end,
		get     = function()
			return opt:getSelectedIconPara('durationPosition')
		end,		
		disabled = function()
			local name = opt:getSelectedIconPara('name')
			return (not name)
		end,
	},

	durationColor = {
		order  = 34,
		type = 'color',
		name = 'Color',
		desc = 'Color of the name text.',
		set           = function(tbl, r, g, b,a)
			opt:setSelectedIconPara('durationColor', {r,g,b,a})
		end,
		get           = function()
			return unpack(opt:getSelectedIconPara('durationColor'))
		end,	
	},

	-- NAME 
	separatorName = {
		order  = 40,
		type   = 'header',
		name   = 'Name Text',
	},

	nameText = {
		order = 41,
		type  = 'toggle',
		desc  = 'Show name text.',
		name  = 'Show',
		set   = function(tbl, value)
			opt:setSelectedIconPara('name', value)
		end,
		get   = function()
			return opt:getSelectedIconPara('name')
		end,
	},

	nameFontSize = {
		order   = 42,
		type    = 'range',
		desc    = 'Font size of the name text.',
		name    = 'Font size',
		min     = 0,
		softMax = 25,
		step    = 1,

		set     = function(tbl, value)
			opt:setSelectedIconPara('nameFontSize', value)
		end,
		get     = function()
			return opt:getSelectedIconPara('nameFontSize')
		end,		
		disabled = function()
			local name = opt:getSelectedIconPara('name')
			return (not name)
		end,
	},

	namePosition = {
		order = 43,
		type = 'select',
		values = EW.utils.dirToAnchorValues,
		name = 'Position',
		desc = 'Position of the name text.',
		set     = function(tbl, value)
			opt:setSelectedIconPara('namePosition', value)
		end,
		get     = function()
			return opt:getSelectedIconPara('namePosition')
		end,		
		disabled = function()
			local name = opt:getSelectedIconPara('name')
			return (not name)
		end,
	},

	nameColor = {
		order  = 44,
		type = 'color',
		name = 'Color',
		desc = 'Color of the name text.',
		set           = function(tbl, r, g, b,a)
			opt:setSelectedIconPara('nameColor', {r,g,b,a})
		end,
		get           = function()
			return unpack(opt:getSelectedIconPara('nameColor'))
		end,	
	},

	nameAcronym = {
		order = 45,
		type  = 'toggle',
		desc  = 'Turn name into acronym (for example: "Evoke Anguish" -> "EA")',
		name  = 'Acronym',

		set   = function(tbl, value)
			opt:setSelectedIconPara('nameAcronym', value)
		end,
		get   = function()
			return opt:getSelectedIconPara('nameAcronym')
		end,	
		disabled = function()
			local name = opt:getSelectedIconPara('name')
			local manual = opt:getSelectedIconPara('nameManual')
			return (not name) or (manual)
		end,
	},

	nameNumber = {
		order = 46,
		type  = 'toggle',
		desc  = 'Include number in name (for example: "Evoke Anguish (2)")'
				..' when BigWigs provides it',
		name  = 'Number',

		set   = function(tbl, value)
			opt:setSelectedIconPara('nameNumber', value)
		end,
		get   = function()
			return opt:getSelectedIconPara('nameNumber')
		end,	
		disabled = function()
			local name = opt:getSelectedIconPara('name')
			return (not name)
		end,
	},

	nameManual = {
		order = 47,
		type  = 'toggle',
		desc  = 'Manually replace the name',
		name  = 'Manual',
		set   = function(tbl, value)
			opt:setSelectedIconPara('nameManual', value)
		end,
		get   = function()
			return opt:getSelectedIconPara('nameManual')
		end,	
		disabled = function()
			local name = opt:getSelectedIconPara('name')
			return (not name) 
		end,
	},

	nameManualEntry = {
		order = 48,
		type  = 'input',
		desc  = 'Set the name',
		name  = 'Name (manual)',
		set   = function(tbl, value)
			opt:setSelectedIconPara('nameManualEntry', value or '')
		end,
		get   = function()
			return opt:getSelectedIconPara('nameManualEntry')
		end,	
		disabled = function()
			local name = opt:getSelectedIconPara('name')
			local manual = opt:getSelectedIconPara('nameManual')
			return (not name) or (not manual)
		end,
	},

	-- NAME 
	separatorIcon = {
		order  = 60,
		type   = 'header',
		name   = 'Icon',
	},

	automaticIcon = {
		order = 61,
		type  = 'toggle',
		desc  = 'Automatically set the icon to the ability icon (as provided by'
			..' BigWigs).',
		name  = 'Automatic icon',
		set   = function(tbl, value)
			opt:setSelectedIconPara('automaticIcon', value)
		end,
		get   = function()
			return opt:getSelectedIconPara('automaticIcon')
		end,
	},
}

-- fill aceOptions.bars
do 
	local args = aceOptions.args.bars.args
	for i = 1, 4 do 
		local barID = ("Bar %s"):format(i)
		args[barID] = {
			type = "group",
			name = barID,
			order = i*10,
			childGroups = 'tab',
			args = {
				hidden = {
					type = 'description',
					name = 'hidden',
					order = 0,
					hidden = function(tbl)
						opt.selectedBar = getNumberAfterSpace(tbl[2])
						return true
					end,
				},

				Bar = {
					type = 'group',
					name = 'Bar',
					order = 10,
					args = CopyTable(barOptions),
				},

				["Icon default"] = {
					type = 'group',
					name = 'Icon default',
					order = 20,
					args = CopyTable(iconOptions)
				},
			}
		}

		args[barID].args['Icon default'].args["hidden"] = {
			type = 'description',
			name = 'hidden',
			order = 0,
			hidden = function()
				opt.selectedOptionKey = nil
				-- if nil then the set/get functions will act on default[barID]
				return true
			end,
		}

		args[barID].args['Icon default'].args.description = nil

	end
end


opt.customTypes = {
	Time           = 'Time',
	['Phase time'] = 'Phase time',
}

local newTimeMinutes, newTimeSeconds = 0, 0
local currentPhaseTimePhase = 1 -- used for phaseTime custom icons

local function addNewTime()
	local s, m = tonumber(newTimeSeconds or 0), tonumber(newTimeMinutes or 0)
	newTimeSeconds, newTimeMinutes = 0, 0 -- reset the bad boys

	local t = m * 60 + s
	if (t == 0) or (t > 86400) then return end -- surely nobody needs >24hrs

	local customTimes = CopyTable(opt:getSelectedIconPara('customTimes'))

	tinsert(customTimes, t)
	tsort(customTimes)
	opt:setSelectedIconPara('customTimes', customTimes)
end

local function addNewPhaseTime()
	local s, m = tonumber(newTimeSeconds or 0), tonumber(newTimeMinutes or 0)
	local phase = currentPhaseTimePhase
	if not phase then return end

	newTimeSeconds, newTimeMinutes = 0, 0 -- reset the bad boys

	local t = m * 60 + s
	if (t == 0) or (t > 86400) then return end -- surely nobody needs >24hrs

	local customTimes = CopyTable(opt:getSelectedIconPara('customPhaseTimes'))
	if not customTimes[phase] then customTimes[phase] = {} end

	tinsert(customTimes[phase], t)
	tsort(customTimes[phase])

	opt:setSelectedIconPara('customPhaseTimes', customTimes)
end

local phaseTable = {}
for i = 1, 10 do phaseTable[i] = ("Phase %s"):format(i) end

local customIconOptions = {
	type = {
		type   = 'select',
		name   = 'Type',
		order  = 1,
		values = opt.customTypes,

		set    = function(tbl, value)
			opt:setSelectedIconPara('customType', value)
		end,
		get    = function()
			return opt:getSelectedIconPara('customType')
		end,	
	},

	-- Phase time --

	phaseTimePhase = {
		type   = 'select',
		name   = 'Phase',
		order  = 2,
		values = phaseTable,
		hidden = function()
			local typ = opt:getSelectedIconPara('customType')
			return typ ~= 'Phase time'
		end,

		set    = function(tbl, value)
			currentPhaseTimePhase = value
		end,
		get    = function()
			return currentPhaseTimePhase
		end,	
	},

	phaseTimePhaseCount = {
		type   = 'toggle',
		name   = 'Phase count',
		order  = 3,
		desc   = 'Enable to use phase counts instead of actual phase numbers. '
			..'For example, if the boss goes phase 1 -> 2 -> 1 -> 2, '
			..'phase count goes 1 -> 2 -> 3 -> 4',
		hidden = function()
			local typ = opt:getSelectedIconPara('customType')
			return typ ~= 'Phase time'
		end,

		set    = function(tbl, value)
			opt:setSelectedIconPara('usePhaseCount', value)
		end,
		get    = function()
			return opt:getSelectedIconPara('usePhaseCount')
		end,	
	},

	-- Time & Phase time --

	timesHeader = {
		type = 'header',
		order = 5,
		name = 'Times',
		hidden = function()
			local typ = opt:getSelectedIconPara('customType')
			return typ ~= 'Time' and typ ~= 'Phase time'
		end,
	},

	newTimeMinutes = {
		type = 'input',
		order = 6,
		name = 'Minutes',
		hidden = function()
			local typ = opt:getSelectedIconPara('customType')
			return typ ~= 'Time' and typ ~= 'Phase time'
		end,
		set = function(tbl, value)
			newTimeMinutes = value
		end,
		get = function()
			return newTimeMinutes
		end,
		width = 0.5,
		pattern = "^%d+$",
	},

	newTimeSeconds = {
		type = 'input',
		order = 7,
		name = 'Seconds',
		hidden = function()
			local typ = opt:getSelectedIconPara('customType')
			return typ ~= 'Time' and typ ~= 'Phase time'
		end,
		set = function(tbl, value)
			newTimeSeconds = value
		end,
		get = function()
			return newTimeSeconds
		end,
		width = 0.5,
		pattern = "^%d+$",
	},

	newTimeButton = {
		type = 'execute',
		order = 8,
		name = 'New Time',
		func = addNewTime,
		width = 0.6,
		hidden = function()
			local typ = opt:getSelectedIconPara('customType')
			return typ ~= 'Time'
		end,
	},

	newPhaseTimeButton = {
		type = 'execute',
		order = 8,
		name = 'New Time',
		func = addNewPhaseTime,
		width = 0.6,
		hidden = function()
			local typ = opt:getSelectedIconPara('customType')
			return typ ~= 'Phase time'
		end,
	},

	newTimeSpacer = {
		order = 9,
		type = 'description',
		width = 'full',
		name = '',
		hidden = function()
			local typ = opt:getSelectedIconPara('customType')
			return typ ~= 'Time' and typ ~= 'Phase time' 
		end,
	},
}

local function removeCustomTime(tbl, ...)
	local name = tbl[6]
	local N = getNumberAfterUnderscore(name)
	if not N then return end

	local customTimes = opt:getSelectedIconPara('customTimes')
	tremove(customTimes, N)
end

local function removeCustomPhaseTime(tbl, ...)
	local name = tbl[6]
	local N = getNumberAfterUnderscore(name)
	if not N then return end

	local customTimes = opt:getSelectedIconPara('customPhaseTimes')
	local customPhaseTimes = customTimes[currentPhaseTimePhase]
	tremove(customPhaseTimes, N)
end

local function addTimerElement(tbl, i, secs, func)
	local name = ("customTime_%s"):format(i)
	tbl[name] = {
		type = 'execute',
		order = 20 + i*3 + 1,
		name = '',
		func = func,
		width = 0.1,
		image = 'INTERFACE\\Buttons\\UI-Panel-MinimizeButton-Up.PNG',
	}

	tbl[name..'label'] = {
		type = 'description',
		name = SecondsToTime(secs),
		order = 20 + i*3,
		width = 0.6,
	}

	tbl[name..'spacer'] = {
		type = 'description',
		name = '',
		order = 20 + i*3 + 2
	}	
end

local currentIconOptionsTable = {}

function opt:addCustomOptionsToTable(tbl)
	local type = opt:getSelectedIconPara('customType')

	if type == 'Time' then 
		local times = opt:getSelectedIconPara('customTimes')
		for i, v in ipairs(times) do 
			addTimerElement(tbl, i, v, removeCustomTime)
		end -- end of ipairs(times)
	end -- end of type == 'Time'

	if type == 'Phase time' then
		local times = opt:getSelectedIconPara('customPhaseTimes')
		if not times[currentPhaseTimePhase] then return end
		local times = times[currentPhaseTimePhase]

		for i, v in ipairs(times) do 
			addTimerElement(tbl, i, v, removeCustomPhaseTime)
		end -- end of ipairs(times)
	end
end

function opt:deleteSelectedCustomElement()
	-- self is not always opt! because AceConfig stuff
	local self = opt

	local optKey = self.selectedOptionKey

	if not optKey then return end
	local o = self.options[optKey]
	local bossID, id, raidID = o.bossID, o.id, tostring(o.raidID)
	local name, bossKey = o.name, o.bossKey

	local para = EW.para.bosses[bossID]
	if para then 
		for i, v in ipairs(para.__extras) do 
			if v == name then tremove(para.__extras, i) end
		end

		if para[id] then para[id] = nil end

		--need to delete from AceConfig options too
		aceOptions.args.bosses.args[raidID].args[bossKey].args[optKey] = nil

	end
end

opt.customIconOptionsGroup = {
	hidden = iconOptions.hidden,

	hidden2 = {
		order = 1,
		name = 'hidden2',
		type = 'description',
		hidden = function()
			currentIconOptionsTable = CopyTable(customIconOptions)
			opt:addCustomOptionsToTable(currentIconOptionsTable)
			opt.customIconOptionsGroup.custom.args = currentIconOptionsTable
			return true
		end,
	},

	delete = {
		order = 5,
		name = 'Delete',
		type = 'execute',
		func = opt.deleteSelectedCustomElement,
		confirm = true,
		confirmText = "Are you sure you want to delete the selected element?",
	},

	visuals = {
		order = 20,
		name = 'Visuals',
		type = 'group',
		childGroups = 'tab',
		args = CopyTable(iconOptions),
	},

	custom = {
		order = 10,
		name = 'Custom',
		type = 'group',
		childGroups = 'tab',
		args = currentIconOptionsTable,		
	},
}

opt.customIconOptionsGroup.visuals.args.hidden = nil 
opt.customIconOptionsGroup.visuals.args.description = nil 

local nameInput = ''
local bossOptions = {
	hidden = {
		order = 0,
		type  = 'description',
		name = 'hidden',
		hidden = function(tbl)
			opt.selectedOptionKey = nil
			
			local _, bossID = opt:getSelectedRaidBossIDs(tbl)
			opt.selectedBossID = bossID
			if not EW.para.bosses[bossID] then EW.para.bosses[bossID] = {} end

			return true
		end,
	},

	nameInput = {
		order = 1,
		type  = 'input',
		name  = 'Name',
		get   = function() return nameInput end,
		set   = function(tbl, value) nameInput = value end,
	},

	newElement = {
		order = 2,
		type  = 'execute',
		name  = 'New element',
		func  = function(tbl) 
			if nameInput == '' or nameInput:sub(1,2) == '__' then return end
			opt:createNewElement(nameInput)
			nameInput = ''
			opt:updateRaidList()
		end,
	}
}

AceConfig:RegisterOptionsTable('ElWigo',aceOptions)
AceConfigDialog:AddToBlizOptions('ElWigo','ElWigo')

local function idSort(a, b)

	return a.id < b.id
end

function opt:createNewElement(name)
	if not self.selectedBossID then return end
	-- toad NAME HANDLING HERE
	local bossID = opt.selectedBossID
	local bosses = EW.para.bosses

	if not bosses[bossID] then bosses[bossID] = {} end
	local boss = bosses[bossID]

	if not boss.__extras then boss.__extras = {} end
	tinsert(boss.__extras, name)
end

function opt:getSelectedIconPara(paraKey)

	return self:getIconPara(self.selectedOptionKey, paraKey)
end

function opt:getSelectedRaidBossIDs(tbl)
	local raidID = tonumber(tbl[2])
	local name   = tbl[3]
	local bosses = self.raids[raidID].bosses
	for _,v in ipairs(bosses) do 
		if v.name == name then return raidID, v.id end
	end

	return raidID, nil
end

function opt:getIconPara(optKey, paraKey)

	if optKey then
		local o = self.options[optKey]
		local bossID, id = o.bossID, o.id
		local optO = EW.para.bosses[bossID][id]

		if (not optO) then return EW.para.icons.defaults[1][paraKey] end
		if optO[paraKey] == nil then 
			local bar = optO['bar'] or 1
			return EW.para.icons.defaults[bar][paraKey]
		else
			return optO[paraKey]
		end
	
	else
		local bar = self.selectedBar
		if not bar then return end

		return EW.para.icons.defaults[bar][paraKey]
	end
end

function opt:setIconPara(optKey, paraKey, value)

	if optKey then
		local o = self.options[optKey]
		local bossID, id = o.bossID, o.id

		local optO = EW.para.bosses[bossID][id]
		if not optO then 
			EW.para.bosses[bossID][id] = {} 
			optO = EW.para.bosses[bossID][id]
		end
		optO[paraKey] = value

	else
		local bar = self.selectedBar
		if not bar then return end 

		EW.para.icons.defaults[bar][paraKey] = value
	end

end

function opt:setSelectedIconPara(paraKey, value)

	self:setIconPara(self.selectedOptionKey, paraKey, value)
end

function opt:getSelectedBarPara(paraKey)

	return self:getBarPara(self.selectedBar, paraKey)
end

function opt:getBarPara(N, paraKey)
	if not N then return end
	local para = EW.para.bars[N]
	return para[paraKey]
end

function opt:setSelectedBarPara(paraKey, value, refresh)

	return self:setBarPara(self.selectedBar, paraKey, value, refresh)
end

function opt:setBarPara(N, paraKey, value, refresh)
	if not N then return end
	local para = EW.para.bars[N]
	para[paraKey] = value
	if refresh then EW:updateBar(N) end
end

local function concatOptionName(bossName, optionName)
	return ('%s_%s'):format(bossName, optionName)
end

function opt:getBWRaidList()
	local para = EW.para.bosses

	-- NOTE:
	-- This is (largely) taken from the bigwigs source code almost as is 
	-- This is just used to have all the raid bosses that BW does
	if self.raids then wipe(self.raids) end
	local raids                = self.raids or {}
	local loader               = BigWigsLoader
	local zoneToId             = {}
	local alphabeticalZoneList = {}
	local zoneTbl              = loader.zoneTbl

	for k in next, loader:GetZoneMenus() do

		if zoneTbl[k] == 'BigWigs_BattleForAzeroth' 
			or zoneTbl[k] == 'LittleWigs_BattleForAzeroth' then 

			local zone
			if k < 0 then
				local tbl = GetMapInfo(-k)
				if tbl then
					zone = tbl.name
				else
					zone = tostring(k)
				end
			else
				zone = GetRealZoneText(k)
			end

			if zone then
				if zoneToId[zone] then
					zone = zone .. "1" -- When instances exist more than once (Karazhan)
				end
				zoneToId[zone] = k
				alphabeticalZoneList[#alphabeticalZoneList+1] = zone
			end
		end
	end 

	sort(alphabeticalZoneList) -- Make alphabetical
	for i = 1, #alphabeticalZoneList do
		local zoneName = alphabeticalZoneList[i]
		local id = zoneToId[zoneName]
		raids[id] = {name = zoneName, bosses = {}}
	end

	for id, _ in pairs(raids) do 
		loader:LoadZone(id)

		-- Grab the module list from this zone
		local moduleList = loader:GetZoneMenus()[id]
		if type(moduleList) ~= "table" then return end -- No modules registered

		for i = 1, #moduleList do
			local module = moduleList[i]
			if module.engageId then 
				a = {
					id          = module.engageId,
					name        = module.moduleName,
					displayName = module.displayName,
					options     = {},
				}
				para[module.engageId] = para[module.engageId] or {}

				local bossOptions = a['options']
				if module.SetupOptions then module:SetupOptions() end
				for i, option in ipairs(module.toggleOptions) do
					local o = option
					if type(o) == "table" then o = option[1] end
					local optPara = para[module.engageId]
					local dbKey, name, desc, icon, alternativeName = 
						BigWigs:GetBossOptionDetails(module, o)

					-- exclude "custom" options (e.g. markers etc)
					if not (type(dbKey) == "string" and dbKey:find("^custom_")) then
						--optPara[o] = optPara[o] or {}
						local oTbl = {
							id        = o,
							name      = name,
							raidID    = id,
							desc      = desc,
							icon      = icon or 134400,
							altName   = alternativeName,
							dbKey     = dbKey,
							optionKey = concatOptionName(module.moduleName, name),
							bossID    = module.engageId,
						}

						tinsert(bossOptions, oTbl)
						self.options[concatOptionName(module.moduleName, name)] = oTbl
					end
				end

				tinsert(raids[id].bosses, a)
			end -- end of if module.engageId then 
		end

		tsort(raids[id].bosses, idSort)
	end

	self.raids = raids
	return raids
end

function opt:updateRaidList(force)
	local raids  = ((not force) and self.raids) or self:getBWRaidList()
	local tree = aceOptions.args.bosses.args
	wipe(tree)
	local bossesPara = EW.para.bosses

	for raidID, raidInfo in pairs(raids) do 
		idString = tostring(raidID)
		tree[idString] = {
			name        = raidInfo.name,
			type        = 'group',
			childGroups = 'tree',
			args        = {},
		}		

		local bosses = tree[idString].args
		local order  = 0
		if raidInfo.bosses then 
			for _, boss in ipairs(raidInfo.bosses) do 
				order = order + 1
				bosses[boss.name] = {
					name  = boss.displayName,
					order = order,
					type  = 'group',
					args  = CopyTable(bossOptions),
				}
				local id = boss.id

				local args = bosses[boss.name].args
				for _, option in ipairs(boss.options) do
					args[concatOptionName(boss.name, option.name)] = {
						name = option.name,
						icon = option.icon or 134400,
						type = 'group',
						args = iconOptions,
					}
				end -- end of for _, option (boss option)
				
				if bossesPara[id] and bossesPara[id].__extras then
					local extras = bossesPara[id].__extras
					for _, extra in ipairs(extras) do
						local extraKey = concatOptionName(boss.name, extra)
						args[extraKey] = {
							name = extra,
							icon = 134400,
							type = 'group',
							childGroups = 'tab',
							args = opt.customIconOptionsGroup,
						}

						local oTbl = {
							id        = extra,
							name      = extra,
							desc      = 'Custom option',
							icon      = 134400,
							altName   = extra,
							dbKey     = nil,
							optionKey = extraKey,
							bossID    = id,
							raidID    = raidID, -- used for deletion
							bossKey   = boss.name, -- used for deletion
						}				
						self.options[extraKey] = oTbl
					end -- end of extras loop
				end -- end of if bossesPara[id] and bossesPara[id].__extras


			end -- end of for _, boss
		end -- end of if raidInfo.bosses
	end -- end of for raidID, raidInfo
end

function opt:selectCurrentRaidBoss()
	local AceConfigDialog = LibStub("AceConfigDialog-3.0")
	local raids = self.raids

	local id = select(8, GetInstanceInfo()) or 0
	local raid = raids[id]
	if not raid then return end

	local engageID = EW.engageID
	local name
	for _, v in ipairs(raid.bosses) do
		if v.id == engageID then name = v.name end
	end

	if (not engageID) or (not name) then 
		AceConfigDialog:SelectGroup("ElWigo", "bosses", tostring(id))
	else
		AceConfigDialog:SelectGroup("ElWigo", "bosses", tostring(id), name)
	end
end
