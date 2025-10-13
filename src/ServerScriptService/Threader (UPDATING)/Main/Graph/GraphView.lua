--!strict
local Colors = require(script.Parent.Parent.Theme.Colors)
local Fonts = require(script.Parent.Parent.Theme.Fonts)
local Spacing = require(script.Parent.Parent.Theme.Spacing)
local InputManager = require(script.Parent.Parent.Managers.InputManager)
local UIStateManager = require(script.Parent.Parent.Managers.UIStateManager)
local ZIndexManager = require(script.Parent.Parent.Managers.ZIndexManager)
local ConnectionManager = require(script.Parent.Parent.Managers.ConnectionManager)
local DialogTree = require(script.Parent.Parent.Core.DialogTree)
local NodeRenderer = require(script.Parent.NodeRenderer)
local ConnectionDrawer = require(script.Parent.ConnectionDrawer)

type DialogNode = DialogTree.DialogNode
type DialogChoice = DialogTree.DialogChoice

local GraphView = {}

local Connections = ConnectionManager.Create()
local GraphContainer: Frame? = nil
local Workspace: Frame? = nil
local LinesRoot: Frame? = nil
local NodePositions: {[DialogNode]: Vector2} = {}
local NodeFrames: {[DialogNode]: Frame} = {}
local DraggedNode: Frame? = nil
local DragOffset = Vector2.zero
local PanOffset = Vector2.zero

function GraphView.Initialize(Parent: Frame, Plugin: Plugin): Frame
	Connections:Cleanup()
	Connections = ConnectionManager.Create()

	GraphContainer = Instance.new("Frame")
	GraphContainer.Name = "GraphContainer"
	GraphContainer.Size = UDim2.new(0.6, 0, 1, -30)
	GraphContainer.Position = UDim2.new(0, 0, 0, 30)
	GraphContainer.BackgroundColor3 = Colors.BackgroundDark
	GraphContainer.BorderSizePixel = 0
	GraphContainer.ClipsDescendants = true
	GraphContainer.Visible = false
	GraphContainer.Parent = Parent

	ZIndexManager.SetLayer(GraphContainer, "Base")

	Workspace = Instance.new("Frame")
	Workspace.Name = "Workspace"
	Workspace.Size = UDim2.fromScale(2, 2)
	Workspace.Position = UDim2.fromScale(0.5, 0.5)
	Workspace.AnchorPoint = Vector2.new(0.5, 0.5)
	Workspace.BackgroundTransparency = 1
	Workspace.Parent = GraphContainer

	LinesRoot = Instance.new("Frame")
	LinesRoot.Name = "LinesRoot"
	LinesRoot.Size = UDim2.fromScale(1, 1)
	LinesRoot.BackgroundTransparency = 1
	LinesRoot.ZIndex = 1
	LinesRoot.Parent = Workspace

	ZIndexManager.SetLayer(LinesRoot, "UI")

	Connections:Add(InputManager.SubscribeToDrag(function(StartPos: Vector2, CurrentPos: Vector2)
		if DraggedNode then
			local Delta = CurrentPos - StartPos
			local NewPosition = DragOffset + Delta

			DraggedNode.Position = UDim2.fromOffset(NewPosition.X, NewPosition.Y)

			for Node, Frame in pairs(NodeFrames) do
				if Frame == DraggedNode then
					NodePositions[Node] = NewPosition
					break
				end
			end

			GraphView.UpdateConnectionLines()
		end
	end))

	Connections:Add(InputManager.SubscribeToPan(function(StartPos: Vector2, CurrentPos: Vector2)
		if not DraggedNode then
			local Delta = CurrentPos - StartPos
			local NewPosition = PanOffset + Delta

			Workspace.Position = UDim2.fromOffset(NewPosition.X, NewPosition.Y)
		end
	end))

	Connections:Add(InputManager.SubscribeToClick(function(Position: Vector2)
		local ClickedNode = GraphView.GetNodeAtPosition(Position)
		if ClickedNode then
			UIStateManager.SelectNode(ClickedNode)
		else
			UIStateManager.ClearSelection()
		end
	end))

	return GraphContainer
end

function GraphView.Refresh(Tree: DialogNode?, OnNodeSelected: (DialogNode) -> (), OnChoiceSelected: (DialogChoice) -> ())
	if not Workspace or not LinesRoot then return end

	for _, Frame in pairs(NodeFrames) do
		Frame:Destroy()
	end
	NodeFrames = {}

	LinesRoot:ClearAllChildren()

	if not Tree then return end

	GraphView.CalculatePositions(Tree)
	GraphView.RenderNodes(Tree, OnNodeSelected)
	GraphView.UpdateConnectionLines()
end

