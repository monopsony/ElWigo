local EW = ElWigoAddon
EW.utils = {}
local ut = EW.utils
	
local ssub = string.sub
function ut.stringStrip(s)
	if not s then return '' end

	local num = s:match("%((%d+)%)")

	local s = s:gsub("(%(%d+%))", "")

	return s, tonumber(num or -1)
end

function ut.acronym(s)
	if not s then return '' end
	local sNew = s
		:gsub(" of ","")
		:gsub(" for ","")
		:gsub(" and ","")
		:gsub(" the ","")
		:gsub(" to ","")
		:gsub("(%w)%S*%s*","%1")
		:upper()

	return sNew
end

function ut.removeBracketsNumber(s)
	if not s then return '' end
	local sNew = s:gsub("(%(%d+%))","")

	return sNew
end

function ut.getNumberAfterUnderscore(s)
	if not s then return nil end
	local N = s:match(".*_(%d+)$")
	if N then return tonumber(N) else return nil end
end

function ut.getNumberAfterSpace(s)
	if not s then return nil end
	local N = s:match(".*%s(%d+)$")
	if N then return tonumber(N) else return nil end
end

ut.dirToAnchors = {
	ABOVE  = {"TOP", "BOTTOM"},
	BELOW  = {"BOTTOM", "TOP"},
	LEFT   = {"LEFT", "RIGHT"},
	RIGHT  = {"RIGHT", "LEFT"},
	CENTER = {"CENTER", "CENTER"}
}

ut.dirToAnchorValues = {
	ABOVE  = "Above",
	BELOW  = "Below",
	LEFT   = "Left",
	RIGHT  = "Right",
	CENTER = "Center",
}

