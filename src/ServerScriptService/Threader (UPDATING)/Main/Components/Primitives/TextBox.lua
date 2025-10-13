--!strict
local Colors = require(script.Parent.Parent.Parent.Theme.Colors)
local Fonts = require(script.Parent.Parent.Parent.Theme.Fonts)
local Spacing = require(script.Parent.Parent.Parent.Theme.Spacing)

local TextBox = {}

function TextBox.Create(PlaceholderText: string, Parent: Instance, OnChanged: ((string) -> ())?, LayoutOrder: number?): TextBox
	local TextBoxElement = Instance.new("TextBox")
	TextBoxElement.Size = UDim2.new(1, 0, 0, 28)
	TextBoxElement.BackgroundColor3 = Colors.BackgroundLight
	TextBoxElement.BorderColor3 = Colors.Border
	TextBoxElement.BorderSizePixel = 1
	TextBoxElement.PlaceholderText = PlaceholderText
	TextBoxElement.Text = ""
	TextBoxElement.TextColor3 = Colors.Text
	TextBoxElement.Font = Fonts.Regular
	TextBoxElement.TextSize = 14
	TextBoxElement.TextXAlignment = Enum.TextXAlignment.Left
	TextBoxElement.ClearTextOnFocus = false
	TextBoxElement.LayoutOrder = LayoutOrder or 0
	TextBoxElement.Parent = Parent

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, Spacing.Padding)
	Padding.PaddingRight = UDim.new(0, Spacing.Padding)
	Padding.Parent = TextBoxElement

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 4)
	Corner.Parent = TextBoxElement

	if OnChanged then
		TextBoxElement.FocusLost:Connect(function()
			OnChanged(TextBoxElement.Text)
		end)
	end

	TextBoxElement.Focused:Connect(function()
		TextBoxElement.BorderColor3 = Colors.Primary
	end)

	TextBoxElement.FocusLost:Connect(function()
		TextBoxElement.BorderColor3 = Colors.Border
	end)

	return TextBoxElement
end

function TextBox.CreateMultiline(PlaceholderText: string, Parent: Instance, OnChanged: ((string) -> ())?, Height: number?, LayoutOrder: number?): TextBox
	local TextBoxElement = TextBox.Create(PlaceholderText, Parent, OnChanged, LayoutOrder)
	TextBoxElement.Size = UDim2.new(1, 0, 0, Height or 80)
	TextBoxElement.MultiLine = true
	TextBoxElement.TextYAlignment = Enum.TextYAlignment.Top

	local Padding = TextBoxElement:FindFirstChildOfClass("UIPadding")
	if Padding then
		Padding.PaddingTop = UDim.new(0, Spacing.Padding)
		Padding.PaddingBottom = UDim.new(0, Spacing.Padding)
	end

	return TextBoxElement
end

return TextBox