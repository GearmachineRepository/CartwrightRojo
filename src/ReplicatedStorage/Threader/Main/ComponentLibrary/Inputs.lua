--!strict
local Constants = require(script.Parent.Parent.Constants)
local TweenService = game:GetService("TweenService")

local Inputs = {}

local TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function CreateTween(Instance: GuiObject, Properties: {[string]: any})
	return TweenService:Create(Instance, TWEEN_INFO, Properties)
end

function Inputs.CreateTextBox(
	InitialText: string,
	Parent: Instance,
	Order: number,
	MultiLine: boolean,
	OnChanged: (string) -> ()
): TextBox
	local Container = Instance.new("Frame")
	Container.Size = UDim2.new(1, 0, 0, MultiLine and 120 or 36)
	Container.BackgroundColor3 = Constants.COLORS.InputBackground
	Container.BorderSizePixel = 0
	Container.LayoutOrder = Order
	Container.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 6)
	Corner.Parent = Container

	local Stroke = Instance.new("UIStroke")
	Stroke.Color = Constants.COLORS.InputBorder
	Stroke.Thickness = 1
	Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	Stroke.Parent = Container

	local TextBox = Instance.new("TextBox")
	TextBox.Size = UDim2.fromScale(1, 1)
	TextBox.Text = InitialText
	TextBox.TextColor3 = Constants.COLORS.TextPrimary
	TextBox.BackgroundTransparency = 1
	TextBox.Font = Constants.FONTS.Regular
	TextBox.TextSize = 14
	TextBox.TextXAlignment = Enum.TextXAlignment.Left
	TextBox.TextYAlignment = MultiLine and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
	TextBox.TextWrapped = true
	TextBox.MultiLine = MultiLine
	TextBox.ClearTextOnFocus = false
	TextBox.PlaceholderColor3 = Constants.COLORS.TextMuted
	TextBox.Parent = Container

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, 12)
	Padding.PaddingRight = UDim.new(0, 12)
	Padding.PaddingTop = UDim.new(0, MultiLine and 10 or 8)
	Padding.PaddingBottom = UDim.new(0, MultiLine and 10 or 8)
	Padding.Parent = TextBox

	TextBox.Focused:Connect(function()
		CreateTween(Stroke, {Color = Constants.COLORS.Primary}):Play()
	end)

	TextBox.FocusLost:Connect(function()
		CreateTween(Stroke, {Color = Constants.COLORS.InputBorder}):Play()
		OnChanged(TextBox.Text)
	end)

	return TextBox
end

function Inputs.CreateLabeledInput(
	LabelText: string,
	InitialValue: string,
	Parent: Instance,
	Order: number,
	OnChanged: (string) -> ()
)
	local Labels = require(script.Parent.Labels)
	Labels.CreateLabel(LabelText, Parent, Order)
	Inputs.CreateTextBox(InitialValue, Parent, Order + 0.1, false, OnChanged)
end

