--!strict
local InventoryManager = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local ObjectDatabase = require(Modules:WaitForChild("ObjectDatabase"))

local MAX_INVENTORY_SLOTS = 3
local BASE_WALKSPEED = 16
local WEIGHT_PER_SPEED_REDUCTION = 5

type InventoryData = {
	EquippedTool: Tool?,
	TotalWeight: number,
	ItemCount: number
}

local PlayerInventories: {[Player]: InventoryData} = {}

local function GetItemWeight(ItemName: string): number
	local Config = ObjectDatabase.GetObjectConfig(ItemName)
	if Config and Config.Weight then
		return Config.Weight
	end
	return 1
end

local function UpdatePlayerSpeed(Player: Player)
	local Character = Player.Character
	if not Character then return end
	
	local Humanoid = Character:FindFirstChild("Humanoid") :: Humanoid?
	if not Humanoid then return end
	
	local Data = PlayerInventories[Player]
	if not Data then return end
	
	if Player:GetAttribute("Carting") then
		return
	end
	
	local SpeedReduction = Data.TotalWeight / WEIGHT_PER_SPEED_REDUCTION
	local NewSpeed = math.max(4, BASE_WALKSPEED - SpeedReduction)
	
	Humanoid.WalkSpeed = NewSpeed
end

local function RecalculateWeight(Player: Player)
	local Data = PlayerInventories[Player]
	if not Data then return end
	
	local TotalWeight = 0
	local ItemCount = 0
	
	local Backpack = Player:FindFirstChild("Backpack")
	if Backpack then
		for _, Item in ipairs(Backpack:GetChildren()) do
			if Item:IsA("Tool") then
				ItemCount += 1
				TotalWeight += GetItemWeight(Item.Name)
			end
		end
	end
	
	local Character = Player.Character
	if Character then
		for _, Item in ipairs(Character:GetChildren()) do
			if Item:IsA("Tool") then
				ItemCount += 1
				TotalWeight += GetItemWeight(Item.Name)
			end
		end
	end
	
	Data.TotalWeight = TotalWeight
	Data.ItemCount = ItemCount
	
	UpdatePlayerSpeed(Player)
end

function InventoryManager.CanPickupItem(Player: Player, _: string): (boolean, string?)
	local Data = PlayerInventories[Player]
	if not Data then
		return false, "No inventory data"
	end
	
	if Data.ItemCount >= MAX_INVENTORY_SLOTS then
		return false, string.format("Inventory full (%d/%d)", Data.ItemCount, MAX_INVENTORY_SLOTS)
	end
	
	return true
end

function InventoryManager.GetInventoryInfo(Player: Player): {ItemCount: number, TotalWeight: number, MaxSlots: number}
	local Data = PlayerInventories[Player]
	if not Data then
		return {ItemCount = 0, TotalWeight = 0, MaxSlots = MAX_INVENTORY_SLOTS}
	end
	
	return {
		ItemCount = Data.ItemCount,
		TotalWeight = Data.TotalWeight,
		MaxSlots = MAX_INVENTORY_SLOTS
	}
end

function InventoryManager.InitializePlayer(Player: Player)
	PlayerInventories[Player] = {
		EquippedTool = nil,
		TotalWeight = 0,
		ItemCount = 0
	}
	
	local function OnCharacterAdded(Character: Model)
		task.wait(0.5)
		RecalculateWeight(Player)
		
		Character.ChildAdded:Connect(function(Child)
			if Child:IsA("Tool") then
				task.wait(0.1)
				RecalculateWeight(Player)
			end
		end)
		
		Character.ChildRemoved:Connect(function(Child)
			if Child:IsA("Tool") then
				task.wait(0.1)
				RecalculateWeight(Player)
			end
		end)
	end
	
	if Player.Character then
		OnCharacterAdded(Player.Character)
	end
	
	Player.CharacterAdded:Connect(OnCharacterAdded)
	
	local Backpack = Player:WaitForChild("Backpack", 5)
	if Backpack then
		Backpack.ChildAdded:Connect(function(Child)
			if Child:IsA("Tool") then
				task.wait(0.1)
				RecalculateWeight(Player)
			end
		end)
		
		Backpack.ChildRemoved:Connect(function(Child)
			if Child:IsA("Tool") then
				task.wait(0.1)
				RecalculateWeight(Player)
			end
		end)
	end
end

function InventoryManager.CleanupPlayer(Player: Player)
	PlayerInventories[Player] = nil
end

Players.PlayerAdded:Connect(function(Player)
	InventoryManager.InitializePlayer(Player)
end)

Players.PlayerRemoving:Connect(function(Player)
	InventoryManager.CleanupPlayer(Player)
end)

for _, Player in ipairs(Players:GetPlayers()) do
	InventoryManager.InitializePlayer(Player)
end

return InventoryManager