function GraphView.CalculatePositions(Root: DialogNode)
	NodePositions = {}

	local CurrentX = 100
	local CurrentY = 100
	local XSpacing = 300
	local YSpacing = 150

	local function Layout(Node: DialogNode, X: number, Y: number, Depth: number)
		NodePositions[Node] = Vector2.new(X, Y)

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

	Layout(Root, CurrentX, CurrentY, 0)
end

function GraphView.RenderNodes(Tree: DialogNode, OnNodeSelected: (DialogNode) -> ())
	if not Workspace then return end

	local function RenderNode(Node: DialogNode)
		local Position = NodePositions[Node]
		if not Position then return end

		local NodeFrame = NodeRenderer.Create(Node, Position, Workspace)
		NodeFrames[Node] = NodeFrame

		local SelectedNode = UIStateManager.GetSelectedNode()
		if SelectedNode == Node then
			NodeFrame.BackgroundColor3 = Colors.Primary
		end

		Connections:Add(NodeFrame.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				GraphView.OnNodeDragStart(NodeFrame)
			end
		end))

		Connections:Add(NodeFrame.InputEnded:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				GraphView.OnNodeDragEnd()
			end
		end))

		Connections:Add(NodeFrame.MouseButton1Click:Connect(function()
			UIStateManager.SelectNode(Node)
			OnNodeSelected(Node)
		end))

		if Node.Choices then
			for _, Choice in ipairs(Node.Choices) do
				if Choice.ResponseNode then
					RenderNode(Choice.ResponseNode)
				end

				if Choice.SkillCheck then
					if Choice.SkillCheck.SuccessNode then
						RenderNode(Choice.SkillCheck.SuccessNode)
					end
					if Choice.SkillCheck.FailureNode then
						RenderNode(Choice.SkillCheck.FailureNode)
					end
				end
			end
		end

		if Node.NextResponseNode then
			RenderNode(Node.NextResponseNode)
		end
	end

	RenderNode(Tree)
end

function GraphView.UpdateConnectionLines()
	if not LinesRoot then return end

	LinesRoot:ClearAllChildren()

	for StartNode, StartFrame in pairs(NodeFrames) do
		if StartNode.Choices then
			for _, Choice in ipairs(StartNode.Choices) do
				if Choice.ResponseNode then
					local EndFrame = NodeFrames[Choice.ResponseNode]
					if EndFrame then
						ConnectionDrawer.DrawConnection(
							StartFrame,
							EndFrame,
							LinesRoot,
							Colors.ResponseToNode
						)
					end
				end

				if Choice.SkillCheck then
					if Choice.SkillCheck.SuccessNode then
						local EndFrame = NodeFrames[Choice.SkillCheck.SuccessNode]
						if EndFrame then
							ConnectionDrawer.DrawConnection(
								StartFrame,
								EndFrame,
								LinesRoot,
								Colors.SkillCheckSuccess
							)
						end
					end
					if Choice.SkillCheck.FailureNode then
						local EndFrame = NodeFrames[Choice.SkillCheck.FailureNode]
						if EndFrame then
							ConnectionDrawer.DrawConnection(
								StartFrame,
								EndFrame,
								LinesRoot,
								Colors.SkillCheckFailure
							)
						end
					end
				end
			end
		end

		if StartNode.NextResponseNode then
			local EndFrame = NodeFrames[StartNode.NextResponseNode]
			if EndFrame then
				ConnectionDrawer.DrawConnection(
					StartFrame,
					EndFrame,
					LinesRoot,
					Colors.Primary
				)
			end
		end
	end
end

function GraphView.OnNodeDragStart(NodeFrame: Frame)
	DraggedNode = NodeFrame
	DragOffset = Vector2.new(
		NodeFrame.Position.X.Offset,
		NodeFrame.Position.Y.Offset
	)
end

function GraphView.OnNodeDragEnd()
	if DraggedNode then
		for Node, Frame in pairs(NodeFrames) do
			if Frame == DraggedNode then
				local Position = Vector2.new(
					DraggedNode.Position.X.Offset,
					DraggedNode.Position.Y.Offset
				)
				NodePositions[Node] = Position
				break
			end
		end
		DraggedNode = nil
	end
end

function GraphView.GetNodeAtPosition(Position: Vector2): DialogNode?
	if not GraphContainer then return nil end

	for Node, Frame in pairs(NodeFrames) do
		local FramePos = Frame.AbsolutePosition
		local FrameSize = Frame.AbsoluteSize

		if Position.X >= FramePos.X and Position.X <= FramePos.X + FrameSize.X and
		   Position.Y >= FramePos.Y and Position.Y <= FramePos.Y + FrameSize.Y then
			return Node
		end
	end

	return nil
end

function GraphView.Cleanup()
	Connections:Cleanup()
end

return GraphView