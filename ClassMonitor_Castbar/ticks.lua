local ADDON_NAME, Engine = ...

local channelingTicks = {
	-- warlock
	[GetSpellInfo(1120)] = 6, -- drain soul
	[GetSpellInfo(689)] = 6, -- drain life
	[GetSpellInfo(103103)] = 4, -- malefic grasp
	[GetSpellInfo(108371)] = 6, -- harvest life
	-- druid
	[GetSpellInfo(740)] = 4, -- Tranquility
	[GetSpellInfo(16914)] = 10, -- Hurricane
	[GetSpellInfo(106996)] = 10, -- Astral Storm
	-- priest
	[GetSpellInfo(15407)] = 3, -- mind flay
	[GetSpellInfo(48045)] = 5, -- mind sear
	[GetSpellInfo(47540)] = 2, -- penance
	-- mage
	[GetSpellInfo(5143)] = 5, -- arcane missiles
	[GetSpellInfo(10)] = 8, -- blizzard
	[GetSpellInfo(12051)] = 3, -- evocation
}

Engine.GetChannelingTicks = function(spellName)
	return channelingTicks[spellName] or 0
end