function Inputs.CreateDropdown(
	Options: {string},
	CurrentValue: string,
	Parent: Instance,
	Order: number,
	OnChanged: (string) -> ()
): TextButton
	local Container = Instance.new("Frame")
	Container.Size = UDim2.new(1, 0, 0, 36)
	Container.BackgroundTransparency = 1
	Container.LayoutOrder = Order
	Container.ClipsDescendants = false
	Container.Parent = Parent

	local Dropdown = Instance.new("TextButton")
	Dropdown.Size = UDim2.fromScale(1, 1)
	Dropdown.Text = ""
	Dropdown.BackgroundColor3 = Constants.COLORS.InputBackground
	Dropdown.BorderSizePixel = 0
	Dropdown.AutoButtonColor = false
	Dropdown.ZIndex = 10
	Dropdown.Parent = Container

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 6)
	Corner.Parent = Dropdown

	local Stroke = Instance.new("UIStroke")
	Stroke.Color = Constants.COLORS.InputBorder
	Stroke.Thickness = 1
	Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	Stroke.Parent = Dropdown

	local ValueLabel = Instance.new("TextLabel")
	ValueLabel.Size = UDim2.new(1, -32, 1, 0)
	ValueLabel.Position = UDim2.fromOffset(12, 0)
	ValueLabel.Text = CurrentValue or (Options[1] or "")
	ValueLabel.TextColor3 = Constants.COLORS.TextPrimary
	ValueLabel.BackgroundTransparency = 1
	ValueLabel.Font = Constants.FONTS.Regular
	ValueLabel.TextSize = 14
	ValueLabel.TextXAlignment = Enum.TextXAlignment.Left
	ValueLabel.TextYAlignment = Enum.TextYAlignment.Center
	ValueLabel.ZIndex = 11
	ValueLabel.Parent = Dropdown

	local Arrow = Instance.new("TextLabel")
	Arrow.Size = UDim2.fromOffset(20, 20)
	Arrow.Position = UDim2.new(1, -28, 0.5, -10)
	Arrow.Text = "▼"
	Arrow.TextColor3 = Constants.COLORS.TextSecondary
	Arrow.BackgroundTransparency = 1
	Arrow.Font = Constants.FONTS.Regular
	Arrow.TextSize = 12
	Arrow.ZIndex = 11
	Arrow.Parent = Dropdown

	local OptionsFrame = Instance.new("ScrollingFrame")
	OptionsFrame.Size = UDim2.new(1, 0, 0, math.min(#Options * 32 + 8, 200))
	OptionsFrame.Position = UDim2.new(0, 0, 1, 4)
	OptionsFrame.BackgroundColor3 = Constants.COLORS.Panel
	OptionsFrame.BorderSizePixel = 0
	OptionsFrame.Visible = false
	OptionsFrame.ZIndex = 100
	OptionsFrame.ScrollBarThickness = 4
	OptionsFrame.CanvasSize = UDim2.fromOffset(0, #Options * 32 + 8)
	OptionsFrame.Parent = Container

	local OptionsCorner = Instance.new("UICorner")
	OptionsCorner.CornerRadius = UDim.new(0, 6)
	OptionsCorner.Parent = OptionsFrame

	local OptionsStroke = Instance.new("UIStroke")
	OptionsStroke.Color = Constants.COLORS.Border
	OptionsStroke.Thickness = 1
	OptionsStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	OptionsStroke.Parent = OptionsFrame

	local OptionsLayout = Instance.new("UIListLayout")
	OptionsLayout.Padding = UDim.new(0, 2)
	OptionsLayout.Parent = OptionsFrame

	local OptionsPadding = Instance.new("UIPadding")
	OptionsPadding.PaddingLeft = UDim.new(0, 4)
	OptionsPadding.PaddingRight = UDim.new(0, 4)
	OptionsPadding.PaddingTop = UDim.new(0, 4)
	OptionsPadding.PaddingBottom = UDim.new(0, 4)
	OptionsPadding.Parent = OptionsFrame

	local OptionButtons: {[string]: TextButton} = {}

	for _, Option in ipairs(Options) do
		local OptionButton = Instance.new("TextButton")
		OptionButton.Size = UDim2.new(1, 0, 0, 28)
		OptionButton.Text = Option
		OptionButton.TextColor3 = Constants.COLORS.TextPrimary
		OptionButton.BackgroundColor3 = Option == CurrentValue and Constants.COLORS.Primary or Color3.fromRGB(0, 0, 0)
		OptionButton.BackgroundTransparency = Option == CurrentValue and 0 or 1
		OptionButton.Font = Constants.FONTS.Regular
		OptionButton.TextSize = 14
		OptionButton.BorderSizePixel = 0
		OptionButton.TextXAlignment = Enum.TextXAlignment.Left
		OptionButton.AutoButtonColor = false
		OptionButton.ZIndex = 101
		OptionButton.Parent = OptionsFrame

		local OptionCorner = Instance.new("UICorner")
		OptionCorner.CornerRadius = UDim.new(0, 4)
		OptionCorner.Parent = OptionButton

		local OptionPadding = Instance.new("UIPadding")
		OptionPadding.PaddingLeft = UDim.new(0, 8)
		OptionPadding.Parent = OptionButton

		OptionButtons[Option] = OptionButton

		OptionButton.MouseEnter:Connect(function()
			if ValueLabel.Text ~= Option then
				CreateTween(OptionButton, {BackgroundTransparency = 0, BackgroundColor3 = Constants.COLORS.PanelHover}):Play()
			end
		end)

		OptionButton.MouseLeave:Connect(function()
			if ValueLabel.Text ~= Option then
				CreateTween(OptionButton, {BackgroundTransparency = 1}):Play()
			end
		end)

		OptionButton.MouseButton1Click:Connect(function()
			for OptionName, Button in pairs(OptionButtons) do
				if OptionName == Option then
					Button.BackgroundColor3 = Constants.COLORS.Primary
					Button.BackgroundTransparency = 0
				else
					Button.BackgroundTransparency = 1
				end
			end

			ValueLabel.Text = Option
			OptionsFrame.Visible = false
			CreateTween(Arrow, {Rotation = 0}):Play()
			CreateTween(Stroke, {Color = Constants.COLORS.InputBorder}):Play()
			OnChanged(Option)
		end)
	end

	Dropdown.MouseButton1Click:Connect(function()
		OptionsFrame.Visible = not OptionsFrame.Visible
		if OptionsFrame.Visible then
			CreateTween(Arrow, {Rotation = 180}):Play()
			CreateTween(Stroke, {Color = Constants.COLORS.Primary}):Play()
		else
			CreateTween(Arrow, {Rotation = 0}):Play()
			CreateTween(Stroke, {Color = Constants.COLORS.InputBorder}):Play()
		end
	end)

	return Dropdown
end

function Inputs.CreateNumberInput(
	InitialValue: number,
	Parent: Instance,
	Order: number,
	OnChanged: (number) -> ()
): Frame
	local Container = Instance.new("Frame")
	Container.Size = UDim2.new(1, 0, 0, 36)
	Container.BackgroundTransparency = 1
	Container.LayoutOrder = Order
	Container.Parent = Parent

	local MinusButton = Instance.new("TextButton")
	MinusButton.Size = UDim2.new(0, 36, 1, 0)
	MinusButton.Position = UDim2.fromScale(0, 0)
	MinusButton.Text = "−"
	MinusButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	MinusButton.BackgroundColor3 = Constants.COLORS.ButtonBackground
	MinusButton.Font = Constants.FONTS.Bold
	MinusButton.TextSize = 18
	MinusButton.BorderSizePixel = 0
	MinusButton.AutoButtonColor = false
	MinusButton.Parent = Container

	local MinusCorner = Instance.new("UICorner")
	MinusCorner.CornerRadius = UDim.new(0, 6)
	MinusCorner.Parent = MinusButton

	local NumberBox = Instance.new("TextBox")
	NumberBox.Size = UDim2.new(1, -76, 1, 0)
	NumberBox.Position = UDim2.fromOffset(40, 0)
	NumberBox.Text = tostring(InitialValue)
	NumberBox.TextColor3 = Constants.COLORS.TextPrimary
	NumberBox.BackgroundColor3 = Constants.COLORS.InputBackground
	NumberBox.Font = Constants.FONTS.Medium
	NumberBox.TextSize = 14
	NumberBox.BorderSizePixel = 0
	NumberBox.Parent = Container

	local NumberCorner = Instance.new("UICorner")
	NumberCorner.CornerRadius = UDim.new(0, 6)
	NumberCorner.Parent = NumberBox

	local NumberStroke = Instance.new("UIStroke")
	NumberStroke.Color = Constants.COLORS.InputBorder
	NumberStroke.Thickness = 1
	NumberStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	NumberStroke.Parent = NumberBox

	local PlusButton = Instance.new("TextButton")
	PlusButton.Size = UDim2.new(0, 36, 1, 0)
	PlusButton.Position = UDim2.new(1, -36, 0, 0)
	PlusButton.Text = "+"
	PlusButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	PlusButton.BackgroundColor3 = Constants.COLORS.ButtonBackground
	PlusButton.Font = Constants.FONTS.Bold
	PlusButton.TextSize = 18
	PlusButton.BorderSizePixel = 0
	PlusButton.AutoButtonColor = false
	PlusButton.Parent = Container

	local PlusCorner = Instance.new("UICorner")
	PlusCorner.CornerRadius = UDim.new(0, 6)
	PlusCorner.Parent = PlusButton

	local function UpdateValue(NewValue: number)
		NumberBox.Text = tostring(NewValue)
		OnChanged(NewValue)
	end

	MinusButton.MouseEnter:Connect(function()
		CreateTween(MinusButton, {BackgroundColor3 = Constants.COLORS.PanelHover}):Play()
	end)

	MinusButton.MouseLeave:Connect(function()
		CreateTween(MinusButton, {BackgroundColor3 = Constants.COLORS.ButtonBackground}):Play()
	end)

	PlusButton.MouseEnter:Connect(function()
		CreateTween(PlusButton, {BackgroundColor3 = Constants.COLORS.PanelHover}):Play()
	end)

	PlusButton.MouseLeave:Connect(function()
		CreateTween(PlusButton, {BackgroundColor3 = Constants.COLORS.ButtonBackground}):Play()
	end)

	MinusButton.MouseButton1Click:Connect(function()
		local Current = tonumber(NumberBox.Text) or InitialValue
		UpdateValue(math.max(0, Current - 1))
	end)

	PlusButton.MouseButton1Click:Connect(function()
		local Current = tonumber(NumberBox.Text) or InitialValue
		UpdateValue(Current + 1)
	end)

	NumberBox.Focused:Connect(function()
		CreateTween(NumberStroke, {Color = Constants.COLORS.Primary}):Play()
	end)

	NumberBox.FocusLost:Connect(function()
		CreateTween(NumberStroke, {Color = Constants.COLORS.InputBorder}):Play()
		local Value = tonumber(NumberBox.Text)
		if Value then
			UpdateValue(math.max(0, Value))
		else
			NumberBox.Text = tostring(InitialValue)
		end
	end)

	return Container
end

return Inputs