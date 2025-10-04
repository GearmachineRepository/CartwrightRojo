--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Maid = require(Modules:WaitForChild("Maid"))

type MaidType = typeof(Maid.new())

local PlayerMaids: {[Player]: MaidType} = {}

local function GetCharactersFolder(): Folder
	local Folder = workspace:FindFirstChild("Characters")
	if not Folder or not Folder:IsA("Folder") then
		if Folder then 
			Folder:Destroy() 
		end
		Folder = Instance.new("Folder")
		Folder.Name = "Characters"
		Folder.Parent = workspace
	end
	return Folder
end

local function ReparentCharacterToFolder(Character: Model, Folder: Folder)
	if Character and Character.Parent ~= Folder then
		Character.Parent = Folder
	end
end

local function OnCharacterAdded(_: Player, Character: Model)
	local Folder = GetCharactersFolder()
	task.defer(function()
		if Character and Character.Parent then
			ReparentCharacterToFolder(Character, Folder)
		end
	end)
end

local function HandlePlayer(Player: Player)
	local PlayerMaid = Maid.new()
	PlayerMaids[Player] = PlayerMaid

	PlayerMaid:GiveTask(Player.CharacterAdded:Connect(function(Character)
		OnCharacterAdded(Player, Character)
	end))

	if Player.Character then
		OnCharacterAdded(Player, Player.Character)
	end
end

local function OnPlayerRemoving(Player: Player)
	local PlayerMaid = PlayerMaids[Player]
	if PlayerMaid then
		PlayerMaid:Destroy()
		PlayerMaids[Player] = nil
	end
end

for _, PlayerInGame in ipairs(Players:GetPlayers()) do
	HandlePlayer(PlayerInGame)
end

Players.PlayerAdded:Connect(HandlePlayer)
Players.PlayerRemoving:Connect(OnPlayerRemoving)