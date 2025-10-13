--!strict
local InputManager = require(script.Parent.Parent.Managers.InputManager)
local ConnectionManager = require(script.Parent.Parent.Managers.ConnectionManager)

local ZoomController = {}

local CurrentZoom = 1.0
local MinZoom = 0.1
local MaxZoom = 2.0
local ZoomSpeed = 0.1
local Workspace: Frame? = nil
local OnZoomChanged: ((number) -> ())? = nil
local Connections = ConnectionManager.Create()

function ZoomController.Initialize(WorkspaceFrame: Frame, OnZoomCallback: ((number) -> ())?)
	Workspace = WorkspaceFrame
	OnZoomChanged = OnZoomCallback

	Connections:Cleanup()
	Connections = ConnectionManager.Create()

	Connections:Add(InputManager.SubscribeToScroll(function(Direction: number)
		if Direction > 0 then
			ZoomController.ZoomIn()
		else
			ZoomController.ZoomOut()
		end
	end))
end

function ZoomController.ZoomIn()
	local NewZoom = math.min(CurrentZoom + ZoomSpeed, MaxZoom)
	ZoomController.SetZoom(NewZoom)
end

function ZoomController.ZoomOut()
	local NewZoom = math.max(CurrentZoom - ZoomSpeed, MinZoom)
	ZoomController.SetZoom(NewZoom)
end

function ZoomController.SetZoom(Zoom: number)
	CurrentZoom = Zoom

	if Workspace then
		local UIScale = Workspace:FindFirstChildOfClass("UIScale")
		if not UIScale then
			UIScale = Instance.new("UIScale")
			UIScale.Parent = Workspace
		end
		UIScale.Scale = CurrentZoom
	end

	if OnZoomChanged then
		OnZoomChanged(CurrentZoom)
	end
end

function ZoomController.GetZoom(): number
	return CurrentZoom
end

function ZoomController.ResetZoom()
	ZoomController.SetZoom(1.0)
end

function ZoomController.Cleanup()
	Connections:Cleanup()
end

return ZoomController