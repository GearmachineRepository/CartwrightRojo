--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local ToolInstancer = require(Modules:WaitForChild("ToolInstancer"))
local OwnershipManager = require(Modules:WaitForChild("OwnershipManager"))
local Maid = require(Modules:WaitForChild("Maid"))

local Events: Folder = ReplicatedStorage:WaitForChild("Events") :: Folder
local InteractionEvents: Folder = Events:WaitForChild("InteractionEvents") :: Folder
local DropRemote: RemoteEvent = InteractionEvents:WaitForChild("Drop") :: RemoteEvent

type MaidType = typeof(Maid.new())
type ToolData = {[Tool]: MaidType}
type PlayerData = {[Player]: {
	Tools: ToolData,
	CharacterMaid: MaidType
}}

local PlayerData: PlayerData = {}

local RaycastParams = RaycastParams.new()
RaycastParams.FilterType = Enum.RaycastFilterType.Exclude

local function SetupTool(Player: Player, Child: Tool): ()
	local Data = PlayerData[Player]
	if not Data then return end
	
	local ToolMaid = Maid.new()
	Data.Tools[Child] = ToolMaid
	
	ToolMaid:GiveTask(Child.Equipped:Connect(function()

	end))
	
	ToolMaid:GiveTask(Child.Unequipped:Connect(function()

	end))
	
	ToolMaid:GiveTask(Child.Activated:Connect(function()
		
	end))
end

local function CleanupTool(Player: Player, Child: Tool): ()
	local Data = PlayerData[Player]
	if not Data then return end

	local ToolMaid = Data.Tools[Child]
	if ToolMaid then
		ToolMaid:Destroy()
		Data.Tools[Child] = nil
	end
end

local function DropRequest(Player: Player)
	local Character = Player.Character
	if not Character then return end
	
	local Root = Character.PrimaryPart
	if not Root then return end

	local Tool = Character:FindFirstChildWhichIsA("Tool")
	if not Tool then return end
	
	local RootPosition = Root.Position
	local RootLookVector = Root.CFrame.LookVector
	local DropDistance = 3
	local DropPosition = RootPosition + (RootLookVector * DropDistance)

	RaycastParams.FilterDescendantsInstances = {Character}

	local RaycastResult = workspace:Raycast(RootPosition, RootLookVector * DropDistance, RaycastParams)

	if RaycastResult then
		local HitDistance = (RaycastResult.Position - RootPosition).Magnitude
		local SafeDistance = math.max(0.5, HitDistance - 0.5)
		DropPosition = RootPosition + (RootLookVector * SafeDistance)
	end

	local DroppedItem = ToolInstancer.Create(Tool, CFrame.new(DropPosition))
	if DroppedItem then
		DroppedItem:SetAttribute("Owner", Player.UserId)
		OwnershipManager.TrackOwnership(DroppedItem, Player.UserId)
	end

	Tool:Destroy()
end

local function InitializePlayerData(Player: Player): ()
	local CharacterMaid = Maid.new()
	
	PlayerData[Player] = {
		Tools = {},
		CharacterMaid = CharacterMaid
	}

	CharacterMaid:GiveTask(Player.CharacterAdded:Connect(function(Character)
		local ChildAddedConn = Character.ChildAdded:Connect(function(Child: Instance)
			if Child:IsA("Tool") then
				SetupTool(Player, Child)
			end
		end)
		
		local ChildRemovedConn = Character.ChildRemoved:Connect(function(Child: Instance)
			if Child:IsA("Tool") then
				CleanupTool(Player, Child)
			end
		end)
		
		CharacterMaid:GiveTask(ChildAddedConn)
		CharacterMaid:GiveTask(ChildRemovedConn)
	end))
end

local function CleanupPlayerData(Player: Player): ()
	local Data = PlayerData[Player]
	if not Data then return end

	for _, ToolMaid in pairs(Data.Tools) do
		ToolMaid:Destroy()
	end
	
	Data.CharacterMaid:Destroy()
	PlayerData[Player] = nil
end

Players.PlayerAdded:Connect(InitializePlayerData)
Players.PlayerRemoving:Connect(CleanupPlayerData)

DropRemote.OnServerEvent:Connect(DropRequest)

for _, Player: Player in pairs(Players:GetPlayers()) do
	InitializePlayerData(Player)
end

workspace.ChildAdded:Connect(function(Child)
	if Child:IsA("Tool") then
		task.wait(0.1)
		ToolInstancer.Create(Child)
	end
end)