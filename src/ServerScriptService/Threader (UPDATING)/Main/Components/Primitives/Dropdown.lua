--!strict
local Colors = require(script.Parent.Parent.Parent.Theme.Colors)
local Fonts = require(script.Parent.Parent.Parent.Theme.Fonts)
local Spacing = require(script.Parent.Parent.Parent.Theme.Spacing)

local Dropdown = {}

function Dropdown.Create(Options: {string}, DefaultOption: string, Parent: Instance, OnSelected: (string) -> (), LayoutOrder: number?): Frame
	local Container = Instance.new("Frame")
	Container.Size = UDim2.new(1, 0, 0, 28)
	Container.BackgroundTransparency = 1
	Container.LayoutOrder = LayoutOrder or 0
	Container.Parent = Parent

	local DropdownButton = Instance.new("TextButton")
	DropdownButton.Size = UDim2.fromScale(1, 1)
	DropdownButton.BackgroundColor3 = Colors.BackgroundLight
	DropdownButton.BorderColor3 = Colors.Border
	DropdownButton.BorderSizePixel = 1
	DropdownButton.Text = DefaultOption
	DropdownButton.TextColor3 = Colors.Text
	DropdownButton.Font = Fonts.Regular
	DropdownButton.TextSize = 14
	DropdownButton.TextXAlignment = Enum.TextXAlignment.Left
	DropdownButton.Parent = Container

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, Spacing.Padding)
	Padding.PaddingRight = UDim.new(0, 24)
	Padding.Parent = DropdownButton

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 4)
	Corner.Parent = DropdownButton

	local Arrow = Instance.new("TextLabel")
	Arrow.Size = UDim2.new(0, 20, 1, 0)
	Arrow.Position = UDim2.new(1, -20, 0, 0)
	Arrow.BackgroundTransparency = 1
	Arrow.Text = "▼"
	Arrow.TextColor3 = Colors.TextSecondary
	Arrow.Font = Fonts.Regular
	Arrow.TextSize = 12
	Arrow.Parent = DropdownButton

	local OptionsFrame = Instance.new("Frame")
	OptionsFrame.Size = UDim2.new(1, 0, 0, #Options * 28)
	OptionsFrame.Position = UDim2.new(0, 0, 1, 4)
	OptionsFrame.BackgroundColor3 = Colors.BackgroundLight
	OptionsFrame.BorderColor3 = Colors.Border
	OptionsFrame.BorderSizePixel = 1
	OptionsFrame.Visible = false
	OptionsFrame.ZIndex = 200
	OptionsFrame.Parent = Container

	local OptionsCorner = Instance.new("UICorner")
	OptionsCorner.CornerRadius = UDim.new(0, 4)
	OptionsCorner.Parent = OptionsFrame

	local Layout = Instance.new("UIListLayout")
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Parent = OptionsFrame

	for Index, Option in ipairs(Options) do
		local OptionButton = Instance.new("TextButton")
		OptionButton.Size = UDim2.new(1, 0, 0, 28)
		OptionButton.BackgroundTransparency = 1
		OptionButton.Text = Option
		OptionButton.TextColor3 = Colors.Text
		OptionButton.Font = Fonts.Regular
		OptionButton.TextSize = 14
		OptionButton.TextXAlignment = Enum.TextXAlignment.Left
		OptionButton.LayoutOrder = Index
		OptionButton.Parent = OptionsFrame

		local OptionPadding = Instance.new("UIPadding")
		OptionPadding.PaddingLeft = UDim.new(0, Spacing.Padding)
		OptionPadding.Parent = OptionButton

		OptionButton.MouseButton1Click:Connect(function()
			DropdownButton.Text = Option
			OptionsFrame.Visible = false
			OnSelected(Option)
		end)

		OptionButton.MouseEnter:Connect(function()
			OptionButton.BackgroundColor3 = Colors.BackgroundDark
			OptionButton.BackgroundTransparency = 0
		end)

		OptionButton.MouseLeave:Connect(function()
			OptionButton.BackgroundTransparency = 1
		end)
	end

	DropdownButton.MouseButton1Click:Connect(function()
		OptionsFrame.Visible = not OptionsFrame.Visible
	end)

	return Container
end

return Dropdown