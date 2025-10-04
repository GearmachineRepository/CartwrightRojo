--!strict
local DragController = {}

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

-- Modules
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local GeneralUtil = require(Modules:WaitForChild("GeneralUtil"))
local ObjectValidator = require(Modules:WaitForChild("ObjectValidator"))

-- Constants
local DRAG_TAG: string = "Drag"
local DRAG_DETECTION_DISTANCE = 32.5
local SNAP_DISTANCE = GeneralUtil.SNAP_DISTANCE

local Player: Player = Players.LocalPlayer
local Mouse: Mouse = Player:GetMouse()
local Camera: Camera = workspace.CurrentCamera

-- State
local CurrentDraggedObject: (BasePart | Model)? = nil

-- Build whitelist of draggable objects
local function BuildDragWhitelist(): {Instance}
	local list = {}
	for _, inst in ipairs(CollectionService:GetTagged(DRAG_TAG)) do
		table.insert(list, inst)
	end
	return list
end

-- Get target part under mouse
function DragController.GetTargetPart(): (BasePart | Model)?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = BuildDragWhitelist()
	params.IgnoreWater = true

	local ray = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
	local res = workspace:Raycast(ray.Origin, ray.Direction * DRAG_DETECTION_DISTANCE, params)
	if not res then return nil end

	local hit = res.Instance
	-- Walk up to find first Drag-tagged ancestor
	local node: Instance? = hit
	while node and node ~= workspace do
		if CollectionService:HasTag(node, DRAG_TAG) then
			-- Prefer returning the model if present
			if node:IsA("BasePart") then
				local m = node:FindFirstAncestorOfClass("Model")
				if m and CollectionService:HasTag(m, DRAG_TAG) then
					return m
				end
			end
			return node :: any
		end
		node = node.Parent
	end
	return nil
end

-- Check if player can drag target
function DragController.CanDragTarget(target: Instance): (boolean, string?)
	if not target or not target.Parent then
		return false, "Invalid target"
	end

	if not CollectionService:HasTag(target, DRAG_TAG) then
		return false, "Not draggable"
	end

	-- Use validator for comprehensive checks
	local validation = ObjectValidator.CanDrag(Player, target)
	if not validation.IsValid then
		return false, validation.Reason
	end

	return true
end

-- Find nearest wheel anchor for snapping
function DragController.FindNearestWheelAnchor(wheelPosition: Vector3): BasePart?
	local closestAnchor: BasePart? = nil
	local closestDistance = SNAP_DISTANCE

	local character = Player.Character
	if not character then return nil end

	-- Find carts owned by player
	for _, cart in ipairs(workspace:GetDescendants()) do
		if cart:IsA("Model") and cart:GetAttribute("Owner") == Player.UserId then
			-- Look for wheel anchors in this cart
			for _, descendant in ipairs(cart:GetDescendants()) do
				if descendant:IsA("BasePart") and string.match(descendant.Name, "Wheel") and descendant.Parent.Name == "Anchors" then
					local distance = (descendant.Position - wheelPosition).Magnitude
					if distance < closestDistance then
						closestDistance = distance
						closestAnchor = descendant
					end
				end
			end
		end
	end

	return closestAnchor
end

-- Set currently dragged object
function DragController.SetDraggedObject(object: (BasePart | Model)?): ()
	CurrentDraggedObject = object
end

-- Get currently dragged object
function DragController.GetDraggedObject(): (BasePart | Model)?
	return CurrentDraggedObject
end

-- Check if dragging
function DragController.IsDragging(): boolean
	return CurrentDraggedObject ~= nil
end

return DragController