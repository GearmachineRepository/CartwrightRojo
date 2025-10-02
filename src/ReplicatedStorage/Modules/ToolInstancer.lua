local ToolInstancer = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

-- Modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local PlacementSnap = require(Modules:WaitForChild("PlacementSnap"))
local ObjectDatabase = require(Modules:WaitForChild("ObjectDatabase"))
local CartAssembly = require(Modules:WaitForChild("CartAssembly"))
local InventoryManager = require(Modules:WaitForChild("InventoryManager"))
local PhysicsGroups = require(Modules:WaitForChild("PhysicsGroups"))

-- Constants
local DRAG_TAG: string = "Drag"
local INTERACTION_TAG: string = "Interactable"

-- Assets
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Items = Assets:WaitForChild("Items")

-- check if an item exists in the Items folder
function ToolInstancer.ItemExists(itemName: string): boolean
	return Items:FindFirstChild(itemName) ~= nil
end

-- get all available item names
function ToolInstancer.GetAvailableItems(): {string}
	local itemNames = {}
	for _, item in pairs(Items:GetChildren()) do
		table.insert(itemNames, item.Name)
	end
	return itemNames
end

function ToolInstancer.Create(object: Instance | string, Location: CFrame?): Model?
	local sourceObject: Instance?
	local shouldDestroyOriginal = false

	if type(object) == "string" then
		local itemName = object :: string
		local itemTemplate = Items:FindFirstChild(itemName)

		if not itemTemplate then
			warn("Item '" .. itemName .. "' not found in Items folder")
			return nil
		end

		-- Clone the item template
		sourceObject = itemTemplate:Clone()
		shouldDestroyOriginal = false -- Don't destroy the template
	else
		-- Handle Instance input
		sourceObject = object :: Instance
		shouldDestroyOriginal = true -- Destroy the original object
	end

	if not sourceObject then
		warn("No valid source object provided")
		return nil
	end

	local model = Instance.new("Model")
	model.Name = sourceObject.Name

	local handle: BasePart? = sourceObject:FindFirstChild("Handle") :: BasePart?
	
	local toolCFrame: CFrame = handle and handle.CFrame or CFrame.new()
	if Location then
		toolCFrame = Location
	end

	-- Move/copy all children from source to model
	local childrenToMove = {}
	for _, child in pairs(sourceObject:GetChildren()) do
		table.insert(childrenToMove, child)
	end

	for _, child in pairs(childrenToMove) do
		-- For string-based creation, we're working with a clone, so we can move directly
		-- For instance-based creation, we're moving from the original
		child.Parent = model

		if child == handle then
			child.Name = "Handle" 
			if child:IsA("BasePart") then
				PhysicsGroups.SetProperty(child, "Anchored", false)
				PhysicsGroups.SetProperty(child, "CanCollide", true)
			end
		end
	end

	-- Set primary part
	if handle and handle.Parent == model then
		model.PrimaryPart = handle
	else
		model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart")
	end

	-- Set collision properties for all parts
	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = true
			part.Anchored = false
		end
	end

	model.Parent = workspace:FindFirstChild("Draggables") or workspace:FindFirstChild("Interactables")

	-- Set position
	if model.PrimaryPart then
		model.PrimaryPart:SetNetworkOwnershipAuto()
		model:PivotTo(toolCFrame)
	end

	-- Clean up original if needed
	if shouldDestroyOriginal then
		sourceObject:Destroy()
	end
	
	-- Get data
	local DataType = ObjectDatabase.GetObjectType(sourceObject.Name)

	-- Add attributes and tags
	model:SetAttribute("CurrentState", "StateB")
	model:SetAttribute("PartType", if DataType then DataType else nil)
	CollectionService:AddTag(model, DRAG_TAG)
	CollectionService:AddTag(model, INTERACTION_TAG)

	return model
end

function ToolInstancer.Pickup(Player: Player, Object: Instance, Config: any): ()
	local Tool: Tool
	local ObjectName = Object.Name
	
	if #Object:GetDescendants() <= 1 or not Object:IsDescendantOf(workspace) then return end
	
	-- CHECK INVENTORY LIMIT
	local CanPickup, Reason = InventoryManager.CanPickupItem(Player, ObjectName)
	if not CanPickup then
		warn("[ToolInstancer] Cannot pickup:", Reason)
		-- TODO: Show feedback to player using FeedbackUI
		return
	end
	
	local ExistingTool = Items:FindFirstChild(ObjectName)
	if ExistingTool and ExistingTool:IsA("Tool") then
		Tool = ExistingTool:Clone()
	else
		Tool = Instance.new("Tool")
		Tool.Name = ObjectName
		Tool.RequiresHandle = true

		if Object:IsA("Model") then
			local PrimaryPart = Object.PrimaryPart or Object:FindFirstChildWhichIsA("BasePart")
			if PrimaryPart then
				PlacementSnap.UnsnapFromPlacementCell(Object)
				CartAssembly.detachWheelAttachment(Object.Parent.Parent.Parent, Object)
				
				for _, Child in pairs(Object:GetChildren()) do
					Child.Parent = Tool
				end
				
				local Handle = Tool:FindFirstChild(PrimaryPart.Name)
				if Handle and Handle:IsA("BasePart") then
					Handle.Name = "Handle"
					Handle.CanCollide = false
					Handle.Anchored = false
				end
			end
		elseif Object:IsA("BasePart") then
			local Handle = Object:Clone()
			Handle.Name = "Handle"
			Handle.CanCollide = false
			Handle.Anchored = false
			Handle.Parent = Tool
		end

		if Config then
			Tool.ToolTip = Config.ToolTip or ObjectName
			if Config.TextureId then
				Tool.TextureId = Config.TextureId
			end
		else
			Tool.ToolTip = ObjectName
		end
	end
	
	PhysicsGroups.SetProperty(Tool, "Anchored", false)
	Tool.Parent = Player.Backpack

	if Object:IsDescendantOf(workspace) then
		Object:Destroy()
	end
end

return ToolInstancer