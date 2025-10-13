--!strict
local InputManager = require(script.Parent.Parent.Managers.InputManager)
local UIStateManager = require(script.Parent.Parent.Managers.UIStateManager)
local ZIndexManager = require(script.Parent.Parent.Managers.ZIndexManager)

local PluginBootstrap = {}

function PluginBootstrap.Initialize(Plugin: Plugin): DockWidgetPluginGui
	local Toolbar = Plugin:CreateToolbar("Threader")
	local Button = Toolbar:CreateButton(
		"Open Editor",
		"Create and edit dialog trees",
		"rbxassetid://124231195330391"
	)

	local WidgetInfo = DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Float,
		false,
		false,
		500,
		700,
		500,
		700
	)

	local Widget = Plugin:CreateDockWidgetPluginGui("DialogTreeEditor", WidgetInfo)
	Widget.Title = "Threader Editor"

	InputManager.Initialize(Widget)
	UIStateManager.Initialize()
	ZIndexManager.Initialize()

	Button.Click:Connect(function()
		Widget.Enabled = not Widget.Enabled
	end)

	return Widget
end

return PluginBootstrap