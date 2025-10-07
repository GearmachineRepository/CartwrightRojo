--!strict
local UserInputService = game:GetService("UserInputService")

local Constants = require(script.Parent.Parent.Constants)
local DialogTree = require(script.Parent.Parent.Data.DialogTree)

local GraphLibrary = script.Parent.Parent.GraphLibrary
local BezierDrawer = require(GraphLibrary.BezierDrawer)
local InputHandler = require(GraphLibrary.InputHandler)
local ZoomHandler = require(GraphLibrary.ZoomHandler)
local NodeRenderer = require(GraphLibrary.NodeRenderer)

type DialogNode = DialogTree.DialogNode
type DialogChoice = DialogTree.DialogChoice

local GraphEditor = {}

local GraphContainer: Frame? = nil
local Workspace: Frame? = nil
local LinesRoot: Frame? = nil
local LinesBufferA: Frame? = nil
local LinesBufferB: Frame? = nil
local ActiveBufferIsA = true
local DidInitialCenter = false

local NodeFrames: {[DialogNode]: Frame} = {}
local FrameToNode: {[Frame]: DialogNode} = {}
local NodePositions: {[DialogNode]: UDim2} = {}

local ChoiceFrames: {[DialogChoice]: Frame} = {}
local FrameToChoice: {[Frame]: DialogChoice} = {}
local ChoicePositions: {[DialogChoice]: UDim2} = {}

local CurrentRootNode: DialogNode? = nil

local function getInactiveLinesBuffer(): Frame?
	if not LinesBufferA or not LinesBufferB then return nil end
	return ActiveBufferIsA and LinesBufferB or LinesBufferA
end

local function swapBuffers()
	if not LinesBufferA or not LinesBufferB then return end
	ActiveBufferIsA = not ActiveBufferIsA
	LinesBufferA.Visible = ActiveBufferIsA
	LinesBufferB.Visible = not ActiveBufferIsA
end

