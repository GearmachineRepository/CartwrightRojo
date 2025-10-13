--!strict
local Colors = require(script.Parent.Parent.Theme.Colors)
local Fonts = require(script.Parent.Parent.Theme.Fonts)
local DialogTree = require(script.Parent.Parent.Core.DialogTree)

type DialogNode = DialogTree.DialogNode

local NodeRenderer = {}

function NodeRenderer.Create(Node: DialogNode, Position: Vector2, Parent: Frame): Frame
	local NodeFrame = Instance.new("Frame")
	NodeFrame.Size = UDim2.fromOffset(200, 80)
	NodeFrame.Position = UDim2.fromOffset(Position.X, Position.Y)
	NodeFrame.BackgroundColor3 = Colors.BackgroundLight
	NodeFrame.BorderColor3 = Colors.Border
	NodeFrame.BorderSizePixel = 1
	NodeFrame.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 8)
	Corner.Parent = NodeFrame

	local NodeId = Instance.new("TextLabel")
	NodeId.Size = UDim2.new(1, 0, 0, 20)
	NodeId.BackgroundColor3 = Colors.Primary
	NodeId.BorderSizePixel = 0
	NodeId.Text = Node.Id or "Unknown"
	NodeId.TextColor3 = Colors.Text
	NodeId.Font = Fonts.Bold
	NodeId.TextSize = 12
	NodeId.Parent = NodeFrame

	local IdCorner = Instance.new("UICorner")
	IdCorner.CornerRadius = UDim.new(0, 8)
	IdCorner.Parent = NodeId

	local IdBottomCover = Instance.new("Frame")
	IdBottomCover.Size = UDim2.new(1, 0, 0, 8)
	IdBottomCover.Position = UDim2.new(0, 0, 1, -8)
	IdBottomCover.BackgroundColor3 = Colors.Primary
	IdBottomCover.BorderSizePixel = 0
	IdBottomCover.Parent = NodeId

	local NodeText = Instance.new("TextLabel")
	NodeText.Size = UDim2.new(1, -16, 1, -28)
	NodeText.Position = UDim2.fromOffset(8, 24)
	NodeText.BackgroundTransparency = 1
	NodeText.Text = Node.Text:sub(1, 60) .. (Node.Text:len() > 60 and "..." or "")
	NodeText.TextColor3 = Colors.Text
	NodeText.Font = Fonts.Regular
	NodeText.TextSize = 11
	NodeText.TextWrapped = true
	NodeText.TextXAlignment = Enum.TextXAlignment.Left
	NodeText.TextYAlignment = Enum.TextYAlignment.Top
	NodeText.Parent = NodeFrame

	local ChoiceCount = 0
	if Node.Choices then
		ChoiceCount = #Node.Choices
	end

	if ChoiceCount > 0 then
		local ChoiceIndicator = Instance.new("TextLabel")
		ChoiceIndicator.Size = UDim2.fromOffset(30, 20)
		ChoiceIndicator.Position = UDim2.new(1, -35, 1, -25)
		ChoiceIndicator.BackgroundColor3 = Colors.Info
		ChoiceIndicator.BorderSizePixel = 0
		ChoiceIndicator.Text = tostring(ChoiceCount)
		ChoiceIndicator.TextColor3 = Colors.Text
		ChoiceIndicator.Font = Fonts.Bold
		ChoiceIndicator.TextSize = 12
		ChoiceIndicator.Parent = NodeFrame

		local IndicatorCorner = Instance.new("UICorner")
		IndicatorCorner.CornerRadius = UDim.new(0, 4)
		IndicatorCorner.Parent = ChoiceIndicator
	end

	return NodeFrame
end

return NodeRenderer