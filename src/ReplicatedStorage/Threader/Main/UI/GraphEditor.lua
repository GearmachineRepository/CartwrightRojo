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

	-- During pan/drag, draw into the visible buffer and don't swap (prevents flicker)
	local isInteracting = InputHandler.IsPanning or (InputHandler.DraggingNode ~= nil)

	local drawParent: Frame? = isInteracting and getActiveLinesBuffer() or getInactiveLinesBuffer()
	if not drawParent then return end
	drawParent:ClearAllChildren()

	local drew = false

	for node, nodeFrame in pairs(NodeFrames) do
		if node.Choices then
			for index, choice in ipairs(node.Choices) do
				-- Collect ALL possible targets for this choice
				local targets = table.create(3)

				if choice.SkillCheck then
					if choice.SkillCheck.SuccessNode then
						table.insert(targets, choice.SkillCheck.SuccessNode)
					end
					if choice.SkillCheck.FailureNode then
						table.insert(targets, choice.SkillCheck.FailureNode)
					end
				end

				if choice.QuestTurnIn then
					if choice.QuestTurnIn.SuccessNode then
						table.insert(targets, choice.QuestTurnIn.SuccessNode)
					end
					if choice.QuestTurnIn.FailureNode then
						table.insert(targets, choice.QuestTurnIn.FailureNode)
					end
				end

				if choice.ResponseNode then
					table.insert(targets, choice.ResponseNode)
				end

				-- Draw a line from this choice's output port to each target's input port
				for _, target in ipairs(targets) do
					local targetFrame = target and NodeFrames[target]
					if targetFrame then
						local inputPort = targetFrame:FindFirstChild("InputPort") :: Frame?
						local outputPort = nodeFrame:FindFirstChild(("OutputPort_%d"):format(index)) :: Frame?
						if inputPort and outputPort then
							local sAbs = outputPort.AbsolutePosition + outputPort.AbsoluteSize/2
							local eAbs = inputPort.AbsolutePosition  + inputPort.AbsoluteSize/2
							local startLocal = (sAbs - wsPos) / scale
							local endLocal   = (eAbs - wsPos) / scale

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
	end

	-- When idle, swap buffers (double-buffering); during interaction we already drew to the active buffer
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
	end)

	ZoomHandler.Initialize(Workspace, Mouse, UpdateLines, GetMouseScreen)

	Workspace:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		UpdateLines()
	end)

	-- Transparent blocker for panning / wheel
	local Blocker = Instance.new("TextButton")
	Blocker.Size = UDim2.fromScale(1, 1)
	Blocker.BackgroundTransparency = 1
	Blocker.Text = ""
	Blocker.AutoButtonColor = false
	Blocker.Modal = false
	Blocker.Selectable = false
	Blocker.Active = true
	Blocker.ZIndex = 0 -- keep below nodes so clicks on nodes still work
	Blocker.Parent = GraphContainer

	Blocker.MouseButton1Down:Connect(function()
		InputHandler.StartPan()
	end)

	Blocker.MouseButton1Up:Connect(function()
		InputHandler.StopPan()
	end)

	Blocker.MouseLeave:Connect(function()
		-- if mouse leaves the graph while panning, stop gracefully
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
		-- Pan and drag are independent; run both each frame.
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
		-- Always stop pan/drag on MouseUp, even if a GUI consumed the input.
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

function GraphEditor.Refresh(RootNode: DialogNode?, SelectedNode: DialogNode?, OnNodeSelected: (DialogNode) -> ())
	if not Workspace or not LinesRoot then return end

	for _, child in ipairs(Workspace:GetChildren()) do
		if child:IsA("Frame") and child ~= LinesRoot then
			child:Destroy()
		end
	end

	table.clear(NodeFrames)
	table.clear(FrameToNode)
	-- Keep NodePositions to preserve layout across refreshes.

	if not RootNode then return end

	local CurrentX = 0.1
	local CurrentY = 0.1

	local function guardedSelect(n: DialogNode)
		if InputHandler.DidDrag then
			-- swallow the click that ended a drag
			InputHandler.DidDrag = false
			return
		end
		OnNodeSelected(n)
	end

	local function renderNode(node: DialogNode, x: number, y: number, depth: number)
		local defaultPos = UDim2.fromScale(x, y)
		local pos = NodePositions[node] or defaultPos
		local isSelected = node == SelectedNode

		local nodeFrame = NodeRenderer.CreateNode(
			node,
			pos,
			isSelected,
			guardedSelect, -- from prior step
			function(frame: Frame) -- onDragStart
				InputHandler.DragStarted(frame)
			end,
			function(frame: Frame) -- onDragEnd
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

			-- Seed once so future refreshes know we have positions
		if not NodePositions[node] then
			NodePositions[node] = nodeFrame.Position
		end

		local nextY = y
		if node.Choices then
			for _, choice in ipairs(node.Choices) do
				if choice.SkillCheck then
					if choice.SkillCheck.SuccessNode then
						renderNode(choice.SkillCheck.SuccessNode, x + 0.15, nextY, depth + 1)
						nextY += 0.15
					end
					if choice.SkillCheck.FailureNode then
						renderNode(choice.SkillCheck.FailureNode, x + 0.15, nextY, depth + 1)
						nextY += 0.15
					end
				elseif choice.ResponseNode then
					renderNode(choice.ResponseNode, x + 0.15, nextY, depth + 1)
					nextY += 0.15
				end
			end
		end
	end

	renderNode(RootNode, CurrentX, CurrentY, 0)
	UpdateLines()

	-- Center only on first layout (when there are no saved positions yet)
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