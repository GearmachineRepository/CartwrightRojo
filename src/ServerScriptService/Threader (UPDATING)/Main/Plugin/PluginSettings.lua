--!strict
local PluginSettings = {}

local DEFAULT_SETTINGS = {
	Theme = "Dark",
	AutoSave = true,
	AutoSaveInterval = 300,
	ShowGrid = true,
	GridSize = 20,
	SnapToGrid = false,
	DefaultZoom = 1.0,
}

local Settings: {[string]: any} = {}

function PluginSettings.Initialize(Plugin: Plugin)
	for Key, DefaultValue in pairs(DEFAULT_SETTINGS) do
		local SavedValue = Plugin:GetSetting("Threader_" .. Key)
		if SavedValue ~= nil then
			Settings[Key] = SavedValue
		else
			Settings[Key] = DefaultValue
		end
	end
end

function PluginSettings.Get(Key: string): any
	return Settings[Key]
end

function PluginSettings.Set(Plugin: Plugin, Key: string, Value: any)
	Settings[Key] = Value
	Plugin:SetSetting("Threader_" .. Key, Value)
end

function PluginSettings.GetTheme(): string
	return Settings.Theme or "Dark"
end

function PluginSettings.SetTheme(Plugin: Plugin, Theme: string)
	PluginSettings.Set(Plugin, "Theme", Theme)
end

function PluginSettings.GetAll(): {[string]: any}
	return Settings
end

function PluginSettings.Reset(Plugin: Plugin)
	for Key, DefaultValue in pairs(DEFAULT_SETTINGS) do
		PluginSettings.Set(Plugin, Key, DefaultValue)
	end
end

return PluginSettings