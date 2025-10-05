--!strict
local Constants = require(script.Parent.Parent.Constants)

local Components = {}

function Components.CreateLabel(Text: string, Parent: Instance, Order: number): TextLabel
	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, 0, 0, Constants.SIZES.LabelHeight)
	Label.Text = Text
	Label.TextColor3 = Constants.COLORS.TextSecondary
	Label.BackgroundTransparency = 1
	Label.Font = Constants.FONTS.Bold
	Label.TextSize = Constants.TEXT_SIZES.Medium
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.LayoutOrder = Order
	Label.Parent = Parent
	return Label
end

function Components.CreateTextBox(InitialText: string, Parent: Instance, Order: number, MultiLine: boolean, OnChanged: (string) -> ()): TextBox
	local Box = Instance.new("TextBox")
	Box.Size = UDim2.new(1, 0, 0, MultiLine and Constants.SIZES.InputHeightMultiLine or Constants.SIZES.InputHeight)
	Box.Text = InitialText
	Box.TextColor3 = Constants.COLORS.TextPrimary
	Box.BackgroundColor3 = Constants.COLORS.InputBackground
	Box.BorderSizePixel = Constants.SIZES.BorderWidth
	Box.BorderColor3 = Constants.COLORS.InputBorder
	Box.Font = Constants.FONTS.Regular
	Box.TextSize = Constants.TEXT_SIZES.Normal
	Box.TextXAlignment = Enum.TextXAlignment.Left
	Box.TextYAlignment = MultiLine and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
	Box.TextWrapped = MultiLine
	Box.MultiLine = MultiLine
	Box.ClearTextOnFocus = false
	Box.LayoutOrder = Order
	Box.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, Constants.SIZES.CornerRadius)
	Corner.Parent = Box

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, Constants.SIZES.PaddingSmall + 2)
	Padding.PaddingRight = UDim.new(0, Constants.SIZES.PaddingSmall + 2)
	Padding.PaddingTop = UDim.new(0, Constants.SIZES.PaddingSmall + 2)
	Padding.PaddingBottom = UDim.new(0, Constants.SIZES.PaddingSmall)
	Padding.Parent = Box

	Box:GetPropertyChangedSignal("Text"):Connect(function()
		if Box:IsFocused() then
			Box.BorderColor3 = Constants.COLORS.Primary
		end
	end)

	Box.Focused:Connect(function()
		Box.BorderColor3 = Constants.COLORS.Primary
	end)

	Box.FocusLost:Connect(function()
		Box.BorderColor3 = Constants.COLORS.InputBorder
		OnChanged(Box.Text)
	end)

	return Box
end

function Components.CreateButton(Text: string, Parent: Instance, Order: number, Color: Color3?, OnClick: () -> ()): TextButton
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(1, 0, 0, Constants.SIZES.ButtonHeight)
	Button.Text = Text
	Button.TextColor3 = Constants.COLORS.TextPrimary
	Button.BackgroundColor3 = Color or Constants.COLORS.Primary
	Button.Font = Constants.FONTS.Medium
	Button.TextSize = Constants.TEXT_SIZES.Medium
	Button.BorderSizePixel = 0
	Button.AutoButtonColor = false
	Button.LayoutOrder = Order
	Button.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, Constants.SIZES.CornerRadius)
	Corner.Parent = Button

	Button.MouseEnter:Connect(function()
		if Color == Constants.COLORS.Primary then
			Button.BackgroundColor3 = Constants.COLORS.PrimaryHover
		elseif Color == Constants.COLORS.Success then
			Button.BackgroundColor3 = Constants.COLORS.SuccessHover
		elseif Color == Constants.COLORS.Danger then
			Button.BackgroundColor3 = Constants.COLORS.DangerHover
		end
	end)

	Button.MouseLeave:Connect(function()
		Button.BackgroundColor3 = Color or Constants.COLORS.Primary
	end)

	Button.MouseButton1Click:Connect(OnClick)

	return Button
end

