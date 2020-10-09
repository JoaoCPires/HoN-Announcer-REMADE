local WORLD_WG = "Wintergrasp"
local BG_AB = "Arathi Basin"
local BG_WG = "Warsong Gulch"
local BG_WGA = "Silverwing Hold"
local BG_WGH = "Warsong Lumber Mill"
local BG_EOTS = "Eye of the Storm"
local BG_AV = "Alterac Valley"
local BG_IOC = "Isle of Conquest"
local BG_SOTA = "Strand of the Ancients"
local ARENA_LORD = "Ruins of Lordaeron"
local ARENA_NAGRAND = "Nagrand Arena"
local ARENA_BEM = "Blade's Edge Arena"
local ARENA_DAL = "Dalaran Arena"
local ARENA_ROV = "Ring of Valor"

local BUFF_BERSERKING = GetSpellInfo(23505)
local hasBerserking 

local BUFF_RESTORATION = GetSpellInfo(23493)
local hasRegeneration

local killResetTime = 5
local killStreak = 0
local multiKill = 0
local killTime = 0
local soundUpdate = 0
local nextSound
local bit_band = bit.band
local bit_bor = bit.bor

local spreeSounds = {
	[1] = "1_kills",
	[2] = "2_kills",
	[3] = "3_kills",
	[4] = "4_kills",
	[5] = "5_kills",
	[6] = "6_kills",
	[7] = "7_kills",
	[8] = "8_kills",
	[9] = "9_kills",
	[10] = "10_kills",
	[11] = "11_kills"
}
local multiSounds = {
	[2] = "double_kill",
	[3] = "triple_kill",
	[4] = "quad_kill",
}

local function hasFlag(flags, flag)
	return bit_band(flags, flag) == flag
end
local onEvent = function(self, event, ...)
	self[event](self, event, ...)
	local name, rank, icon, count, dispelType, duration, expires, caster, isStealable = UnitBuff("player", BUFF_BERSERKING)
	if name == BUFF_BERSERKING then
		if duration == 60 then
			if hasBerserking then
				--Stops repeat
			else
				PlaySoundFile("Interface\\AddOns\\HoNAnnouncer-Remade\\sounds\\powerup_doubledamage.ogg")
				hasBerserking = true
			end
		else
			if hasBerserking then
				hasBerserking = false
			else
				--Blank
			end
		end
	end
	if UnitBuff("player", BUFF_RESTORATION) then
		if hasRegeneration then
			--Stops repeat
		else
			PlaySoundFile("Interface\\AddOns\\HoNAnnouncer-Remade\\sounds\\powerup_regeneration.ogg")
			hasRegeneration = true
		end
	else
		if hasRegeneration then
			hasRegeneration = false
		else
			--Blank
		end
	end
end

local onUpdate = function(self, elapsed)
	soundUpdate = soundUpdate + elapsed
	if soundUpdate > 2 then
		soundUpdate = 0
		if nextSound then
			PlaySoundFile(nextSound)
			nextSound = nil
		end
	end
end

HoNAnnouncer = CreateFrame("Frame")
HoNAnnouncer:SetScript("OnEvent", onEvent)
HoNAnnouncer:SetScript("OnUpdate", onUpdate)
HoNAnnouncer:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
HoNAnnouncer:RegisterEvent("ZONE_CHANGED_NEW_AREA")
HoNAnnouncer:RegisterEvent("PLAYER_DEAD")
		
function HoNAnnouncer:PLAYER_DEAD()
	killStreak = 0
	PlaySoundFile("Interface\\AddOns\\HoNAnnouncer-Remade\\sounds\\defeat.ogg")
end

function HoNAnnouncer:ZONE_CHANGED_NEW_AREA()
	local zoneText = GetZoneText();
	if (zoneText == WORLD_WG or zoneText == BG_AB or zoneText == BG_WG or zoneText == BG_WGA or zoneText == BG_WGH or zoneText == BG_EOTS or zoneText == BG_AV or zoneText == BG_IOC or zoneText == BG_SOTA or zoneText == ARENA_LORD or zoneText == ARENA_NAGRAND or zoneText == ARENA_BEM or zoneText == ARENA_DAL or zoneText == ARENA_ROV) then
		PlaySoundFile("Interface\\AddOns\\HoNAnnouncer-Remade\\sounds\\startgame.ogg")
	end
	killStreak = 0
end

function HoNAnnouncer:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, spellSchool, auraType, ...)
	if eventType == "PARTY_KILL" and hasFlag(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) and hasFlag(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) then
		local now = GetTime()
		if killTime + killResetTime > now then
			multiKill = multiKill + 1
		else
			multiKill = 1
		end
		if (UnitHealth("player") / UnitHealthMax("player") * 100 <= 5) and (UnitHealth("player") > 1) then
			PlaySoundFile("Interface\\AddOns\\HoNAnnouncer-Remade\\sounds\\smackdown.ogg")
		end
		killTime = now
		killStreak = killStreak + 1
		self:PlaySounds()
	end
	if eventType == "SPELL_CAST_SUCCESS" and hasFlag(sourceFlags, COMBATLOG_OBJECT_TARGET) and hasFlag(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) and spellName == "Divine Shield" then
		PlaySoundFile("Interface\\AddOns\\HoNAnnouncer-Remade\\sounds\\rage_quit.ogg")
	end
	if eventType == "SPELL_AURA_APPLIED" and hasFlag(destFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) and spellId == 23451 then
		PlaySoundFile("Interface\\AddOns\\HoNAnnouncer-Remade\\sounds\\powerup_haste.ogg")
	end
end

function HoNAnnouncer:PlaySounds()
	local path = "Interface\\AddOns\\HoNAnnouncer-Remade\\sounds\\%s.ogg"
	local multiKillLocation = multiSounds[math.min(4, multiKill)]
	local killSpreeLocation = spreeSounds[math.min(11, killStreak)]
	if multiKillLocation then
		PlaySoundFile(string.format(path, multiKillLocation))
	end
	if killSpreeLocation then
		local killSpreePath = string.format(path, killSpreeLocation)

		if not multiKillLocation then
			PlaySoundFile(killSpreePath)
		else
			nextSound = killSpreePath
		end
	end
end