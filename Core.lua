EnhancedTooltipsAddon =
    LibStub("AceAddon-3.0"):NewAddon("EnhancedTooltips", "AceConsole-3.0")

local ET = EnhancedTooltipsAddon
local AceGUI = LibStub("AceGUI-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local defaults = {
    profile = {modifierOnly = false, modifier = "shift"} -- end of profile
}

function ET:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("EnhancedTooltipsDB", defaults, true)
    self.para = self.db.profile

    local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

    -- AceConfigDialog:SetDefaultSize("EnhancedTooltips", 1200, 700)
end

function ET:OnEnable()
    --
end

function ET:OnDisable()
    --
end

function ET:RefreshConfig()
    -- ReloadUI()
    self.para = self.db.profile

    -- self.options:updateRaidListAll()
end

function ET:chatCommandHandler(msg)
    AceConfigDialog:Open("EnhancedTooltips")
end
ET:RegisterChatCommand("enhancedtooltips", "chatCommandHandler")

ET.eventFrame = CreateFrame("Frame", "EnhancedTooltipsEventFrame", UIParent)
ET.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
ET.eventFrame:SetScript(
    "OnEvent",
    function(self, event, ...)
        ET:initialiseHooks()
    end
)

function ET:stringDuration(s, cap)
    local n = s:match("%d+%.?%d*")
    if not n then
        return "?"
    end
    s = s:lower()

    n = tonumber(n)

    if s:match("sec") or s:match("second") or s:match("seconds") then
        if n <= 10 then
            return cap and "Very Short" or "very short"
        else
            return cap and "Short" or "short"
        end
    elseif s:match("min") or s:match("minutes") then
        if n <= 4 then
            return cap and "Medium" or "medium"
        elseif n <= 10 then
            return cap and "Longish" or "longish"
        else
            return cap and "Long" or "long"
        end
    else
        return cap and "Very Long" or "very long"
    end
end

local magicSchools = {
    "Physical",
    "Arcane",
    "Fire",
    "Frost",
    "Nature",
    "Shadow",
    "Holy",
    "Astral",
    "Chaos",
    "Elemental",
    "Firestorm",
    "Flamestrike",
    "Plague",
    "Radiant",
    "Shadowflame",
    "Shadowstrike",
    "Spellfrost",
    "Spellstrike",
    "Twilight",
    "Frostfire",
    "Shadowfrost"
}

