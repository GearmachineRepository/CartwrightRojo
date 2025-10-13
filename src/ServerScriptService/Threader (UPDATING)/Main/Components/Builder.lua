--!strict
--local Label = require(script.Parent.Primitives.Label)
local Button = require(script.Parent.Primitives.Button)
local TextBox = require(script.Parent.Primitives.TextBox)
local Dropdown = require(script.Parent.Primitives.Dropdown)
local NumberInput = require(script.Parent.Primitives.NumberInput)
--local Container = require(script.Parent.Primitives.Container)
local CollapsibleSection = require(script.Parent.Compound.CollapsibleSection)
local LabeledInput = require(script.Parent.Compound.LabeledInput)
local ButtonRow = require(script.Parent.Compound.ButtonRow)
local ToggleButton = require(script.Parent.Compound.ToggleButton)

local Colors = require(script.Parent.Parent.Theme.Colors)
local Fonts = require(script.Parent.Parent.Theme.Fonts)
local Spacing = require(script.Parent.Parent.Theme.Spacing)

local Builder = {}

type PanelConfig = {
	Title: string?,
	Width: number?,
	Height: number?,
	Children: {Instance}?
}

type LabelConfig = {
	Text: string?,
	Bold: boolean?,
	Color: Color3?
}

type TextBoxConfig = {
	Value: string?,
	PlaceholderText: string?,
	Multiline: boolean?,
	Height: number?,
	OnChanged: ((string) -> ())?
}

type ButtonConfig = {
	Text: string,
	Color: Color3?,
	Type: string?,
	OnClick: () -> ()
}

type DropdownConfig = {
	Label: string?,
	Options: {string},
	Selected: string?,
	OnSelected: (string) -> ()
}

type NumberInputConfig = {
	Label: string?,
	Value: number?,
	Min: number?,
	Max: number?,
	OnChanged: ((number) -> ())?
}

type ToggleConfig = {
	Text: string,
	Default: boolean?,
	OnToggle: (boolean) -> ()
}

type CollapsibleConfig = {
	Title: string,
	StartCollapsed: boolean?,
	Children: {Instance}?
}

-- Container Builders
function Builder.Panel(Config: PanelConfig): Frame
	local Panel = Instance.new("Frame")
	Panel.Size = UDim2.fromOffset(Config.Width or 400, Config.Height or 500)
	Panel.BackgroundColor3 = Colors.Background
	Panel.BorderSizePixel = 0

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 8)
	Corner.Parent = Panel

	local Layout = Instance.new("UIListLayout")
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Padding = UDim.new(0, Spacing.Gap)
	Layout.Parent = Panel

	local PanelPadding = Instance.new("UIPadding")
	PanelPadding.PaddingLeft = UDim.new(0, Spacing.PanelPadding)
	PanelPadding.PaddingRight = UDim.new(0, Spacing.PanelPadding)
	PanelPadding.PaddingTop = UDim.new(0, Spacing.PanelPadding)
	PanelPadding.PaddingBottom = UDim.new(0, Spacing.PanelPadding)
	PanelPadding.Parent = Panel

	if Config.Title then
		local TitleLabel = Instance.new("TextLabel")
		TitleLabel.Size = UDim2.new(1, 0, 0, 32)
		TitleLabel.BackgroundTransparency = 1
		TitleLabel.Text = Config.Title
		TitleLabel.TextColor3 = Colors.Text
		TitleLabel.Font = Fonts.Bold
		TitleLabel.TextSize = 18
		TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
		TitleLabel.LayoutOrder = 0
		TitleLabel.Parent = Panel
	end

	if Config.Children then
		for Index, Child in ipairs(Config.Children) do
			Child.LayoutOrder = Index
			Child.Parent = Panel
		end
	end

	return Panel
end

function Builder.Row(Children: {Instance}): Frame
	local Row = Instance.new("Frame")
	Row.Size = UDim2.new(1, 0, 0, 28)
	Row.BackgroundTransparency = 1

	local Layout = Instance.new("UIListLayout")
	Layout.FillDirection = Enum.FillDirection.Horizontal
	Layout.Padding = UDim.new(0, Spacing.Gap)
	Layout.Parent = Row

	for Index, Child in ipairs(Children) do
		Child.LayoutOrder = Index
		Child.Parent = Row
	end

	return Row
