--!strict
local Colors = require(script.Parent.Parent.Parent.Theme.Colors)
local Fonts = require(script.Parent.Parent.Parent.Theme.Fonts)

local ToggleButton = {}

function ToggleButton.Create(Text: string, Parent: Instance, OnToggle: (boolean) -> (), DefaultState: boolean?, LayoutOrder: number?): TextButton
	local IsToggled = DefaultState or false

	local ButtonElement = Instance.new("TextButton")
	ButtonElement.Size = UDim2.fromOffset(120, 28)
	ButtonElement.BackgroundColor3 = IsToggled and Colors.Success or Colors.BackgroundLight
	ButtonElement.BorderSizePixel = 0
	ButtonElement.Text = Text
	ButtonElement.TextColor3 = Colors.Text
	ButtonElement.Font = Fonts.Medium
	ButtonElement.TextSize = 14
	ButtonElement.LayoutOrder = LayoutOrder or 0
	ButtonElement.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 4)
	Corner.Parent = ButtonElement

	ButtonElement.MouseButton1Click:Connect(function()
		IsToggled = not IsToggled
		ButtonElement.BackgroundColor3 = IsToggled and Colors.Success or Colors.BackgroundLight
		OnToggle(IsToggled)
	end)

	return ButtonElement
end

return ToggleButton