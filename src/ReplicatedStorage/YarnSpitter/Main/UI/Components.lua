--!strict
local Constants = require(script.Parent.Parent.Constants)

local Components = {}

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
	Label.Size = UDim2.new(0, Width, 1, 0)
	Label.Text = Text
	Label.TextColor3 = Constants.COLORS.TextSecondary
	Label.BackgroundTransparency = 1
	Label.Font = Constants.FONTS.Medium
	Label.TextSize = 13
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Parent

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, 8)
	Padding.Parent = Label

	return Label
end

function Components.CreateLabeledInput(LabelText: string, InitialText: string, Parent: Instance, Order: number, OnChanged: (string) -> ()): Frame
	local Container = Instance.new("Frame")
	Container.Size = UDim2.new(1, 0, 0, Constants.SIZES.InputHeight)
	Container.BackgroundTransparency = 1
	Container.LayoutOrder = Order
	Container.Parent = Parent

	Components.CreateInlineLabel(LabelText, Container, 100)

	local Box = Instance.new("TextBox")
	Box.Size = UDim2.new(1, -105, 1, 0)
	Box.Position = UDim2.fromOffset(105, 0)
	Box.Text = InitialText
	Box.TextColor3 = Constants.COLORS.TextPrimary
	Box.BackgroundColor3 = Constants.COLORS.InputBackground
	Box.BorderSizePixel = 1
	Box.BorderColor3 = Constants.COLORS.InputBorder
	Box.Font = Constants.FONTS.Regular
	Box.TextSize = 13
	Box.TextXAlignment = Enum.TextXAlignment.Left
	Box.ClearTextOnFocus = false
	Box.Parent = Container

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 4)
	Corner.Parent = Box

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, 8)
	Padding.PaddingRight = UDim.new(0, 8)
	Padding.Parent = Box

	Box.Focused:Connect(function()
		Box.BorderColor3 = Constants.COLORS.Primary
		Box.BorderSizePixel = 2
	end)

	Box.FocusLost:Connect(function()
		Box.BorderColor3 = Constants.COLORS.InputBorder
		Box.BorderSizePixel = 1
		OnChanged(Box.Text)
	end)

	return Container
end

function Components.CreateTextBox(InitialText: string, Parent: Instance, Order: number, MultiLine: boolean, OnChanged: (string) -> ()): TextBox
	local Height = MultiLine and 70 or Constants.SIZES.InputHeight

	local Box = Instance.new("TextBox")
	Box.Size = UDim2.new(1, 0, 0, Height)
	Box.Text = InitialText
	Box.TextColor3 = Constants.COLORS.TextPrimary
	Box.BackgroundColor3 = Constants.COLORS.InputBackground
	Box.BorderSizePixel = 1
	Box.BorderColor3 = Constants.COLORS.InputBorder
	Box.Font = Constants.FONTS.Regular
	Box.TextSize = 13
	Box.TextXAlignment = Enum.TextXAlignment.Left
	Box.TextYAlignment = MultiLine and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
	Box.TextWrapped = MultiLine
	Box.MultiLine = MultiLine
	Box.ClearTextOnFocus = false
	Box.LayoutOrder = Order
	Box.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 4)
	Corner.Parent = Box

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, 8)
	Padding.PaddingRight = UDim.new(0, 8)
	Padding.PaddingTop = UDim.new(0, MultiLine and 8 or 0)
	Padding.Parent = Box

	Box.Focused:Connect(function()
		Box.BorderColor3 = Constants.COLORS.Primary
		Box.BorderSizePixel = 2
	end)

	Box.FocusLost:Connect(function()
		Box.BorderColor3 = Constants.COLORS.InputBorder
		Box.BorderSizePixel = 1
		OnChanged(Box.Text)
	end)

	return Box
end

