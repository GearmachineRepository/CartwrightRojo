--!strict
local Constants = require(script.Parent.Parent.Constants)
local TweenService = game:GetService("TweenService")

local Components = {}

local TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function CreateTween(Instance: GuiObject, Properties: {[string]: any})
	return TweenService:Create(Instance, TWEEN_INFO, Properties)
end

function Components.CreateLabel(Text: string, Parent: Instance, Order: number): TextLabel
	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, 0, 0, 18)
	Label.Text = Text
	Label.TextColor3 = Constants.COLORS.TextSecondary
	Label.BackgroundTransparency = 1
	Label.Font = Constants.FONTS.Bold
	Label.TextSize = 12
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.LayoutOrder = Order
	Label.Parent = Parent
	return Label
end

function Components.CreateInlineLabel(Text: string, Parent: Instance, Width: number): TextLabel
	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.fromOffset(Width, 36)
	Label.Text = Text
	Label.TextColor3 = Constants.COLORS.TextSecondary
	Label.BackgroundTransparency = 1
	Label.Font = Constants.FONTS.Medium
	Label.TextSize = 13
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Parent
	return Label
end

function Components.CreateSectionLabel(Text: string, Parent: Instance, Order: number): TextLabel
	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, 0, 0, 24)
	Label.Text = Text
	Label.TextColor3 = Constants.COLORS.TextPrimary
	Label.BackgroundTransparency = 1
	Label.Font = Constants.FONTS.Bold
	Label.TextSize = 14
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.LayoutOrder = Order
	Label.Parent = Parent
	return Label
end