function Components.CreateDropdown(Options: {string}, CurrentValue: string, Parent: Instance, Order: number, OnChanged: (string) -> ()): TextButton
	local Dropdown = Instance.new("TextButton")
	Dropdown.Size = UDim2.new(1, 0, 0, Constants.SIZES.InputHeight)
	Dropdown.Text = CurrentValue .. " ▼"
	Dropdown.TextColor3 = Constants.COLORS.TextPrimary
	Dropdown.BackgroundColor3 = Constants.COLORS.InputBackground
	Dropdown.Font = Constants.FONTS.Regular
	Dropdown.TextSize = Constants.TEXT_SIZES.Normal
	Dropdown.LayoutOrder = Order
	Dropdown.ZIndex = 10
	Dropdown.Parent = Parent

	local DropdownContainer = Instance.new("Frame")
	DropdownContainer.Size = UDim2.new(1, 0, 0, Constants.SIZES.InputHeight)
	DropdownContainer.BackgroundTransparency = 1
	DropdownContainer.LayoutOrder = Order + 0.5
	DropdownContainer.ZIndex = 11
	DropdownContainer.Parent = Parent

	local OptionsFrame = Instance.new("ScrollingFrame")
	OptionsFrame.Size = UDim2.new(1, 0, 0, math.min(#Options * 25, 150))
	OptionsFrame.BackgroundColor3 = Constants.COLORS.InputBackground
	OptionsFrame.BorderSizePixel = 1
	OptionsFrame.BorderColor3 = Constants.COLORS.Border
	OptionsFrame.Visible = false
	OptionsFrame.ZIndex = 12
	OptionsFrame.ScrollBarThickness = Constants.SIZES.ScrollBarThicknessThin
	OptionsFrame.CanvasSize = UDim2.new(0, 0, 0, #Options * 25)
	OptionsFrame.ClipsDescendants = false
	OptionsFrame.Parent = DropdownContainer

	local OptionsLayout = Instance.new("UIListLayout")
	OptionsLayout.Parent = OptionsFrame

	local OptionButtons = {}

	for _, Option in ipairs(Options) do
		local OptionButton = Instance.new("TextButton")
		OptionButton.Size = UDim2.new(1, 0, 0, 25)
		OptionButton.Text = Option
		OptionButton.TextColor3 = Constants.COLORS.TextPrimary
		OptionButton.BackgroundColor3 = Option == CurrentValue and Constants.COLORS.Selected or Constants.COLORS.ButtonBackground
		OptionButton.Font = Constants.FONTS.Regular
		OptionButton.TextSize = Constants.TEXT_SIZES.Small
		OptionButton.BorderSizePixel = 0
		OptionButton.TextXAlignment = Enum.TextXAlignment.Left
		OptionButton.ZIndex = 13
		OptionButton.Parent = OptionsFrame

		local OptionPadding = Instance.new("UIPadding")
		OptionPadding.PaddingLeft = UDim.new(0, Constants.SIZES.PaddingSmall)
		OptionPadding.Parent = OptionButton

		OptionButtons[Option] = OptionButton

		OptionButton.MouseButton1Click:Connect(function()
			for _, Btn in pairs(OptionButtons) do
				Btn.BackgroundColor3 = Constants.COLORS.ButtonBackground
			end

			OptionButton.BackgroundColor3 = Constants.COLORS.Selected
			Dropdown.Text = Option .. " ▼"
			OptionsFrame.Visible = false
			OnChanged(Option)
		end)
	end

	Dropdown.MouseButton1Click:Connect(function()
		OptionsFrame.Visible = not OptionsFrame.Visible
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
	MinusButton.Size = UDim2.new(0, 30, 1, 0)
	MinusButton.Position = UDim2.fromScale(0, 0)
	MinusButton.Text = "-"
	MinusButton.TextColor3 = Constants.COLORS.TextPrimary
	MinusButton.BackgroundColor3 = Constants.COLORS.ButtonBackground
	MinusButton.Font = Constants.FONTS.Bold
	MinusButton.TextSize = Constants.TEXT_SIZES.ExtraLarge
	MinusButton.Parent = Container

	local NumberBox = Instance.new("TextBox")
	NumberBox.Size = UDim2.new(1, -70, 1, 0)
	NumberBox.Position = UDim2.new(0, 35, 0, 0)
	NumberBox.Text = tostring(InitialValue)
	NumberBox.TextColor3 = Constants.COLORS.TextPrimary
	NumberBox.BackgroundColor3 = Constants.COLORS.InputBackground
	NumberBox.Font = Constants.FONTS.Regular
	NumberBox.TextSize = Constants.TEXT_SIZES.Normal
	NumberBox.Parent = Container

	local PlusButton = Instance.new("TextButton")
	PlusButton.Size = UDim2.new(0, 30, 1, 0)
	PlusButton.Position = UDim2.new(1, -30, 0, 0)
	PlusButton.Text = "+"
	PlusButton.TextColor3 = Constants.COLORS.TextPrimary
	PlusButton.BackgroundColor3 = Constants.COLORS.ButtonBackground
	PlusButton.Font = Constants.FONTS.Bold
	PlusButton.TextSize = Constants.TEXT_SIZES.ExtraLarge
	PlusButton.Parent = Container

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
	Button.Size = UDim2.new(1, 0, 0, Constants.SIZES.ButtonHeight)
	Button.Text = IsToggled and "✓ " .. Text or "☐ " .. Text
	Button.TextColor3 = Constants.COLORS.TextPrimary
	Button.BackgroundColor3 = IsToggled and Constants.COLORS.Primary or Constants.COLORS.Unselected
	Button.BorderSizePixel = 0
	Button.Font = Constants.FONTS.Medium
	Button.TextSize = Constants.TEXT_SIZES.Normal
	Button.AutoButtonColor = false
	Button.LayoutOrder = Order
	Button.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, Constants.SIZES.CornerRadius)
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
	Container.BorderSizePixel = Constants.SIZES.BorderWidth
	Container.BorderColor3 = Constants.COLORS.Border
	Container.LayoutOrder = Order
	Container.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, Constants.SIZES.CornerRadius)
	Corner.Parent = Container

	local Layout = Instance.new("UIListLayout")
	Layout.Padding = UDim.new(0, Constants.SIZES.PaddingSmall)
	Layout.Parent = Container

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, Constants.SIZES.Padding)
	Padding.PaddingRight = UDim.new(0, Constants.SIZES.Padding)
	Padding.PaddingTop = UDim.new(0, Constants.SIZES.Padding)
	Padding.PaddingBottom = UDim.new(0, Constants.SIZES.Padding)
	Padding.Parent = Container

	Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		Container.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y + Constants.SIZES.Padding * 2)
	end)

	return Container