local function UpdateLines()
	if not LinesRoot or not Workspace then return end

	local uiScale = Workspace:FindFirstChildOfClass("UIScale")
	local scale = uiScale and math.max(uiScale.Scale, 0.0001) or 1
	local wsPos = Workspace.AbsolutePosition

	local function getActiveLinesBuffer(): Frame?
		if not LinesBufferA or not LinesBufferB then return nil end
		return ActiveBufferIsA and LinesBufferA or LinesBufferB
	end

	local isInteracting = InputHandler.IsPanning or (InputHandler.DraggingNode ~= nil)
	local drawParent: Frame? = isInteracting and getActiveLinesBuffer() or getInactiveLinesBuffer()
	if not drawParent then return end
	drawParent:ClearAllChildren()

	local drew = false

	for node, nodeFrame in pairs(NodeFrames) do
		if node.Choices then
			for index, choice in ipairs(node.Choices) do
				local choiceFrame = ChoiceFrames[choice]
				if choiceFrame then
					local inputPort = choiceFrame:FindFirstChild("InputPort") :: Frame?
					local outputPort = nodeFrame:FindFirstChild(("OutputPort_%d"):format(index)) :: Frame?
					if inputPort and outputPort then
						local sAbs = outputPort.AbsolutePosition + outputPort.AbsoluteSize/2
						local eAbs = inputPort.AbsolutePosition + inputPort.AbsoluteSize/2
						local startLocal = (sAbs - wsPos) / scale
						local endLocal = (eAbs - wsPos) / scale

						local container = Instance.new("Frame")
						container.BackgroundTransparency = 1
						container.Size = UDim2.fromScale(1, 1)
						container.ZIndex = 1000
						container.Parent = drawParent

						BezierDrawer.DrawCurve(3, 80, startLocal, endLocal, Constants.COLORS.Border, container)
						drew = true
					end
				end
			end
		end
	end

	for choice, choiceFrame in pairs(ChoiceFrames) do
		local targets = table.create(3)

		if choice.SkillCheck then
			if choice.SkillCheck.SuccessNode then
				table.insert(targets, {node = choice.SkillCheck.SuccessNode, color = Constants.COLORS.Success})
			end
			if choice.SkillCheck.FailureNode then
				table.insert(targets, {node = choice.SkillCheck.FailureNode, color = Constants.COLORS.Danger})
			end
		elseif choice.ResponseNode then
			table.insert(targets, {node = choice.ResponseNode, color = Constants.COLORS.Border})
		end

		for _, target in ipairs(targets) do
			local targetFrame = NodeFrames[target.node]
			if targetFrame then
				local inputPort = targetFrame:FindFirstChild("InputPort") :: Frame?
				local outputPort = choiceFrame:FindFirstChild("OutputPort_1") :: Frame?
				if inputPort and outputPort then
					local sAbs = outputPort.AbsolutePosition + outputPort.AbsoluteSize/2
					local eAbs = inputPort.AbsolutePosition + inputPort.AbsoluteSize/2
					local startLocal = (sAbs - wsPos) / scale
					local endLocal = (eAbs - wsPos) / scale

					local container = Instance.new("Frame")
					container.BackgroundTransparency = 1
					container.Size = UDim2.fromScale(1, 1)
					container.ZIndex = 1000
					container.Parent = drawParent

					BezierDrawer.DrawCurve(3, 80, startLocal, endLocal, target.color, container)
					drew = true
				end
			end
		end

		if choice.ReturnToNodeId then
			local returnTargetNode = DialogTree.FindNodeById(CurrentRootNode, choice.ReturnToNodeId)
			if returnTargetNode then
				local returnTargetFrame = NodeFrames[returnTargetNode]
				if returnTargetFrame then
					local inputPort = returnTargetFrame:FindFirstChild("InputPort") :: Frame?
					local outputPort = choiceFrame:FindFirstChild("OutputPort_1") :: Frame?
					if inputPort and outputPort then
						local sAbs = outputPort.AbsolutePosition + outputPort.AbsoluteSize/2
						local eAbs = inputPort.AbsolutePosition + inputPort.AbsoluteSize/2
						local startLocal = (sAbs - wsPos) / scale
						local endLocal = (eAbs - wsPos) / scale

						local container = Instance.new("Frame")
						container.BackgroundTransparency = 1
						container.Size = UDim2.fromScale(1, 1)
						container.ZIndex = 1000
						container.Parent = drawParent

						BezierDrawer.DrawCurve(4, 100, startLocal, endLocal, Constants.COLORS.Accent, container)
						drew = true
					end
				end
			end
		end
	end

	if (not isInteracting) and drew then
		swapBuffers()
	end
end

local function CenterOnFrame(target: Frame)
	if not Workspace or not GraphContainer or not target then return end
	local gcSize = GraphContainer.AbsoluteSize
	local targetPos = target.AbsolutePosition
	local targetSize = target.AbsoluteSize
	local targetCenter = targetPos + targetSize/2

	local delta = Vector2.new(
		(gcSize.X/2) - targetCenter.X,
		(gcSize.Y/2) - targetCenter.Y
	)

	Workspace.Position = UDim2.fromOffset(
		Workspace.Position.X.Offset + delta.X,
		Workspace.Position.Y.Offset + delta.Y
	)
end

