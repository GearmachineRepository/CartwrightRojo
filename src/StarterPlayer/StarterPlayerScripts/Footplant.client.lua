local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Maid = require(Modules:WaitForChild("Maid"))

local Events = ReplicatedStorage:WaitForChild("Events")
local FootplantRemotes = Events:WaitForChild("FootplantEvents")
local OnFootPlanted = FootplantRemotes:WaitForChild("OnFootPlanted")

local LocalPlayer = Players.LocalPlayer

type MaidType = typeof(Maid.new())

local CharacterMaid: MaidType = Maid.new()

local function OnKeyframeReached(_: AnimationTrack, _: Model) -- AnimationTrack, Character
	OnFootPlanted:FireServer(true)
	task.wait(0.1)
	OnFootPlanted:FireServer(false)
end

local function ConnectToAnimationTrack(Track: AnimationTrack, Character: Model)
	local TrackMaid = Maid.new()
	
	TrackMaid:GiveTask(Track:GetMarkerReachedSignal("Footplant"):Connect(function()
		OnKeyframeReached(Track, Character)
	end))

	TrackMaid:GiveTask(Track.Stopped:Connect(function()
		TrackMaid:Destroy()
	end))
	
	CharacterMaid:GiveTask(TrackMaid)
end

local function OnAnimationPlayed(AnimationTrack: AnimationTrack)
	local Character = LocalPlayer.Character
	if Character then
		ConnectToAnimationTrack(AnimationTrack, Character)
	end
end

local function SetupCharacter(Character: Model)
	CharacterMaid:DoCleaning()

	local Humanoid = Character:WaitForChild("Humanoid") :: Humanoid
	local Animator = Humanoid:WaitForChild("Animator") :: Animator

	CharacterMaid:GiveTask(Animator.AnimationPlayed:Connect(OnAnimationPlayed))

	local PlayingTracks = Animator:GetPlayingAnimationTracks()
	for _, Track in ipairs(PlayingTracks) do
		ConnectToAnimationTrack(Track, Character)
	end
end

local function OnCharacterAdded(Character: Model)
	SetupCharacter(Character)
end

local function OnCharacterRemoving()
	CharacterMaid:DoCleaning()
end

if LocalPlayer.Character then
	SetupCharacter(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)
LocalPlayer.CharacterRemoving:Connect(OnCharacterRemoving)