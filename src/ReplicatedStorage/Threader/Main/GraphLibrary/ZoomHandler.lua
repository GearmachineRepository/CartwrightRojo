--!strict
local ZoomHandler = {}

local ZOOM_SPEED = 0.1
local ZOOM_MIN = 0.1
local ZOOM_MAX = 2

ZoomHandler.CurrentZoom = 1.0
ZoomHandler.ZoomScale = nil
ZoomHandler.Workspace = nil
ZoomHandler.PluginMouse = nil
ZoomHandler.OnLinesUpdate = nil
ZoomHandler.GetMousePosition = nil :: (() -> Vector2)?

function ZoomHandler.Initialize(WorkspaceFrame: Frame, Mouse: Mouse, UpdateCallback: () -> (), GetMouse: (() -> Vector2)?)
	ZoomHandler.Workspace = WorkspaceFrame
	ZoomHandler.PluginMouse = Mouse
	ZoomHandler.OnLinesUpdate = UpdateCallback
	ZoomHandler.GetMousePosition = GetMouse

	local Scale = WorkspaceFrame:FindFirstChildOfClass("UIScale")
	if not Scale then
		Scale = Instance.new("UIScale")
		Scale.Scale = 1.0
		Scale.Parent = WorkspaceFrame
	end
	ZoomHandler.ZoomScale = Scale
	ZoomHandler.CurrentZoom = Scale.Scale

	Scale:GetPropertyChangedSignal("Scale"):Connect(function()
		task.defer(function()
			if ZoomHandler.OnLinesUpdate then
				ZoomHandler.OnLinesUpdate()
			end
		end)
	end)
end

local function ReadMouse(): Vector2
	if ZoomHandler.GetMousePosition then
		return ZoomHandler.GetMousePosition()
	end
	return game:GetService("UserInputService"):GetMouseLocation()
end

local function ZoomTo(newScale: number)
	if not ZoomHandler.ZoomScale or not ZoomHandler.Workspace then return end

	local oldScale = ZoomHandler.CurrentZoom
	newScale = math.clamp(newScale, ZOOM_MIN, ZOOM_MAX)
	if math.abs(newScale - oldScale) < 1e-6 then return end

	local mouse = ReadMouse()
	local wsPos = ZoomHandler.Workspace.AbsolutePosition

	-- Convert mouse to workspace-local using the *old* scale
	local mouseLocal = (mouse - wsPos) / math.max(oldScale, 1e-6)

	-- Apply the new scale
	ZoomHandler.CurrentZoom = newScale
	ZoomHandler.ZoomScale.Scale = newScale

	-- Reposition the workspace so the same local point stays under the cursor
	local newWsPos = mouse - (mouseLocal * newScale)
	ZoomHandler.Workspace.Position = UDim2.fromOffset(newWsPos.X, newWsPos.Y)

	ZoomHandler.ClampWorkspace()
	if ZoomHandler.OnLinesUpdate then
		ZoomHandler.OnLinesUpdate()
	end
end

function ZoomHandler.ZoomIn()
	ZoomTo(ZoomHandler.CurrentZoom + ZOOM_SPEED)
end

function ZoomHandler.ZoomOut()
	ZoomTo(ZoomHandler.CurrentZoom - ZOOM_SPEED)
end

function ZoomHandler.ClampWorkspace()
	if not ZoomHandler.Workspace then return end

	local view = ZoomHandler.Workspace.Parent
	if not view or not view:IsA("GuiObject") then return end

	local absPos = ZoomHandler.Workspace.Position
	local absSize = ZoomHandler.Workspace.AbsoluteSize
	local viewSize = view.AbsoluteSize

	local newX: number
	local newY: number

	-- X axis: center if content smaller than view; else clamp
	if absSize.X <= viewSize.X then
		newX = math.floor((viewSize.X - absSize.X) * 0.5)
	else
		local minX = viewSize.X - absSize.X -- negative
		local maxX = 0
		newX = math.clamp(absPos.X.Offset, minX, maxX)
	end

	-- Y axis: center if content smaller than view; else clamp
	if absSize.Y <= viewSize.Y then
		newY = math.floor((viewSize.Y - absSize.Y) * 0.5)
	else
		local minY = viewSize.Y - absSize.Y -- negative
		local maxY = 0
		newY = math.clamp(absPos.Y.Offset, minY, maxY)
	end

	ZoomHandler.Workspace.Position = UDim2.fromOffset(newX, newY)

	if ZoomHandler.OnLinesUpdate then
		ZoomHandler.OnLinesUpdate()
	end
end

return ZoomHandler