function Components.CreateButton(Text: string, Parent: Instance, Order: number, Color: Color3?, OnClick: () -> ()): TextButton
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(1, 0, 0, 28)
	Button.Text = Text
	Button.TextColor3 = Constants.COLORS.TextPrimary
	Button.BackgroundColor3 = Color or Constants.COLORS.Primary
	Button.Font = Constants.FONTS.Medium
	Button.TextSize = 13
	Button.BorderSizePixel = 0
	Button.AutoButtonColor = false
	Button.LayoutOrder = Order
	Button.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 4)
	Corner.Parent = Button

	local OriginalColor = Color or Constants.COLORS.Primary
	local HoverColor = Constants.COLORS.PrimaryHover

	if Color == Constants.COLORS.Success then
		HoverColor = Constants.COLORS.SuccessHover
	elseif Color == Constants.COLORS.Danger then
		HoverColor = Constants.COLORS.DangerHover
	elseif Color == Constants.COLORS.Accent then
		HoverColor = Constants.COLORS.AccentHover
	end

	Button.MouseEnter:Connect(function()
		Button.BackgroundColor3 = HoverColor
	end)

	Button.MouseLeave:Connect(function()
		Button.BackgroundColor3 = OriginalColor
	end)

	Button.MouseButton1Click:Connect(OnClick)

	return Button
end

