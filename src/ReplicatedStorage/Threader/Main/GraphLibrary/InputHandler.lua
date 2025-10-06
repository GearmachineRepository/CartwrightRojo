--!strict
local InputHandler = {}

InputHandler.DraggingNode = nil
InputHandler.DragOffsetX = 0
InputHandler.DragOffsetY = 0
InputHandler.IsPanning = false
InputHandler.LastPanPosition = nil
InputHandler.PluginMouse = nil
InputHandler.Workspace = nil
InputHandler.OnLinesUpdate = nil
InputHandler.GetMousePosition = nil :: (() -> Vector2)?
InputHandler.DidDrag = false
InputHandler.DragStartPos = nil :: Vector2?
InputHandler.PendingDragFrame = nil :: Frame?
InputHandler.PressMousePos = nil :: Vector2?

InputHandler.PRESS_TO_DRAG_THRESHOLD = 3

InputHandler._PanConn = nil :: RBXScriptConnection?
InputHandler._DragConn = nil :: RBXScriptConnection?

function InputHandler.Initialize(
	Mouse: Mouse,
	WorkspaceFrame: Frame,
	OnLinesUpdate: (() -> ())?,
	GetMousePosition: (() -> Vector2)?,
	OnNodeMoved: ((Frame) -> ())?
)
	InputHandler.PluginMouse = Mouse
	InputHandler.Workspace = WorkspaceFrame
	InputHandler.OnLinesUpdate = OnLinesUpdate
	InputHandler.GetMousePosition = GetMousePosition
	InputHandler.OnNodeMoved = OnNodeMoved
	InputHandler.IsPanning = false
end

local function GetWorkspaceScale(ws: Frame): number
	local ui = ws:FindFirstChildOfClass("UIScale")
	return ui and math.max(ui.Scale, 0.0001) or 1
end

local function GetNodeLocalOffset(frame: Frame, ws: Frame, scale: number): Vector2
	-- Top-left in workspace-local, pre-scale space (matches fromOffset)
	return (frame.AbsolutePosition - ws.AbsolutePosition) / scale
end

local function ReadMouse(): Vector2
	if InputHandler.GetMousePosition then
		return InputHandler.GetMousePosition()
	end
	return game:GetService("UserInputService"):GetMouseLocation()
end

function InputHandler.DragStarted(frame: Frame)
	InputHandler.PendingDragFrame = frame
	InputHandler.DraggingNode = nil
	InputHandler.DidDrag = false

	local ws = InputHandler.Workspace
	local mouse = ReadMouse()
	if not ws then
		InputHandler.PressMousePos = mouse
		InputHandler.DragStartPos = Vector2.new(0, 0)
		InputHandler.DragOffsetX, InputHandler.DragOffsetY = 0, 0
		return
	end

	local scale = GetWorkspaceScale(ws)
	local wsPos = ws.AbsolutePosition

	-- Node start in local/pre-scale space (works for fromScale and fromOffset)
	local nodeLocal = GetNodeLocalOffset(frame, ws, scale)
	InputHandler.DragStartPos = nodeLocal

	-- Mouse in local/pre-scale space
	local mouseLocal = (mouse - wsPos) / scale

	-- Correct drag offset so node stays under cursor when drag promotes
	InputHandler.DragOffsetX = mouseLocal.X - nodeLocal.X
	InputHandler.DragOffsetY = mouseLocal.Y - nodeLocal.Y

	InputHandler.PressMousePos = mouse
end

function InputHandler.DragUpdate()
	local ws = InputHandler.Workspace
	if not ws then return end

	local mouse = ReadMouse()
	local scale = GetWorkspaceScale(ws)
	local wsPos = ws.AbsolutePosition
	local mouseLocal = (mouse - wsPos) / scale

	-- Promote from "pending" to real drag after a small move
	if not InputHandler.DraggingNode and InputHandler.PendingDragFrame and InputHandler.PressMousePos then
		local moved = math.abs(mouse.X - InputHandler.PressMousePos.X) + math.abs(mouse.Y - InputHandler.PressMousePos.Y)
		if moved >= (InputHandler.PRESS_TO_DRAG_THRESHOLD or 3) then
			InputHandler.DraggingNode = InputHandler.PendingDragFrame
			InputHandler.PendingDragFrame = nil
			InputHandler.DidDrag = true
		end
	end

	local node = InputHandler.DraggingNode
	if not node then return end

	-- Use the precomputed offset against current mouse (both in local/pre-scale)
	local newX = mouseLocal.X - (InputHandler.DragOffsetX or 0)
	local newY = mouseLocal.Y - (InputHandler.DragOffsetY or 0)
	node.Position = UDim2.fromOffset(newX, newY)

	if InputHandler.OnNodeMoved then
		InputHandler.OnNodeMoved(node)
	end
	if InputHandler.OnLinesUpdate then
		InputHandler.OnLinesUpdate()
	end
end

function InputHandler.DragEnded(_frame: Frame?)
	InputHandler.DraggingNode = nil
	InputHandler.PendingDragFrame = nil
	InputHandler.PressMousePos = nil
	InputHandler.DragStartPos = nil
	InputHandler.DragOffsetX = 0
	InputHandler.DragOffsetY = 0
end

function InputHandler.CancelAll()
	InputHandler.StopPan()
	InputHandler.DragEnded(nil)
end

function InputHandler.PanUpdate()
	if not InputHandler.IsPanning or not InputHandler.Workspace then return end

	local mouse = ReadMouse()
	local startMouse = InputHandler.PanStartMouse
	local startOffset = InputHandler.PanStartOffset
	if not startMouse or not startOffset then return end

	-- Screen-space pan: do NOT divide by zoom scale
	local delta = (mouse - startMouse)
	local newOffset = startOffset + delta

	InputHandler.Workspace.Position = UDim2.fromOffset(newOffset.X, newOffset.Y)

	if InputHandler.OnLinesUpdate then
		InputHandler.OnLinesUpdate()
	end
end

function InputHandler.StartPan()
	if not InputHandler.Workspace then return end
	if InputHandler.IsPanning then return end
	InputHandler.IsPanning = true

	local mouse = ReadMouse()
	InputHandler.PanStartMouse = mouse
	InputHandler.PanStartOffset = Vector2.new(
		InputHandler.Workspace.Position.X.Offset,
		InputHandler.Workspace.Position.Y.Offset
	)
end

function InputHandler.StopPan()
	if not InputHandler.IsPanning then return end
	InputHandler.IsPanning = false
	InputHandler.PanStartMouse = nil
	InputHandler.PanStartOffset = nil
end

return InputHandler