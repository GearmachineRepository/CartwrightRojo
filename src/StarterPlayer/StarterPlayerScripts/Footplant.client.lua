local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = ReplicatedStorage:WaitForChild("Events")
local FootplantRemotes = Events:WaitForChild("FootplantEvents")
local OnFootPlanted = FootplantRemotes:WaitForChild("OnFootPlanted")

local LocalPlayer = Players.LocalPlayer

local connections = {}

local function onKeyframeReached(animationTrack, character)
	OnFootPlanted:FireServer(true)
	task.wait(.1)
	OnFootPlanted:FireServer(false)
end

local function connectToAnimationTrack(track: AnimationTrack, character)
	-- Connect to the KeyframeReached event for this track
	local connection = track:GetMarkerReachedSignal("Footplant"):Connect(function()
		onKeyframeReached(track, character)
	end)

	-- Store the connection for cleanup
	table.insert(connections, connection)

	-- Clean up when the track stops
	track.Stopped:Connect(function()
		connection:Disconnect()
		-- Remove from connections table
		for i, conn in ipairs(connections) do
			if conn == connection then
				table.remove(connections, i)
				break
			end
		end
	end)
end

local function onAnimationPlayed(animationTrack)
	local character = LocalPlayer.Character
	if character then
		connectToAnimationTrack(animationTrack, character)
	end
end

local function setupCharacter(character)
	-- Clear existing connections
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	connections = {}

	-- Wait for humanoid and animator
	local humanoid = character:WaitForChild("Humanoid")
	local animator = humanoid:WaitForChild("Animator")

	-- Connect to animation played event
	animator.AnimationPlayed:Connect(onAnimationPlayed)

	-- Also check for any currently playing animations
	local playingTracks = animator:GetPlayingAnimationTracks()
	for _, track in ipairs(playingTracks) do
		connectToAnimationTrack(track, character)
	end
end

local function onCharacterAdded(character)
	setupCharacter(character)
end

local function onCharacterRemoving()
	-- Clean up connections when character is removed
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	connections = {}
end

-- Connect to player events
if LocalPlayer.Character then
	setupCharacter(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
LocalPlayer.CharacterRemoving:Connect(onCharacterRemoving)