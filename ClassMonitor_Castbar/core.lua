local ADDON_NAME, Engine = ...

local ClassMonitor = ClassMonitor
local UI = ClassMonitor.UI

-- TODO:
-- spell icon
-- interrupt shield
-- latency
--[[
local sparkfactory = {
	__index = function(t,k)
		local spark = castBar:CreateTexture(nil, 'OVERLAY')
		t[k] = spark
		spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
		spark:SetVertexColor(unpack(Quartz3.db.profile.sparkcolor))
		spark:SetBlendMode('ADD')
		spark:SetWidth(20)
		spark:SetHeight(db.h*2.2)
		return spark
	end
}
local barticks = setmetatable({}, sparkfactory)

local function setBarTicks(ticknum)
	if( ticknum and ticknum > 0) then
		local delta = ( db.w / ticknum )
		for k = 1,ticknum do
			local t = barticks[k]
			t:ClearAllPoints()
			t:SetPoint("CENTER", castBar, "LEFT", delta * (k-1), 0 )
			t:Show()
		end
		for k = ticknum+1,#barticks do
			barticks[k]:Hide()
		end
	else
		barticks[1].Hide = nil
		for i=1,#barticks do
			barticks[i]:Hide()
		end
	end
end




local function getChannelingTicks(spell)
	if not db.showticks then
		return 0
	end
	
	return channelingTicks[spell] or 0
end


function Player:UNIT_SPELLCAST_START(bar, unit)
	if bar.channeling then
		local spell = UnitChannelInfo(unit)
		bar.channelingTicks = getChannelingTicks(spell)
		setBarTicks(bar.channelingTicks)
	else
		setBarTicks(0)
	end
end

function Player:UNIT_SPELLCAST_STOP(bar, unit)
	setBarTicks(0)
end

function Player:UNIT_SPELLCAST_FAILED(bar, unit)
	setBarTicks(0)
end

function Player:UNIT_SPELLCAST_INTERRUPTED(bar, unit)
	setBarTicks(0)
end

function Player:UNIT_SPELLCAST_DELAYED(bar, unit)

end






Spark
if(self.Spark) then
	self.Spark:SetPoint("CENTER", self, "LEFT", (duration / self.max) * self:GetWidth(), 0)
end
--]]

-- Plugin displaying a simple castbar
local pluginName = "CASTBARPLUGIN"
local CastbarPlugin = ClassMonitor:NewPlugin(pluginName) -- create new plugin entry point in ClassMonitor

-- Return value or default is value is nil
local function DefaultBoolean(value, default)
	if value == nil then
		return default
	else
		return value
	end
end


-- MANDATORY FUNCTIONS
function CastbarPlugin:Initialize()
	--
	self.settings.unit = self.settings.unit or "player"
	self.settings.colors = self.settings.colors or {
		{0.31, 0.45, 0.63, 0.5}, -- normal
		{1, 0, 0, 1}, -- no interrupt
		{0.69, 0.31, 0.31, 0.75}, -- latency
		{1, 1, 1, 1}, -- tick spark
	}
	self.settings.latency = DefaultBoolean(self.settings.latency, true)
	self.settings.showticks = DefaultBoolean(self.settings.showticks, true)
	--
	self:UpdateGraphics()
end

function CastbarPlugin:Enable()
	--
	self:RegisterUnitEvent("UNIT_SPELLCAST_START", self.settings.unit, CastbarPlugin.SpellCastStart)
	self:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", self.settings.unit, CastbarPlugin.SpellCastFailed)
	self:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", self.settings.unit, CastbarPlugin.SpellCastInterrupted)
	self:RegisterUnitEvent("UNIT_SPELLCAST_STOP", self.settings.unit, CastbarPlugin.SpellCastInterruptible)
	self:RegisterUnitEvent("UNIT_SPELLCAST_STOP", self.settings.unit, CastbarPlugin.SpellCastnoInterrupt)
	self:RegisterUnitEvent("UNIT_SPELLCAST_STOP", self.settings.unit, CastbarPlugin.SpellCastDelayed)
	self:RegisterUnitEvent("UNIT_SPELLCAST_STOP", self.settings.unit, CastbarPlugin.SpellCastStop)
	self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", self.settings.unit, CastbarPlugin.SpellCastChannelStart)
	self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", self.settings.unit, CastbarPlugin.SpellCastChannelUpdate) 
	self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", self.settings.unit, CastbarPlugin.SpellCastChannelStop) 