function Components.CreateTextBox(
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

function Components.CreateLabeledInput(
	LabelText: string,
	InitialValue: string,
	Parent: Instance,
	Order: number,
	OnChanged: (string) -> ()
)
	Components.CreateLabel(LabelText, Parent, Order)
	Components.CreateTextBox(InitialValue, Parent, Order + 0.1, false, OnChanged)
end

function Components.CreateButton(
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

function Components.CreateButtonRow(
	Buttons: {{Text: string, Color: Color3?, OnClick: () -> ()}},
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

	for _, ButtonData in ipairs(Buttons) do
		local Button = Instance.new("TextButton")
		Button.Size = UDim2.new(1 / #Buttons, -8 * (#Buttons - 1) / #Buttons, 1, 0)
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

function Components.CreateDropdown(
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
	ValueLabel.Text = CurrentValue
	ValueLabel.TextColor3 = Constants.COLORS.TextPrimary
	ValueLabel.BackgroundTransparency = 1
	ValueLabel.Font = Constants.FONTS.Regular
	ValueLabel.TextSize = 14
	ValueLabel.TextXAlignment = Enum.TextXAlignment.Left
	ValueLabel.Parent = Dropdown

	local Arrow = Instance.new("TextLabel")
	Arrow.Size = UDim2.fromOffset(20, 20)
	Arrow.Position = UDim2.new(1, -28, 0.5, -10)
	Arrow.Text = "▼"
	Arrow.TextColor3 = Constants.COLORS.TextSecondary
	Arrow.BackgroundTransparency = 1
	Arrow.Font = Constants.FONTS.Regular
	Arrow.TextSize = 12
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

		OptionButton.MouseEnter:Connect(function()
			if Option ~= CurrentValue then
				CreateTween(OptionButton, {BackgroundTransparency = 0, BackgroundColor3 = Constants.COLORS.PanelHover}):Play()
			end
		end)

		OptionButton.MouseLeave:Connect(function()
			if Option ~= CurrentValue then
				CreateTween(OptionButton, {BackgroundTransparency = 1}):Play()
			end
		end)

		OptionButton.MouseButton1Click:Connect(function()
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

function Components.CreateNumberInput(
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

function Components.CreateToggleButton(
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

function Components.CreateContainer(Parent: Instance, Order: number): Frame
	local Container = Instance.new("Frame")
	Container.Size = UDim2.new(1, 0, 0, 100)
	Container.BackgroundColor3 = Constants.COLORS.Card
	Container.BorderSizePixel = 0
	Container.LayoutOrder = Order
	Container.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 8)
	Corner.Parent = Container

	local Layout = Instance.new("UIListLayout")
	Layout.Padding = UDim.new(0, 8)
	Layout.Parent = Container

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, 12)
	Padding.PaddingRight = UDim.new(0, 12)
	Padding.PaddingTop = UDim.new(0, 12)
	Padding.PaddingBottom = UDim.new(0, 12)
	Padding.Parent = Container

	local function UpdateSize()
		local ContentHeight = Layout.AbsoluteContentSize.Y + 24
		if ContentHeight < 50 then
			ContentHeight = 50
		end
		Container.Size = UDim2.new(1, 0, 0, ContentHeight)
	end

	Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateSize)

	task.defer(UpdateSize)

	return Container
end

function Components.CreateCollapsibleSection(
	Title: string,
	Parent: Instance,
	Order: number,
	StartCollapsed: boolean?
): (Frame, Frame)
	local Section = Instance.new("Frame")
	Section.Size = UDim2.new(1, 0, 0, 36)
	Section.BackgroundTransparency = 1
	Section.LayoutOrder = Order
	Section.Parent = Parent

	local Layout = Instance.new("UIListLayout")
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Padding = UDim.new(0, 6)
	Layout.Parent = Section

	local Header = Instance.new("TextButton")
	Header.Size = UDim2.new(1, 0, 0, 32)
	Header.BackgroundColor3 = Constants.COLORS.PanelHover
	Header.BorderSizePixel = 0
	Header.Text = ""
	Header.AutoButtonColor = false
	Header.LayoutOrder = 1
	Header.Parent = Section

	local HeaderCorner = Instance.new("UICorner")
	HeaderCorner.CornerRadius = UDim.new(0, 6)
	HeaderCorner.Parent = Header

	local Arrow = Instance.new("TextLabel")
	Arrow.Size = UDim2.fromOffset(20, 20)
	Arrow.Position = UDim2.fromOffset(8, 6)
	Arrow.Text = "▼"
	Arrow.TextColor3 = Constants.COLORS.TextSecondary
	Arrow.BackgroundTransparency = 1
	Arrow.Font = Constants.FONTS.Regular
	Arrow.TextSize = 12
	Arrow.Rotation = StartCollapsed and -90 or 0
	Arrow.Parent = Header

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Size = UDim2.new(1, -36, 1, 0)
	TitleLabel.Position = UDim2.fromOffset(32, 0)
	TitleLabel.Text = Title
	TitleLabel.TextColor3 = Constants.COLORS.TextPrimary
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Font = Constants.FONTS.Medium
	TitleLabel.TextSize = 14
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.Parent = Header

	local Content = Instance.new("Frame")
	Content.Size = UDim2.fromScale(1, 0)
	Content.BackgroundTransparency = 1
	Content.Visible = not StartCollapsed
	Content.LayoutOrder = 2
	Content.Parent = Section

	local ContentLayout = Instance.new("UIListLayout")
	ContentLayout.Padding = UDim.new(0, 6)
	ContentLayout.Parent = Content

	local function UpdateSizes()
		local ContentHeight = ContentLayout.AbsoluteContentSize.Y
		Content.Size = UDim2.new(1, 0, 0, ContentHeight)
		Section.Size = UDim2.new(1, 0, 0, 38 + (Content.Visible and ContentHeight or 0))
	end

	ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateSizes)

	task.defer(UpdateSizes)

	Header.MouseEnter:Connect(function()
		CreateTween(Header, {BackgroundColor3 = Constants.COLORS.Panel}):Play()
	end)

	Header.MouseLeave:Connect(function()
		CreateTween(Header, {BackgroundColor3 = Constants.COLORS.PanelHover}):Play()
	end)

	Header.MouseButton1Click:Connect(function()
		Content.Visible = not Content.Visible
		CreateTween(Arrow, {Rotation = Content.Visible and 0 or -90}):Play()
		UpdateSizes()
	end)

	return Section, Content
end

return Components