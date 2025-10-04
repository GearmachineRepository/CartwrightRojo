--!strict
local DragController = {}

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local GeneralUtil = require(Modules:WaitForChild("GeneralUtil"))
local ObjectValidator = require(Modules:WaitForChild("ObjectValidator"))

local DRAG_TAG: string = "Drag"
local DRAG_DETECTION_DISTANCE = 32.5
local SNAP_DISTANCE = GeneralUtil.SNAP_DISTANCE

local Player: Player = Players.LocalPlayer
local Mouse: Mouse = Player:GetMouse()
local Camera: Camera = workspace.CurrentCamera

local CurrentDraggedObject: (BasePart | Model)? = nil

local function BuildDragWhitelist(): {Instance}
	local Whitelist = {}
	for _, Instance in ipairs(CollectionService:GetTagged(DRAG_TAG)) do
		table.insert(Whitelist, Instance)
	end
	return Whitelist
end

function DragController.GetTargetPart(): (BasePart | Model)?
	local RayParams = RaycastParams.new()
	RayParams.FilterType = Enum.RaycastFilterType.Include
	RayParams.FilterDescendantsInstances = BuildDragWhitelist()
	RayParams.IgnoreWater = true

	local Ray = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
	local Result = workspace:Raycast(Ray.Origin, Ray.Direction * DRAG_DETECTION_DISTANCE, RayParams)
	if not Result then
		return nil
	end

	local HitInstance = Result.Instance
	local Node: Instance? = HitInstance

	while Node and Node ~= workspace do
		if CollectionService:HasTag(Node, DRAG_TAG) then
			if Node:IsA("BasePart") then
				local ParentModel = Node:FindFirstAncestorOfClass("Model")
				if ParentModel and CollectionService:HasTag(ParentModel, DRAG_TAG) then
					return ParentModel
				end
			end
			return Node :: any
		end
		Node = Node.Parent
	end

	return nil
end

function DragController.CanDragTarget(Target: Instance): (boolean, string?)
	if not Target or not Target.Parent then
		return false, "Invalid target"
	end

	if not CollectionService:HasTag(Target, DRAG_TAG) then
		return false, "Not draggable"
	end

	local Validation = ObjectValidator.CanDrag(Player, Target)
	if not Validation.IsValid then
		return false, Validation.Reason
	end

	return true
end

function DragController.FindNearestWheelAnchor(WheelPosition: Vector3): BasePart?
	local ClosestAnchor: BasePart? = nil
	local ClosestDistance = SNAP_DISTANCE

	local Character = Player.Character
	if not Character then
		return nil
	end

	for _, Cart in ipairs(workspace:GetDescendants()) do
		if Cart:IsA("Model") and Cart:GetAttribute("Owner") == Player.UserId then
			for _, Descendant in ipairs(Cart:GetDescendants()) do
				if Descendant:IsA("BasePart") and string.match(Descendant.Name, "Wheel") and Descendant.Parent.Name == "Anchors" then
					local Distance = (Descendant.Position - WheelPosition).Magnitude
					if Distance < ClosestDistance then
						ClosestDistance = Distance
						ClosestAnchor = Descendant
					end
				end
			end
		end
	end

	return ClosestAnchor
end

function DragController.SetDraggedObject(Object: (BasePart | Model)?): ()
	CurrentDraggedObject = Object
end

function DragController.GetDraggedObject(): (BasePart | Model)?
	return CurrentDraggedObject
end

function DragController.IsDragging(): boolean
	return CurrentDraggedObject ~= nil
end

return DragController