function GraphEditor.Create(Parent: Instance, Mouse: Mouse, HostWidget: DockWidgetPluginGui): Frame
	GraphContainer = Instance.new("Frame")
	GraphContainer.Name = "GraphEditor"
	GraphContainer.Size = UDim2.new(1, 0, 1, -Constants.SIZES.TopBarHeight)
	GraphContainer.Position = UDim2.fromOffset(0, Constants.SIZES.TopBarHeight)
	GraphContainer.BackgroundColor3 = Constants.COLORS.Background
	GraphContainer.BorderSizePixel = 0
	GraphContainer.ClipsDescendants = false
	GraphContainer.Visible = false
	GraphContainer.Parent = Parent

	Workspace = Instance.new("Frame")
	Workspace.Name = "Workspace"
	Workspace.Size = UDim2.fromOffset(2000, 2000)
	Workspace.Position = UDim2.fromOffset(0, 0)
	Workspace.BackgroundTransparency = 1
	Workspace.Parent = GraphContainer

	LinesRoot = Instance.new("Frame")
	LinesRoot.Name = "LinesRoot"
	LinesRoot.Size = UDim2.fromScale(1, 1)
	LinesRoot.BackgroundTransparency = 1
	LinesRoot.ZIndex = 900
	LinesRoot.Parent = Workspace

	LinesBufferA = Instance.new("Frame")
	LinesBufferA.Name = "LinesA"
	LinesBufferA.Size = UDim2.fromScale(1, 1)
	LinesBufferA.BackgroundTransparency = 1
	LinesBufferA.Visible = true
	LinesBufferA.Parent = LinesRoot

	LinesBufferB = Instance.new("Frame")
	LinesBufferB.Name = "LinesB"
	LinesBufferB.Size = UDim2.fromScale(1, 1)
	LinesBufferB.BackgroundTransparency = 1
	LinesBufferB.Visible = false
	LinesBufferB.Parent = LinesRoot

	local function GetMouseScreen(): Vector2
		local p = HostWidget:GetRelativeMousePosition()
		return Vector2.new(HostWidget.AbsolutePosition.X + p.X, HostWidget.AbsolutePosition.Y + p.Y)
	end

	InputHandler.Initialize(Mouse, Workspace, UpdateLines, GetMouseScreen, function(frame: Frame)
		local n = FrameToNode[frame]
		if n then
			NodePositions[n] = frame.Position
		end
		local c = FrameToChoice[frame]
		if c then
			ChoicePositions[c] = frame.Position
		end
	end)

	ZoomHandler.Initialize(Workspace, Mouse, UpdateLines, GetMouseScreen)

	Workspace:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		UpdateLines()
	end)

	local Blocker = Instance.new("TextButton")
	Blocker.Size = UDim2.fromScale(1, 1)
	Blocker.BackgroundTransparency = 1
	Blocker.Text = ""
	Blocker.AutoButtonColor = false
	Blocker.Modal = false
	Blocker.Selectable = false
	Blocker.Active = true
	Blocker.ZIndex = 0
	Blocker.Parent = GraphContainer

	Blocker.MouseButton1Down:Connect(function()
		InputHandler.StartPan()
	end)

	Blocker.MouseButton1Up:Connect(function()
		InputHandler.StopPan()
	end)

	Blocker.MouseLeave:Connect(function()
		InputHandler.StopPan()
	end)

	Blocker.MouseWheelForward:Connect(function()
		ZoomHandler.ZoomIn()
	end)

	Blocker.MouseWheelBackward:Connect(function()
		ZoomHandler.ZoomOut()
	end)

	local RunService = game:GetService("RunService")
	RunService:BindToRenderStep("Threader_GraphEditor_InputLoop", Enum.RenderPriority.Input.Value, function()
		InputHandler.PanUpdate()
		InputHandler.DragUpdate()
	end)

	UserInputService.InputBegan:Connect(function(input: InputObject, gpe: boolean)
		if gpe then return end
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Escape then
			InputHandler.CancelAll()
		end
		if input.UserInputType == Enum.UserInputType.MouseButton3 then
			InputHandler.StartPan()
		end
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject, _: boolean)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.MouseButton3 then
			InputHandler.StopPan()
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if InputHandler.DraggingNode or InputHandler.PendingDragFrame then
				InputHandler.DragEnded(InputHandler.DraggingNode)
			end
		end
	end)

	UserInputService.WindowFocusReleased:Connect(function()
		InputHandler.CancelAll()
	end)

	return GraphContainer
end

