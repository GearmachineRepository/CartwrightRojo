--!strict
local Colors = require(script.Parent.Parent.Parent.Theme.Colors)
local Spacing = require(script.Parent.Parent.Parent.Theme.Spacing)

local Container = {}

function Container.Create(Parent: Instance, LayoutOrder: number?): Frame
	local ContainerFrame = Instance.new("Frame")
	ContainerFrame.Size = UDim2.new(1, 0, 0, 100)
	ContainerFrame.BackgroundColor3 = Colors.BackgroundLight
	ContainerFrame.BorderSizePixel = 0
	ContainerFrame.LayoutOrder = LayoutOrder or 0
	ContainerFrame.Parent = Parent

	local Layout = Instance.new("UIListLayout")
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Padding = UDim.new(0, Spacing.Gap)
	Layout.Parent = ContainerFrame

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, Spacing.Padding)
	Padding.PaddingRight = UDim.new(0, Spacing.Padding)
	Padding.PaddingTop = UDim.new(0, Spacing.Padding)
	Padding.PaddingBottom = UDim.new(0, Spacing.Padding)
	Padding.Parent = ContainerFrame

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 4)
	Corner.Parent = ContainerFrame

	Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		ContainerFrame.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y + Spacing.Padding * 2)
	end)

	return ContainerFrame
end

return Container