function Components.CreateButtonRow(Buttons: {{Text: string, Color: Color3?, OnClick: () -> ()}}, Parent: Instance, Order: number): Frame
	local Row = Instance.new("Frame")
	Row.Size = UDim2.new(1, 0, 0, 28)
	Row.BackgroundTransparency = 1
	Row.LayoutOrder = Order
	Row.Parent = Parent

	local Layout = Instance.new("UIListLayout")
	Layout.FillDirection = Enum.FillDirection.Horizontal
	Layout.Padding = UDim.new(0, 6)
	Layout.Parent = Row

	for _, ButtonData in ipairs(Buttons) do
		local Button = Instance.new("TextButton")
		Button.Size = UDim2.new(1 / #Buttons, -6 * (#Buttons - 1) / #Buttons, 1, 0)
		Button.Text = ButtonData.Text
		Button.TextColor3 = Constants.COLORS.TextPrimary
		Button.BackgroundColor3 = ButtonData.Color or Constants.COLORS.Primary
		Button.Font = Constants.FONTS.Medium
		Button.TextSize = 13
		Button.BorderSizePixel = 0
		Button.AutoButtonColor = false
		Button.Parent = Row

		local Corner = Instance.new("UICorner")
		Corner.CornerRadius = UDim.new(0, 4)
		Corner.Parent = Button

		local OriginalColor = ButtonData.Color or Constants.COLORS.Primary
		local HoverColor = Constants.COLORS.PrimaryHover

		if ButtonData.Color == Constants.COLORS.Success then
			HoverColor = Constants.COLORS.SuccessHover
		elseif ButtonData.Color == Constants.COLORS.Danger then
			HoverColor = Constants.COLORS.DangerHover
		end

		Button.MouseEnter:Connect(function()
			Button.BackgroundColor3 = HoverColor
		end)

		Button.MouseLeave:Connect(function()
			Button.BackgroundColor3 = OriginalColor
		end)

		Button.MouseButton1Click:Connect(ButtonData.OnClick)
	end

	return Row
end

function Components.CreateDropdown(Options: {string}, CurrentValue: string, Parent: Instance, Order: number, OnChanged: (string) -> ()): TextButton
	local Dropdown = Instance.new("TextButton")
	Dropdown.Size = UDim2.new(1, 0, 0, Constants.SIZES.InputHeight)
	Dropdown.Text = CurrentValue .. " ▼"
	Dropdown.TextColor3 = Constants.COLORS.TextPrimary
	Dropdown.BackgroundColor3 = Constants.COLORS.InputBackground
	Dropdown.Font = Constants.FONTS.Regular
	Dropdown.TextSize = 13
	Dropdown.BorderSizePixel = 1
	Dropdown.BorderColor3 = Constants.COLORS.InputBorder
	Dropdown.AutoButtonColor = false
	Dropdown.LayoutOrder = Order
	Dropdown.ZIndex = 10
	Dropdown.Parent = Parent

	local DropdownCorner = Instance.new("UICorner")
	DropdownCorner.CornerRadius = UDim.new(0, 4)
	DropdownCorner.Parent = Dropdown

	local DropdownPadding = Instance.new("UIPadding")
	DropdownPadding.PaddingLeft = UDim.new(0, 8)
	DropdownPadding.Parent = Dropdown

	local DropdownContainer = Instance.new("Frame")
	DropdownContainer.Size = UDim2.new(1, 0, 0, Constants.SIZES.InputHeight)
	DropdownContainer.BackgroundTransparency = 1
	DropdownContainer.LayoutOrder = Order + 0.5
	DropdownContainer.ZIndex = 100
	DropdownContainer.Parent = Parent

	local OptionsFrame = Instance.new("ScrollingFrame")
	OptionsFrame.Size = UDim2.new(1, 0, 0, math.min(#Options * 26, 156))
	OptionsFrame.BackgroundColor3 = Constants.COLORS.Panel
	OptionsFrame.BorderSizePixel = 1
	OptionsFrame.BorderColor3 = Constants.COLORS.Border
	OptionsFrame.Visible = false
	OptionsFrame.ZIndex = 101
	OptionsFrame.ScrollBarThickness = 4
	OptionsFrame.CanvasSize = UDim2.fromOffset(0, #Options * 26)
	OptionsFrame.Parent = DropdownContainer

	local OptionsCorner = Instance.new("UICorner")
	OptionsCorner.CornerRadius = UDim.new(0, 4)
	OptionsCorner.Parent = OptionsFrame

	local OptionsLayout = Instance.new("UIListLayout")
	OptionsLayout.Padding = UDim.new(0, 1)
	OptionsLayout.Parent = OptionsFrame

	local OptionsPadding = Instance.new("UIPadding")
	OptionsPadding.PaddingLeft = UDim.new(0, 2)
	OptionsPadding.PaddingRight = UDim.new(0, 2)
	OptionsPadding.PaddingTop = UDim.new(0, 2)
	OptionsPadding.PaddingBottom = UDim.new(0, 2)
	OptionsPadding.Parent = OptionsFrame

	for _, Option in ipairs(Options) do
		local OptionButton = Instance.new("TextButton")
		OptionButton.Size = UDim2.new(1, 0, 0, 24)
		OptionButton.Text = Option
		OptionButton.TextColor3 = Constants.COLORS.TextPrimary
		OptionButton.BackgroundColor3 = Option == CurrentValue and Constants.COLORS.SelectedBg or Color3.fromRGB(0, 0, 0)
		OptionButton.BackgroundTransparency = Option == CurrentValue and 0 or 1
		OptionButton.Font = Constants.FONTS.Regular
		OptionButton.TextSize = 13
		OptionButton.BorderSizePixel = 0
		OptionButton.TextXAlignment = Enum.TextXAlignment.Left
		OptionButton.AutoButtonColor = false
		OptionButton.ZIndex = 102
		OptionButton.Parent = OptionsFrame

		local OptionCorner = Instance.new("UICorner")
		OptionCorner.CornerRadius = UDim.new(0, 3)
		OptionCorner.Parent = OptionButton

		local OptionPadding = Instance.new("UIPadding")
		OptionPadding.PaddingLeft = UDim.new(0, 8)
		OptionPadding.Parent = OptionButton

		OptionButton.MouseEnter:Connect(function()
			if Option ~= CurrentValue then
				OptionButton.BackgroundTransparency = 0
				OptionButton.BackgroundColor3 = Constants.COLORS.PanelHover
			end
		end)

		OptionButton.MouseLeave:Connect(function()
			if Option ~= CurrentValue then
				OptionButton.BackgroundTransparency = 1
			end
		end)

		OptionButton.MouseButton1Click:Connect(function()
			Dropdown.Text = Option .. " ▼"
			OptionsFrame.Visible = false
			Dropdown.BorderColor3 = Constants.COLORS.InputBorder
			Dropdown.BorderSizePixel = 1
			OnChanged(Option)
		end)
	end

	Dropdown.MouseButton1Click:Connect(function()
		OptionsFrame.Visible = not OptionsFrame.Visible
		if OptionsFrame.Visible then
			Dropdown.BorderColor3 = Constants.COLORS.Primary
			Dropdown.BorderSizePixel = 2
		else
			Dropdown.BorderColor3 = Constants.COLORS.InputBorder
			Dropdown.BorderSizePixel = 1
		end
	end)

	return Dropdown
end

function Components.CreateNumberInput(InitialValue: number, Parent: Instance, Order: number, OnChanged: (number) -> ()): Frame
	local Container = Instance.new("Frame")
	Container.Size = UDim2.new(1, 0, 0, Constants.SIZES.InputHeight)
	Container.BackgroundTransparency = 1
	Container.LayoutOrder = Order
	Container.Parent = Parent

	local MinusButton = Instance.new("TextButton")
	MinusButton.Size = UDim2.new(0, 28, 1, 0)
	MinusButton.Position = UDim2.fromScale(0, 0)
	MinusButton.Text = "-"
	MinusButton.TextColor3 = Constants.COLORS.TextPrimary
	MinusButton.BackgroundColor3 = Constants.COLORS.ButtonBackground
	MinusButton.Font = Constants.FONTS.Bold
	MinusButton.TextSize = 16
	MinusButton.BorderSizePixel = 0
	MinusButton.AutoButtonColor = false
	MinusButton.Parent = Container

	local MinusCorner = Instance.new("UICorner")
	MinusCorner.CornerRadius = UDim.new(0, 4)
	MinusCorner.Parent = MinusButton

	local NumberBox = Instance.new("TextBox")
	NumberBox.Size = UDim2.new(1, -60, 1, 0)
	NumberBox.Position = UDim2.fromOffset(30, 0)
	NumberBox.Text = tostring(InitialValue)
	NumberBox.TextColor3 = Constants.COLORS.TextPrimary
	NumberBox.BackgroundColor3 = Constants.COLORS.InputBackground
	NumberBox.BorderSizePixel = 1
	NumberBox.BorderColor3 = Constants.COLORS.InputBorder
	NumberBox.Font = Constants.FONTS.Regular
	NumberBox.TextSize = 13
	NumberBox.Parent = Container

	local NumberCorner = Instance.new("UICorner")
	NumberCorner.CornerRadius = UDim.new(0, 4)
	NumberCorner.Parent = NumberBox

	local PlusButton = Instance.new("TextButton")
	PlusButton.Size = UDim2.new(0, 28, 1, 0)
	PlusButton.Position = UDim2.new(1, -28, 0, 0)
	PlusButton.Text = "+"
	PlusButton.TextColor3 = Constants.COLORS.TextPrimary
	PlusButton.BackgroundColor3 = Constants.COLORS.ButtonBackground
	PlusButton.Font = Constants.FONTS.Bold
	PlusButton.TextSize = 16
	PlusButton.BorderSizePixel = 0
	PlusButton.AutoButtonColor = false
	PlusButton.Parent = Container

	local PlusCorner = Instance.new("UICorner")
	PlusCorner.CornerRadius = UDim.new(0, 4)
	PlusCorner.Parent = PlusButton

	MinusButton.MouseEnter:Connect(function()
		MinusButton.BackgroundColor3 = Constants.COLORS.PanelHover
	end)

	MinusButton.MouseLeave:Connect(function()
		MinusButton.BackgroundColor3 = Constants.COLORS.ButtonBackground
	end)

	PlusButton.MouseEnter:Connect(function()
		PlusButton.BackgroundColor3 = Constants.COLORS.PanelHover
	end)

	PlusButton.MouseLeave:Connect(function()
		PlusButton.BackgroundColor3 = Constants.COLORS.ButtonBackground
	end)

	MinusButton.MouseButton1Click:Connect(function()
		local Current = tonumber(NumberBox.Text) or InitialValue
		NumberBox.Text = tostring(math.max(1, Current - 1))
		OnChanged(tonumber(NumberBox.Text) or InitialValue)
	end)

	PlusButton.MouseButton1Click:Connect(function()
		local Current = tonumber(NumberBox.Text) or InitialValue
		NumberBox.Text = tostring(math.min(99, Current + 1))
		OnChanged(tonumber(NumberBox.Text) or InitialValue)
	end)

	NumberBox.FocusLost:Connect(function()
		local Value = tonumber(NumberBox.Text)
		if Value then
			NumberBox.Text = tostring(math.clamp(Value, 1, 99))
			OnChanged(tonumber(NumberBox.Text) or InitialValue)
		else
			NumberBox.Text = tostring(InitialValue)
		end
	end)

	return Container
end

function Components.CreateToggleButton(Text: string, IsToggled: boolean, Parent: Instance, Order: number, OnToggle: (boolean) -> ()): TextButton
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(1, 0, 0, 28)
	Button.Text = IsToggled and "✓ " .. Text or "☐ " .. Text
	Button.TextColor3 = Constants.COLORS.TextPrimary
	Button.BackgroundColor3 = IsToggled and Constants.COLORS.Primary or Constants.COLORS.Unselected
	Button.BorderSizePixel = 0
	Button.Font = Constants.FONTS.Medium
	Button.TextSize = 13
	Button.AutoButtonColor = false
	Button.LayoutOrder = Order
	Button.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 4)
	Corner.Parent = Button

	Button.MouseButton1Click:Connect(function()
		IsToggled = not IsToggled
		Button.Text = IsToggled and "✓ " .. Text or "☐ " .. Text
		Button.BackgroundColor3 = IsToggled and Constants.COLORS.Primary or Constants.COLORS.Unselected
		OnToggle(IsToggled)
	end)

	return Button
end

function Components.CreateContainer(Parent: Instance, Order: number): Frame
	local Container = Instance.new("Frame")
	Container.Size = UDim2.new(1, 0, 0, 100)
	Container.BackgroundColor3 = Constants.COLORS.Panel
	Container.BorderSizePixel = 0
	Container.LayoutOrder = Order
	Container.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 5)
	Corner.Parent = Container

	local Layout = Instance.new("UIListLayout")
	Layout.Padding = UDim.new(0, 6)
	Layout.Parent = Container

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, 10)
	Padding.PaddingRight = UDim.new(0, 10)
	Padding.PaddingTop = UDim.new(0, 10)
	Padding.PaddingBottom = UDim.new(0, 10)
	Padding.Parent = Container

	Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		Container.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y + 20)
	end)

	return Container
