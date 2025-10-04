--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local ObjectDatabase = require(Modules:WaitForChild("ObjectDatabase"))
local GeneralUtil = require(Modules:WaitForChild("GeneralUtil"))

local InventoryManager = {}

type InventoryData = {
	EquippedTool: Tool?,
	InventoryWeight: number,
	CartWeight: number,
	ItemCount: number,
	AttachedCart: Model?
}

local PlayerInventories: {[Player]: InventoryData} = {}
local CartMonitorThreads: {[Player]: thread} = {}
local BackpackConnections: {[Player]: {RBXScriptConnection}} = {}

local function GetItemWeight(ItemName: string): number
	local Config = ObjectDatabase.GetObjectConfig(ItemName)
	if Config and Config.Weight then
		return Config.Weight
	end
	return 1
end

local function GetCartWeight(Cart: Model): number
	local TotalWeight = 0
	
	local Wagon = Cart:FindFirstChild("Wagon")
	if not Wagon then 
		return 0 
	end
	
	local PlacementGrid = Wagon:FindFirstChild("PlacementGrid", true)
	if not PlacementGrid then 
		return 0 
	end
	
	for _, Item in ipairs(PlacementGrid:GetDescendants()) do
		if Item:IsA("Model") and Item:GetAttribute("SnappedToGrid") then
			TotalWeight += GetItemWeight(Item.Name)
		end
	end
	
	return TotalWeight
end

local function UpdatePlayerSpeed(Player: Player): ()
	local Data = PlayerInventories[Player]
	if not Data then 
		return 
	end
	
	local InventorySpeedReduction = Data.InventoryWeight / GeneralUtil.INVENTORY_WEIGHT_PER_SPEED
	local CartSpeedReduction = Data.CartWeight / (GeneralUtil.CART_WEIGHT_PER_SPEED * 2)
	
	local TotalReduction = InventorySpeedReduction + CartSpeedReduction
	local NewSpeed = math.max(4, GeneralUtil.BASE_WALKSPEED - TotalReduction)
	
	Player:SetAttribute("BaseWalkSpeed", NewSpeed)
end

local function RecalculateInventoryWeight(Player: Player): ()
	local Data = PlayerInventories[Player]
	if not Data then 
		return 
	end
	
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
	
	Data.InventoryWeight = TotalWeight
	Data.ItemCount = ItemCount
	
	UpdatePlayerSpeed(Player)
end

local function RecalculateCartWeight(Player: Player): ()
	local Data = PlayerInventories[Player]
	if not Data then 
		return 
	end
	
	if Data.AttachedCart and Data.AttachedCart.Parent then
		Data.CartWeight = GetCartWeight(Data.AttachedCart)
	else
		Data.CartWeight = 0
	end
	
	UpdatePlayerSpeed(Player)
end

local function MonitorCart(Player: Player, Cart: Model): ()
	local Data = PlayerInventories[Player]
	if not Data then 
		return 
	end
	
	Data.AttachedCart = Cart
	RecalculateCartWeight(Player)
	
	local Wagon = Cart:FindFirstChild("Wagon")
	if not Wagon then 
		return 
	end
	
	local PlacementGrid = Wagon:FindFirstChild("PlacementGrid", true)
	if not PlacementGrid then 
		return 
	end
	
	local Connections = {}
	
	table.insert(Connections, PlacementGrid.DescendantAdded:Connect(function(Descendant)
		if Descendant:IsA("Model") then
			task.wait(0.1)
			if PlayerInventories[Player] then 
				RecalculateCartWeight(Player)
			end
		end
	end))
	
	table.insert(Connections, PlacementGrid.DescendantRemoving:Connect(function(Descendant)
		if Descendant:IsA("Model") then
			task.wait(0.1)
			if PlayerInventories[Player] then
				RecalculateCartWeight(Player)
			end
		end
	end))

	local function Cleanup()
		for _, Connection in ipairs(Connections) do
			Connection:Disconnect()
		end
		if CartMonitorThreads[Player] then
			task.cancel(CartMonitorThreads[Player])
			CartMonitorThreads[Player] = nil
		end
	end
	
	CartMonitorThreads[Player] = task.spawn(function()
		while PlayerInventories[Player] and Data.AttachedCart == Cart do
			task.wait(2)
			if PlayerInventories[Player] and Data.AttachedCart == Cart then
				RecalculateCartWeight(Player)
			else
				break
			end
		end
		Cleanup()
	end)
end

