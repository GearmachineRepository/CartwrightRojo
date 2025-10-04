--!strict
local ToolInstancer = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local PlacementSnap = require(Modules:WaitForChild("PlacementSnap"))
local ObjectDatabase = require(Modules:WaitForChild("ObjectDatabase"))
local CartAssembly = require(Modules:WaitForChild("CartAssembly"))
local InventoryManager = require(Modules:WaitForChild("InventoryManager"))
local PhysicsGroups = require(Modules:WaitForChild("PhysicsGroups"))

local DRAG_TAG: string = "Drag"
local INTERACTION_TAG: string = "Interactable"

local Assets = ReplicatedStorage:WaitForChild("Assets")
local Items = Assets:WaitForChild("Items")

function ToolInstancer.ItemExists(ItemName: string): boolean
	return Items:FindFirstChild(ItemName) ~= nil
end

function ToolInstancer.GetAvailableItems(): {string}
	local ItemNames = {}
	for _, Item in pairs(Items:GetChildren()) do
		table.insert(ItemNames, Item.Name)
	end
	return ItemNames
end

function ToolInstancer.Create(Object: Instance | string, Location: CFrame?): Model?
	local SourceObject: Instance?
	local ShouldDestroyOriginal = false

	if type(Object) == "string" then
		local ItemName = Object :: string
		local ItemTemplate = Items:FindFirstChild(ItemName)

		if not ItemTemplate then
			warn("Item '" .. ItemName .. "' not found in Items folder")
			return nil
		end

		SourceObject = ItemTemplate:Clone()
		ShouldDestroyOriginal = false
	else
		SourceObject = Object :: Instance
		ShouldDestroyOriginal = true
	end

	if not SourceObject then
		warn("No valid source object provided")
		return nil
	end

	local NewModel = Instance.new("Model")
	NewModel.Name = SourceObject.Name

	local Handle: BasePart? = SourceObject:FindFirstChild("Handle") :: BasePart?

	local ToolCFrame: CFrame = Handle and Handle.CFrame or CFrame.new()
	if Location then
		ToolCFrame = Location
	end

	local ChildrenToMove = {}
	for _, Child in pairs(SourceObject:GetChildren()) do
		table.insert(ChildrenToMove, Child)
	end

	for _, Child in pairs(ChildrenToMove) do
		Child.Parent = NewModel

		if Child == Handle then
			Child.Name = "Handle"
			if Child:IsA("BasePart") then
				PhysicsGroups.SetProperty(Child, "Anchored", false)
				PhysicsGroups.SetProperty(Child, "CanCollide", true)
			end
		end
	end

	if Handle and Handle.Parent == NewModel then
		NewModel.PrimaryPart = Handle
	else
		NewModel.PrimaryPart = NewModel:FindFirstChildWhichIsA("BasePart")
	end

	for _, Part in pairs(NewModel:GetDescendants()) do
		if Part:IsA("BasePart") then
			Part.CanCollide = true
			Part.Anchored = false
		end
	end

	NewModel.Parent = workspace:FindFirstChild("Draggables") or workspace:FindFirstChild("Interactables")

	if NewModel.PrimaryPart then
		NewModel.PrimaryPart:SetNetworkOwnershipAuto()
		NewModel:PivotTo(ToolCFrame)
	end

	if ShouldDestroyOriginal then
		SourceObject:Destroy()
	end

	local DataType = ObjectDatabase.GetObjectType(SourceObject.Name)

	NewModel:SetAttribute("CurrentState", "StateB")
	NewModel:SetAttribute("PartType", if DataType then DataType else nil)
	CollectionService:AddTag(NewModel, DRAG_TAG)
	CollectionService:AddTag(NewModel, INTERACTION_TAG)

	return NewModel
end

function ToolInstancer.Pickup(Player: Player, Object: Instance, Config: any): ()
	local Tool: Tool
	local ObjectName = Object.Name

	if #Object:GetDescendants() <= 1 or not Object:IsDescendantOf(workspace) then
		return
	end

	local CanPickup, Reason = InventoryManager.CanPickupItem(Player, ObjectName)
	if not CanPickup then
		warn("[ToolInstancer] Cannot pickup:", Reason)
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

				local NewHandle = Tool:FindFirstChild(PrimaryPart.Name)
				if NewHandle and NewHandle:IsA("BasePart") then
					NewHandle.Name = "Handle"
					NewHandle.CanCollide = false
					NewHandle.Anchored = false
				end
			end
		elseif Object:IsA("BasePart") then
			local NewHandle = Object:Clone()
			NewHandle.Name = "Handle"
			NewHandle.CanCollide = false
			NewHandle.Anchored = false
			NewHandle.Parent = Tool
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

	Tool.Parent = Player.Backpack
	PhysicsGroups.SetProperty(Tool, "Anchored", false)
	PhysicsGroups.SetProperty(Tool, "CanCollide", false)

	InventoryManager.OnItemPickedUp(Player)

	if Object:IsDescendantOf(workspace) then
		Object:Destroy()
	end
end

return ToolInstancer