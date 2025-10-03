--!strict
--!optimize 2
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local GridVisualization = require(Modules:WaitForChild("GridVisualization"))
local DragVisuals = require(Modules:WaitForChild("DragVisuals"))
local DragController = require(Modules:WaitForChild("DragController"))

-- Constants
local DRAG_DISTANCE: number = 10
local MIN_DRAG_DISTANCE: number = 5
local MAX_DRAG_DISTANCE: number = 20
local DISTANCE_INCREMENT: number = 1
local UPDATE_FREQUENCY: number = 1/60
local LastWheelIndicatorUpdate = 0
local WHEEL_INDICATOR_UPDATE_RATE = 0.1

-- Services and Objects
local Player: Player = Players.LocalPlayer
local Mouse: Mouse = Player:GetMouse()
local Camera: Camera = workspace.CurrentCamera

-- Remote Events
local Events: Folder = ReplicatedStorage:WaitForChild("Events")

local DragEvents: Folder = Events:WaitForChild("DragEvents") :: Folder
local UpdateCameraPositionRemote: RemoteEvent = DragEvents:WaitForChild("UpdateCameraPosition") :: RemoteEvent
local DragObjectRemote: RemoteEvent = DragEvents:WaitForChild("DragObject") :: RemoteEvent

local InputEvents: Folder = Events:WaitForChild("InputEvents") :: Folder
local DragStartEvent: BindableEvent = InputEvents:WaitForChild("DragStart") :: BindableEvent
local DragStopEvent: BindableEvent = InputEvents:WaitForChild("DragStop") :: BindableEvent
local AdjustDistanceEvent: BindableEvent = InputEvents:WaitForChild("AdjustDistance") :: BindableEvent

-- Variables
local IsMouseHeld: boolean = false
local CameraUpdateConnection: RBXScriptConnection?
local LastUpdateTime: number = 0
local CurrentDragDistance: number = DRAG_DISTANCE

-- Check if we're in first person
local function IsFirstPerson(): boolean
	if not Player.Character then return false end

	local Head: BasePart? = Player.Character:FindFirstChild("Head") :: BasePart
	if not Head then return false end

	local DistanceToHead: number = (Camera.CFrame.Position - Head.Position).Magnitude
	return DistanceToHead < 2
end

-- Handle distance adjustment
local function AdjustDistance(direction: number, modifierHeld: boolean): ()
	if not IsFirstPerson() and not modifierHeld then return end

	CurrentDragDistance = math.clamp(
		CurrentDragDistance + (direction * DISTANCE_INCREMENT),
		MIN_DRAG_DISTANCE,
		MAX_DRAG_DISTANCE
	)
end

-- Camera Position Update Function
local function UpdateCameraPosition(): ()
	local CurrentTime: number = tick()
	if CurrentTime - LastUpdateTime < UPDATE_FREQUENCY then
		return
	end
	LastUpdateTime = CurrentTime

	if not Player.Character then return end

	local Character: Model = Player.Character
	local Head: BasePart? = Character:FindFirstChild("Head") :: BasePart
	if not Head then return end

	local HeadPosition: Vector3 = Head.Position
	local CameraPosition: Vector3 = Camera.CFrame.Position
	local DistanceToHead: number = (CameraPosition - HeadPosition).Magnitude
	local IsFirstPersonMode: boolean = DistanceToHead < 2

	local TargetPosition: Vector3

	if IsFirstPersonMode then
		local CameraForward: Vector3 = Camera.CFrame.LookVector
		TargetPosition = HeadPosition + (CameraForward * CurrentDragDistance)
	else
		local MouseDirection: Vector3 = (Mouse.Hit.Position - HeadPosition).Unit
		TargetPosition = HeadPosition + (MouseDirection * CurrentDragDistance)
	end

	local CurrentDragged = DragController.GetDraggedObject()
	if CurrentTime - LastWheelIndicatorUpdate >= WHEEL_INDICATOR_UPDATE_RATE then
		LastWheelIndicatorUpdate = CurrentTime
		
		if CurrentDragged and CurrentDragged:IsA("Model") and CurrentDragged:GetAttribute("PartType") == "Wheel" then
			local WheelRoot = CurrentDragged.PrimaryPart or CurrentDragged:FindFirstChildWhichIsA("BasePart")
			if WheelRoot then
				local NearestAnchor = DragController.FindNearestWheelAnchor(WheelRoot.Position)
				if NearestAnchor then
					if not DragVisuals.GetCurrentWheelIndicator() then
						DragVisuals.CreateWheelIndicator(WheelRoot, NearestAnchor)
					else
						DragVisuals.UpdateWheelIndicator(NearestAnchor)
					end
				else
					DragVisuals.RemoveWheelIndicator()
				end
			end
		else
			DragVisuals.RemoveWheelIndicator()
		end
	end

	local TargetCFrame: CFrame = CFrame.lookAt(TargetPosition, TargetPosition + Camera.CFrame.LookVector)
	UpdateCameraPositionRemote:FireServer(TargetCFrame)
end

-- Input Event Handlers
local function OnDragStart(): ()
	if Player:GetAttribute("Carting") then
		return
	end

	IsMouseHeld = true
	CurrentDragDistance = DRAG_DISTANCE

	local Target = DragController.GetTargetPart()
	if not Target then return end

	local canDrag, reason = DragController.CanDragTarget(Target)
	if not canDrag then
		return
	end

	DragController.SetDraggedObject(Target)
	DragVisuals.CreateHighlight(Target)
	DragObjectRemote:FireServer(Target, true)

	if not Target:HasTag("Cart") then
		GridVisualization.StartVisualization(Target, Player.UserId, Player.Character)
	end

	-- Verify drag started on server
	task.delay(0.25, function()
		local draggedObj = DragController.GetDraggedObject()
		if draggedObj and (not draggedObj:GetAttribute("BeingDragged")) then
			DragVisuals.RemoveHighlight(true)
			GridVisualization.StopVisualization()
			DragController.SetDraggedObject(nil)
		end
	end)
end

local function OnDragStop(): ()
	IsMouseHeld = false

	DragVisuals.RemoveHighlight(false)
	DragVisuals.RemoveWheelIndicator()
	GridVisualization.StopVisualization()
	DragController.SetDraggedObject(nil)
	DragObjectRemote:FireServer(nil, false)

	-- Safety cleanup
	task.delay(0.1, function()
		DragVisuals.CleanupAll()
	end)
end

local function OnDistanceAdjust(direction: number, modifierHeld: boolean): ()
	if IsMouseHeld then
		AdjustDistance(direction, modifierHeld)
	end
end

-- Cleanup function
local function CleanupHighlights(): ()
	DragVisuals.CleanupAll()
	DragController.SetDraggedObject(nil)
end

-- Initialize Camera Update Loop
local function StartCameraUpdate(): ()
	if CameraUpdateConnection then
		CameraUpdateConnection:Disconnect()
	end

	CameraUpdateConnection = RunService.Heartbeat:Connect(UpdateCameraPosition)
end

-- Connect to Input Events
DragStartEvent.Event:Connect(OnDragStart)
DragStopEvent.Event:Connect(OnDragStop)
AdjustDistanceEvent.Event:Connect(OnDistanceAdjust)

-- Start camera updates when player spawns
Player.CharacterAdded:Connect(function(_: Model)
	CleanupHighlights()
	GridVisualization.CleanupVisualization()
	StartCameraUpdate()
end)

-- Start immediately if character already exists
if Player.Character then
	StartCameraUpdate()
end