end

function Components.CreateCollapsibleSection(Title: string, Parent: Instance, Order: number, StartCollapsed: boolean?): (Frame, Frame)
	local Section = Instance.new("Frame")
	Section.Size = UDim2.new(1, 0, 0, 30)
	Section.BackgroundTransparency = 1
	Section.LayoutOrder = Order
	Section.Parent = Parent

	local Layout = Instance.new("UIListLayout")
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Padding = UDim.new(0, 4)
	Layout.Parent = Section

	local Header = Instance.new("TextButton")
	Header.Size = UDim2.new(1, 0, 0, 26)
	Header.BackgroundColor3 = Constants.COLORS.PanelHover
	Header.BorderSizePixel = 0
	Header.Text = (StartCollapsed and "▶ " or "▼ ") .. Title
	Header.TextColor3 = Constants.COLORS.TextSecondary
	Header.Font = Constants.FONTS.Bold
	Header.TextSize = 13
	Header.TextXAlignment = Enum.TextXAlignment.Left
	Header.AutoButtonColor = false
	Header.LayoutOrder = 1
	Header.Parent = Section

	local HeaderCorner = Instance.new("UICorner")
	HeaderCorner.CornerRadius = UDim.new(0, 4)
	HeaderCorner.Parent = Header

	local HeaderPadding = Instance.new("UIPadding")
	HeaderPadding.PaddingLeft = UDim.new(0, 8)
	HeaderPadding.Parent = Header

	local Content = Instance.new("Frame")
	Content.Size = UDim2.fromScale(1, 0)
	Content.BackgroundTransparency = 1
	Content.Visible = not StartCollapsed
	Content.LayoutOrder = 2
	Content.Parent = Section

	local ContentLayout = Instance.new("UIListLayout")
	ContentLayout.Padding = UDim.new(0, 6)
	ContentLayout.Parent = Content

	Header.MouseEnter:Connect(function()
		Header.BackgroundColor3 = Constants.COLORS.Panel
	end)

	Header.MouseLeave:Connect(function()
		Header.BackgroundColor3 = Constants.COLORS.PanelHover
	end)

	ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		Content.Size = UDim2.new(1, 0, 0, ContentLayout.AbsoluteContentSize.Y)
		Section.Size = UDim2.new(1, 0, 0, Header.Size.Y.Offset + (Content.Visible and Content.Size.Y.Offset + 4 or 0))
	end)

	Header.MouseButton1Click:Connect(function()
		Content.Visible = not Content.Visible
		Header.Text = (Content.Visible and "▼ " or "▶ ") .. Title
		Section.Size = UDim2.new(1, 0, 0, Header.Size.Y.Offset + (Content.Visible and Content.Size.Y.Offset + 4 or 0))
	end)

	return Section, Content
end

return Components