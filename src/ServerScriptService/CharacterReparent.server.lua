--!strict
local Players = game:GetService("Players")

-- Keep track of connections per player for cleanup
local charAddedConns: {[Player]: RBXScriptConnection} = {}

local function getCharactersFolder(): Folder
	local folder = workspace:FindFirstChild("Characters")
	if not folder or not folder:IsA("Folder") then
		if folder then folder:Destroy() end
		folder = Instance.new("Folder")
		folder.Name = "Characters"
		folder.Parent = workspace
	end
	return folder
end

local function reparentCharacterToFolder(character: Model, folder: Folder)
	if character and character.Parent ~= folder then
		character.Parent = folder
	end
end

local function onCharacterAdded(player: Player, character: Model)
	-- Ensure folder exists (handles runtime deletion/recreation)
	local folder = getCharactersFolder()
	-- Slight defer so engine finishes initial assembly (optional)
	task.defer(function()
		if character and character.Parent then
			reparentCharacterToFolder(character, folder)
		end
	end)
end

local function handlePlayer(player: Player)
	-- If somehow we already had a connection for this player, replace it safely
	if charAddedConns[player] then
		charAddedConns[player]:Disconnect()
		charAddedConns[player] = nil
	end

	-- Connect once per player, store for cleanup
	charAddedConns[player] = player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)

	-- Reparent an already-spawned character (if any)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

-- Cleanup on leave
local function onPlayerRemoving(player: Player)
	local conn = charAddedConns[player]
	if conn then
		conn:Disconnect()
		charAddedConns[player] = nil
	end
end

-- Hook existing players (in case script starts late)
for _, p in ipairs(Players:GetPlayers()) do
	handlePlayer(p)
end

Players.PlayerAdded:Connect(handlePlayer)
Players.PlayerRemoving:Connect(onPlayerRemoving)
