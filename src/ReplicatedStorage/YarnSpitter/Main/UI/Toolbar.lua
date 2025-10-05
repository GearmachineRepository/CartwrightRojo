--!strict
local Constants = require(script.Parent.Parent.Constants)
local TweenService = game:GetService("TweenService")

local Toolbar = {}

local TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

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
	Padding.PaddingLeft = UDim.new(0, Constants.SIZES.Padding)
	Padding.PaddingRight = UDim.new(0, Constants.SIZES.Padding)
	Padding.PaddingTop = UDim.new(0, Constants.SIZES.PaddingSmall + 2)
	Padding.PaddingBottom = UDim.new(0, Constants.SIZES.PaddingSmall + 2)
	Padding.Parent = ButtonContainer

	local Layout = Instance.new("UIListLayout")
	Layout.FillDirection = Enum.FillDirection.Horizontal
	Layout.Padding = UDim.new(0, Constants.SIZES.PaddingSmall + 2)
	Layout.VerticalAlignment = Enum.VerticalAlignment.Center
	Layout.Parent = ButtonContainer

	local function CreateToolbarButton(Text: string, Color: Color3, OnClick: () -> ()): TextButton
		local Button = Instance.new("TextButton")
		Button.Size = UDim2.fromOffset(95, 34)
		Button.Text = Text
		Button.TextColor3 = Constants.COLORS.TextPrimary
		Button.BackgroundColor3 = Color
		Button.Font = Constants.FONTS.Medium
		Button.TextSize = Constants.TEXT_SIZES.Normal
		Button.BorderSizePixel = 0
		Button.AutoButtonColor = false
		Button.Parent = ButtonContainer

		local Corner = Instance.new("UICorner")
		Corner.CornerRadius = UDim.new(0, Constants.SIZES.CornerRadius)
		Corner.Parent = Button

		local OriginalColor = Color
		local HoverColor = Color

		if Color == Constants.COLORS.Primary then
			HoverColor = Constants.COLORS.PrimaryHover
		elseif Color == Constants.COLORS.Accent then
			HoverColor = Constants.COLORS.AccentHover
		elseif Color == Constants.COLORS.Success then
			HoverColor = Constants.COLORS.SuccessHover
		end

		Button.MouseEnter:Connect(function()
			TweenService:Create(Button, TWEEN_INFO, {BackgroundColor3 = HoverColor}):Play()
		end)

		Button.MouseLeave:Connect(function()
			TweenService:Create(Button, TWEEN_INFO, {BackgroundColor3 = OriginalColor}):Play()
		end)

		Button.MouseButton1Down:Connect(function()
			Button.Size = UDim2.fromOffset(95, 32)
		end)

		Button.MouseButton1Up:Connect(function()
			Button.Size = UDim2.fromOffset(95, 34)
		end)

		Button.MouseButton1Click:Connect(OnClick)

		return Button
	end

	CreateToolbarButton("📄 New", Constants.COLORS.Primary, OnNewTree)
	CreateToolbarButton("💾 Save", Constants.COLORS.Accent, OnSave)
	CreateToolbarButton("📂 Load", Constants.COLORS.Accent, OnLoad)
	CreateToolbarButton("⚡ Generate", Constants.COLORS.Success, OnGenerateCode)

	local NameBox = Instance.new("TextBox")
	NameBox.Size = UDim2.fromOffset(200, 34)
	NameBox.Text = "UntitledDialog"
	NameBox.PlaceholderText = "Dialog Name..."
	NameBox.TextColor3 = Constants.COLORS.TextPrimary
	NameBox.BackgroundColor3 = Constants.COLORS.InputBackground
	NameBox.BorderSizePixel = Constants.SIZES.BorderWidth
	NameBox.BorderColor3 = Constants.COLORS.InputBorder
	NameBox.Font = Constants.FONTS.Regular
	NameBox.TextSize = Constants.TEXT_SIZES.Normal
	NameBox.ClearTextOnFocus = false
	NameBox.Parent = ButtonContainer

	local NameCorner = Instance.new("UICorner")
	NameCorner.CornerRadius = UDim.new(0, Constants.SIZES.CornerRadius)
	NameCorner.Parent = NameBox

	local NamePadding = Instance.new("UIPadding")
	NamePadding.PaddingLeft = UDim.new(0, Constants.SIZES.PaddingSmall + 4)
	NamePadding.PaddingRight = UDim.new(0, Constants.SIZES.PaddingSmall + 4)
	NamePadding.Parent = NameBox

	NameBox.Focused:Connect(function()
		TweenService:Create(NameBox, TWEEN_INFO, {
			BorderColor3 = Constants.COLORS.Primary,
			BackgroundColor3 = Constants.COLORS.BackgroundLight
		}):Play()
	end)

	NameBox.FocusLost:Connect(function()
		TweenService:Create(NameBox, TWEEN_INFO, {
			BorderColor3 = Constants.COLORS.InputBorder,
			BackgroundColor3 = Constants.COLORS.InputBackground
		}):Play()
		OnNameChanged(NameBox.Text)
	end)

	return TopBar, NameBox
end

return Toolbar