end

function Components.CreateCollapsibleSection(Title: string, Parent: Instance, Order: number, StartCollapsed: boolean?): (Frame, Frame)
	local Section = Instance.new("Frame")
	Section.Size = UDim2.new(1, 0, 0, 40)
	Section.BackgroundTransparency = 1
	Section.LayoutOrder = Order
	Section.Parent = Parent

	local Layout = Instance.new("UIListLayout")
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Padding = UDim.new(0, Constants.SIZES.PaddingSmall)
	Layout.Parent = Section

	local Header = Instance.new("TextButton")
	Header.Size = UDim2.new(1, 0, 0, 32)
	Header.BackgroundColor3 = Constants.COLORS.PanelHover
	Header.BorderSizePixel = 0
	Header.Text = (StartCollapsed and "▶ " or "▼ ") .. Title
	Header.TextColor3 = Constants.COLORS.TextSecondary
	Header.Font = Constants.FONTS.Bold
	Header.TextSize = Constants.TEXT_SIZES.Medium
	Header.TextXAlignment = Enum.TextXAlignment.Left
	Header.AutoButtonColor = false
	Header.LayoutOrder = 1
	Header.Parent = Section

	local HeaderCorner = Instance.new("UICorner")
	HeaderCorner.CornerRadius = UDim.new(0, Constants.SIZES.CornerRadius)
	HeaderCorner.Parent = Header

	local HeaderPadding = Instance.new("UIPadding")
	HeaderPadding.PaddingLeft = UDim.new(0, Constants.SIZES.Padding)
	HeaderPadding.Parent = Header

	local Content = Instance.new("Frame")
	Content.Size = UDim2.new(1, 0, 0, 0)
	Content.BackgroundTransparency = 1
	Content.Visible = not StartCollapsed
	Content.LayoutOrder = 2
	Content.Parent = Section

	local ContentLayout = Instance.new("UIListLayout")
	ContentLayout.Padding = UDim.new(0, Constants.SIZES.PaddingSmall)
	ContentLayout.Parent = Content

	ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		Content.Size = UDim2.new(1, 0, 0, ContentLayout.AbsoluteContentSize.Y)
		Section.Size = UDim2.new(1, 0, 0, Header.Size.Y.Offset + (Content.Visible and Content.Size.Y.Offset + Constants.SIZES.PaddingSmall or 0))
	end)

	Header.MouseButton1Click:Connect(function()
		Content.Visible = not Content.Visible
		Header.Text = (Content.Visible and "▼ " or "▶ ") .. Title
		Section.Size = UDim2.new(1, 0, 0, Header.Size.Y.Offset + (Content.Visible and Content.Size.Y.Offset + Constants.SIZES.PaddingSmall or 0))
	end)

	return Section, Content
end

return Components