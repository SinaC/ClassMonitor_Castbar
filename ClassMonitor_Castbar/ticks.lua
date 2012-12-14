local ADDON_NAME, Engine = ...

local channelingTicks = {
	-- Warlock
	[GetSpellInfo(1120)] = 6, -- Drain Soul
	[GetSpellInfo(689)] = 6, -- Drain Life
	[GetSpellInfo(103103)] = 4, -- Malefic Grasp
	[GetSpellInfo(108371)] = 6, -- Harvest Life
	-- Druid
	[GetSpellInfo(740)] = 4, -- Tranquility
	[GetSpellInfo(16914)] = 10, -- Hurricane
	[GetSpellInfo(106996)] = 10, -- Astral Storm
	-- Priest
	[GetSpellInfo(15407)] = 3, -- Mind Flay
	[GetSpellInfo(48045)] = 5, -- Mind Sear
	[GetSpellInfo(47540)] = 2, -- Penance
	-- Mage
	[GetSpellInfo(5143)] = 5, -- Arcane Missiles
	[GetSpellInfo(10)] = 8, -- Blizzard
	[GetSpellInfo(12051)] = 3, -- Evocation
}

Engine.GetChannelingTicks = function(spellName)
	return channelingTicks[spellName] or 0
end