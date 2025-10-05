--!strict
local Constants = require(script.Parent.Parent.Constants)

local Toolbar = {}

function Toolbar.Create(Parent: Instance, OnNewTree: () -> (), OnSave: () -> (), OnLoad: () -> (), OnGenerateCode: () -> (), OnNameChanged: (string) -> ()): (Frame, TextBox)
	local TopBar = Instance.new("Frame")
	TopBar.Size = UDim2.new(1, 0, 0, Constants.SIZES.TopBarHeight)
	TopBar.BackgroundColor3 = Constants.COLORS.BackgroundDark
	TopBar.BorderSizePixel = 0
	TopBar.Parent = Parent

	local ButtonContainer = Instance.new("Frame")
	ButtonContainer.Size = UDim2.fromScale(1, 1)
	ButtonContainer.BackgroundTransparency = 1
	ButtonContainer.Parent = TopBar

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, Constants.SIZES.PaddingSmall)
	Padding.PaddingRight = UDim.new(0, Constants.SIZES.PaddingSmall)
	Padding.PaddingTop = UDim.new(0, Constants.SIZES.PaddingSmall + 3)
	Padding.PaddingBottom = UDim.new(0, Constants.SIZES.PaddingSmall)
	Padding.Parent = ButtonContainer

	local Layout = Instance.new("UIListLayout")
	Layout.FillDirection = Enum.FillDirection.Horizontal
	Layout.Padding = UDim.new(0, Constants.SIZES.PaddingSmall)
	Layout.Parent = ButtonContainer

	local function CreateToolbarButton(Text: string, Color: Color3, OnClick: () -> ()): TextButton
		local Button = Instance.new("TextButton")
		Button.Size = UDim2.fromOffset(90, 32)
		Button.Text = Text
		Button.TextColor3 = Constants.COLORS.TextPrimary
		Button.BackgroundColor3 = Color
		Button.Font = Constants.FONTS.Medium
		Button.TextSize = 13
		Button.BorderSizePixel = 0
		Button.AutoButtonColor = false
		Button.Parent = ButtonContainer

		local Corner = Instance.new("UICorner")
		Corner.CornerRadius = UDim.new(0, Constants.SIZES.CornerRadius)
		Corner.Parent = Button

		Button.MouseButton1Click:Connect(OnClick)

		return Button
	end

	CreateToolbarButton("📄 New", Constants.COLORS.Primary, OnNewTree)
	CreateToolbarButton("💾 Save", Constants.COLORS.Accent, OnSave)
	CreateToolbarButton("📂 Load", Constants.COLORS.Accent, OnLoad)
	CreateToolbarButton("⚡ Generate", Constants.COLORS.Success, OnGenerateCode)

	local NameBox = Instance.new("TextBox")
	NameBox.Size = UDim2.fromOffset(180, 32)
	NameBox.Text = "UntitledDialog"
	NameBox.PlaceholderText = "Dialog Name..."
	NameBox.TextColor3 = Constants.COLORS.TextPrimary
	NameBox.BackgroundColor3 = Constants.COLORS.InputBackground
	NameBox.BorderSizePixel = 1
	NameBox.BorderColor3 = Constants.COLORS.InputBorder
	NameBox.Font = Constants.FONTS.Regular
	NameBox.TextSize = 13
	NameBox.ClearTextOnFocus = false
	NameBox.Parent = ButtonContainer

	local NameCorner = Instance.new("UICorner")
	NameCorner.CornerRadius = UDim.new(0, Constants.SIZES.CornerRadius)
	NameCorner.Parent = NameBox

	local NamePadding = Instance.new("UIPadding")
	NamePadding.PaddingLeft = UDim.new(0, 8)
	NamePadding.PaddingRight = UDim.new(0, 8)
	NamePadding.Parent = NameBox

	NameBox.Focused:Connect(function()
		NameBox.BorderColor3 = Constants.COLORS.Primary
	end)

	NameBox.FocusLost:Connect(function()
		NameBox.BorderColor3 = Constants.COLORS.InputBorder
		OnNameChanged(NameBox.Text)
	end)

	return TopBar, NameBox
end

return Toolbar