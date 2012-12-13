local ADDON_NAME, Engine = ...
local ADDON_NAME, Engine = ...

local ClassMonitor = ClassMonitor
local UI = ClassMonitor.UI

-- TODO:
-- spell icon
-- interrupt shield
-- latency
--[[
if C["unitframes"].cbicons == true then
				castbar.button = CreateFrame("Frame", nil, castbar)
				castbar.button:Size(26)
				castbar.button:SetTemplate("Default")
				castbar.button:CreateShadow("Default")

				castbar.icon = castbar.button:CreateTexture(nil, "ARTWORK")
				castbar.icon:Point("TOPLEFT", castbar.button, 2, -2)
				castbar.icon:Point("BOTTOMRIGHT", castbar.button, -2, 2)
				castbar.icon:SetTexCoord(0.08, 0.92, 0.08, .92)
			
				if unit == "player" then
					if C["unitframes"].charportrait == true then
						castbar.button:SetPoint("LEFT", -82.5, 26.5)
					else
						castbar.button:SetPoint("LEFT", -46.5, 26.5)
					end
				elseif unit == "target" then
					if C["unitframes"].charportrait == true then
						castbar.button:SetPoint("RIGHT", 82.5, 26.5)
					else
						castbar.button:SetPoint("RIGHT", 46.5, 26.5)
					end					
				end
			end
			
			-- cast bar latency on player
			if unit == "player" and C["unitframes"].cblatency == true then
				castbar.safezone = castbar:CreateTexture(nil, "ARTWORK")
				castbar.safezone:SetTexture(normTex)
				castbar.safezone:SetVertexColor(0.69, 0.31, 0.31, 0.75)
				castbar.SafeZone = c
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
	}
	self.settings.latency = DefaultBoolean(self.settings.latency, true)
	--
	self:UpdateGraphics()
end

function CastbarPlugin:Enable()
	--
	self:RegisterUnitEvent("UNIT_SPELLCAST_START", self.settings.unit, CastbarPlugin.SpellCastStart)
	self:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", self.settings.unit, CastbarPlugin.SpellCastFailed)
	self:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", self.settings.unit, CastbarPlugin.SpellCastInterrupted)
	self:RegisterUnitEvent("UNIT_SPELLCAST_STOP", self.settings.unit, CastbarPlugin.SpellCastInterruptible)
	self:RegisterUnitEvent("UNIT_SPELLCAST_STOP", self.settings.unit, CastbarPlugin.SpellCastNotInterruptible)
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
		bar.status:SetFrameLevel(6)
		bar.status:Point("TOPLEFT", bar, "TOPLEFT", 2, -2)
		bar.status:Point("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -2, 2)
	end
	bar.status:SetStatusBarColor(unpack(self.settings.colors[0]))
	bar.status:SetMinMaxValues(0, 1)
	--
	if not bar.spellText then
		bar.spellText = UI.SetFontString(bar.status, 12)
		bar.spellText:Point("CENTER", bar.status)
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
		bar.latency = castbar:CreateTexture(nil, "ARTWORK")
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
			self.bar:Hide()
			self:UnregisterUpdate()
		else
			if self.delay ~= 0 then
				self.bar.durationText:SetFormattedText("%.1f|cffff0000-%.1f|r", duration, self.delay)
			else
				self.bar.durationText:SetFormattedText("%.1f", duration)
			end
			self.duration = duration
			self.bar:SetValue(duration)
		end
	elseif self.channeling then
		local duration = self.duration - elapsed
		if duration <= 0 then
			self.channeling = nil
			self.bar:Hide()
			self:UnregisterUpdate()
		else
			if self.delay ~= 0 then
				self.bar.durationText:SetFormattedText("%.1f|cffff0000-%.1f|r", duration, self.delay)
			else
				self.bar.durationText:SetFormattedText("%.1f", duration)
			end
			self.duration = duration
			self.bar:SetValue(duration)
		end
	else
		self.casting = nil
		self.channeling = nil
		self.castID = nil

		self.bar:SetValue(0)
		self.bar:Hide()
		self:UnregisterUpdate()
	end
end

function CastbarPlugin:UpdateLatency(horizontalAnchor)
	if self.settings.latency ~= true then return end

	local latency = self.latency
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

function CastbarPlugin:SpellCastStart(_, unit, spell, _, lineID, spellID)
	local name, _, text, _, startTime, endTime, _, castID, notInterruptible = UnitCastingInfo(self.settings.unit)
	if not name then
		self.bar:Hide()
		return
	end

	self.casting = true
	self.castID = castID
	self.interrupt = notInterruptible
	self.endTime = endTime / 1e3
	self.startTime = startTime / 1e3
	self.max = self.endTime - self.startTime
	self.duration = GetTime() - self.startTime
	self.delay = 0

	self.bar.text:SetText(text)
	self.bar.status:SetMinMaxValues(0, self.max)
	self.bar.status:SetValue(0)
	if notInterruptible then
		self.bar.status:SetStatusBarColor(unpack(self.settings.colors[1]))
	else
		self.bar.status:SetStatusBarColor(unpack(self.settings.colors[0]))
	end
	self:UpdateLatency("RIGHT")

	self.bar:Show()
	self:RegisterUpdate(CastbarPlugin.Update)
end

function CastbarPlugin:SpellCastFailed(_, unit, spell, _, lineID, castID)
	if self.castID ~= castID then
		return
	end

	self.casting = nil
	self.interrupt = nil

	self.bar.SetValue(0)

	self:UnregisterUpdate()
	self.bar:Hide()
end

function CastbarPlugin:SpellCastInterrupted(_, unit, spell, _, lineID, castID)
	if self.castID ~= castID then
		return
	end

	self.casting = nil
	self.channeling = nil

	self.bar.SetValue(0)

	self:UnregisterUpdate()
	self.bar:Hide()
end

function CastbarPlugin:SpellCastInterruptible(_, unit)
	self.bar.status:SetStatusBarColor(unpack(self.settings.colors[0]))
end

function CastbarPlugin:SpellCastNotInterruptible(_, unit)
	self.bar.status:SetStatusBarColor(unpack(self.settings.colors[1])
end

function CastbarPlugin:SpellCastDelayed(_, unit, spellName, _, castID)
	local name, _, text, texture, startTime, endTime = UnitCastingInfo(unit)
	if not startTime or not self.bar:IsShown() then return end

	local duration = GetTime() - (startTime / 1e3)
	if(duration < 0) then duration = 0 end

	self.delay = self.delay + self.duration - duration
	self.duration = duration

	self.bar:SetValue(duration)
end

function CastbarPlugin:SpellCastStop(_, unit, spell, _, lineID, spellID)
	if self.castID ~= castID then
		return
	end

	self.casting = nil
	self.interrupt = nil

	self.bar.SetValue(0)

	self:UnregisterUpdate()
	self.bar:Hide()
end

function CastbarPlugin:SpellCastChannelStart(_, unit, spell, _, lineID, spellID)
	local name, _, text, _, startTime, endTime, _, notInterruptible = UnitChannelInfo(self.settings.unit)
	if not name then
		self.bar:Hide()
		return
	end

	self.channeling = true
	self.casting = nil -- it's possible for spell casts to never have _STOP executed or be fully completed by the OnUpdate handler before CHANNEL_START is called
	self.castID = nil -- 
	self.interrupt = notInterruptible
	self.endTime = endTime / 1e3
	self.startTime = startTime / 1e3
	self.max = self.endTime - self.startTime
	self.duration = GetTime() - self.startTime
	self.delay = 0

	self.bar.text:SetText(name..":"..text)
	self.bar.status:SetMinMaxValues(0, self.max)
	self.bar.status:SetValue(duration)
	if notInterruptible then
		self.bar.status:SetStatusBarColor(unpack(self.settings.colors[1]))
	else
		self.bar.status:SetStatusBarColor(unpack(self.settings.colors[0]))
	end
	self:UpdateLatency("LEFT")

	self.bar:Show()
	self:RegisterUpdate(CastbarPlugin.Update)
end

function CastbarPlugin:SpellCastChannelUpdate(_, unit, spell, _, lineID, spellID)
	local name, _, text, _, startTime, endTime, oldStart = UnitChannelInfo(self.settings.unit)
	if not name or not self.bar:IsShown() then
		return
	end

	local duration = (endTime / 1e3) - GetTime()

	self.delay = self.delay + self.duration - duration
	self.duration = duration
	self.max = (endTime - startTime) / 1e3

	self.bar:SetMinMaxValues(0, self.max)
	self.bar:SetValue(self.duration)
end

function CastbarPlugin:SpellCastChannelStop(_, unit, spell, _, lineID, spellID)
	if not self.bar:IsShown() then return end

	self.channeling = nil
	self.interrupt = nil

	self.bar:SetValue(self.max)

	self:UnregisterUpdate()
	self.bar:Hide()
end

-- OPTION DEFINITION
local ClassMonitor_ConfigUI = ClassMonitor_ConfigUI
if ClassMonitor_ConfigUI then
--print("CREATE CastbarPlugin DEFINITION")
	local Helpers = ClassMonitor_ConfigUI.Helpers

	local colors = Helpers.CreateColorsDefinition("colors", 3, {"Color", "NoInterrupt", "Latency"})
	local options = {
		[1] = Helpers.Description,
		[2] = Helpers.Name,
		[3] = Helpers.DisplayName,
		[4] = Helpers.Kind,
		[5] = Helpers.Enabled,
		[6] = Helpers.WidthAndHeight,
		[7] = Helpers.Unit,
		[8] = {
			key = "latency", -- use self.settings.latency to access this option
			name = "Latency", -- TODO: locales
			desc = "Show latency", -- TODO: locales
			type = "toggle", -- Ace3 config type
			get = Helpers.GetValue, -- simple get value
			set = Helpers.SetValue, -- simple set value
			disabled = Helpers.IsPluginDisabled, -- disabled if plugin is disabled
		},
		[9] = colors,
		[10] = Helpers.Anchor,
		[11] = Helpers.AutoGridAnchor,
	}
	local short = "Cast bar"
	local long = "Display a cast bar"
	ClassMonitor_ConfigUI:NewPluginDefinition(pluginName, options, short, long) -- add plugin definition in ClassMonitor_ConfigUI
end