--!strict
local Colors = require(script.Parent.Parent.Parent.Theme.Colors)
local Fonts = require(script.Parent.Parent.Parent.Theme.Fonts)
local Spacing = require(script.Parent.Parent.Parent.Theme.Spacing)

local NumberInput = {}

function NumberInput.Create(DefaultValue: number, Min: number?, Max: number?, Parent: Instance, OnChanged: ((number) -> ())?, LayoutOrder: number?): Frame
	local Container = Instance.new("Frame")
	Container.Size = UDim2.new(1, 0, 0, 28)
	Container.BackgroundTransparency = 1
	Container.LayoutOrder = LayoutOrder or 0
	Container.Parent = Parent

	local MinValue = Min or -math.huge
	local MaxValue = Max or math.huge

	local TextBoxElement = Instance.new("TextBox")
	TextBoxElement.Size = UDim2.new(1, -60, 1, 0)
	TextBoxElement.BackgroundColor3 = Colors.BackgroundLight
	TextBoxElement.BorderColor3 = Colors.Border
	TextBoxElement.BorderSizePixel = 1
	TextBoxElement.Text = tostring(DefaultValue)
	TextBoxElement.TextColor3 = Colors.Text
	TextBoxElement.Font = Fonts.Regular
	TextBoxElement.TextSize = 14
	TextBoxElement.ClearTextOnFocus = false
	TextBoxElement.Parent = Container

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, Spacing.Padding)
	Padding.PaddingRight = UDim.new(0, Spacing.Padding)
	Padding.Parent = TextBoxElement

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 4)
	Corner.Parent = TextBoxElement

	local ButtonContainer = Instance.new("Frame")
	ButtonContainer.Size = UDim2.new(0, 56, 1, 0)
	ButtonContainer.Position = UDim2.new(1, -56, 0, 0)
	ButtonContainer.BackgroundTransparency = 1
	ButtonContainer.Parent = Container

	local ButtonLayout = Instance.new("UIListLayout")
	ButtonLayout.FillDirection = Enum.FillDirection.Horizontal
	ButtonLayout.Padding = UDim.new(0, 4)
	ButtonLayout.Parent = ButtonContainer

	local DecrementButton = Instance.new("TextButton")
	DecrementButton.Size = UDim2.new(0, 26, 1, 0)
	DecrementButton.BackgroundColor3 = Colors.BackgroundLight
	DecrementButton.BorderColor3 = Colors.Border
	DecrementButton.BorderSizePixel = 1
	DecrementButton.Text = "-"
	DecrementButton.TextColor3 = Colors.Text
	DecrementButton.Font = Fonts.Bold
	DecrementButton.TextSize = 16
	DecrementButton.Parent = ButtonContainer

	local DecrementCorner = Instance.new("UICorner")
	DecrementCorner.CornerRadius = UDim.new(0, 4)
	DecrementCorner.Parent = DecrementButton

	local IncrementButton = Instance.new("TextButton")
	IncrementButton.Size = UDim2.new(0, 26, 1, 0)
	IncrementButton.BackgroundColor3 = Colors.BackgroundLight
	IncrementButton.BorderColor3 = Colors.Border
	IncrementButton.BorderSizePixel = 1
	IncrementButton.Text = "+"
	IncrementButton.TextColor3 = Colors.Text
	IncrementButton.Font = Fonts.Bold
	IncrementButton.TextSize = 16
	IncrementButton.Parent = ButtonContainer

	local IncrementCorner = Instance.new("UICorner")
	IncrementCorner.CornerRadius = UDim.new(0, 4)
	IncrementCorner.Parent = IncrementButton

	local function UpdateValue(NewValue: number)
		NewValue = math.clamp(NewValue, MinValue, MaxValue)
		TextBoxElement.Text = tostring(NewValue)
		if OnChanged then
			OnChanged(NewValue)
		end
	end

	TextBoxElement.FocusLost:Connect(function()
		local Value = tonumber(TextBoxElement.Text)
		if Value then
			UpdateValue(Value)
		else
			TextBoxElement.Text = tostring(DefaultValue)
		end
	end)

	DecrementButton.MouseButton1Click:Connect(function()
		local CurrentValue = tonumber(TextBoxElement.Text) or DefaultValue
		UpdateValue(CurrentValue - 1)
	end)

	IncrementButton.MouseButton1Click:Connect(function()
		local CurrentValue = tonumber(TextBoxElement.Text) or DefaultValue
		UpdateValue(CurrentValue + 1)
	end)

	return Container
end

return NumberInput