function ET:purifyText(s)
    if not s then
        return ""
    end

    -- if true then
    --     return s
    -- end

    -- get rid of those pesky numbers on stats
    s = s:gsub("%+%d*(.*)", "+%1")

    -- see if it contains an unnecessary CD indication
    local cd = s:match("(%d+%.?%d* %D*) [cC]ooldown")
    if cd then
        local dur = ET:stringDuration(cd, s:match("Cooldown"))
        s = s:gsub("%d+%.?%d* %D* ([cC]ooldown)", dur .. " %1")
    end

    local cd = s:match("(%d+%.?%d* %D*) [rR]echarge")
    if cd then
        local dur = ET:stringDuration(cd, s:match("Recharge"))
        s = s:gsub("%d+%.?%d* %D* ([rR]echarge)", dur .. " %1")
    end

    -- number of enemies is irrelevant
    s = s:gsub("up to %d+ (%S-%s?)allies", "some %1allies")
    s = s:gsub("up to %d+ (%S-%s?)enemies", "some %1enemies")
    s = s:gsub("up to %d+ (%S-%s?)targets", "some %1targets")
    s = s:gsub("%d+ (%S-%s?)allies", "some %1allies")
    s = s:gsub("%d+ (%S-%s?)enemies", "some %1enemies")
    s = s:gsub("%d+ (%S-%s?)targets", "some %1targets")

    -- for +duration is just unnecessary
    s = s:gsub("([fF]or) %d+ sec", "%1 a bit")
    s = s:gsub("([fF]or) %d+ min", "%1 a while")
    s = s:gsub("([fF]or) %d+ hours?", "%1 a long time")
    s = s:gsub("([fF]or) that amount%s?", "") -- cleaning up

    -- get rid of cast stuff
    s = s:gsub("%d+%.?%d- sec ([cC])ast", "Cast")
    s = s:gsub("%d+%.?%d* min ([cC])ast", "Cast")

    --mana/health & other dumb resources
    s = s:gsub("%d+,?%d* Mana(%s?)", "Some Mana%1")
    s = s:gsub("%d+,?%d* mana(%s?)", "some mana%1")
    s = s:gsub("%d+,?%d* Health(%s?)", "Some Health%1")
    s = s:gsub("%d+,?%d* health(%s?)", "some health%1")
    s = s:gsub("%d+ to %d+ Combo Points%s?", "Some Combo Points")
    s = s:gsub("%d+ Combo Points%s?", "Some Combo Points")
    s = s:gsub("%d+ Energy%s?", "Some Energy")
    s = s:gsub("%d+ Rage%s?", "Some Rage")
    s = s:gsub("%d+ Focus%s?", "Some Focus")
    s = s:gsub("%d+ Runic Power%s?", "Some Runic Power")
    s = s:gsub("%d+ Chi%s?", "Some Chi")
    s = s:gsub("%d+ Insanity%s?", "Some Insanity")
    s = s:gsub("%d+ Astral Power%s?", "Some Astral Power")
    s = s:gsub("%d+ Soul Shards?%s?", "Some Soul Shards")
    s = s:gsub("%d+ Maelstrom%s?", "Some Maelstrom")

    -- stats
    s = s:gsub("%d+ primary stat", "primary stats")
    s = s:gsub("%d+ Agility", "Agility")
    s = s:gsub("%d+ Intellect", "Intellect")
    s = s:gsub("%d+ Strength", "Strength")
    s = s:gsub("%d+ Critical Strike", "Critical Strike")
    s = s:gsub("%d+ Versatility", "Versatility")
    s = s:gsub("%d+ Haste", "Haste")

    -- get rid of nerdy damage schools
    if s:match("damage") then
        for _, school in ipairs(magicSchools) do
            s = s:gsub(school .. " damage", "damage")
        end
    end

    -- need to get rid of % of damage/healing things first or itll not work well
    s = s:gsub("%d%% of the damage", "a fraction of the damage")
    s = s:gsub("%d%% of the healing", "a fraction of the healing")

    -- damage/healing numbers are just unnecessary
    s = s:gsub("([Dd]amages? .-)for %d+,?%d*,?%d*%s?", "%1")
    s = s:gsub("([Hh]eals? .-)for %d+,?%d*,?%d*%s?", "%1")
    s = s:gsub("([Dd]amaging .-)for %d+,?%d*,?%d*%s?", "%1")
    s = s:gsub("([Hh]ealing .-)for %d+,?%d*,?%d*%s?", "%1")
    s = s:gsub("(until%D*)%d+,?%d*,?%d* total damage", "%1enough damage")
    s = s:gsub("(until%D*)%d+,?%d*,?%d* total healing", "%1enough healing")
    s = s:gsub("%d+,?%d*,?%d* damage", "damage")
    s = s:gsub("%d+,?%d*,?%d* heal", "heal")

    -- stupid durations
    s = s:gsub("([eE]very) %d+.?%d* sec", "%1 now and then")
    s = s:gsub("over %d+.?%d* sec", "over time")
    s = s:gsub("next %d.*%d* sec", "a while")
    s = s:gsub("([Ll]asts?) %d+ sec", "%1 a while")
    s = s:gsub("for %d.*%d* sec", "for a while")
    s = s:gsub("for up to %d.*%d* sec", "for a while")
    s = s:gsub("by %d.*%d* sec", "by a bit")

    -- range
    s = s:gsub("within %d+ yds?", "in range")
    range = s:match("(%d+) yd")
    if range then
        s = s:gsub("%d+ yd", (tonumber(range) >= 30 and "long" or "short"))
    end

    s = s:gsub("within %d+ yards?", "in range")
    range = s:match("(%d+) yards?")
    if range then
        s = s:gsub("%d+ yards?", (tonumber(range) >= 30 and "long" or "short"))
    end

    -- by followed by a number is never a good sign
    s = s:gsub("by %d+%%?%s?", "")

    -- random things nobody needs to see
    s = s:gsub("instantly%s?", "")
    s = s:gsub("%d.?%d*%% of your maximum mana", "some mana")
    s = s:gsub("%d.?%d*%% of your maximum health", "some health")
    s = s:gsub("%d.?%d*%% of", "a portion of")
    s = s:gsub("an additional %d+%%", "an additional amount")
    s = s:gsub("up to %d+%%", "some")
    s = s:gsub("%d+%%", "some")
    s = s:gsub("Max %d+ Charges", "Has Charges")

    return s
end

function ET.tooltipUpdate(gt)
    local ET = ET

    if ET.para.modifierOnly then
        if
            (ET.para.modifier == "ctrl" and not IsControlKeyDown()) or
                (ET.para.modifier == "shift" and not IsShiftKeyDown()) or
                (ET.para.modifier == "alt" and not IsAltKeyDown())
         then
            return
        end
    end

    local n = select("#", gt:GetRegions())
    local s = ""
    for i = 1, n do
        local reg = select(i, gt:GetRegions())
        if reg.GetText then
            local s = ET:purifyText(reg:GetText())
            if s then
                reg:SetText(s)
            end
        end
    end
end

function ET:initialiseHooks()
    local gt = GameTooltip
    if gt.EnhancedTooltipsHooked then
        return
    end

    gt:HookScript("OnTooltipSetSpell", self.tooltipUpdate)
    gt:HookScript("OnTooltipSetItem", self.tooltipUpdate)
end

local options = {
    type = "group",
    args = {
        modifierOnly = {
            type = "toggle",
            name = "Only with modifier",
            order = 2,
            get = function()
                return ET.para.modifierOnly
            end,
            set = function(tbl, value)
                ET.para.modifierOnly = value
            end
        },
        modifier = {
            type = "select",
            name = "Modifier",
            order = 3,
            values = {alt = "alt", ctrl = "ctrl", shift = "shift"},
            disabled = function()
                return not ET.para.modifierOnly
            end,
            get = function()
                return ET.para.modifier
            end,
            set = function(tbl, value)
                ET.para.modifier = value
            end
        }
    }
}

AceConfig:RegisterOptionsTable("EnhancedTooltips", options)