end

function CastbarPlugin:Disable()
	--
	self:UnregisterAllEvents()
	--
	self.bar:Hide()
end

function CastbarPlugin:SettingsModified()
	self:Disable()
	self:UpdateGraphics()
	if self:IsEnabled() then
		self:Enable()
	end
end

-- OWN FUNCTIONS
function CastbarPlugin:UpdateGraphics()
	local bar = self.bar
	if not bar then
		bar = CreateFrame("Frame", self.name, UI.PetBattleHider)
		bar:SetTemplate()
		bar:SetFrameStrata("BACKGROUND")
		bar:Hide()
		self.bar = bar
	end
	bar:ClearAllPoints()
	bar:Point(unpack(self:GetAnchor()))
	bar:Size(self:GetWidth(), self:GetHeight())
	--
	if not bar.status then
		bar.status = CreateFrame("StatusBar", nil, bar)
		bar.status:SetStatusBarTexture(UI.NormTex)
		--bar.status:SetFrameLevel(6)
		--bar.status:Point("TOPLEFT", bar, "TOPLEFT", 2, -2)
		--bar.status:Point("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -2, 2)
		bar.status:SetInside()
	end
	bar.status:SetStatusBarColor(unpack(self.settings.colors[1]))
	bar.status:SetMinMaxValues(0, 1)
	--
	if not bar.spellText then
		bar.spellText = UI.SetFontString(bar.status, 12)
		bar.spellText:Point("LEFT", bar.status)
	end
	bar.spellText:SetText("")
	--
	if not bar.durationText then
		bar.durationText = UI.SetFontString(bar.status, 12)
		bar.durationText:Point("RIGHT", bar.status)
	end
	bar.durationText:SetText("")
	--
	if self.settings.latency == true and not bar.latency then
		bar.latency = bar.status:CreateTexture(nil, "ARTWORK")
		bar.latency:SetTexture(UI.NormTex)
		bar.latency:SetVertexColor(unpack(self.settings.colors[2]))
		bar.latency:Hide()
	end
end

function CastbarPlugin:Update(elapsed)
	-- self.timeSinceLastUpdate = (self.timeSinceLastUpdate or GetTime()) + elapsed
	-- if self.timeSinceLastUpdate > 0.2 then
		-- local timeElapsed = GetTime() - self.startTime
		-- if self.settings.fill == true then
			-- self.bar.status:SetValue(timeElapsed)
		-- else
			-- self.bar.status:SetValue(self.duration - timeElapsed)
		-- end
		-- self.bar.durationText:SetFormattedText("%2.1f / %2.1f", timeElapsed, self.duration)
	-- end
	if self.casting then
		local duration = self.duration + elapsed
		if duration >= self.max then
			self.casting = nil
			self.bar.status:SetValue(0)
			self.bar:Hide()
			self:UnregisterUpdate()
		else
			if self.delay ~= 0 then
				--self.bar.durationText:SetFormattedText("%.1f|cffff0000-%.1f|r", duration, self.delay)
				self.bar.durationText:SetFormattedText("%.1f |cffaf5050+ %.1f|r", self.max - duration, self.delay)
			else
				--self.bar.durationText:SetFormattedText("%.1f", duration)
				self.bar.durationText:SetFormattedText("%.1f / %.1f", self.max - duration, self.max)
			end
			self.duration = duration
			self.bar.status:SetValue(duration)
		end
	elseif self.channeling then
		local duration = self.duration - elapsed
--print("DURATION:"..tostring(duration))
		if duration <= 0 then
			self.channeling = nil
			self.bar.status:SetValue(0)
			self:UpdateTicks(0)
			self.bar:Hide()
			self:UnregisterUpdate()
		else
			if self.delay ~= 0 then
				--self.bar.durationText:SetFormattedText("%.1f|cffff0000-%.1f|r", duration, self.delay)
				self.bar.durationText:SetFormattedText("%.1f |cffaf5050- %.1f|r", duration, self.delay)
			else
				--self.bar.durationText:SetFormattedText("%.1f", duration)
				self.bar.durationText:SetFormattedText("%.1f / %.1f", duration, self.max)
			end
			self.duration = duration
			self.bar.status:SetValue(duration)
		end
	else
		self.casting = nil
		self.channeling = nil
		self.castID = nil

		self:UpdateTicks(0)
		self.bar.status:SetValue(0)
		self.bar:Hide()
		self:UnregisterUpdate()
	end
end

function CastbarPlugin:UpdateLatency(horizontalAnchor)
	if self.settings.latency ~= true then return end

	local latency = self.bar.latency
	latency:ClearAllPoints()
	latency:SetPoint(horizontalAnchor)
	latency:SetPoint("TOP")
	latency:SetPoint("BOTTOM")

	local width = self.bar:GetWidth()
	local _, _, _, ms = GetNetStats()

	-- Guard against GetNetStats returning latencies of 0.
	if ms ~= 0 then
		-- MADNESS!
		local safeZonePercent = (width / self.max) * (ms / 1e5)
		if safeZonePercent > 1 then safeZonePercent = 1 end
		latency:SetWidth(width * safeZonePercent)
		latency:Show()
	else
		latency:Hide()
	end
end

function CastbarPlugin:UpdateSpark(index, width, height, color)
	self.bar.sparks = self.bar.sparks or {}
	local spark = self.bar.sparks[index]
	if not spark then
		spark = self.bar.status:CreateTexture(nil, "OVERLAY")
		spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
		spark:SetBlendMode("ADD")
	end
	spark:SetVertexColor(unpack(color))
	spark:SetWidth(width)
	spark:SetHeight(height)

	self.bar.sparks[index] = spark
	return spark
end

function CastbarPlugin:UpdateTicks(tickCount)
	if self.settings.showticks == true and tickCount and tickCount > 0 then
		local delta = self.bar:GetWidth() / tickCount
		-- don't display first and last tick
		for i = 1, tickCount-1 do
		--for i = 1, tickCount do
			local spark = self:UpdateSpark(i, 10, self.bar:GetHeight(), self.settings.colors[4])
			spark:ClearAllPoints()
			spark:SetPoint("CENTER", self.bar, "LEFT", delta * i, 0 )
			--spark:SetPoint("CENTER", self.bar, "LEFT", delta * (i-1), 0 )
			spark:Show()
		end
		for i = tickCount+1, #self.bar.sparks do
			self.bar.sparks[i]:Hide()
		end
	else
		for i = 1, #self.bar.sparks do
			self.bar.sparks[i]:Hide()
		end
	end
end

function CastbarPlugin:SpellCastStart(_, unit, spell)
	local name, _, text, _, startTime, endTime, _, castID, noInterrupt = UnitCastingInfo(self.settings.unit)
	if not name then
		self.bar:Hide()
		return
	end
--print("SpellCastStop:"..tostring(unit).."  "..tostring(spell).."  "..tostring(castID))

	self.casting = true
	self.castID = castID
	self.noInterrupt = noInterrupt
	self.endTime = endTime / 1e3
	self.startTime = startTime / 1e3
	self.max = self.endTime - self.startTime
	self.duration = GetTime() - self.startTime
	self.delay = 0

	self.bar.spellText:SetText(text)
	self.bar.status:SetMinMaxValues(0, self.max)
	self.bar.status:SetValue(0)
	if noInterrupt then
		self.bar.status:SetStatusBarColor(unpack(self.settings.colors[2]))
	else
		self.bar.status:SetStatusBarColor(unpack(self.settings.colors[1]))
	end
	self:UpdateLatency("RIGHT")

	self.bar:Show()
	self:RegisterUpdate(CastbarPlugin.Update)
end

function CastbarPlugin:SpellCastFailed(_, unit, spell, _, castID)
	if self.castID ~= castID then
		return
	end

	self.casting = nil
	self.noInterrupt = nil

	self.bar.status:SetValue(0)

	self:UnregisterUpdate()
	self.bar:Hide()
end

function CastbarPlugin:SpellCastInterrupted(_, unit, spell, _, castID)
	if self.castID ~= castID then
		return
	end

	self.casting = nil
	self.channeling = nil

	self.bar.status:SetValue(0)

	self:UnregisterUpdate()
	self.bar:Hide()
end

function CastbarPlugin:SpellCastInterruptible(_, unit)
	self.bar.status:SetStatusBarColor(unpack(self.settings.colors[1]))
end

function CastbarPlugin:SpellCastnoInterrupt(_, unit)
	self.bar.status:SetStatusBarColor(unpack(self.settings.colors[2]))
end

function CastbarPlugin:SpellCastDelayed(_, unit, spell, _, castID)
	local name, _, text, texture, startTime, endTime = UnitCastingInfo(unit)
	if not startTime or not self.bar:IsShown() then return end

	local duration = GetTime() - (startTime / 1e3)
	if duration < 0 then duration = 0 end

	self.delay = self.delay + self.duration - duration
	self.duration = duration

	self.bar.status:SetValue(duration)
end

function CastbarPlugin:SpellCastStop(_, unit, spell, _, castID)
--print("SpellCastStop:"..tostring(unit).."  "..tostring(spell).."  "..tostring(castID))
	if self.castID ~= castID then
		return
	end

	self.casting = nil
	self.noInterrupt = nil

	self.bar.status:SetValue(0)

	self:UnregisterUpdate()
	self.bar:Hide()
end

function CastbarPlugin:SpellCastChannelStart(_, unit, spell)
	local name, _, text, _, startTime, endTime, _, noInterrupt = UnitChannelInfo(self.settings.unit)
	if not name then
		self.bar:Hide()
		return
	end

	self.channeling = true
	self.casting = nil -- it's possible for spell casts to never have _STOP executed or be fully completed by the OnUpdate handler before CHANNEL_START is called
	self.castID = nil -- 
	self.noInterrupt = noInterrupt
	self.endTime = endTime / 1e3
	self.startTime = startTime / 1e3
	self.max = self.endTime - self.startTime
	self.duration = self.endTime - GetTime()
	self.delay = 0

	--self.bar.spellText:SetText(name..":"..text)
	self.bar.spellText:SetText(name)
	self.bar.status:SetMinMaxValues(0, self.max)
	self.bar.status:SetValue(self.duration)
	if noInterrupt then
		self.bar.status:SetStatusBarColor(unpack(self.settings.colors[2]))
	else
		self.bar.status:SetStatusBarColor(unpack(self.settings.colors[1]))
	end
	self:UpdateLatency("LEFT")
	-- tick
	local tickCount = Engine.GetChannelingTicks(name)
	self:UpdateTicks(tickCount)

	self.bar:Show()
	self:RegisterUpdate(CastbarPlugin.Update)
end

function CastbarPlugin:SpellCastChannelUpdate(_, unit, spell)
	local name, _, text, _, startTime, endTime, oldStart = UnitChannelInfo(self.settings.unit)
	if not name or not self.bar:IsShown() then
		return
	end

	local duration = (endTime / 1e3) - GetTime()

	self.delay = self.delay + self.duration - duration
	self.duration = duration
	self.max = (endTime - startTime) / 1e3

	self.bar.status:SetMinMaxValues(0, self.max)
	self.bar.status:SetValue(self.duration)
end

function CastbarPlugin:SpellCastChannelStop(_, unit, spell
)
	if not self.bar:IsShown() then return end

	self.channeling = nil
	self.noInterrupt = nil

	self.bar.status:SetValue(self.max)
	self:UpdateTicks(0)

	self:UnregisterUpdate()
	self.bar:Hide()
end