function GraphEditor.Refresh(
	RootNode: DialogNode?,
	SelectedNode: DialogNode?,
	SelectedChoice: DialogChoice?,
	OnNodeSelected: (DialogNode) -> (),
	OnChoiceSelected: (DialogChoice) -> ()
)
	if not Workspace or not LinesRoot then return end

	for _, child in ipairs(Workspace:GetChildren()) do
		if child:IsA("Frame") and child ~= LinesRoot then
			child:Destroy()
		end
	end

	table.clear(NodeFrames)
	table.clear(FrameToNode)
	table.clear(ChoiceFrames)
	table.clear(FrameToChoice)

	if not RootNode then return end

	CurrentRootNode = RootNode

	local CurrentX = 0.1
	local CurrentY = 0.1

	local function guardedSelect(n: DialogNode)
		if InputHandler.DidDrag then
			InputHandler.DidDrag = false
			return
		end
		OnNodeSelected(n)
	end

	local function guardedChoiceSelect(c: DialogChoice)
		if InputHandler.DidDrag then
			InputHandler.DidDrag = false
			return
		end
		OnChoiceSelected(c)
	end

	local function renderNode(node: DialogNode, x: number, y: number, depth: number)
		local defaultPos = UDim2.fromScale(x, y)
		local pos = NodePositions[node] or defaultPos
		local isSelected = node == SelectedNode

		local nodeFrame = NodeRenderer.CreateNode(
			node,
			pos,
			isSelected,
			guardedSelect,
			function(frame: Frame)
				InputHandler.DragStarted(frame)
			end,
			function(frame: Frame)
				InputHandler.DragEnded(frame)
				local n = FrameToNode[frame]
				if n then
					NodePositions[n] = frame.Position
				end
			end
		)

		nodeFrame.Parent = Workspace
		NodeFrames[node] = nodeFrame
		FrameToNode[nodeFrame] = node

		if not NodePositions[node] then
			NodePositions[node] = nodeFrame.Position
		end

		local nextY = y
		if node.Choices then
			for _, choice in ipairs(node.Choices) do
				local choiceX = x + 0.15
				local choiceY = nextY

				local choiceDefaultPos = UDim2.fromScale(choiceX, choiceY)
				local choicePos = ChoicePositions[choice] or choiceDefaultPos
				local isChoiceSelected = choice == SelectedChoice

				local choiceFrame = NodeRenderer.CreateChoiceNode(
					choice,
					choicePos,
					isChoiceSelected,
					guardedChoiceSelect,
					function(frame: Frame)
						InputHandler.DragStarted(frame)
					end,
					function(frame: Frame)
						InputHandler.DragEnded(frame)
						ChoicePositions[choice] = frame.Position
					end
				)

				choiceFrame.Parent = Workspace
				ChoiceFrames[choice] = choiceFrame
				FrameToChoice[choiceFrame] = choice

				if not ChoicePositions[choice] then
					ChoicePositions[choice] = choiceFrame.Position
				end

				if choice.SkillCheck then
					if choice.SkillCheck.SuccessNode then
						renderNode(choice.SkillCheck.SuccessNode, choiceX + 0.15, choiceY, depth + 1)
						nextY += 0.15
					end
					if choice.SkillCheck.FailureNode then
						renderNode(choice.SkillCheck.FailureNode, choiceX + 0.15, choiceY + 0.05, depth + 1)
						nextY += 0.15
					end
				elseif choice.ResponseNode then
					renderNode(choice.ResponseNode, choiceX + 0.15, choiceY, depth + 1)
					nextY += 0.15
				end
			end
		end
	end

	renderNode(RootNode, CurrentX, CurrentY, 0)
	UpdateLines()

	if next(NodePositions) == nil then
		if not DidInitialCenter then
			DidInitialCenter = true
			task.defer(function()
				local rootFrame = NodeFrames[RootNode]
				if rootFrame then
					CenterOnFrame(rootFrame)
				end
			end)
		end
	end
end

function GraphEditor.GetContainer(): Frame?
	return GraphContainer
end

return GraphEditor