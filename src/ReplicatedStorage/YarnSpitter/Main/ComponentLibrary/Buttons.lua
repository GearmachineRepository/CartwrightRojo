--!strict
local Constants = require(script.Parent.Parent.Constants)
local TweenService = game:GetService("TweenService")

local Buttons = {}

local TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function CreateTween(Instance: GuiObject, Properties: {[string]: any})
	return TweenService:Create(Instance, TWEEN_INFO, Properties)
end

function Buttons.CreateButton(
	Text: string,
	Parent: Instance,
	Order: number,
	Color: Color3,
	OnClick: () -> ()
): TextButton
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(1, 0, 0, 36)
	Button.Text = Text
	Button.TextColor3 = Color3.fromRGB(255, 255, 255)
	Button.BackgroundColor3 = Color
	Button.Font = Constants.FONTS.Medium
	Button.TextSize = 14
	Button.BorderSizePixel = 0
	Button.AutoButtonColor = false
	Button.LayoutOrder = Order
	Button.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 6)
	Corner.Parent = Button

	local OriginalColor = Color
	local HoverColor = Color3.fromRGB(
		math.min(255, Color.R * 255 + 20),
		math.min(255, Color.G * 255 + 20),
		math.min(255, Color.B * 255 + 20)
	)

	Button.MouseEnter:Connect(function()
		CreateTween(Button, {BackgroundColor3 = HoverColor}):Play()
	end)

	Button.MouseLeave:Connect(function()
		CreateTween(Button, {BackgroundColor3 = OriginalColor}):Play()
	end)

	Button.MouseButton1Down:Connect(function()
		CreateTween(Button, {Size = UDim2.new(1, 0, 0, 34)}):Play()
	end)

	Button.MouseButton1Up:Connect(function()
		CreateTween(Button, {Size = UDim2.new(1, 0, 0, 36)}):Play()
	end)

	Button.MouseButton1Click:Connect(OnClick)

	return Button
end

function Buttons.CreateButtonRow(
	ButtonsList: {{Text: string, Color: Color3?, OnClick: () -> ()}},
	Parent: Instance,
	Order: number
): Frame
	local Row = Instance.new("Frame")
	Row.Size = UDim2.new(1, 0, 0, 36)
	Row.BackgroundTransparency = 1
	Row.LayoutOrder = Order
	Row.Parent = Parent

	local Layout = Instance.new("UIListLayout")
	Layout.FillDirection = Enum.FillDirection.Horizontal
	Layout.Padding = UDim.new(0, 8)
	Layout.Parent = Row

	for _, ButtonData in ipairs(ButtonsList) do
		local Button = Instance.new("TextButton")
		Button.Size = UDim2.new(1 / #ButtonsList, -8 * (#ButtonsList - 1) / #ButtonsList, 1, 0)
		Button.Text = ButtonData.Text
		Button.TextColor3 = Color3.fromRGB(255, 255, 255)
		Button.BackgroundColor3 = ButtonData.Color or Constants.COLORS.Primary
		Button.Font = Constants.FONTS.Medium
		Button.TextSize = 14
		Button.BorderSizePixel = 0
		Button.AutoButtonColor = false
		Button.Parent = Row

		local Corner = Instance.new("UICorner")
		Corner.CornerRadius = UDim.new(0, 6)
		Corner.Parent = Button

		local OriginalColor = ButtonData.Color or Constants.COLORS.Primary
		local HoverColor = Color3.fromRGB(
			math.min(255, OriginalColor.R * 255 + 20),
			math.min(255, OriginalColor.G * 255 + 20),
			math.min(255, OriginalColor.B * 255 + 20)
		)

		Button.MouseEnter:Connect(function()
			CreateTween(Button, {BackgroundColor3 = HoverColor}):Play()
		end)

		Button.MouseLeave:Connect(function()
			CreateTween(Button, {BackgroundColor3 = OriginalColor}):Play()
		end)

		Button.MouseButton1Click:Connect(ButtonData.OnClick)
	end

	return Row
end

function Buttons.CreateToggleButton(
	Text: string,
	IsToggled: boolean,
	Parent: Instance,
	Order: number,
	OnToggle: (boolean) -> ()
): TextButton
	local Container = Instance.new("TextButton")
	Container.Size = UDim2.new(1, 0, 0, 44)
	Container.BackgroundColor3 = Constants.COLORS.Panel
	Container.BorderSizePixel = 0
	Container.AutoButtonColor = false
	Container.LayoutOrder = Order
	Container.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 6)
	Corner.Parent = Container

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, -60, 1, 0)
	Label.Position = UDim2.fromOffset(12, 0)
	Label.Text = Text
	Label.TextColor3 = Constants.COLORS.TextPrimary
	Label.BackgroundTransparency = 1
	Label.Font = Constants.FONTS.Medium
	Label.TextSize = 14
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Container

	local ToggleTrack = Instance.new("Frame")
	ToggleTrack.Size = UDim2.fromOffset(44, 24)
	ToggleTrack.Position = UDim2.new(1, -52, 0.5, -12)
	ToggleTrack.BackgroundColor3 = IsToggled and Constants.COLORS.Primary or Constants.COLORS.Unselected
	ToggleTrack.BorderSizePixel = 0
	ToggleTrack.Parent = Container

	local TrackCorner = Instance.new("UICorner")
	TrackCorner.CornerRadius = UDim.new(1, 0)
	TrackCorner.Parent = ToggleTrack

	local ToggleThumb = Instance.new("Frame")
	ToggleThumb.Size = UDim2.fromOffset(20, 20)
	ToggleThumb.Position = IsToggled and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2)
	ToggleThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ToggleThumb.BorderSizePixel = 0
	ToggleThumb.Parent = ToggleTrack

	local ThumbCorner = Instance.new("UICorner")
	ThumbCorner.CornerRadius = UDim.new(1, 0)
	ThumbCorner.Parent = ToggleThumb

	Container.MouseButton1Click:Connect(function()
		IsToggled = not IsToggled

		local ThumbPos = IsToggled and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2)
		local TrackColor = IsToggled and Constants.COLORS.Primary or Constants.COLORS.Unselected

		CreateTween(ToggleThumb, {Position = ThumbPos}):Play()
		CreateTween(ToggleTrack, {BackgroundColor3 = TrackColor}):Play()

		OnToggle(IsToggled)
	end)

	Container.MouseEnter:Connect(function()
		CreateTween(Container, {BackgroundColor3 = Constants.COLORS.PanelHover}):Play()
	end)

	Container.MouseLeave:Connect(function()
		CreateTween(Container, {BackgroundColor3 = Constants.COLORS.Panel}):Play()
	end)

	return Container
end

return Buttons