local tremove = table.remove

local EW = ElWigoAddon
EW.utils = {}
local ut = EW.utils

local ssub = string.sub
function ut.stringStrip(s)
    if not s then
        return ""
    end

    local num = s:match("%((%d+)%)")

    local s = s:gsub("(%(%d+%))", "")

    return s, tonumber(num or -1)
end

function ut.acronym(s)
    if not s then
        return ""
    end
    --
    local sNew =
        s:gsub("<", ""):gsub(">", ""):gsub("%)", " %)"):gsub("%(", "%( "):gsub(
        "(%w)%S*%s*",
        "%1"
    ):upper()
    return sNew
end

function ut.removeBracketsNumber(s)
    if not s then
        return ""
    end
    local sNew = s:gsub("(%(%d+%))", "")

    return sNew
end

function ut.getNumberAfterUnderscore(s)
    if not s then
        return nil
    end
    local N = s:match(".*_(%d+)$")
    if N then
        return tonumber(N)
    else
        return nil
    end
end

function ut.getNumberAfterSpace(s)
    if not s then
        return nil
    end
    local N = s:match(".*%s(%d+)$")
    if N then
        return tonumber(N)
    else
        return nil
    end
end

ut.dirToAnchors = {
    ABOVE = {"TOP", "BOTTOM"},
    BELOW = {"BOTTOM", "TOP"},
    LEFT = {"LEFT", "RIGHT"},
    RIGHT = {"RIGHT", "LEFT"},
    CENTER = {"CENTER", "CENTER"}
}

ut.dirToAnchorValues = {
    ABOVE = "Above",
    BELOW = "Below",
    LEFT = "Left",
    RIGHT = "Right",
    CENTER = "Center"
}

function ut.isInTable(tbl, v)
    for i = 1, #tbl do
        if tbl[i] == v then
            return true
        end
    end
    return false
end
local isInTable = ut.isInTable

function ut.includeInTable(tbl, v)
    if not isInTable(tbl, v) then
        tbl[#tbl + 1] = v
    end
end

function ut.removeFromTable(tbl, v)
    for i = 1, #tbl do
        if tbl[i] == v then
            tremove(tbl, i)
            return
        end
    end
end

function ut.isWANameEW(name)
    local match = name:match("^EW(%d)__.*")
    return match and tonumber(match) or nil
end

function ut.toggleMovable(frame, func)
    if frame._currentlyMovable then
        ut.setNotMovable(frame)
    else
        ut.setMovable(frame, func)
    end
end

function ut.setMovable(frame, func)
    frame._movableFrame = CreateFrame("Frame", nil, frame)
    frame._currentlyMovable = true
    frame:SetMovable(true)
    local f = frame._movableFrame

    f.texture = f:CreateTexture(nil, "OVERLAY")
    f.texture:SetAllPoints()
    f.texture:SetColorTexture(0, 0.8, 0, 0.5)

    f:SetAllPoints()
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript(
        "OnDragStart",
        function(...)
            frame:StartMoving()
        end
    )
    f:SetScript(
        "OnDragStop",
        function(...)
            frame:StopMovingOrSizing()
            local left, bottom = frame:GetLeft(), frame:GetBottom()
            func(left, bottom)
        end
    )
end

function ut.setNotMovable(frame)
    frame._currentlyMovable = false
    frame._movableFrame:Hide()
    frame._movableFrame = nil
    frame:SetMovable(false)
end
