--!strict
local Constants = require(script.Parent.Parent.Constants)

local Labels = {}

function Labels.CreateLabel(Text: string, Parent: Instance, Order: number): TextLabel
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

function Labels.CreateInlineLabel(Text: string, Parent: Instance, Width: number): TextLabel
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

function Labels.CreateSectionLabel(Text: string, Parent: Instance, Order: number): TextLabel
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

return Labels