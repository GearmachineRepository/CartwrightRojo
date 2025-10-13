--!strict
local Spacing = require(script.Parent.Parent.Parent.Theme.Spacing)

local ButtonRow = {}

function ButtonRow.Create(Parent: Instance, LayoutOrder: number?): Frame
	local Container = Instance.new("Frame")
	Container.Size = UDim2.new(1, 0, 0, 28)
	Container.BackgroundTransparency = 1
	Container.LayoutOrder = LayoutOrder or 0
	Container.Parent = Parent

	local Layout = Instance.new("UIListLayout")
	Layout.FillDirection = Enum.FillDirection.Horizontal
	Layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	Layout.Padding = UDim.new(0, Spacing.Small)
	Layout.Parent = Container

	return Container
end

return ButtonRow