end

function Builder.Column(Children: {Instance}): Frame
	local Column = Instance.new("Frame")
	Column.Size = UDim2.fromScale(1, 0)
	Column.BackgroundTransparency = 1
	Column.AutomaticSize = Enum.AutomaticSize.Y

	local Layout = Instance.new("UIListLayout")
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Padding = UDim.new(0, Spacing.Gap)
	Layout.Parent = Column

	for Index, Child in ipairs(Children) do
		Child.LayoutOrder = Index
		Child.Parent = Column
	end

	return Column
end

-- Primitive Builders
function Builder.Label(Text: string, Config: LabelConfig?): TextLabel
	local LabelElement = Instance.new("TextLabel")
	LabelElement.Size = UDim2.new(1, 0, 0, 20)
	LabelElement.BackgroundTransparency = 1
	LabelElement.Text = Text
	LabelElement.TextColor3 = (Config and Config.Color) or Colors.Text
	LabelElement.Font = (Config and Config.Bold) and Fonts.Bold or Fonts.Regular
	LabelElement.TextSize = 14
	LabelElement.TextXAlignment = Enum.TextXAlignment.Left

	return LabelElement
end

function Builder.TextBox(Config: TextBoxConfig): TextBox
	local Parent = Instance.new("Frame")
	Parent.Size = UDim2.new(1, 0, 0, 1)
	Parent.BackgroundTransparency = 1

	if Config.Multiline then
		return TextBox.CreateMultiline(
			Config.PlaceholderText or "",
			Parent,
			Config.OnChanged,
			Config.Height
		)
	else
		return TextBox.Create(
			Config.PlaceholderText or "",
			Parent,
			Config.OnChanged
		)
	end
end

function Builder.Button(Config: ButtonConfig): TextButton
	local Parent = Instance.new("Frame")
	Parent.Size = UDim2.new(1, 0, 0, 1)
	Parent.BackgroundTransparency = 1

	local ButtonElement: TextButton

	if Config.Type == "Danger" then
		ButtonElement = Button.CreateDanger(Config.Text, Parent, Config.OnClick)
	elseif Config.Type == "Success" then
		ButtonElement = Button.CreateSuccess(Config.Text, Parent, Config.OnClick)
	else
		ButtonElement = Button.Create(Config.Text, Parent, Config.OnClick)
	end

	if Config.Color then
		ButtonElement.BackgroundColor3 = Config.Color
	end

	return ButtonElement
end

function Builder.Dropdown(Config: DropdownConfig): Frame
	local Parent = Instance.new("Frame")
	Parent.Size = UDim2.new(1, 0, 0, 1)
	Parent.BackgroundTransparency = 1

	local Container = Instance.new("Frame")
	Container.Size = UDim2.fromScale(1, 0)
	Container.BackgroundTransparency = 1
	Container.AutomaticSize = Enum.AutomaticSize.Y
	Container.Parent = Parent

	local Layout = Instance.new("UIListLayout")
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Padding = UDim.new(0, Spacing.Tiny)
	Layout.Parent = Container

	if Config.Label then
		local LabelElement = Builder.Label(Config.Label)
		LabelElement.LayoutOrder = 1
		LabelElement.Parent = Container
	end

	local DropdownElement = Dropdown.Create(
		Config.Options,
		Config.Selected or Config.Options[1],
		Container,
		Config.OnSelected,
		2
	)

	return Container
end

