--!strict
local DialogTree = require(script.Parent.Parent.Core.DialogTree)
local MathUtils = require(script.Parent.Parent.Utils.MathUtils)

type DialogNode = DialogTree.DialogNode

local LayoutEngine = {}

export type Rect = {
	X: number,
	Y: number,
	Width: number,
	Height: number
}

function LayoutEngine.ArrangeTree(RootNode: DialogNode): {[DialogNode]: Vector2}
	local Positions: {[DialogNode]: Vector2} = {}
	local CurrentX = 100
	local CurrentY = 100
	local XSpacing = 300
	local YSpacing = 150

	local function Layout(Node: DialogNode, X: number, Y: number, Depth: number)
		Positions[Node] = Vector2.new(X, Y)

		if Node.Choices then
			local ChildY = Y
			for _, Choice in ipairs(Node.Choices) do
				if Choice.ResponseNode then
					Layout(Choice.ResponseNode, X + XSpacing, ChildY, Depth + 1)
					ChildY = ChildY + YSpacing
				end

				if Choice.SkillCheck then
					if Choice.SkillCheck.SuccessNode then
						Layout(Choice.SkillCheck.SuccessNode, X + XSpacing, ChildY, Depth + 1)
						ChildY = ChildY + YSpacing
					end
					if Choice.SkillCheck.FailureNode then
						Layout(Choice.SkillCheck.FailureNode, X + XSpacing, ChildY, Depth + 1)
						ChildY = ChildY + YSpacing
					end
				end
			end
		end

		if Node.NextResponseNode then
			Layout(Node.NextResponseNode, X, Y + YSpacing, Depth)
		end
	end

	Layout(RootNode, CurrentX, CurrentY, 0)
	return Positions
end

function LayoutEngine.ArrangeTreeHierarchical(RootNode: DialogNode): {[DialogNode]: Vector2}
	local Positions: {[DialogNode]: Vector2} = {}
	local LayerHeights: {[number]: number} = {}
	local NodeWidths: {[DialogNode]: number} = {}

	local NodeWidth = 200
	local NodeHeight = 80
	local XSpacing = 100
	local YSpacing = 150

	local function CalculateSubtreeWidth(Node: DialogNode, Depth: number): number
		local Width = NodeWidth

		if Node.Choices and #Node.Choices > 0 then
			local ChildrenWidth = 0
			for _, Choice in ipairs(Node.Choices) do
				if Choice.ResponseNode then
					ChildrenWidth = ChildrenWidth + CalculateSubtreeWidth(Choice.ResponseNode, Depth + 1)
				end
			end
			Width = math.max(Width, ChildrenWidth)
		end

		NodeWidths[Node] = Width
		return Width + XSpacing
	end

	local function Layout(Node: DialogNode, X: number, Y: number, Depth: number, AvailableWidth: number)
		Positions[Node] = Vector2.new(X, Y)

		if Node.Choices and #Node.Choices > 0 then
			local TotalChildrenWidth = 0
			for _, Choice in ipairs(Node.Choices) do
				if Choice.ResponseNode then
					TotalChildrenWidth = TotalChildrenWidth + (NodeWidths[Choice.ResponseNode] or NodeWidth)
				end
			end

			local StartX = X - TotalChildrenWidth / 2
			local CurrentX = StartX

			for _, Choice in ipairs(Node.Choices) do
				if Choice.ResponseNode then
					local ChildWidth = NodeWidths[Choice.ResponseNode] or NodeWidth
					Layout(Choice.ResponseNode, CurrentX + ChildWidth / 2, Y + YSpacing, Depth + 1, ChildWidth)
					CurrentX = CurrentX + ChildWidth
				end
			end
		end

		if Node.NextResponseNode then
			Layout(Node.NextResponseNode, X, Y + YSpacing, Depth, AvailableWidth)
		end
	end

	CalculateSubtreeWidth(RootNode, 0)
	Layout(RootNode, 400, 100, 0, NodeWidths[RootNode] or NodeWidth)

	return Positions
end

function LayoutEngine.GetBounds(Positions: {[DialogNode]: Vector2}): Rect
	local MinX = math.huge
	local MinY = math.huge
	local MaxX = -math.huge
	local MaxY = -math.huge

	for _, Position in pairs(Positions) do
		MinX = math.min(MinX, Position.X)
		MinY = math.min(MinY, Position.Y)
		MaxX = math.max(MaxX, Position.X + 200)
		MaxY = math.max(MaxY, Position.Y + 80)
	end

	return {
		X = MinX,
		Y = MinY,
		Width = MaxX - MinX,
		Height = MaxY - MinY
	}
end

function LayoutEngine.CenterInView(Positions: {[DialogNode]: Vector2}, ViewSize: Vector2): {[DialogNode]: Vector2}
	local Bounds = LayoutEngine.GetBounds(Positions)
	local CenterX = Bounds.X + Bounds.Width / 2
	local CenterY = Bounds.Y + Bounds.Height / 2

	local OffsetX = ViewSize.X / 2 - CenterX
	local OffsetY = ViewSize.Y / 2 - CenterY

	local CenteredPositions: {[DialogNode]: Vector2} = {}

	for Node, Position in pairs(Positions) do
		CenteredPositions[Node] = Vector2.new(
			Position.X + OffsetX,
			Position.Y + OffsetY
		)
	end

	return CenteredPositions
end

return LayoutEngine