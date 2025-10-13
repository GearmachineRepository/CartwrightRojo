--!strict
local Colors = require(script.Parent.Parent.Parent.Theme.Colors)
local Fonts = require(script.Parent.Parent.Parent.Theme.Fonts)

local Label = {}

function Label.Create(Text: string, Parent: Instance, LayoutOrder: number?): TextLabel
	local LabelElement = Instance.new("TextLabel")
	LabelElement.Size = UDim2.new(1, 0, 0, 20)
	LabelElement.BackgroundTransparency = 1
	LabelElement.Text = Text
	LabelElement.TextColor3 = Colors.Text
	LabelElement.Font = Fonts.Regular
	LabelElement.TextSize = 14
	LabelElement.TextXAlignment = Enum.TextXAlignment.Left
	LabelElement.LayoutOrder = LayoutOrder or 0
	LabelElement.Parent = Parent

	return LabelElement
end

function Label.CreateSection(Text: string, Parent: Instance, LayoutOrder: number?): TextLabel
	local SectionLabel = Instance.new("TextLabel")
	SectionLabel.Size = UDim2.new(1, 0, 0, 24)
	SectionLabel.BackgroundTransparency = 1
	SectionLabel.Text = Text
	SectionLabel.TextColor3 = Colors.Text
	SectionLabel.Font = Fonts.Bold
	SectionLabel.TextSize = 16
	SectionLabel.TextXAlignment = Enum.TextXAlignment.Left
	SectionLabel.LayoutOrder = LayoutOrder or 0
	SectionLabel.Parent = Parent

	return SectionLabel
end

function Label.CreateInline(Text: string, Parent: Instance): TextLabel
	local InlineLabel = Instance.new("TextLabel")
	InlineLabel.Size = UDim2.fromOffset(100, 20)
	InlineLabel.BackgroundTransparency = 1
	InlineLabel.Text = Text
	InlineLabel.TextColor3 = Colors.TextSecondary
	InlineLabel.Font = Fonts.Regular
	InlineLabel.TextSize = 14
	InlineLabel.TextXAlignment = Enum.TextXAlignment.Left
	InlineLabel.Parent = Parent

	return InlineLabel
end

return Label