function Builder.NumberInput(Config: NumberInputConfig): Frame
	local Parent = Instance.new("Frame")
	Parent.Size = UDim2.new(1, 0, 0, 1)
	Parent.BackgroundTransparency = 1

	local Container = Instance.new("Frame")
	Container.Size = UDim2.fromScale(1, 0)
	Container.BackgroundTransparency = 1
	Container.AutomaticSize = Enum.AutomaticSize.Y
	Container.Parent = Parent

	local Layout = Instance.new("UIListLayout")
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Padding = UDim.new(0, Spacing.Tiny)
	Layout.Parent = Container

	if Config.Label then
		local LabelElement = Builder.Label(Config.Label)
		LabelElement.LayoutOrder = 1
		LabelElement.Parent = Container
	end

	local NumberInputElement = NumberInput.Create(
		Config.Value or 0,
		Config.Min,
		Config.Max,
		Container,
		Config.OnChanged,
		2
	)

	return Container
end

function Builder.Toggle(Config: ToggleConfig): TextButton
	local Parent = Instance.new("Frame")
	Parent.Size = UDim2.new(1, 0, 0, 1)
	Parent.BackgroundTransparency = 1

	return ToggleButton.Create(
		Config.Text,
		Parent,
		Config.OnToggle,
		Config.Default
	)
end

-- Compound Builders
function Builder.LabeledInput(Label: string, Config: TextBoxConfig): Frame
	local Parent = Instance.new("Frame")
	Parent.Size = UDim2.new(1, 0, 0, 1)
	Parent.BackgroundTransparency = 1

	return LabeledInput.Create(
		Label,
		Config.PlaceholderText or "",
		Parent,
		Config.OnChanged
	)
end

function Builder.CollapsibleSection(Config: CollapsibleConfig): Frame
	local Parent = Instance.new("Frame")
	Parent.Size = UDim2.new(1, 0, 0, 1)
	Parent.BackgroundTransparency = 1

	local SectionContainer, ContentFrame = CollapsibleSection.Create(
		Config.Title,
		Parent,
		Config.StartCollapsed
	)

	if Config.Children then
		for Index, Child in ipairs(Config.Children) do
			Child.LayoutOrder = Index
			Child.Parent = ContentFrame
		end
	end

	return SectionContainer
end

function Builder.ButtonRow(Buttons: {TextButton}): Frame
	local Row = ButtonRow.Create(Instance.new("Frame"))

	for Index, ButtonElement in ipairs(Buttons) do
		ButtonElement.LayoutOrder = Index
		ButtonElement.Parent = Row
	end

	return Row
end

-- Helper function to create a complete form
function Builder.Form(Config: {Title: string, Fields: {{Type: string, Config: any}}}): Frame
	local FormPanel = Builder.Panel({
		Title = Config.Title,
		Width = 400
	})

	for Index, Field in ipairs(Config.Fields) do
		local Element: Instance

		if Field.Type == "Label" then
			Element = Builder.Label(Field.Config.Text, Field.Config)
		elseif Field.Type == "TextBox" then
			Element = Builder.TextBox(Field.Config)
		elseif Field.Type == "Button" then
			Element = Builder.Button(Field.Config)
		elseif Field.Type == "Dropdown" then
			Element = Builder.Dropdown(Field.Config)
		elseif Field.Type == "NumberInput" then
			Element = Builder.NumberInput(Field.Config)
		elseif Field.Type == "Toggle" then
			Element = Builder.Toggle(Field.Config)
		elseif Field.Type == "LabeledInput" then
			Element = Builder.LabeledInput(Field.Config.Label, Field.Config)
		elseif Field.Type == "CollapsibleSection" then
			Element = Builder.CollapsibleSection(Field.Config)
		elseif Field.Type == "ButtonRow" then
			Element = Builder.ButtonRow(Field.Config.Buttons)
		end

		if Element then
			Element.LayoutOrder = Index
			Element.Parent = FormPanel
		end
	end

	return FormPanel
end

-- Spacing helpers
function Builder.Spacer(Height: number?): Frame
	local Spacer = Instance.new("Frame")
	Spacer.Size = UDim2.new(1, 0, 0, Height or Spacing.Medium)
	Spacer.BackgroundTransparency = 1

	return Spacer
end

function Builder.Divider(): Frame
	local Divider = Instance.new("Frame")
	Divider.Size = UDim2.new(1, 0, 0, 1)
	Divider.BackgroundColor3 = Colors.Border
	Divider.BorderSizePixel = 0

	return Divider
end

return Builder