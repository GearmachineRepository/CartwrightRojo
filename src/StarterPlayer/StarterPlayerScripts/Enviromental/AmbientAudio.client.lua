local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AmbientAudio = ReplicatedStorage:WaitForChild("AmbientAudio")

local AmbientSoundManager = require(AmbientAudio:WaitForChild("AmbientSoundManager"))

AmbientSoundManager.SetConfiguration({
	TargetDynamicSounds = 4,
	DynamicSchedulerInterval = 0.25,
	SoundFadeSpeed = 10,

	WindEnabled = true,
	WindIntensity = 1.5,
	WindBedVolume = 0.15,
	WindGustTarget = 2,     -- try 2 on coasts/cliffs
	WindSpeedStudsPerSec = workspace.GlobalWind.Magnitude * 5,

})

task.wait(1)
for Index, Tree in pairs(CollectionService:GetTagged("Tree")) do
	AmbientSoundManager.RegisterDynamicSource(Tree.PrimaryPart, "TreeRustling")
end
for Index, Grass in pairs(CollectionService:GetTagged("Grass")) do
	AmbientSoundManager.RegisterDynamicSource(Grass.PrimaryPart, "GrassRustle")
end

CollectionService:GetInstanceAddedSignal("Tree"):Connect(function(Child: Instance)
	AmbientSoundManager.RegisterDynamicSource(Child.PrimaryPart, "TreeRustling")
end)

CollectionService:GetInstanceAddedSignal("Grass"):Connect(function(Child: Instance)
	AmbientSoundManager.RegisterDynamicSource(Child.PrimaryPart, "GrassRustle")
end)

AmbientSoundManager.Initialize()

-- Optimization loop
local Player = Players.LocalPlayer
local Character = Player.Character
local root = nil

while true do
	if not Character then Character = Player.Character task.wait(.5) continue end
	if not root then root = Character:FindFirstChild("HumanoidRootPart") task.wait(.5) continue end

	AmbientSoundManager.Update(root.Position)

	task.wait()
end