local function StopMonitoringCart(Player: Player): ()
	local Data = PlayerInventories[Player]
	if not Data then 
		return 
	end
	
	Data.AttachedCart = nil
	Data.CartWeight = 0

	if CartMonitorThreads[Player] then
		task.cancel(CartMonitorThreads[Player])
		CartMonitorThreads[Player] = nil
	end
	
	UpdatePlayerSpeed(Player)
end

function InventoryManager.CanPickupItem(Player: Player, _: string): (boolean, string?)
	local Data = PlayerInventories[Player]
	if not Data then
		return false, "No inventory data"
	end
	
	if Data.ItemCount >= GeneralUtil.MAX_INVENTORY_SLOTS then
		return false, string.format("Inventory full (%d/%d)", Data.ItemCount, GeneralUtil.MAX_INVENTORY_SLOTS)
	end
	
	return true
end

function InventoryManager.GetInventoryInfo(Player: Player): {ItemCount: number, InventoryWeight: number, CartWeight: number, MaxSlots: number}
	local Data = PlayerInventories[Player]
	if not Data then
		return {
			ItemCount = 0, 
			InventoryWeight = 0, 
			CartWeight = 0, 
			MaxSlots = GeneralUtil.MAX_INVENTORY_SLOTS
		}
	end
	
	return {
		ItemCount = Data.ItemCount,
		InventoryWeight = Data.InventoryWeight,
		CartWeight = Data.CartWeight,
		MaxSlots = GeneralUtil.MAX_INVENTORY_SLOTS
	}
end

function InventoryManager.OnItemPickedUp(Player: Player): ()
	task.wait(0.1)
	RecalculateInventoryWeight(Player)
end

function InventoryManager.InitializePlayer(Player: Player): ()
	PlayerInventories[Player] = {
		EquippedTool = nil,
		InventoryWeight = 0,
		CartWeight = 0,
		ItemCount = 0,
		AttachedCart = nil
	}
	
	Player:SetAttribute("BaseWalkSpeed", GeneralUtil.BASE_WALKSPEED)
	
	Player:GetAttributeChangedSignal("Carting"):Connect(function()
		local IsCarting = Player:GetAttribute("Carting")
		if IsCarting then
			local Character = Player.Character
			if Character then
				local AttachedCart
				for _, Object in ipairs(workspace:GetDescendants()) do
					if Object:IsA("Model") and Object:GetAttribute("Type") == "Cart" then
						if Object:GetAttribute("Owner") == Player.UserId and Object:GetAttribute("AttachedTo") == Player.Name then
							AttachedCart = Object
							break
						end
					end
				end
				
				if AttachedCart then
					MonitorCart(Player, AttachedCart)
				end
			end
		else
			StopMonitoringCart(Player)
		end
	end)
	
	local function OnCharacterAdded(Character: Model)
		task.wait(0.5)
		RecalculateInventoryWeight(Player)
		
		Character.ChildAdded:Connect(function(Child)
			if Child:IsA("Tool") then
				task.wait(0.1)
				RecalculateInventoryWeight(Player)
			end
		end)
			
		Character.ChildRemoved:Connect(function(Child)
			if Child:IsA("Tool") then
				task.wait(0.1)
				RecalculateInventoryWeight(Player)
			end
		end)
	end
	
	if Player.Character then
		OnCharacterAdded(Player.Character)
	end
	
	Player.CharacterAdded:Connect(OnCharacterAdded)
	
	BackpackConnections[Player] = {}
	
	local Backpack = Player:WaitForChild("Backpack", 5)
	if Backpack then
		table.insert(BackpackConnections[Player], Backpack.ChildAdded:Connect(function(Child)
			if Child:IsA("Tool") then
				task.wait(0.1)
				RecalculateInventoryWeight(Player)
			end
		end))
		
		table.insert(BackpackConnections[Player], Backpack.ChildRemoved:Connect(function(Child)
			if Child:IsA("Tool") then
				task.wait(0.1)
				RecalculateInventoryWeight(Player)
			end
		end))
	end
end

function InventoryManager.CleanupPlayer(Player: Player): ()
	if CartMonitorThreads[Player] then
		task.cancel(CartMonitorThreads[Player])
		CartMonitorThreads[Player] = nil
	end
	
	if BackpackConnections[Player] then
		for _, Connection in pairs(BackpackConnections[Player]) do
			Connection:Disconnect()
		end
		BackpackConnections[Player] = nil
	end
	
	PlayerInventories[Player] = nil
end

Players.PlayerAdded:Connect(InventoryManager.InitializePlayer)
Players.PlayerRemoving:Connect(InventoryManager.CleanupPlayer)

return InventoryManager