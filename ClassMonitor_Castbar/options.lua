local pluginName = "CASTBARPLUGIN"

-- OPTION DEFINITION
local ClassMonitor_ConfigUI = ClassMonitor_ConfigUI
if ClassMonitor_ConfigUI then
--print("CREATE CastbarPlugin DEFINITION")
	local Helpers = ClassMonitor_ConfigUI.Helpers

	local colors = Helpers.CreateColorsDefinition("colors", 4, {"Color", "NoInterrupt", "Latency", "Tick"})
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
		[9] = {
			key = "showticks", -- use self.settings.showticks to access this option
			name = "Show ticks", -- TODO: locales
			desc = "Show channeled ticks", -- TODO: locales
			type = "toggle", -- Ace3 config type
			get = Helpers.GetValue, -- simple get value
			set = Helpers.SetValue, -- simple set value
			disabled = Helpers.IsPluginDisabled, -- disabled if plugin is disabled
		},
		[10] = colors,
		[11] = Helpers.Anchor,
		[12] = Helpers.AutoGridAnchor,
	}
	local short = "Cast bar"
	local long = "Display a cast bar"
	ClassMonitor_ConfigUI:NewPluginDefinition(pluginName, options, short, long) -- add plugin definition in ClassMonitor_ConfigUI
end