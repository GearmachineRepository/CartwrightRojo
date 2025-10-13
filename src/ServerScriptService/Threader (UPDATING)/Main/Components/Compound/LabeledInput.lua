--!strict
local Label = require(script.Parent.Parent.Primitives.Label)
local TextBox = require(script.Parent.Parent.Primitives.TextBox)
local Spacing = require(script.Parent.Parent.Parent.Theme.Spacing)

local LabeledInput = {}

function LabeledInput.Create(LabelText: string, PlaceholderText: string, Parent: Instance, OnChanged: ((string) -> ())?, LayoutOrder: number?): Frame
	local Container = Instance.new("Frame")
	Container.Size = UDim2.new(1, 0, 0, 52)
	Container.BackgroundTransparency = 1
	Container.LayoutOrder = LayoutOrder or 0
	Container.Parent = Parent

	local Layout = Instance.new("UIListLayout")
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Padding = UDim.new(0, Spacing.Tiny)
	Layout.Parent = Container

	Label.Create(LabelText, Container, 1)
	TextBox.Create(PlaceholderText, Container, OnChanged, 2)

	return Container
end

return LabeledInput